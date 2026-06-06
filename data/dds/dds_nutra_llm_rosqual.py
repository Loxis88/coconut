import os
import json
import hashlib
import logging
import requests
import psycopg2
from psycopg2.extras import execute_values
from pydantic import BaseModel
from openai import OpenAI
from tqdm import tqdm
from ocr_mistral import extract_text_from_pdf


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG, OPENAI_API_KEY


# --- Pydantic models for structured output ---

class MicronutrientAmount(BaseModel):
    nutrient_name: str
    amount: float | None = None


class HealthRisk(BaseModel):
    fact: str


class LLMResponse(BaseModel):
    micronutrients: list[MicronutrientAmount]
    unknown: list[str]
    health_risks: list[HealthRisk]


# --- Helpers ---

def get_product_info_value(data: dict, *field_names: str) -> str | None:
    for item in data.get("product_info", []):
        if item.get("name") in field_names:
            return item.get("info")
    return None


PDF_CACHE_DIR = os.path.join(os.path.dirname(__file__), "pdf_cache")


def download_pdf(url: str) -> str | None:
    """Download PDF to cache, return cached path or None."""
    os.makedirs(PDF_CACHE_DIR, exist_ok=True)
    url_hash = hashlib.md5(url.encode()).hexdigest()
    cached_path = os.path.join(PDF_CACHE_DIR, f"{url_hash}.pdf")

    if not os.path.exists(cached_path):
        try:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            with open(cached_path, "wb") as f:
                f.write(resp.content)
        except Exception as e:
            log.warning("Failed to download PDF %s: %s", url, e)
            return None
    else:
        log.info("PDF cached: %s", cached_path)
    return cached_path




def build_context(data: dict, pdf_texts: list[str]) -> str:
    parts = []

    description = data.get("description")
    if description:
        parts.append(f"Описание продукта:\n{description}")

    ingredients = get_product_info_value(data, "Состав")
    if ingredients:
        parts.append(f"Состав:\n{ingredients}")

    nutrition_info = get_product_info_value(data, "Дополнительная информация")
    if nutrition_info:
        parts.append(f"Дополнительная информация (пищевая ценность):\n{nutrition_info}")

    for i, pdf_text in enumerate(pdf_texts, 1):
        if pdf_text.strip():
            parts.append(f"Документ {i}:\n{pdf_text}")

    return "\n\n---\n\n".join(parts)


def load_micronutrients(conn) -> tuple[dict[str, int], str]:
    """Load micronutrients from DB, return (name->id map, formatted list for prompt)."""
    with conn.cursor() as cur:
        cur.execute("SELECT id, name, unit FROM product_catalog.micronutrients")
        rows = cur.fetchall()

    name_to_id = {name: nid for nid, name, _ in rows}
    nutrient_list_str = "\n".join(f"- {name} (unit: {unit})" for _, name, unit in rows)
    return name_to_id, nutrient_list_str


def build_system_prompt(nutrient_list_str: str) -> str:
    return f"""Ты — эксперт по нутрициологии и пищевой безопасности. Тебе дана информация о продукте питания.

Твои задачи:
1. Извлечь микронутриенты ТОЛЬКО из этого списка (используй ИМЕННО эти названия):
{nutrient_list_str}

   Возвращай в поле micronutrients те, для которых есть числовое значение (amount = число).
   Если микронутриент упомянут в составе/тексте но БЕЗ числового значения — тоже добавь его с amount = null.

2. ВСЕ остальные вещества с числовыми значениями которых НЕТ в списке выше (тяжёлые металлы, пестициды, токсины, любые химические соединения) — верни в поле unknown как строку в формате "Название: значение единица".
   Также добавь в unknown ВСЕ пищевые добавки E (E100, E200, E621 и т.д.) найденные в тексте — в формате "E-код: название".

3. Выделить факты о продукте, которые могут вредить здоровью потребителя.

Если микронутриентов нет — верни пустой список micronutrients.
Если неизвестных веществ нет — верни пустой список unknown.
Если рисков нет — верни пустой список health_risks."""


CHUNK_SIZE = 15000  # chars per chunk


class DeduplicatedRisks(BaseModel):
    facts: list[str]


def deduplicate_risks(client: OpenAI, risks: list[HealthRisk]) -> list[str]:
    """Use LLM to deduplicate health risks that may be phrased differently."""
    raw_facts = [risk.fact for risk in risks]
    if len(raw_facts) <= 1:
        return raw_facts

    try:
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Тебе дан список фактов о вреде продукта. Убери дубликаты — оставь только уникальные по смыслу факты. Перефразировать не нужно, выбери лучшую формулировку из дубликатов."},
                {"role": "user", "content": "\n".join(f"- {f}" for f in raw_facts)},
            ],
            response_format=DeduplicatedRisks,
            temperature=0.0,
        )
        return completion.choices[0].message.parsed.facts
    except Exception as e:
        log.error("Dedup LLM failed: %s", e)
        return list(set(raw_facts))


def split_into_chunks(text: str, chunk_size: int = CHUNK_SIZE) -> list[str]:
    """Split text into chunks by lines, respecting chunk_size limit."""
    chunks = []
    current = ""
    for line in text.split("\n"):
        if len(current) + len(line) + 1 > chunk_size and current:
            chunks.append(current)
            current = line
        else:
            current = current + "\n" + line if current else line
    if current:
        chunks.append(current)
    return chunks


def call_llm(client: OpenAI, system_prompt: str, context: str) -> LLMResponse | None:
    if not context.strip():
        return None

    try:
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": context},
            ],
            response_format=LLMResponse,
            temperature=0.0,
        )
        return completion.choices[0].message.parsed
    except Exception as e:
        log.error("LLM call failed: %s", e)
        return None


def call_llm_chunked(client: OpenAI, system_prompt: str, context: str) -> LLMResponse | None:
    """Split large context into chunks, call LLM on each, merge results."""
    if not context.strip():
        return None

    if len(context) <= CHUNK_SIZE:
        return call_llm(client, system_prompt, context)

    chunks = split_into_chunks(context)
    log.info("  Splitting into %d chunks", len(chunks))

    all_micronutrients = []
    all_unknown = []
    all_health_risks = []

    for i, chunk in enumerate(chunks, 1):
        log.info("  Chunk %d/%d (%d chars)", i, len(chunks), len(chunk))
        result = call_llm(client, system_prompt, chunk)
        if result:
            all_micronutrients.extend(result.micronutrients)
            all_unknown.extend(result.unknown)
            all_health_risks.extend(result.health_risks)

    if not all_micronutrients and not all_unknown and not all_health_risks:
        return None

    return LLMResponse(micronutrients=all_micronutrients, unknown=all_unknown, health_risks=all_health_risks)


# --- Main ---

def run():
    client = OpenAI(api_key=OPENAI_API_KEY)
    conn = psycopg2.connect(**DB_CONFIG)

    # Load micronutrients dictionary from DB
    name_to_id, nutrient_list_str = load_micronutrients(conn)
    log.info("Loaded %d micronutrients from DB", len(name_to_id))
    system_prompt = build_system_prompt(nutrient_list_str)

    with conn.cursor() as cur:
        cur.execute("SELECT id, data FROM staging.raw_rosqual_producs")
        rows = cur.fetchall()

    log.info("Loaded %d raw products from staging", len(rows))

    # Get mapping: staging id (source_id) -> product.id for rosqual products
    with conn.cursor() as cur:
        cur.execute("SELECT id, source_id FROM product_catalog.product WHERE source = 'rosqual'")
        source_id_to_product_id = {int(sid): pid for pid, sid in cur.fetchall() if sid is not None}
    valid_ids = set(source_id_to_product_id.keys())

    # Skip already processed products (local file tracks all, even those with 0 micronutrients)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    processed_file = os.path.join(script_dir, "processed_products.json")
    if os.path.exists(processed_file):
        with open(processed_file, "r") as f:
            already_processed = set(json.load(f))
    else:
        already_processed = set()
    log.info("Skipping %d already processed products", len(already_processed))

    # Filter
    rows = [(pid, data) for pid, data in rows if pid in valid_ids and pid not in already_processed]
    log.info("Products to process: %d", len(rows))

    # Get document links
    with conn.cursor() as cur:
        cur.execute("SELECT product_id, doc_link FROM product_catalog.product_documents")
        doc_links: dict[int, list[str]] = {}
        for pid, link in cur.fetchall():
            doc_links.setdefault(pid, []).append(link)

    inserted_total = 0

    for staging_id, data in tqdm(rows, desc="Parsing micronutrients"):
        product_id = source_id_to_product_id[staging_id]

        # Download PDFs and OCR
        pdf_texts = []
        for link in doc_links.get(product_id, []):
            if link and link.lower().endswith(".pdf"):
                log.info("[%d] Downloading PDF: %s", product_id, link)
                pdf_path = download_pdf(link)
                if pdf_path is None:
                    continue
                try:
                    text = extract_text_from_pdf(pdf_path)
                    log.info("[%d] OCR extracted %d chars", product_id, len(text))
                    pdf_texts.append(text)
                except Exception as e:
                    log.warning("[%d] OCR failed: %s", product_id, e)

        context = build_context(data, pdf_texts)
        if not context.strip():
            log.debug("[%d] No context, skipping", product_id)
            continue

        # Save LLM input to log file
        logs_dir = os.path.join(os.path.dirname(__file__), "logs")
        os.makedirs(logs_dir, exist_ok=True)
        with open(os.path.join(logs_dir, f"{product_id}.txt"), "w", encoding="utf-8") as f:
            f.write(context)

        log.info("[%d] Calling LLM (context: %d chars)", product_id, len(context))
        result = call_llm_chunked(client, system_prompt, context)
        if result is None:
            log.warning("[%d] LLM returned None", product_id)
            continue

        # Collect micronutrient rows
        unknown_file = os.path.join(script_dir, "unknown_nutrients.txt")
        micro_rows = []
        for item in result.micronutrients:
            nutrient_id = name_to_id.get(item.nutrient_name)
            if nutrient_id is not None:
                micro_rows.append((product_id, nutrient_id, item.amount))
            else:
                log.warning("[%d] Unknown nutrient from LLM: %s", product_id, item.nutrient_name)

        # Write unknown substances to file
        if result.unknown:
            with open(unknown_file, "a", encoding="utf-8") as f:
                for entry in result.unknown:
                    f.write(f"{product_id}\t{entry}\n")
            log.info("[%d] %d unknown substances written to file", product_id, len(result.unknown))

        log.info("[%d] LLM result: %d micronutrients, %d health risks",
                 product_id, len(micro_rows), len(result.health_risks))

        # Write to DB
        with conn.cursor() as cur:
            if micro_rows:
                execute_values(
                    cur,
                    """
                    INSERT INTO product_catalog.product_micronutrients
                        (product_id, nutrient_id, amount)
                    VALUES %s
                    """,
                    micro_rows,
                )
                inserted_total += len(micro_rows)

            if result.health_risks:
                unique_risks = deduplicate_risks(client, result.health_risks)
                risk_rows = [(product_id, fact) for fact in unique_risks]
                execute_values(
                    cur,
                    """
                    INSERT INTO product_catalog.health_risks
                        (product_id, fact)
                    VALUES %s
                    """,
                    risk_rows,
                )
                for fact in unique_risks:
                    log.info("[%d] Health risk: %s", product_id, fact)

        conn.commit()

        # Mark product as processed
        already_processed.add(staging_id)
        with open(processed_file, "w") as f:
            json.dump(list(already_processed), f)

    log.info("Inserted %d micronutrient records total", inserted_total)

    conn.close()


if __name__ == "__main__":
    run()
