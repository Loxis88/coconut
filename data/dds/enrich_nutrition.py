"""
enrich_nutrition.py

Enriches rosqual products with sugar_g, salt_g, saturated_fat_g
from OpenFoodFacts staging data.

Strategy:
  1. Barcode match — exact OFF product values
  2. Category median — median of OFF products in the same category

Only fills NULL values, never overwrites existing data.

Usage:
    python dds/enrich_nutrition.py
"""

import logging
import statistics

import psycopg2

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG


def safe_float(val) -> float | None:
    if val is None or val == "":
        return None
    try:
        v = float(val)
        return v if v >= 0 else None
    except (ValueError, TypeError):
        return None


def enrich():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        # Migration
        cur.execute(
            "ALTER TABLE product_catalog.nutrition_facts "
            "ADD COLUMN IF NOT EXISTS saturated_fat_g NUMERIC"
        )
        conn.commit()

        # ── Step 1: Barcode match ─────────────────────────────────────────

        # Get rosqual products with barcodes matching OFF
        cur.execute("""
            SELECT DISTINCT ON (p.id)
                p.id,
                off.sugars_100g,
                off.salt_100g,
                off.saturated_fat_100g
            FROM product_catalog.product p
            JOIN product_catalog.product_barcode pb ON pb.product_id = p.id
            JOIN staging.raw_openfood_products off ON off.code = pb.barcode
            WHERE p.source IN ('rosqual', 'kuper')
              AND (off.sugars_100g IS NOT NULL AND off.sugars_100g != ''
                OR off.salt_100g IS NOT NULL AND off.salt_100g != ''
                OR off.saturated_fat_100g IS NOT NULL AND off.saturated_fat_100g != '')
            ORDER BY p.id
        """)
        barcode_matches = cur.fetchall()
        log.info("Barcode matches with OFF nutrition: %d", len(barcode_matches))

        barcode_updated = 0
        barcode_inserted = 0
        barcode_product_ids = set()

        for product_id, sugar, salt, sat_fat in barcode_matches:
            sugar_f = safe_float(sugar)
            salt_f = safe_float(salt)
            sat_fat_f = safe_float(sat_fat)

            if sugar_f is None and salt_f is None and sat_fat_f is None:
                continue

            barcode_product_ids.add(product_id)

            # Check if nutrition_facts row exists
            cur.execute(
                "SELECT id, sugar_g, salt_g, saturated_fat_g "
                "FROM product_catalog.nutrition_facts WHERE product_id = %s",
                (product_id,),
            )
            row = cur.fetchone()

            if row:
                nf_id, existing_sugar, existing_salt, existing_sat = row
                updates = []
                values = []
                if existing_sugar is None and sugar_f is not None:
                    updates.append("sugar_g = %s")
                    values.append(sugar_f)
                if existing_salt is None and salt_f is not None:
                    updates.append("salt_g = %s")
                    values.append(salt_f)
                if existing_sat is None and sat_fat_f is not None:
                    updates.append("saturated_fat_g = %s")
                    values.append(sat_fat_f)
                if updates:
                    values.append(nf_id)
                    cur.execute(
                        f"UPDATE product_catalog.nutrition_facts "
                        f"SET {', '.join(updates)} WHERE id = %s",
                        values,
                    )
                    barcode_updated += 1
            else:
                cur.execute(
                    "INSERT INTO product_catalog.nutrition_facts "
                    "(product_id, sugar_g, salt_g, saturated_fat_g) "
                    "VALUES (%s, %s, %s, %s)",
                    (product_id, sugar_f, salt_f, sat_fat_f),
                )
                barcode_inserted += 1

        log.info(
            "Barcode: updated %d, inserted %d", barcode_updated, barcode_inserted
        )

        # ── Step 2: Build category medians ────────────────────────────────

        # Get distinct OFF categories used by rosqual products
        cur.execute("""
            SELECT DISTINCT c.name
            FROM product_catalog.product p
            JOIN product_catalog.category c ON c.id = p.category_id
            WHERE p.source IN ('rosqual', 'kuper')
        """)
        rosqual_categories = [r[0] for r in cur.fetchall()]
        log.info("Distinct rosqual OFF categories: %d", len(rosqual_categories))

        category_medians: dict[str, dict] = {}

        for i, cat_name in enumerate(rosqual_categories, 1):
            log.info("  [%d/%d] %s", i, len(rosqual_categories), cat_name)
            # OFF categories_tags is comma-separated: "en:dairies,en:yogurts,..."
            # Use LIKE to find OFF products tagged with this category
            pattern = f"%{cat_name}%"
            cur.execute(
                """
                SELECT sugars_100g, salt_100g, saturated_fat_100g
                FROM staging.raw_openfood_products
                WHERE categories_tags LIKE %s
                  AND sugars_100g IS NOT NULL AND sugars_100g != ''
                  AND salt_100g IS NOT NULL AND salt_100g != ''
                  AND saturated_fat_100g IS NOT NULL AND saturated_fat_100g != ''
                LIMIT 5000
                """,
                (pattern,),
            )
            rows = cur.fetchall()

            if not rows:
                log.info("    no OFF matches")
                continue

            sugars = [safe_float(r[0]) for r in rows if safe_float(r[0]) is not None]
            salts = [safe_float(r[1]) for r in rows if safe_float(r[1]) is not None]
            sat_fats = [safe_float(r[2]) for r in rows if safe_float(r[2]) is not None]

            if sugars and salts and sat_fats:
                med_sugar = statistics.median(sugars)
                med_salt = statistics.median(salts)
                med_sat = statistics.median(sat_fats)
                log.info(
                    "    n=%d  sugar=%.1f  salt=%.2f  sat_fat=%.1f",
                    len(rows), med_sugar, med_salt, med_sat,
                )
                category_medians[cat_name] = {
                    "sugar": med_sugar,
                    "salt": med_salt,
                    "sat_fat": med_sat,
                    "sample_size": len(rows),
                }

        log.info(
            "Category medians computed: %d / %d categories",
            len(category_medians), len(rosqual_categories),
        )
        for cat, m in sorted(
            category_medians.items(), key=lambda x: -x[1]["sample_size"]
        )[:10]:
            log.info(
                "  %s: sugar=%.1f salt=%.2f sat_fat=%.1f (n=%d)",
                cat, m["sugar"], m["salt"], m["sat_fat"], m["sample_size"],
            )

        # ── Step 3: Apply category medians ────────────────────────────────

        cur.execute("""
            SELECT p.id, c.name
            FROM product_catalog.product p
            JOIN product_catalog.category c ON c.id = p.category_id
            WHERE p.source IN ('rosqual', 'kuper')
        """)
        products_with_cat = cur.fetchall()

        cat_updated = 0
        cat_inserted = 0

        for product_id, cat_name in products_with_cat:
            if product_id in barcode_product_ids:
                continue

            medians = category_medians.get(cat_name)
            if not medians:
                continue

            cur.execute(
                "SELECT id, sugar_g, salt_g, saturated_fat_g "
                "FROM product_catalog.nutrition_facts WHERE product_id = %s",
                (product_id,),
            )
            row = cur.fetchone()

            if row:
                nf_id, existing_sugar, existing_salt, existing_sat = row
                updates = []
                values = []
                if existing_sugar is None:
                    updates.append("sugar_g = %s")
                    values.append(medians["sugar"])
                if existing_salt is None:
                    updates.append("salt_g = %s")
                    values.append(medians["salt"])
                if existing_sat is None:
                    updates.append("saturated_fat_g = %s")
                    values.append(medians["sat_fat"])
                if updates:
                    values.append(nf_id)
                    cur.execute(
                        f"UPDATE product_catalog.nutrition_facts "
                        f"SET {', '.join(updates)} WHERE id = %s",
                        values,
                    )
                    cat_updated += 1
            else:
                cur.execute(
                    "INSERT INTO product_catalog.nutrition_facts "
                    "(product_id, sugar_g, salt_g, saturated_fat_g) "
                    "VALUES (%s, %s, %s, %s)",
                    (product_id, medians["sugar"], medians["salt"], medians["sat_fat"]),
                )
                cat_inserted += 1

        log.info(
            "Category median: updated %d, inserted %d", cat_updated, cat_inserted
        )

        # ── Summary ──────────────────────────────────────────────────────

        cur.execute("""
            SELECT count(*),
                   count(sugar_g),
                   count(salt_g),
                   count(saturated_fat_g)
            FROM product_catalog.nutrition_facts nf
            JOIN product_catalog.product p ON p.id = nf.product_id
            WHERE p.source IN ('rosqual', 'kuper')
        """)
        total, n_sugar, n_salt, n_sat = cur.fetchone()

    conn.commit()
    conn.close()
    log.info(
        "Done. Nutrition rows: %d, sugar: %d, salt: %d, sat_fat: %d",
        total, n_sugar, n_salt, n_sat,
    )


if __name__ == "__main__":
    enrich()
