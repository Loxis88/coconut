import logging
import psycopg2

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG


def load_openfood():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False

    with conn.cursor() as cur:
        # Delete old openfood data
        log.info("Deleting old openfood data...")
        cur.execute("""
            DELETE FROM product_catalog.product_micronutrients
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'openfood')
        """)
        cur.execute("""
            DELETE FROM product_catalog.nutrition_facts
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'openfood')
        """)
        cur.execute("""
            DELETE FROM product_catalog.product_barcode
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'openfood')
        """)
        cur.execute("DELETE FROM product_catalog.product WHERE source = 'openfood'")
        log.info("Deleted old openfood data")

        # 1. Create temp table with selected openfood rows (Russia + 500k random)
        log.info("Selecting openfood rows into temp table...")
        cur.execute("""
            CREATE TEMP TABLE tmp_openfood AS
            (SELECT * FROM staging.raw_openfood_products WHERE countries_en LIKE '%%Russia%%')
            UNION ALL
            (SELECT * FROM staging.raw_openfood_products
             WHERE (countries_en NOT LIKE 'Russia' OR countries_en IS NULL)
             LIMIT 500000)
        """)
        cur.execute("CREATE INDEX ON tmp_openfood (code)")
        cur.execute("SELECT count(*) FROM tmp_openfood")
        total = cur.fetchone()[0]
        log.info("Temp table: %d rows", total)

        # 2. Insert categories
        log.info("Inserting categories...")
        cur.execute("""
            INSERT INTO product_catalog.category (title, image_link)
            SELECT DISTINCT split_part(COALESCE(categories_en, categories), ',', 1), NULL
            FROM tmp_openfood
            WHERE COALESCE(categories_en, categories) IS NOT NULL
            ON CONFLICT (title) DO NOTHING
        """)
        log.info("Categories inserted")

        # 3. Insert products (skip those with barcode already in product_barcode)
        log.info("Inserting products...")
        cur.execute("""
            INSERT INTO product_catalog.product
                (source_id, source, category_id, total_rating, brand,
                 image_link, name, ingredients)
            SELECT
                o.code,
                'openfood',
                c.category_id,
                NULL,
                o.brands,
                o.image_url,
                o.product_name,
                o.ingredients_text
            FROM tmp_openfood o
            LEFT JOIN product_catalog.category c
                ON c.title = split_part(COALESCE(o.categories_en, o.categories), ',', 1)
            WHERE o.code IS NOT NULL
              AND o.product_name IS NOT NULL
              AND o.product_name != ''
              AND NOT EXISTS (
                  SELECT 1 FROM product_catalog.product_barcode pb
                  WHERE pb.barcode = o.code
              )
        """)
        product_count = cur.rowcount
        log.info("Inserted %d products", product_count)

        # 4. Insert barcodes (code is the barcode for openfood)
        log.info("Inserting barcodes...")
        cur.execute("""
            INSERT INTO product_catalog.product_barcode (product_id, barcode)
            SELECT p.id, p.source_id
            FROM product_catalog.product p
            WHERE p.source = 'openfood'
        """)
        log.info("Inserted %d barcodes", cur.rowcount)

        # 5. Insert nutrition facts
        log.info("Inserting nutrition facts...")
        cur.execute("""
            INSERT INTO product_catalog.nutrition_facts
                (product_id, serving_size_g, calories_kcal, protein_g, fat_g,
                 carbs_g, fiber_g, sugar_g, salt_g, sodium_mg)
            SELECT
                p.id,
                100,
                o.energy_kcal_100g::numeric,
                o.proteins_100g::numeric,
                o.fat_100g::numeric,
                o.carbohydrates_100g::numeric,
                o.fiber_100g::numeric,
                o.sugars_100g::numeric,
                o.salt_100g::numeric,
                o.sodium_100g::numeric * 1000
            FROM tmp_openfood o
            JOIN product_catalog.product p ON p.source_id = o.code AND p.source = 'openfood'
            WHERE o.energy_kcal_100g IS NOT NULL
               OR o.proteins_100g IS NOT NULL
               OR o.fat_100g IS NOT NULL
               OR o.carbohydrates_100g IS NOT NULL
        """)
        log.info("Inserted %d nutrition facts", cur.rowcount)

        # 6. Insert micronutrients
        log.info("Inserting micronutrients...")
        cur.execute("SELECT id, code FROM product_catalog.micronutrients")
        micronutrients = cur.fetchall()

        total_micros = 0
        for nutrient_id, code in micronutrients:
            col = f"{code}_100g"
            cur.execute(f"""
                INSERT INTO product_catalog.product_micronutrients (product_id, nutrient_id, amount)
                SELECT p.id, %s, o.{col}::numeric
                FROM tmp_openfood o
                JOIN product_catalog.product p ON p.source_id = o.code AND p.source = 'openfood'
                WHERE o.{col} IS NOT NULL AND o.{col} != '' AND o.{col}::numeric > 0
            """, (nutrient_id,))
            total_micros += cur.rowcount

        log.info("Inserted %d micronutrient records", total_micros)

        # Cleanup
        cur.execute("DROP TABLE tmp_openfood")

    conn.commit()
    log.info("OpenFood DDS load complete")
    conn.close()


if __name__ == "__main__":
    load_openfood()
