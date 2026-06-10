"""
dict_categories.py

Loads OpenFoodFacts category taxonomy from categories.txt
into product_catalog.category + product_catalog.category_parent.

Idempotent: TRUNCATE + INSERT.

Usage:
    python dds/dict_categories.py
"""

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
CATEGORIES_TXT = os.path.join(PROJECT_DIR, "categories.txt")


def parse_categories_txt(filepath: str) -> dict[str, dict]:
    """
    Parse OpenFoodFacts categories.txt.

    Returns: {canonical_id: {en: [...], ru: [...], parents: [...]}}
    """
    entries: dict[str, dict] = {}

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    block_lines: list[str] = []

    def process_block(block: list[str]):
        en_names: list[str] = []
        ru_names: list[str] = []
        parents: list[str] = []

        for bline in block:
            bline = bline.rstrip("\n")
            if bline.startswith("#"):
                continue

            if bline.startswith("< "):
                parent_ref = bline[2:].strip()
                parent_id = "en:" + parent_ref.split(":", 1)[-1].strip().lower().replace(" ", "-")
                parents.append(parent_id)
                continue

            # Skip property lines
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
                entries[canonical]["parents"] = list(
                    set(entries[canonical]["parents"]) | set(parents)
                )
            else:
                entries[canonical] = {
                    "en": en_names,
                    "ru": ru_names,
                    "parents": parents,
                }

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


def seed():
    log.info("Parsing %s", CATEGORIES_TXT)
    categories = parse_categories_txt(CATEGORIES_TXT)
    log.info("Parsed %d categories", len(categories))

    with_ru = sum(1 for e in categories.values() if e.get("ru"))
    with_parents = sum(1 for e in categories.values() if e.get("parents"))
    log.info("  With Russian: %d, with parents: %d", with_ru, with_parents)

    # Build rows: (name, name_ru)
    rows = []
    for cid, entry in sorted(categories.items()):
        ru_names = entry.get("ru", [])
        name_ru = ru_names[0] if ru_names else None
        rows.append((cid, name_ru))

    # Build parent links: (child_name, parent_name)
    parent_links = []
    for cid, entry in categories.items():
        for pid in entry.get("parents", []):
            if pid in categories:
                parent_links.append((cid, pid))

    log.info("Parent links: %d", len(parent_links))

    conn = psycopg2.connect(**DB_CONFIG)
    with conn.cursor() as cur:
        cur.execute("TRUNCATE product_catalog.category CASCADE")

        execute_values(
            cur,
            """
            INSERT INTO product_catalog.category (name, name_ru)
            VALUES %s
            """,
            rows,
        )
        log.info("Inserted %d categories", len(rows))

        if parent_links:
            cur.execute("""
                INSERT INTO product_catalog.category_parent (category_id, parent_id)
                SELECT c.id, p.id
                FROM unnest(%s::text[], %s::text[]) AS t(child_name, parent_name)
                JOIN product_catalog.category c ON c.name = t.child_name
                JOIN product_catalog.category p ON p.name = t.parent_name
            """, (
                [l[0] for l in parent_links],
                [l[1] for l in parent_links],
            ))
            log.info("Inserted %d parent links", cur.rowcount)

    conn.commit()
    conn.close()
    log.info("Done")


if __name__ == "__main__":
    seed()
