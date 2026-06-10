"""
dds_ingredients.py

Loads ingredients from staging.raw_product_ingredients into
product_catalog.ingredient + product_catalog.product_ingredient.

Assumes taxonomy dictionary is already seeded by dds_ingredient_dict.py.
Idempotent: DELETE + INSERT for links.

Usage:
    python dds/dds_ingredients.py
"""

import logging

import psycopg2

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG


def load_dds_ingredients_for_source(cur, source: str):
    cur.execute("""
        DELETE FROM product_catalog.product_ingredient
        WHERE product_id IN (
            SELECT id FROM product_catalog.product WHERE source = %s
        )
    """, (source,))
    log.info("Cleared product_ingredient for %s", source)

    cur.execute("""
        INSERT INTO product_catalog.product_ingredient
            (product_id, ingredient_id, original_name, qty, unit, qualifier)
        SELECT DISTINCT ON (p.id, r.ingredient_name)
            p.id,
            i.id,
            r.ingredient_name,
            r.qty,
            r.unit,
            r.qualifier
        FROM staging.raw_product_ingredients r
        JOIN product_catalog.product p
            ON p.source_id = r.source_id AND p.source = %s
        LEFT JOIN product_catalog.ingredient_alias a
            ON a.alias = r.ingredient_name
        LEFT JOIN product_catalog.ingredient i
            ON i.name = COALESCE(a.canonical_name, r.ingredient_name)
        ORDER BY p.id, r.ingredient_name
    """, (source,))
    log.info("Inserted %d product_ingredient links for %s", cur.rowcount, source)

    cur.execute("""
        SELECT count(*),
               count(ingredient_id),
               count(*) - count(ingredient_id)
        FROM product_catalog.product_ingredient
        WHERE product_id IN (
            SELECT id FROM product_catalog.product WHERE source = %s
        )
    """, (source,))
    total, matched, unmatched = cur.fetchone()
    log.info("%s links: %d (matched: %d, unmatched: %d)", source, total, matched, unmatched)


def load_dds_ingredients():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        for source in ("rosqual", "kuper"):
            load_dds_ingredients_for_source(cur, source)

    conn.commit()
    conn.close()
    log.info("Done")


if __name__ == "__main__":
    load_dds_ingredients()
