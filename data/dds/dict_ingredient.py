"""
dds_ingredient_dict.py

Seeds product_catalog.ingredient from OpenFoodFacts taxonomy files
(ingredients.txt, additives.txt) and structured metadata (ingredients.json).

Populates: name, name_ru, description, e_number, category, is_allergen.
Idempotent via ON CONFLICT (name) DO UPDATE.

Usage:
    python dds/dds_ingredient_dict.py
"""

import json
import logging
import os
import re

import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
INGREDIENTS_JSON = os.path.join(PROJECT_DIR, "ingredients.json")
INGREDIENTS_TXT = os.path.join(PROJECT_DIR, "ingredients.txt")
ADDITIVES_TXT = os.path.join(PROJECT_DIR, "additives.txt")

E_CODE_RE = re.compile(r"^e\d", re.IGNORECASE)


def parse_taxonomy_txt(filepath: str) -> dict[str, dict]:
    """
    Parse OpenFoodFacts taxonomy .txt file.

    Returns: {canonical_id: {en: [...], ru: [...]}}
    """
    entries: dict[str, dict] = {}

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    block_lines: list[str] = []

    def process_block(block: list[str]):
        en_names: list[str] = []
        ru_names: list[str] = []

        for bline in block:
            bline = bline.rstrip("\n")
            if bline.startswith("#") or bline.startswith("< "):
                continue
            if re.match(r"^[a-z][a-z0-9_]*:", bline) and not re.match(
                r"^[a-z]{2}(_[a-z]{2})?: ", bline
            ):
                continue
            m = re.match(r"^([a-z]{2}(?:_[a-z]{2})?): (.+)$", bline)
            if m:
                lang = m.group(1)
                values = [v.strip() for v in m.group(2).split(",") if v.strip()]
                if lang == "en":
                    en_names.extend(values)
                elif lang == "ru":
                    ru_names.extend(values)

        if en_names:
            canonical = "en:" + en_names[0].lower().replace(" ", "-")
            if canonical in entries:
                entries[canonical]["en"] = list(
                    set(entries[canonical]["en"]) | set(en_names)
                )
                entries[canonical]["ru"] = list(
                    set(entries[canonical]["ru"]) | set(ru_names)
                )
            else:
                entries[canonical] = {"en": en_names, "ru": ru_names}

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if block_lines:
                process_block(block_lines)
                block_lines = []
        else:
            block_lines.append(line)

    if block_lines:
        process_block(block_lines)

    return entries


def pick_best_ru(txt_ru: list[str], json_name_ru: str | None) -> str | None:
    """Pick best Russian name: first non-E-code synonym from TXT, else JSON, else None."""
    for syn in txt_ru:
        if not E_CODE_RE.match(syn.strip()):
            return syn.strip()
    if json_name_ru and not E_CODE_RE.match(json_name_ru.strip()):
        return json_name_ru.strip()
    return None


def seed():
    # 1. Load ingredients.json
    log.info("Loading %s", INGREDIENTS_JSON)
    with open(INGREDIENTS_JSON, "r", encoding="utf-8") as f:
        meta: dict = json.load(f)
    log.info("  %d entries in JSON", len(meta))

    # 2. Parse taxonomy TXT files for Russian synonyms
    log.info("Parsing %s", INGREDIENTS_TXT)
    ingredients_tax = parse_taxonomy_txt(INGREDIENTS_TXT)
    log.info("  %d entries from ingredients.txt", len(ingredients_tax))

    log.info("Parsing %s", ADDITIVES_TXT)
    additives_tax = parse_taxonomy_txt(ADDITIVES_TXT)
    log.info("  %d entries from additives.txt", len(additives_tax))

    # Merge TXT taxonomies
    txt_synonyms: dict[str, list[str]] = {}
    for tax in (ingredients_tax, additives_tax):
        for tid, entry in tax.items():
            ru = entry.get("ru", [])
            if tid in txt_synonyms:
                txt_synonyms[tid] = list(set(txt_synonyms[tid]) | set(ru))
            else:
                txt_synonyms[tid] = list(ru)

    with_ru_txt = sum(1 for v in txt_synonyms.values() if v)
    log.info("  TXT entries with Russian: %d", with_ru_txt)

    # 3. Collect all canonical_ids from both sources (en: only)
    all_ids = {k for k in meta.keys() if k.startswith("en:")} | set(txt_synonyms.keys())
    log.info("Combined unique canonical IDs (en: only): %d", len(all_ids))

    # 4. Build rows
    rows = []
    for cid in sorted(all_ids):
        m = meta.get(cid, {})
        txt_ru = txt_synonyms.get(cid, [])
        json_name_ru = (m.get("name") or {}).get("ru")

        name_ru = pick_best_ru(txt_ru, json_name_ru)
        description = (m.get("description") or {}).get("en")
        e_number = (m.get("e_number") or {}).get("en")
        category = (m.get("additives_classes") or {}).get("en")
        is_allergen = "allergens" in m and bool(m["allergens"])

        rows.append((cid, name_ru, description, e_number, category, is_allergen))

    with_ru = sum(1 for r in rows if r[1])
    with_desc = sum(1 for r in rows if r[2])
    with_enum = sum(1 for r in rows if r[3])
    log.info(
        "Rows: %d total, %d with name_ru, %d with description, %d with e_number",
        len(rows), with_ru, with_desc, with_enum,
    )

    # 5. Upsert into DB
    conn = psycopg2.connect(**DB_CONFIG)
    with conn.cursor() as cur:
        cur.execute(
            "ALTER TABLE product_catalog.ingredient "
            "ADD COLUMN IF NOT EXISTS name_ru TEXT"
        )

        execute_values(
            cur,
            """
            INSERT INTO product_catalog.ingredient
                (name, name_ru, description, e_number, category, is_allergen)
            VALUES %s
            ON CONFLICT (name) DO UPDATE SET
                name_ru     = EXCLUDED.name_ru,
                description = EXCLUDED.description,
                e_number    = EXCLUDED.e_number,
                category    = EXCLUDED.category,
                is_allergen = EXCLUDED.is_allergen
            """,
            rows,
        )
        log.info("Upserted %d ingredient rows", cur.rowcount)

    conn.commit()
    conn.close()
    log.info("Done")


if __name__ == "__main__":
    seed()
