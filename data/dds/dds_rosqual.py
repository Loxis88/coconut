import json
import os
import re
import logging

import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


# --------------- helpers ---------------

def get_product_info_value(data: dict, *field_names: str) -> str | None:
    for item in data.get("product_info", []):
        if item.get("name") in field_names:
            return item.get("info")
    return None


def parse_number(text: str) -> float | None:
    if not text:
        return None
    text = text.replace(",", ".").strip()
    try:
        return float(text)
    except ValueError:
        return None


def split_barcodes(text: str | None) -> list[str]:
    if not text:
        return []
    parts = re.split(r"[;,\s]+", text.strip())
    return [p for p in parts if p]


def parse_nutrition(text: str) -> dict:
    result = {
        "serving_size_g": 100,
        "calories_kcal": None,
        "protein_g": None,
        "fat_g": None,
        "carbs_g": None,
        "fiber_g": None,
        "sugar_g": None,
        "salt_g": None,
        "sodium_mg": None,
    }
    if not text:
        return result

    patterns = {
        "protein_g": r"бел(?:ки|ок)\s*[-–—:]\s*([\d,\.]+)",
        "fat_g": r"жир[ы]?\s*[-–—:]\s*([\d,\.]+)",
        "carbs_g": r"углевод[ы]?\s*[-–—:]\s*([\d,\.]+)",
        "fiber_g": r"пищевые\s+волокна\s*[-–—:]\s*([\d,\.]+)",
        "sugar_g": r"сахар[а]?\s*[-–—:]\s*([\d,\.]+)",
        "salt_g": r"соль\s*[-–—:]\s*([\d,\.]+)",
        "sodium_mg": r"натрий\s*[-–—:]\s*([\d,\.]+)",
    }

    for key, pattern in patterns.items():
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            result[key] = parse_number(m.group(1))

    m = re.search(r"([\d,\.]+)\s*ккал", text, re.IGNORECASE)
    if m:
        result["calories_kcal"] = parse_number(m.group(1))

    if result["calories_kcal"] is None:
        m = re.search(r"кДж\s*/\s*ккал\s*\)?\s*:?\s*[\d,\.]+\s*/\s*([\d,\.]+)", text, re.IGNORECASE)
        if m:
            result["calories_kcal"] = parse_number(m.group(1))

    m = re.search(r"на\s+([\d,\.]+)\s*г", text, re.IGNORECASE)
    if m:
        result["serving_size_g"] = parse_number(m.group(1))

    return result


# --------------- main ---------------

def load_dds():
    conn = get_connection()

    with conn.cursor() as cur:
        cur.execute("SELECT id, data FROM staging.raw_rosqual_producs")
        rows = cur.fetchall()

    log.info("Loaded %d raw products", len(rows))

    # 1. Load OFF category dictionary (name → id)
    with conn.cursor() as cur:
        cur.execute("SELECT id, name FROM product_catalog.category")
        name_to_cat_id = {name: cid for cid, name in cur.fetchall()}

    log.info("Categories in DB: %d", len(name_to_cat_id))

    # 2. Load RSKRF → OFF mapping
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mapping_file = os.path.join(os.path.dirname(script_dir), "rosqual_off_category_mapping.json")

    rskrf_to_off: dict[str, str] = {}
    if os.path.exists(mapping_file):
        with open(mapping_file, "r", encoding="utf-8") as f:
            raw = json.load(f)
        for rskrf_name, off_id in raw.items():
            if off_id:
                rskrf_to_off[rskrf_name.strip()] = off_id
        log.info("Loaded mapping: %d RSKRF → OFF entries", len(rskrf_to_off))
    else:
        log.warning("%s not found — rosqual categories will be NULL", mapping_file)

    def resolve_cat_id(data: dict) -> int | None:
        # Try product group first (more specific)
        research_title = (data.get("research") or {}).get("title")
        if research_title:
            off_name = rskrf_to_off.get(research_title.strip())
            if off_name and off_name in name_to_cat_id:
                return name_to_cat_id[off_name]
        # Fallback to subcategory
        category_name = data.get("category_name")
        if category_name:
            off_name = rskrf_to_off.get(category_name.strip())
            if off_name and off_name in name_to_cat_id:
                return name_to_cat_id[off_name]
        return None

    # 3. Build product, document, nutrition, barcode, health_risks rows
    product_rows = []
    doc_rows_by_source_id = {}
    nutrition_rows_by_source_id = {}
    barcode_rows_by_source_id = {}
    risks_by_source_id = {}

    for _, data in rows:
        source_id = str(data.get("id"))
        cat_id = resolve_cat_id(data)
        barcode_raw = get_product_info_value(data, "Штрихкоды", "Штрихкод")
        barcodes = split_barcodes(barcode_raw)
        ingredients = get_product_info_value(data, "Состав")

        product_rows.append((
            source_id, "rosqual", cat_id, data.get("total_rating"),
            data.get("manufacturer"), data.get("thumbnail"),
            data.get("title"), data.get("description"), ingredients,
        ))

        if barcodes:
            barcode_rows_by_source_id[source_id] = barcodes

        docs = []
        for doc in data.get("product_documents", []):
            docs.append(doc.get("file"))
        if docs:
            doc_rows_by_source_id[source_id] = docs

        disadvantages = data.get("disadvantage", [])
        if disadvantages:
            risks_by_source_id[source_id] = disadvantages

        nutrition_text = get_product_info_value(data, "Дополнительная информация")
        nf = parse_nutrition(nutrition_text)
        if any(v is not None for k, v in nf.items() if k != "serving_size_g"):
            nutrition_rows_by_source_id[source_id] = nf

    n_with = sum(1 for row in product_rows if row[2] is not None)
    log.info("Products with category: %d / %d", n_with, len(product_rows))

    # 4. Delete old rosqual data only
    with conn.cursor() as cur:
        cur.execute("""
            DELETE FROM product_catalog.health_risks
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'rosqual')
        """)
        cur.execute("""
            DELETE FROM product_catalog.product_micronutrients
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'rosqual')
        """)
        cur.execute("""
            DELETE FROM product_catalog.nutrition_facts
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'rosqual')
        """)
        cur.execute("""
            DELETE FROM product_catalog.product_documents
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'rosqual')
        """)
        cur.execute("""
            DELETE FROM product_catalog.product_barcode
            WHERE product_id IN (SELECT id FROM product_catalog.product WHERE source = 'rosqual')
        """)
        cur.execute("DELETE FROM product_catalog.product WHERE source = 'rosqual'")
        log.info("Deleted old rosqual data")

        # 4. Insert products
        execute_values(
            cur,
            """
            INSERT INTO product_catalog.product
                (source_id, source, category_id, total_rating, brand,
                 image_link, name, description, ingredients)
            VALUES %s
            """,
            product_rows,
        )
        log.info("Inserted %d products", len(product_rows))

        # Get generated IDs back
        cur.execute("SELECT id, source_id FROM product_catalog.product WHERE source = 'rosqual'")
        source_id_to_id = {sid: pid for pid, sid in cur.fetchall()}

        # 5. Insert barcodes
        barcode_rows = []
        for source_id, barcodes in barcode_rows_by_source_id.items():
            pid = source_id_to_id.get(source_id)
            if pid:
                for bc in barcodes:
                    barcode_rows.append((pid, bc))

        if barcode_rows:
            execute_values(
                cur,
                "INSERT INTO product_catalog.product_barcode (product_id, barcode) VALUES %s",
                barcode_rows,
            )
            log.info("Inserted %d barcodes", len(barcode_rows))

        # 6. Insert documents
        doc_rows = []
        for source_id, links in doc_rows_by_source_id.items():
            pid = source_id_to_id.get(source_id)
            if pid:
                for link in links:
                    doc_rows.append((pid, link))

        if doc_rows:
            execute_values(
                cur,
                "INSERT INTO product_catalog.product_documents (product_id, doc_link) VALUES %s",
                doc_rows,
            )
            log.info("Inserted %d documents", len(doc_rows))

        # 7. Insert nutrition facts
        nutrition_rows = []
        for source_id, nf in nutrition_rows_by_source_id.items():
            pid = source_id_to_id.get(source_id)
            if pid:
                nutrition_rows.append((
                    pid, nf["serving_size_g"], nf["calories_kcal"], nf["protein_g"],
                    nf["fat_g"], nf["carbs_g"], nf["fiber_g"], nf["sugar_g"],
                    nf["salt_g"], nf["sodium_mg"],
                ))

        if nutrition_rows:
            execute_values(
                cur,
                """
                INSERT INTO product_catalog.nutrition_facts
                    (product_id, serving_size_g, calories_kcal, protein_g, fat_g,
                     carbs_g, fiber_g, sugar_g, salt_g, sodium_mg)
                VALUES %s
                """,
                nutrition_rows,
            )
            log.info("Inserted %d nutrition facts", len(nutrition_rows))

        # 8. Insert health risks (disadvantages)
        risk_rows = []
        for source_id, facts in risks_by_source_id.items():
            pid = source_id_to_id.get(source_id)
            if pid:
                for fact in facts:
                    risk_rows.append((pid, fact))

        if risk_rows:
            execute_values(
                cur,
                "INSERT INTO product_catalog.health_risks (product_id, fact) VALUES %s",
                risk_rows,
            )
            log.info("Inserted %d health risks", len(risk_rows))

    conn.commit()
    log.info("DDS rosqual load complete")
    conn.close()


if __name__ == "__main__":
    load_dds()
