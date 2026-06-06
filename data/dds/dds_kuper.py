import logging
import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG


def load_kuper_dds():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        # Delete old kuper data
        cur.execute("""
            DELETE FROM product_catalog.nutrition_facts
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'kuper')
        """)
        cur.execute("""
            DELETE FROM product_catalog.product_barcode
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'kuper')
        """)
        cur.execute("DELETE FROM product_catalog.product WHERE source = 'kuper'")
        deleted = cur.rowcount
        log.info("Deleted %d old kuper products", deleted)

        # Expand all EANs from raw_kuper into temp table
        cur.execute("""
            CREATE TEMP TABLE tmp_kuper_eans AS
            SELECT r.sku, e.ean
            FROM staging.raw_kuper r,
                 LATERAL jsonb_array_elements_text(r.data->'eans') AS e(ean)
            WHERE jsonb_typeof(r.data->'eans') = 'array'
        """)
        cur.execute("CREATE INDEX ON tmp_kuper_eans (ean)")
        cur.execute("CREATE INDEX ON tmp_kuper_eans (sku)")
        log.info("Built temp eans table")

        # Build temp table with enriched product data
        cur.execute("""
            CREATE TEMP TABLE tmp_kuper_products AS
            SELECT
                r.sku,
                COALESCE(
                    e.data->'data'->'product'->>'name',
                    r.data->>'name'
                ) AS name,
                e.data->'data'->'product'->'brand'->>'name' AS brand,
                COALESCE(
                    e.data->'data'->'product'->'images'->0->>'original_url',
                    r.data->'images'->0->>'original_url'
                ) AS image_link,
                COALESCE(
                    (e.data->'data'->'product'->>'score')::numeric,
                    (r.data->>'score')::numeric
                ) AS total_rating,
                (SELECT pp->>'value'
                 FROM jsonb_array_elements(e.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'ingredients'
                 LIMIT 1
                ) AS ingredients,
                (SELECT t->>'name'
                 FROM jsonb_array_elements(e.data->'data'->'product_taxons') t
                 WHERE (t->>'leaf')::boolean = true
                 LIMIT 1
                ) AS category_name,
                (SELECT regexp_replace(pp->>'value', '[^0-9.,]', '', 'g')
                 FROM jsonb_array_elements(e.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'energy_value'
                 LIMIT 1
                ) AS calories,
                (SELECT regexp_replace(pp->>'value', '[^0-9.,]', '', 'g')
                 FROM jsonb_array_elements(e.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'protein'
                 LIMIT 1
                ) AS protein,
                (SELECT regexp_replace(pp->>'value', '[^0-9.,]', '', 'g')
                 FROM jsonb_array_elements(e.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'fat'
                 LIMIT 1
                ) AS fat,
                (SELECT regexp_replace(pp->>'value', '[^0-9.,]', '', 'g')
                 FROM jsonb_array_elements(e.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'carbohydrate'
                 LIMIT 1
                ) AS carbs
            FROM staging.raw_kuper r
            LEFT JOIN staging.raw_kuper_enriched e ON e.id = r.id
        """)
        cur.execute("CREATE INDEX ON tmp_kuper_products (sku)")

        # Diagnostic: how many products have category_name
        cur.execute("""
            SELECT count(*) AS total,
                   count(category_name) AS with_cat
            FROM tmp_kuper_products
        """)
        diag = cur.fetchone()
        log.info(
            "Temp products: %d total, %d with category_name, %d without",
            diag[0], diag[1], diag[0] - diag[1],
        )
        log.info("Built temp enriched products table")

        # Insert products (skip those with barcode overlap)
        cur.execute("""
            INSERT INTO product_catalog.product
                (source_id, source, category_id, total_rating, brand, image_link, name, ingredients)
            SELECT
                tp.sku,
                'kuper',
                c.category_id,
                tp.total_rating,
                tp.brand,
                tp.image_link,
                tp.name,
                tp.ingredients
            FROM tmp_kuper_products tp
                LEFT JOIN product_catalog.category c ON c.title = tp.category_name
            WHERE NOT EXISTS (
                SELECT 1
                FROM tmp_kuper_eans te
                JOIN product_catalog.product_barcode pb ON pb.barcode = te.ean
                WHERE te.sku = tp.sku
            )
        """)
        inserted = cur.rowcount
        log.info("Inserted %d kuper products", inserted)

        # Insert barcodes
        cur.execute("""
            INSERT INTO product_catalog.product_barcode (product_id, barcode)
            SELECT p.id, te.ean
            FROM product_catalog.product p
            JOIN tmp_kuper_eans te ON te.sku = p.source_id
            WHERE p.source = 'kuper'
        """)
        barcode_count = cur.rowcount
        log.info("Inserted %d barcodes", barcode_count)

        # Insert nutrition facts where available
        cur.execute("""
            INSERT INTO product_catalog.nutrition_facts
                (product_id, calories_kcal, protein_g, fat_g, carbs_g)
            SELECT
                p.id,
                NULLIF(replace(tp.calories, ',', '.'), '')::numeric,
                NULLIF(replace(tp.protein, ',', '.'), '')::numeric,
                NULLIF(replace(tp.fat, ',', '.'), '')::numeric,
                NULLIF(replace(tp.carbs, ',', '.'), '')::numeric
            FROM product_catalog.product p
            JOIN tmp_kuper_products tp ON tp.sku = p.source_id
            WHERE p.source = 'kuper'
              AND (tp.calories IS NOT NULL
                OR tp.protein IS NOT NULL
                OR tp.fat IS NOT NULL
                OR tp.carbs IS NOT NULL)
        """)
        nutrition_count = cur.rowcount
        log.info("Inserted %d nutrition facts", nutrition_count)

    conn.commit()
    conn.close()
    log.info("Done")


if __name__ == "__main__":
    load_kuper_dds()
