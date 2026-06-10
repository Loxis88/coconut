"""
map_rosqual_categories.py

Maps RSKRF (Роскачество) categories to Sbermarket (Kuper) categories
using LLM (gpt-4o-mini) for semantic matching.

Workflow:
  1. Fetches RSKRF category tree from rskrf.ru API
     (top categories → subcategories → product groups)
  2. Loads Sbermarket categories from example_categories.json
  3. Uses LLM to match:
     - category_mapping:       RSKRF subcategory → Sbermarket top-level
     - product_group_mapping:  RSKRF product group → Sbermarket depth-1 subcategory
  4. Saves to rosqual_category_mapping.json

Usage:
    python map_rosqual_categories.py
"""

import json
import os
import logging

import requests
from pydantic import BaseModel
from openai import OpenAI

from config import OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_URL = "https://rskrf.ru/rest/1"
KUPER_CATEGORIES_FILE = os.path.join(SCRIPT_DIR, "example_categories.json")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "rosqual_category_mapping.json")

# RSKRF top-level IDs with food content
FOOD_CATEGORY_IDS = [8, 28]  # Продукты питания, Напитки


# ── Pydantic models for structured LLM output ─────────────────────────────────

class CategoryMatch(BaseModel):
    source_name: str
    target_id: int
    target_name: str


class CategoryMappingResponse(BaseModel):
    matches: list[CategoryMatch]


# ── HTTP ──────────────────────────────────────────────────────────────────────

http_session = requests.Session()


def fetch_json(url: str) -> dict | None:
    try:
        resp = http_session.get(url, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        log.error("GET %s → %s", url, e)
        return None


def fetch_rskrf_tree() -> list[dict]:
    """Fetch: top categories → subcategories → product groups."""
    top = fetch_json(f"{BASE_URL}/catalog/categories/")
    if not top:
        return []

    tree = []
    for cat in top.get("response", []):
        if cat["id"] not in FOOD_CATEGORY_IDS:
            continue

        log.info("Category: %s (id=%d)", cat["title"], cat["id"])
        sub_data = fetch_json(f"{BASE_URL}/catalog/categories/{cat['id']}/")
        if not sub_data:
            continue

        raw = sub_data.get("response", [])
        if isinstance(raw, dict):
            raw = [raw]

        subcats = []
        for sub in raw:
            log.info("  Subcategory: %s (id=%d)", sub["title"], sub["id"])
            pg = fetch_json(
                f"{BASE_URL}/catalog/categories/{sub['id']}/productGroups/"
            )
            groups = []
            if pg:
                r = pg.get("response", {})
                if isinstance(r, dict):
                    groups = [
                        {"id": g["id"], "title": g["title"]}
                        for g in r.get("productGroups", [])
                        if "id" in g and "title" in g
                    ]

            subcats.append({
                "id": sub["id"],
                "title": sub["title"],
                "product_groups": groups,
            })

        tree.append({
            "id": cat["id"],
            "title": cat["title"],
            "subcategories": subcats,
        })

    return tree


# ── Sbermarket categories ─────────────────────────────────────────────────────

def load_kuper_categories() -> list[dict]:
    with open(KUPER_CATEGORIES_FILE, "r", encoding="utf-8") as f:
        return json.load(f)["categories"]


def flatten_kuper(categories: list[dict]) -> list[dict]:
    """Flatten nested Sbermarket tree into a flat list."""
    result = []
    for cat in categories:
        result.append({
            "id": cat["id"],
            "name": cat["name"],
            "depth": cat.get("depth", 0),
        })
        for ch in cat.get("children", []):
            result.append({
                "id": ch["id"],
                "name": ch["name"],
                "depth": ch.get("depth", 1),
            })
            for ch2 in ch.get("children", []):
                result.append({
                    "id": ch2["id"],
                    "name": ch2["name"],
                    "depth": ch2.get("depth", 2),
                })
    return result


def build_kuper_children_index(
    categories: list[dict],
) -> dict[int, list[dict]]:
    """Map: top-level kuper ID → depth-1 children (skip 'Все товары …')."""
    index: dict[int, list[dict]] = {}
    for cat in categories:
        children = []
        for ch in cat.get("children", []):
            if ch["name"].startswith("Все товары"):
                continue
            children.append({"id": ch["id"], "name": ch["name"]})
        index[cat["id"]] = children
    return index


# ── LLM matching ──────────────────────────────────────────────────────────────

def match_via_llm(
    client: OpenAI,
    source_names: list[str],
    target_categories: list[dict],
    context_hint: str = "",
) -> list[CategoryMatch]:
    """Use LLM to match source names to target categories.

    Args:
        source_names:      List of RSKRF category/product group names to map.
        target_categories: List of dicts with 'id' and 'name' (Sbermarket side).
        context_hint:      Extra context for the LLM (e.g. parent category info).

    Returns:
        List of CategoryMatch objects.
    """
    target_list = "\n".join(
        f"  {c['id']}: {c['name']}" for c in target_categories
    )
    source_list = "\n".join(f"  - {name}" for name in source_names)

    system = (
        "Ты эксперт по категоризации продуктов питания в российских магазинах.\n\n"
        "Тебе даны два списка категорий:\n"
        "  1. ИСТОЧНИК — категории Роскачества (rskrf.ru)\n"
        "  2. ЦЕЛЬ — категории Сбермаркета (kuper.ru)\n\n"
        "Для каждой категории-источника выбери ОДНУ наиболее подходящую "
        "категорию-цель из списка. Используй точные id и name из списка целей.\n"
        "Если ни одна категория не подходит — выбери ближайшую по смыслу."
    )

    user = f"{context_hint}Категории-источник (Роскачество):\n{source_list}\n\n" \
           f"Категории-цель (Сбермаркет):\n{target_list}"

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


# ── Build mapping ─────────────────────────────────────────────────────────────

def build_mapping():
    client = OpenAI(api_key=OPENAI_API_KEY)

    # 1. RSKRF
    log.info("Fetching RSKRF category tree from API...")
    rskrf_tree = fetch_rskrf_tree()
    if not rskrf_tree:
        log.error("Failed to fetch RSKRF tree, aborting")
        return

    # 2. Sbermarket
    log.info("Loading Sbermarket categories from %s", KUPER_CATEGORIES_FILE)
    kuper_cats = load_kuper_categories()
    kuper_flat = flatten_kuper(kuper_cats)
    kuper_by_id = {k["id"]: k["name"] for k in kuper_flat}
    kuper_top = [k for k in kuper_flat if k["depth"] == 0]
    kuper_children_idx = build_kuper_children_index(kuper_cats)

    # 3. Category-level mapping via LLM
    #    (RSKRF subcategory → Sbermarket top-level)
    log.info("\n=== Category mapping (LLM) ===")
    all_subcats = []
    for top_cat in rskrf_tree:
        for sub in top_cat["subcategories"]:
            all_subcats.append(sub["title"])

    log.info("Matching %d RSKRF subcategories → %d Sbermarket top-level",
             len(all_subcats), len(kuper_top))

    llm_cat_matches = match_via_llm(
        client,
        source_names=all_subcats,
        target_categories=kuper_top,
        context_hint="Это верхнеуровневые категории продуктов питания.\n\n",
    )

    category_mapping: dict = {}
    for m in llm_cat_matches:
        category_mapping[m.source_name] = {
            "kuper_id": m.target_id,
            "kuper_name": m.target_name,
            "match": "llm",
        }
        log.info("  %s → %s (%d)", m.source_name, m.target_name, m.target_id)

    # Add any subcategories the LLM missed
    for name in all_subcats:
        if name not in category_mapping:
            log.warning("  LLM missed: %s (no mapping)", name)
            category_mapping[name] = None

    # 4. Product-group-level mapping via LLM
    #    (RSKRF product group → ANY Sbermarket depth-1 subcategory)
    #    No parent constraint — LLM picks from ALL subcategories.
    log.info("\n=== Product group mapping (LLM) ===")
    product_group_mapping: dict = {}

    # Build full list of all depth-1 subcategories across all top-levels
    all_kuper_subcats: list[dict] = []
    for top_id, children in kuper_children_idx.items():
        top_name = kuper_by_id.get(top_id, "?")
        for ch in children:
            all_kuper_subcats.append({
                "id": ch["id"],
                "name": f"{ch['name']} ({top_name})",
                "raw_name": ch["name"],
            })

    log.info("Total Sbermarket depth-1 subcategories: %d", len(all_kuper_subcats))

    for top_cat in rskrf_tree:
        for sub in top_cat["subcategories"]:
            cat_entry = category_mapping.get(sub["title"])
            if not cat_entry:
                continue

            pg_names = [pg["title"] for pg in sub["product_groups"]]
            if not pg_names:
                continue

            log.info(
                "  [%s] %d product groups → all Sbermarket subcategories",
                sub["title"], len(pg_names),
            )

            llm_pg_matches = match_via_llm(
                client,
                source_names=pg_names,
                target_categories=all_kuper_subcats,
                context_hint=(
                    f"Родительская категория Роскачества: «{sub['title']}»\n"
                    "Выбирай из ВСЕХ подкатегорий Сбермаркета — "
                    "в скобках указана родительская категория для контекста.\n\n"
                ),
            )

            matched_names = set()
            for m in llm_pg_matches:
                # Recover raw_name without parent suffix
                raw_name = m.target_name
                for sc in all_kuper_subcats:
                    if sc["id"] == m.target_id:
                        raw_name = sc["raw_name"]
                        break
                product_group_mapping[m.source_name] = {
                    "kuper_id": m.target_id,
                    "kuper_name": raw_name,
                    "parent_rskrf": sub["title"],
                    "match": "llm",
                }
                matched_names.add(m.source_name)
                log.info("    %s → %s (%d)", m.source_name, raw_name, m.target_id)

            # Fallback for unmatched
            parent_kuper_id = cat_entry["kuper_id"]
            for pg_title in pg_names:
                if pg_title not in matched_names:
                    product_group_mapping[pg_title] = {
                        "kuper_id": parent_kuper_id,
                        "kuper_name": cat_entry["kuper_name"],
                        "parent_rskrf": sub["title"],
                        "match": "fallback",
                    }
                    log.info("    [fallback] %s → %s", pg_title, cat_entry["kuper_name"])

    # 5. Save
    result = {
        "category_mapping": category_mapping,
        "product_group_mapping": product_group_mapping,
    }
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    n_cat = sum(1 for v in category_mapping.values() if v)
    n_unmatched = sum(1 for v in category_mapping.values() if not v)
    log.info("\nSaved to %s", OUTPUT_FILE)
    log.info("Categories: %d mapped, %d unmatched", n_cat, n_unmatched)
    log.info("Product groups: %d total (%d llm, %d fallback)",
             len(product_group_mapping),
             sum(1 for v in product_group_mapping.values() if v.get("match") == "llm"),
             sum(1 for v in product_group_mapping.values() if v.get("match") == "fallback"))


# ── Helper for dds_rosqual.py integration ─────────────────────────────────────

def load_category_mapping(path: str | None = None) -> tuple[dict[str, int], dict[str, int]]:
    """Load pre-built mapping.

    Returns:
        (category_map, product_group_map)
        category_map:       RSKRF category_name → kuper_id (depth 0)
        product_group_map:  RSKRF product group title → kuper_id (depth 1)
    """
    if path is None:
        path = OUTPUT_FILE

    if not os.path.exists(path):
        raise FileNotFoundError(
            f"{path} not found. Run `python map_rosqual_categories.py` first."
        )

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    cat_map = {}
    for name, entry in data.get("category_mapping", {}).items():
        if entry:
            cat_map[name] = entry["kuper_id"]

    pg_map = {}
    for name, entry in data.get("product_group_mapping", {}).items():
        if entry:
            pg_map[name] = entry["kuper_id"]

    return cat_map, pg_map


if __name__ == "__main__":
    build_mapping()
