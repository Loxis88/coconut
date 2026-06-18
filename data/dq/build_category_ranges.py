"""
build_category_ranges.py

Builds the per-category nutrition-range dictionary with an LLM and stores it in
dq.category_nutrition_range. For each food category, the model returns plausible
min/max per-100g bounds for each nutrient — e.g. protein in tea ~0, calories in
water ~0. run_dq.py's category_nutrition check then flags products whose values
fall outside their category's range.

Categories are processed most-used first and in batches (one LLM call covers
many categories). Resumable: categories already in the table are skipped unless
--refresh is given.

Usage:
    python dq/build_category_ranges.py                # all uncovered categories
    python dq/build_category_ranges.py --limit 200    # only top 200 by product count
    python dq/build_category_ranges.py --batch-size 8 # categories per LLM call (default 8)
    python dq/build_category_ranges.py --refresh      # regenerate even if present
"""

import argparse
import logging
import sys
import time
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values
from pydantic import BaseModel
from openai import OpenAI
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG, OPENAI_API_KEY

MODEL = "gpt-4o-mini"

# Nutrients the model bounds, with the unit it must reason in (per 100 g).
NUTRIENTS = {
    "calories_kcal":   "kcal",
    "protein_g":       "g",
    "fat_g":           "g",
    "saturated_fat_g": "g",
    "carbs_g":         "g",
    "fiber_g":         "g",
    "sugar_g":         "g",
    "salt_g":          "g",
    "sodium_mg":       "mg",
}


# ── Structured output ────────────────────────────────────────────────────


class NutrientRange(BaseModel):
    nutrient: str          # one of NUTRIENTS keys
    min_per_100g: float
    max_per_100g: float


class CategoryRanges(BaseModel):
    category_name: str     # echoed back exactly as given
    ranges: list[NutrientRange]


class BatchResponse(BaseModel):
    categories: list[CategoryRanges]


SYSTEM_PROMPT = f"""You are a food-science and nutrition expert helping build a \
data-quality dictionary. For each food CATEGORY you are given, output realistic \
lower and upper bounds for the following nutrients, expressed PER 100 g of the \
product as sold:

{chr(10).join(f"- {col} (in {unit})" for col, unit in NUTRIENTS.items())}

Rules:
- Bounds must cover the realistic spread of genuine products in that category, \
but be tight enough to flag impossible values. Think of the 1st and 99th \
percentile of real products, then round outward slightly.
- If a nutrient is essentially absent for the category, use a min of 0 and a \
small max (e.g. protein in tea or coffee infusions ~0-1 g; calories/sugar in \
still water ~0-1; salt in fresh fruit ~0-0.2).
- Nothing per 100 g can exceed 100 g for a single macronutrient, 900 kcal for \
calories, or 40000 mg for sodium. Never output negative numbers.
- Category names are OpenFoodFacts-style tags such as "en:black-teas", \
"en:still-waters", "en:salted-butters". Interpret them as food categories.
- Echo category_name back EXACTLY as provided. Provide all listed nutrients."""


def fetch_categories(conn, limit: int | None, refresh: bool) -> list[str]:
    """Categories that have at least one product, most-used first.
    Skips categories already covered unless --refresh."""
    covered_filter = ""
    if not refresh:
        covered_filter = """
            AND c.name NOT IN (
                SELECT DISTINCT category_name FROM dq.category_nutrition_range
            )"""
    sql = f"""
        SELECT c.name, count(*) AS n
        FROM product_catalog.category c
        JOIN product_catalog.product p ON p.category_id = c.id
        WHERE c.name IS NOT NULL AND c.name <> ''
        {covered_filter}
        GROUP BY c.name
        ORDER BY n DESC
    """
    if limit:
        sql += f"\nLIMIT {int(limit)}"
    with conn.cursor() as cur:
        cur.execute(sql)
        return [r[0] for r in cur.fetchall()]


# Map loose nutrient names the model may emit onto canonical column names.
NUTRIENT_ALIASES = {
    "protein": "protein_g", "proteins": "protein_g",
    "fat": "fat_g", "total_fat": "fat_g", "fats": "fat_g",
    "saturated_fat": "saturated_fat_g", "sat_fat": "saturated_fat_g",
    "saturates": "saturated_fat_g",
    "carbs": "carbs_g", "carbohydrate": "carbs_g", "carbohydrates": "carbs_g",
    "fiber": "fiber_g", "fibre": "fiber_g", "dietary_fiber": "fiber_g",
    "sugar": "sugar_g", "sugars": "sugar_g",
    "salt": "salt_g",
    "sodium": "sodium_mg",
    "calories": "calories_kcal", "energy": "calories_kcal", "kcal": "calories_kcal",
}


def _canon_nutrient(name: str) -> str | None:
    key = name.strip().lower().replace(" ", "_").replace("-", "_")
    if key in NUTRIENTS:
        return key
    return NUTRIENT_ALIASES.get(key)


def _norm(name: str) -> str:
    """Normalize a category name for matching: drop a leading language prefix
    like 'en:', lowercase, and unify separators. The model often echoes back
    'black-teas' for 'en:black-teas', so we match on this and keep the original."""
    n = name.strip().lower()
    if ":" in n:
        n = n.split(":", 1)[1]
    return n.replace("_", "-").replace(" ", "-").strip("-")


def call_llm(client: OpenAI, category_names: list[str]) -> BatchResponse | None:
    user = "Categories:\n" + "\n".join(f"- {c}" for c in category_names)
    t0 = time.monotonic()
    try:
        completion = client.beta.chat.completions.parse(
            model=MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user},
            ],
            response_format=BatchResponse,
            temperature=0.0,
        )
        log.info("  LLM responded in %.1fs", time.monotonic() - t0)
        return completion.choices[0].message.parsed
    except Exception as e:
        log.error("LLM call failed after %.1fs (batch of %d): %s",
                  time.monotonic() - t0, len(category_names), e)
        return None


def upsert(conn, rows: list[tuple]):
    if not rows:
        return
    with conn.cursor() as cur:
        execute_values(
            cur,
            """
            INSERT INTO dq.category_nutrition_range
                (category_name, nutrient, min_per_100g, max_per_100g, model)
            VALUES %s
            ON CONFLICT (category_name, nutrient) DO UPDATE
              SET min_per_100g = EXCLUDED.min_per_100g,
                  max_per_100g = EXCLUDED.max_per_100g,
                  model        = EXCLUDED.model,
                  generated_at = now()
            """,
            rows,
        )
    conn.commit()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None,
                    help="only the top-N categories by product count")
    ap.add_argument("--batch-size", type=int, default=8,
                    help="categories per LLM call (keep small; big batches stall the model)")
    ap.add_argument("--refresh", action="store_true",
                    help="regenerate ranges even for already-covered categories")
    args = ap.parse_args()

    client = OpenAI(api_key=OPENAI_API_KEY, timeout=90)
    conn = psycopg2.connect(**DB_CONFIG)

    categories = fetch_categories(conn, args.limit, args.refresh)
    log.info("Categories to process: %d (batch size %d)", len(categories), args.batch_size)
    if not categories:
        log.info("Nothing to do.")
        conn.close()
        return

    total_rows = 0

    n_batches = (len(categories) + args.batch_size - 1) // args.batch_size
    for bi, i in enumerate(
        tqdm(range(0, len(categories), args.batch_size), desc="LLM batches"), 1
    ):
        batch = categories[i:i + args.batch_size]
        # Map normalized name -> original, so we can recover the model's answer
        # even when it drops the 'en:' prefix or tweaks separators.
        by_norm = {_norm(c): c for c in batch}

        log.info("Batch %d/%d: %d categories", bi, n_batches, len(batch))
        resp = call_llm(client, batch)
        if resp is None:
            continue

        rows: list[tuple] = []
        matched = 0
        for cat in resp.categories:
            original = by_norm.get(_norm(cat.category_name))
            if original is None:
                log.warning("Could not match returned category %r, skipping", cat.category_name)
                continue
            matched += 1
            for nr in cat.ranges:
                nut = _canon_nutrient(nr.nutrient)
                if nut is None:
                    log.warning("Unknown nutrient %r for %s", nr.nutrient, original)
                    continue
                lo, hi = nr.min_per_100g, nr.max_per_100g
                if lo > hi:
                    lo, hi = hi, lo
                rows.append((original, nut, lo, hi, MODEL))

        upsert(conn, rows)
        total_rows += len(rows)
        log.info("  matched %d/%d categories, upserted %d range rows",
                 matched, len(batch), len(rows))

    log.info("Done. Upserted %d range rows into dq.category_nutrition_range", total_rows)
    conn.close()


if __name__ == "__main__":
    main()
