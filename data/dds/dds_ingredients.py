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


def load_dds_ingredients():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        # 1. Clear product_ingredient for rosqual
        cur.execute("""
            DELETE FROM product_catalog.product_ingredient
            WHERE product_id IN (
                SELECT id FROM product_catalog.product WHERE source = 'rosqual'
            )
        """)
        log.info("Cleared product_ingredient for rosqual")

        # 2. Insert product_ingredient links (ingredient_id = NULL if not in dictionary)
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
                ON p.source_id = r.source_id AND p.source = 'rosqual'
            LEFT JOIN product_catalog.ingredient_alias a
                ON a.alias = r.ingredient_name
            LEFT JOIN product_catalog.ingredient i
                ON i.name = COALESCE(a.canonical_name, r.ingredient_name)
            ORDER BY p.id, r.ingredient_name
        """)
        log.info("Inserted %d product_ingredient links", cur.rowcount)

        # 3. Summary
        cur.execute("""
            SELECT count(*),
                   count(ingredient_id),
                   count(*) - count(ingredient_id)
            FROM product_catalog.product_ingredient
            WHERE product_id IN (
                SELECT id FROM product_catalog.product WHERE source = 'rosqual'
            )
        """)
        total, matched, unmatched = cur.fetchone()

    conn.commit()
    conn.close()
    log.info("Done. Links: %d (matched: %d, unmatched: %d)", total, matched, unmatched)


if __name__ == "__main__":
    load_dds_ingredients()
