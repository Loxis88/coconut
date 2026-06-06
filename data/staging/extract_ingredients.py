"""
extract_ingredients.py

Parses ingredient composition strings from rosqual products into
individual ingredient names using LLM (gpt-4o-mini).

Writes results to staging.raw_product_ingredients.
Tracks progress in .ingredients_progress.json — safe to restart.

Usage:
    python staging/extract_ingredients.py
"""

import os
import json
import time
import logging
from typing import Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

import psycopg2
from psycopg2.extras import execute_values
from pydantic import BaseModel
from openai import OpenAI

from config import DB_CONFIG, OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

LLM_BATCH = 1          # products per LLM call
MAX_WORKERS = 1         # parallel LLM calls

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROGRESS_FILE = os.path.join(SCRIPT_DIR, ".ingredients_progress.json")


# ── Pydantic models ──────────────────────────────────────────────────────────

class Ingredient(BaseModel):
    name: str
    is_transparent: bool = True
    qty: Optional[float] = None
    unit: Optional[str] = None
    qualifier: Optional[str] = None


class ProductIngredients(BaseModel):
    source_id: str
    ingredients: list[Ingredient]


class ExtractionResponse(BaseModel):
    products: list[ProductIngredients]


# ── LLM extraction ──────────────────────────────────────────────────────────

SYSTEM_PROMPT = """\
Ты парсер составов продуктов питания. Тебе дан список продуктов с полем "ingredients" (строка состава).

Для каждого продукта извлеки ВСЕ отдельные ингредиенты.

Правила парсинга:
1. Раскрывай скобки: "масло растительное (подсолнечное, пальмовое)" → "масло подсолнечное", "масло пальмовое".
2. "загуститель пектин" → name="пектин". "консервант сорбат калия" → name="сорбат калия". \
Функция (загуститель, консервант, краситель, эмульгатор, стабилизатор, антиокислитель, \
регулятор кислотности, разрыхлитель, фиксатор окраски, усилитель вкуса и аромата, \
глазирователь, подсластитель, желирующий агент, агент влагоудерживающий, уплотнитель) — \
НЕ часть названия. Убирай её.
3. Если указана ТОЛЬКО функция без конкретики ("ароматизаторы", "красители", "специи") → \
name = функция в единственном числе ("ароматизатор", "краситель", "специя").
4. "перец черный, белый, зеленый" → "перец черный", "перец белый", "перец зеленый".
6. qty/unit/qualifier — если указано количество: "не менее 25%" → qty=25, unit="%", qualifier="min". \
"не более 1%" → qty=1, unit="%", qualifier="max". Иначе null.
7. is_transparent — false если производитель использует общую формулировку без конкретики: \
"ароматизатор" (какой?), "красители" (какие?), "специи" (какие?), "растительные масла" (какие?). \
Если указано конкретно ("ароматизатор ванилин", "масло подсолнечное") → true.
8. Все названия в нижнем регистре.
9. Текст после точки вне скобок — не ингредиенты (информация о составе), игнорируй.
10. "содержит следы" / "может содержать" — не ингредиенты, игнорируй.
"""


def extract_batch(
    client: OpenAI,
    products: list[dict],
) -> list[ProductIngredients]:
    """Extract ingredients. Retries individual missed products."""
    results = _call_llm(client, products)

    # Retry missed products individually
    returned_ids = {r.source_id for r in results}
    missed = [p for p in products if p["source_id"] not in returned_ids]
    if missed:
        log.warning("    Missed %d products, retrying individually...", len(missed))
        for product in missed:
            retry_results = _call_llm(client, [product])
            results.extend(retry_results)

    return results


def _call_llm(
    client: OpenAI,
    products: list[dict],
) -> list[ProductIngredients]:
    log.info("    Calling LLM for %d products...", len(products))
    user_content = json.dumps({"products": products}, ensure_ascii=False)

    for attempt in range(3):
        try:
            completion = client.beta.chat.completions.parse(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_content},
                ],
                response_format=ExtractionResponse,
                temperature=0.0,
            )
            usage = completion.usage
            log.info(
                "    Tokens: %d prompt + %d completion = %d total",
                usage.prompt_tokens, usage.completion_tokens, usage.total_tokens,
            )
            parsed = completion.choices[0].message.parsed
            if parsed is None:
                raw_content = completion.choices[0].message.content
                log.warning("    Parsed is None! finish_reason=%s raw=%s",
                            completion.choices[0].finish_reason,
                            raw_content[:500] if raw_content else "EMPTY")
                continue
            log.info("    Sent: %d  Returned: %d", len(products), len(parsed.products))
            return parsed.products
        except Exception as e:
            wait = 2 ** attempt
            log.warning("    attempt %d failed: %s — retry in %ds", attempt + 1, e, wait)
            time.sleep(wait)

    log.error("    LLM failed after 3 attempts for %d products", len(products))
    return []


# ── Progress ─────────────────────────────────────────────────────────────────

def load_progress() -> set[str]:
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return set(data.get("done_source_ids", []))
    return set()


def save_progress(done_ids: set[str]):
    with open(PROGRESS_FILE, "w", encoding="utf-8") as f:
        json.dump({"done_source_ids": sorted(done_ids)}, f)


# ── Main ─────────────────────────────────────────────────────────────────────

def run_extraction():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS staging.raw_product_ingredients (
                source_id TEXT NOT NULL,
                ingredient_name TEXT NOT NULL,
                position INT,
                is_transparent BOOLEAN DEFAULT true,
                qty NUMERIC,
                unit TEXT,
                qualifier TEXT
            )
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_raw_pi_source_id
            ON staging.raw_product_ingredients (source_id)
        """)
    conn.commit()

    # 1. Fetch rosqual products with ingredients
    with conn.cursor() as cur:
        cur.execute("""
            SELECT source_id, ingredients
            FROM product_catalog.product
            WHERE source = 'rosqual'
              AND ingredients IS NOT NULL
        """)
        all_products = cur.fetchall()

    # Filter out already processed
    done_ids = load_progress()

    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT source_id FROM staging.raw_product_ingredients")
        done_in_staging = {row[0] for row in cur.fetchall()}
    done_ids |= done_in_staging

    products = [p for p in all_products if p[0] not in done_ids]

    log.info(
        "Products with ingredients: %d total, %d already done, %d to process",
        len(all_products), len(done_ids), len(products),
    )

    if not products:
        log.info("Nothing to process")
        conn.close()
        return

    # 2. Process in batches via LLM
    import httpx
    client = OpenAI(
        api_key=OPENAI_API_KEY,
        http_client=httpx.Client(
            limits=httpx.Limits(
                max_connections=MAX_WORKERS,
                max_keepalive_connections=MAX_WORKERS,
            )
        ),
    )
    total_rows = 0

    # Split all products into LLM-sized batches
    batches = []
    for i in range(0, len(products), LLM_BATCH):
        sub = products[i:i + LLM_BATCH]
        llm_input = [
            {"source_id": source_id, "ingredients": ingredients}
            for source_id, ingredients in sub
        ]
        batches.append((sub, llm_input))

    log.info("Total batches: %d (batch size=%d, workers=%d)", len(batches), LLM_BATCH, MAX_WORKERS)
    completed = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {
            pool.submit(extract_batch, client, llm_input): sub
            for sub, llm_input in batches
        }
        for future in as_completed(futures):
            sub = futures[future]
            results = future.result()
            completed += 1

            staging_rows = []
            sub_done = []
            for product_result in results:
                for pos, ing in enumerate(product_result.ingredients, start=1):
                    name = ing.name.strip().lower()
                    if not name:
                        continue
                    staging_rows.append((
                        product_result.source_id, name, pos,
                        ing.is_transparent,
                        ing.qty, ing.unit, ing.qualifier,
                    ))
                sub_done.append(product_result.source_id)

            if staging_rows:
                with conn.cursor() as cur:
                    execute_values(
                        cur,
                        """
                        INSERT INTO staging.raw_product_ingredients
                            (source_id, ingredient_name, position, is_transparent,
                             qty, unit, qualifier)
                        VALUES %s
                        """,
                        staging_rows,
                    )
                total_rows += len(staging_rows)

            for sid in sub_done:
                done_ids.add(sid)

            conn.commit()
            save_progress(done_ids)
            log.info("  Batch %d/%d done. Products: %d/%d, rows: %d",
                     completed, len(batches), len(done_ids), len(all_products), total_rows)

    log.info("Done. Total staging rows inserted: %d", total_rows)
    conn.close()


if __name__ == "__main__":
    run_extraction()
