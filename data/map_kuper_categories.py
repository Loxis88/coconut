"""
map_kuper_categories.py

Maps RSKRF (Роскачество) categories to deduplicated Kuper store categories
using LLM (gpt-4o-mini) for semantic matching.

Workflow:
  1. Gets distinct store_ids from staging.raw_kuper
  2. Fetches category tree per store via Kuper API (Playwright)
  3. Collects unique leaf category names across all stores
  4. Loads RSKRF categories from product_catalog.category
  5. Uses LLM to match: RSKRF category → Kuper leaf category
  6. Saves to kuper_category_mapping.json

Usage:
    python map_kuper_categories.py
"""

import json
import os
import logging

import psycopg2
from pydantic import BaseModel
from openai import OpenAI
from playwright.sync_api import sync_playwright

from config import DB_CONFIG, OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "kuper_category_mapping.json")


# ── Pydantic models ──────────────────────────────────────────────────────────

class CategoryMatch(BaseModel):
    source_name: str
    target_name: str


class CategoryMappingResponse(BaseModel):
    matches: list[CategoryMatch]


# ── Kuper store categories ───────────────────────────────────────────────────

def fetch_store_categories(page, store_id: int) -> list[dict]:
    """
    Получает категории через браузерную сессию Kuper.
    Использует те же куки и заголовки, что настоящий сайт.
    """
    try:
        result = page.evaluate(
            """
            async (storeId) => {
                const resp = await fetch(
                    `https://kuper.ru/api/v3/stores/${storeId}/categories?tree_depth=2`,
                    {
                        method: "GET",
                        credentials: "include"
                    }
                );

                if (!resp.ok) {
                    throw new Error(
                        `HTTP ${resp.status}: ${await resp.text()}`
                    );
                }

                return await resp.json();
            }
            """,
            store_id,
        )

        cats = result.get("categories", [])
        log.info("  Store %d: %d top-level categories", store_id, len(cats))
        return cats

    except Exception as e:
        log.error(
            "Failed to fetch categories for store %d: %s",
            store_id,
            e,
        )
        return []


def collect_leaf_names(categories: list[dict]) -> set[str]:
    """Recursively collect leaf category names."""
    leaves = set()
    for cat in categories:
        name = cat.get("name", "")
        if name.startswith("Все товары"):
            continue

        has_children = cat.get("has_children")
        children = cat.get("children", [])
        real_children = [c for c in children if not c.get("name", "").startswith("Все товары")]

        if has_children is False or (has_children is None and not real_children):
            leaves.add(name)
        else:
            leaves |= collect_leaf_names(real_children)
    return leaves


# ── LLM matching ─────────────────────────────────────────────────────────────

def match_via_llm(
    client: OpenAI,
    source_names: list[str],
    target_names: list[str],
) -> list[CategoryMatch]:
    target_list = "\n".join(f"  - {name}" for name in target_names)
    source_list = "\n".join(f"  - {name}" for name in source_names)

    system = (
        "Ты эксперт по категоризации продуктов питания в российских магазинах.\n\n"
        "Тебе даны два списка категорий:\n"
        "  1. ИСТОЧНИК — категории Роскачества (rskrf.ru)\n"
        "  2. ЦЕЛЬ — категории магазина Kuper (Сбермаркет)\n\n"
        "Для каждой категории-источника выбери ОДНУ наиболее подходящую "
        "категорию-цель из списка. Используй точное название из списка целей.\n"
        "Если ни одна категория не подходит — выбери ближайшую по смыслу."
    )

    user = (
        f"Категории-источник (Роскачество):\n{source_list}\n\n"
        f"Категории-цель (Kuper):\n{target_list}"
    )

    try:
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            response_format=CategoryMappingResponse,
            temperature=0.0,
        )
        return completion.choices[0].message.parsed.matches
    except Exception as e:
        log.error("LLM matching failed: %s", e)
        return []


# ── Main ─────────────────────────────────────────────────────────────────────

def build_mapping():
    # 1. Get distinct store_ids
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT DISTINCT (data->>'store_id')::int
            FROM staging.raw_kuper
            WHERE data->>'store_id' IS NOT NULL
        """)
        store_ids = [row[0] for row in cur.fetchall()]

    if not store_ids:
        log.error("No store_ids found in raw_kuper")
        conn.close()
        return

    log.info(
        "Found %d distinct store(s): %s",
        len(store_ids),
        store_ids,
    )

    # 2. Start Playwright using existing Chrome session
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(
            "http://127.0.0.1:9222"
        )

        context = browser.contexts[0]
        page = context.new_page()

        page.goto(
            "https://kuper.ru",
            wait_until="domcontentloaded",
            timeout=30000,
        )

        # 3. Fetch categories through browser session
        all_leaves: set[str] = set()

        for sid in store_ids:
            log.info("Fetching categories for store %d...", sid)

            cats = fetch_store_categories(page=page, store_id=sid)
            leaves = collect_leaf_names(cats)

            log.info("Store %d: %d leaf categories", sid, len(leaves))
            all_leaves |= leaves

    log.info("Total unique Kuper leaf categories: %d", len(all_leaves))

    if not all_leaves:
        log.error("No leaf categories found")
        conn.close()
        return

    kuper_names = sorted(all_leaves)

    # 4. Load RSKRF categories
    with conn.cursor() as cur:
        cur.execute("""
            SELECT rskrf_id, title, depth
            FROM product_catalog.category
            ORDER BY depth, title
        """)
        rskrf_rows = cur.fetchall()

    conn.close()

    if not rskrf_rows:
        log.error(
            "No RSKRF categories in DB. Run dict_categories.py first."
        )
        return

    rskrf_all = [
        {"id": rid, "name": title, "depth": depth}
        for rid, title, depth in rskrf_rows
    ]

    log.info(
        "RSKRF categories: %d (depth 0: %d, depth 1: %d)",
        len(rskrf_all),
        sum(1 for r in rskrf_all if r["depth"] == 0),
        sum(1 for r in rskrf_all if r["depth"] == 1),
    )

    # 5. LLM matching: RSKRF → Kuper
    client = OpenAI(api_key=OPENAI_API_KEY)
    rskrf_names = [r["name"] for r in rskrf_all]
    rskrf_by_name = {r["name"]: r for r in rskrf_all}

    BATCH_SIZE = 50
    mapping = {}

    for i in range(0, len(rskrf_names), BATCH_SIZE):
        batch = rskrf_names[i:i + BATCH_SIZE]
        log.info(
            "LLM batch %d-%d / %d | sources: %s",
            i + 1, i + len(batch), len(rskrf_names), batch,
        )

        matches = match_via_llm(
            client,
            source_names=batch,
            target_names=kuper_names,
        )

        for m in matches:
            rskrf_entry = rskrf_by_name.get(m.source_name)
            if rskrf_entry and m.target_name in all_leaves:
                mapping[m.source_name] = {
                    "kuper_name": m.target_name,
                    "rskrf_id": rskrf_entry["id"],
                    "depth": rskrf_entry["depth"],
                    "match": "llm",
                }
                log.info(
                    "  %s (rskrf_id=%d depth=%d) → %s",
                    m.source_name, rskrf_entry["id"],
                    rskrf_entry["depth"], m.target_name,
                )

    # Mark unmatched
    for name in rskrf_names:
        if name not in mapping:
            log.warning("  UNMATCHED: %s", name)
            mapping[name] = None

    result = {"rskrf_to_kuper": mapping}

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    n_mapped = sum(1 for v in mapping.values() if v)
    n_missed = sum(1 for v in mapping.values() if not v)

    log.info("Saved to %s", OUTPUT_FILE)
    log.info("Mapped: %d, missed: %d", n_mapped, n_missed)


if __name__ == "__main__":
    build_mapping()
