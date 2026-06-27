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


_MACRO_FIELDS = ("calories_kcal", "protein_g", "fat_g", "carbs_g")
_KUPER_PROP_MAP = {
    "calories_kcal": "energy_value",
    "protein_g": "protein",
    "fat_g": "fat",
    "carbs_g": "carbohydrate",
}


def fetch_kuper_macros_by_barcodes(cur, barcodes: list[str]) -> dict[str, dict]:
    """Return {barcode: {calories_kcal, protein_g, fat_g, carbs_g}} for kuper matches."""
    if not barcodes:
        return {}
    cur.execute(
        """
        SELECT DISTINCT ON (e.ean)
            e.ean,
            regexp_replace(
                (SELECT pp->>'value'
                 FROM jsonb_array_elements(ke.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'energy_value' LIMIT 1),
                '[^0-9.,]', '', 'g') AS calories,
            regexp_replace(
                (SELECT pp->>'value'
                 FROM jsonb_array_elements(ke.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'protein' LIMIT 1),
                '[^0-9.,]', '', 'g') AS protein,
            regexp_replace(
                (SELECT pp->>'value'
                 FROM jsonb_array_elements(ke.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'fat' LIMIT 1),
                '[^0-9.,]', '', 'g') AS fat,
            regexp_replace(
                (SELECT pp->>'value'
                 FROM jsonb_array_elements(ke.data->'data'->'product_properties') pp
                 WHERE pp->>'name' = 'carbohydrate' LIMIT 1),
                '[^0-9.,]', '', 'g') AS carbs
        FROM staging.raw_kuper kr
        JOIN staging.raw_kuper_enriched ke ON ke.id = kr.id,
             LATERAL jsonb_array_elements_text(kr.data->'eans') AS e(ean)
        WHERE e.ean = ANY(%s)
          AND jsonb_typeof(kr.data->'eans') = 'array'
        ORDER BY e.ean
        """,
        (barcodes,),
    )
    result = {}
    for ean, cal, prot, fat, carb in cur.fetchall():
        macros = {
            "calories_kcal": parse_number(cal),
            "protein_g": parse_number(prot),
            "fat_g": parse_number(fat),
            "carbs_g": parse_number(carb),
        }
        if any(v is not None for v in macros.values()):
            result[ean] = macros
    return result


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

    # Separator: dash/colon OR plain space (both appear in source data)
    sep = r"(?:\s*[-–—:]\s*|\s+)"
    patterns = {
        "protein_g": rf"бел(?:ки|ок|ков){sep}([\d,\.]+)",
        "fat_g": rf"жир(?:ы|ов)?{sep}([\d,\.]+)",
        "carbs_g": rf"углевод(?:ы|ов)?{sep}([\d,\.]+)",
        "fiber_g": rf"пищевые\s+волокна{sep}([\d,\.]+)",
        "sugar_g": rf"сахар(?:а|ов)?{sep}([\d,\.]+)",
        "salt_g": rf"соль{sep}([\d,\.]+)",
        "sodium_mg": rf"натри(?:й|я){sep}([\d,\.]+)",
    }

    for key, pattern in patterns.items():
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            result[key] = parse_number(m.group(1))

    # Calories: look for paired кДж/ккал or ккал/кДж first.
    # Source data sometimes has them swapped; physically kJ must be ~4.18× kcal.
    kj_val = kcal_val = None
    m = re.search(r"([\d,\.]+)\s*к[дД][жЖ]\s*[/\s]\s*([\d,\.]+)\s*к[кК]ал", text, re.IGNORECASE)
    if m:
        kj_val, kcal_val = parse_number(m.group(1)), parse_number(m.group(2))
    else:
        m = re.search(r"([\d,\.]+)\s*к[кК]ал\s*[/\s]\s*([\d,\.]+)\s*к[дД][жЖ]", text, re.IGNORECASE)
        if m:
            kcal_val, kj_val = parse_number(m.group(1)), parse_number(m.group(2))

    if kj_val and kcal_val:
        if kj_val >= kcal_val:
            # Normal ordering: kJ is larger
            result["calories_kcal"] = kcal_val
        else:
            # Impossible physically → labels are swapped; smaller value is true kcal
            smaller = min(kj_val, kcal_val)
            result["calories_kcal"] = smaller if smaller <= 900 else round(smaller / 4.184, 1)
    elif kcal_val is not None:
        result["calories_kcal"] = kcal_val if kcal_val <= 900 else round(kcal_val / 4.184, 1)
    else:
        # No paired expression – try standalone ккал (value after or before unit label)
        m = re.search(r"([\d,\.]+)\s*к[кК]ал", text, re.IGNORECASE)
        if not m:
            m = re.search(r"к[кК]ал\s*[-–—:]\s*([\d,\.]+)", text, re.IGNORECASE)
        if m:
            v = parse_number(m.group(1))
            result["calories_kcal"] = v if (v and v <= 900) else (round(v / 4.184, 1) if v else None)

        # kDzh-only standalone: convert to kcal
        if result["calories_kcal"] is None:
            m = re.search(r"к[дД][жЖ]\s*[-–—:]\s*([\d,\.]+)", text, re.IGNORECASE)
            if m:
                v = parse_number(m.group(1))
                if v:
                    result["calories_kcal"] = round(v / 4.184, 1)

    # Derive kcal from macros when absent (Atwater: protein×4 + fat×9 + carbs×4)
    if result["calories_kcal"] is None:
        p, f, c = result["protein_g"], result["fat_g"], result["carbs_g"]
        if p is not None and f is not None and c is not None:
            result["calories_kcal"] = round(p * 4 + f * 9 + c * 4, 1)

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

    # 3. Deduplicate by barcode: for each barcode keep the record with the
    #    highest "Год исследования". Products with no barcodes are always kept.
    def research_year(data: dict) -> int:
        yr = get_product_info_value(data, "Год исследования", "Год исследования ")
        try:
            return int(yr.strip()) if yr else 0
        except ValueError:
            return 0

    # barcode → best (year, staging_id)
    barcode_best: dict[str, tuple[int, int]] = {}
    for staging_id, data in rows:
        yr = research_year(data)
        bc_raw = get_product_info_value(data, "Штрихкоды", "Штрихкод")
        for bc in split_barcodes(bc_raw):
            if bc not in barcode_best or yr > barcode_best[bc][0]:
                barcode_best[bc] = (yr, staging_id)

    # staging_ids that win at least one barcode
    winning_ids: set[int] = {sid for _, sid in barcode_best.values()}

    def is_kept(staging_id: int, data: dict) -> bool:
        bc_raw = get_product_info_value(data, "Штрихкоды", "Штрихкод")
        barcodes = split_barcodes(bc_raw)
        if not barcodes:
            return True  # no barcode — always keep
        return staging_id in winning_ids

    n_before = len(rows)
    rows = [(sid, data) for sid, data in rows if is_kept(sid, data)]
    log.info("Deduplication by barcode: %d → %d records (dropped %d)",
             n_before, len(rows), n_before - len(rows))

    # 3b. Filter: drop products that have no nutrition in source AND no barcode
    #     in kuper raw (even unenriched). If kuper has the barcode, keep it —
    #     enriched data may arrive later.
    with conn.cursor() as cur:
        cur.execute("""
            SELECT e.ean
            FROM staging.raw_kuper kr,
                 LATERAL jsonb_array_elements_text(kr.data->'eans') AS e(ean)
            WHERE jsonb_typeof(kr.data->'eans') = 'array'
        """)
        kuper_eans: set[str] = {row[0] for row in cur.fetchall()}
    log.info("Kuper EANs loaded: %d", len(kuper_eans))

    def has_source_nutrition(data: dict) -> bool:
        nutrition_text = get_product_info_value(
            data, "Дополнительная информация", "Пищевая ценность в 100г",
        )
        nf = parse_nutrition(nutrition_text)
        if any(v is not None for k, v in nf.items() if k != "serving_size_g"):
            return True
        kcal_text = get_product_info_value(data, "Энергетическая ценность, ккал")
        return bool(kcal_text and parse_number(kcal_text.strip()) is not None)

    def has_kuper_barcode(data: dict) -> bool:
        bc_raw = get_product_info_value(data, "Штрихкоды", "Штрихкод")
        return any(bc in kuper_eans for bc in split_barcodes(bc_raw))

    n_before = len(rows)
    rows = [
        (sid, data) for sid, data in rows
        if has_source_nutrition(data) or has_kuper_barcode(data)
    ]
    log.info("Nutrition filter: %d → %d records (dropped %d with no source nutrition and no kuper barcode)",
             n_before, len(rows), n_before - len(rows))

    # 3d. Build product, document, nutrition, barcode, health_risks rows
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

        # Try all fields that may contain nutrition text, merge results
        nutrition_text = get_product_info_value(
            data,
            "Дополнительная информация",
            "Пищевая ценность в 100г",
        )
        nf = parse_nutrition(nutrition_text)

        # "Энергетическая ценность, ккал" is a standalone calories field
        # (sources sometimes put kJ value here by mistake)
        if nf["calories_kcal"] is None:
            kcal_text = get_product_info_value(data, "Энергетическая ценность, ккал")
            if kcal_text:
                v = parse_number(kcal_text.strip())
                if v:
                    nf["calories_kcal"] = v if v <= 900 else round(v / 4.184, 1)

        if any(v is not None for k, v in nf.items() if k != "serving_size_g"):
            nutrition_rows_by_source_id[source_id] = nf

    n_with = sum(1 for row in product_rows if row[2] is not None)
    log.info("Products with category: %d / %d", n_with, len(product_rows))

    # 3b. Enrich macros from kuper raw via barcode match
    all_barcodes = [bc for bcs in barcode_rows_by_source_id.values() for bc in bcs]
    with conn.cursor() as cur:
        kuper_macros = fetch_kuper_macros_by_barcodes(cur, all_barcodes)
    log.info("Kuper barcode matches with macros: %d", len(kuper_macros))

    kuper_filled = 0
    for source_id, barcodes in barcode_rows_by_source_id.items():
        for bc in barcodes:
            km = kuper_macros.get(bc)
            if not km:
                continue
            nf = nutrition_rows_by_source_id.get(source_id)
            if nf is None:
                nf = {
                    "serving_size_g": 100,
                    "calories_kcal": None, "protein_g": None,
                    "fat_g": None, "carbs_g": None,
                    "fiber_g": None, "sugar_g": None,
                    "salt_g": None, "sodium_mg": None,
                }
                nutrition_rows_by_source_id[source_id] = nf
            filled = False
            for field in _MACRO_FIELDS:
                if nf[field] is None and km.get(field) is not None:
                    nf[field] = km[field]
                    filled = True
            if filled:
                kuper_filled += 1
            break  # first barcode match is enough
    log.info("Products enriched with kuper macros: %d", kuper_filled)

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
    _enrich_nutrition(conn, "rosqual")
    log.info("DDS rosqual load complete")
    conn.close()


def _enrich_nutrition(conn, source: str):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    model_dir = os.environ.get("NUTR_MODEL_DIR", os.path.join(project_dir, "models", "nutr"))
    if not os.path.exists(model_dir):
        log.warning("NUTR_MODEL_DIR not found (%s) — skipping ML nutrition enrichment", model_dir)
        return
    try:
        from dds.nutr_model import NutritionModel
    except ImportError:
        from nutr_model import NutritionModel
    model = NutritionModel.load(model_dir)
    model.enrich_source(conn, source)


if __name__ == "__main__":
    load_dds()
