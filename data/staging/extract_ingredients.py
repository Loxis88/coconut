"""
extract_ingredients.py

Parses ingredient composition strings from rosqual + kuper products
using OpenAI Batch API (50% cheaper, async).

Deduplicates by ingredient text — one LLM request per unique composition string.

Usage:
    python staging/extract_ingredients.py          # auto: submit if no pending batch, else collect
    python staging/extract_ingredients.py submit   # force submit
    python staging/extract_ingredients.py collect  # force collect (check status + save if done)
"""

import os
import sys
import json
import hashlib
import logging
from typing import Optional

import psycopg2
from psycopg2.extras import execute_values
from pydantic import BaseModel, field_validator
from openai import OpenAI

from config import DB_CONFIG, OPENAI_API_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

MODEL = "gpt-4o-mini"
BATCH_SIZE = 5000  # requests per OpenAI batch

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROGRESS_FILE   = os.path.join(SCRIPT_DIR, ".ingredients_progress.json")
BATCH_STATE_FILE = os.path.join(SCRIPT_DIR, ".ingredients_batch_state.json")


# ── Pydantic models ──────────────────────────────────────────────────────────

class Ingredient(BaseModel):
    name: str
    is_transparent: bool = True
    qty: Optional[float] = None
    unit: Optional[str] = None
    qualifier: Optional[str] = None

    @field_validator("qty", mode="before")
    @classmethod
    def coerce_qty(cls, v):
        if not isinstance(v, dict):
            return v
        if v.get("type") == "null":
            return None
        # {"min": 5, "max": 12} → midpoint
        if "min" in v and "max" in v:
            return (v["min"] + v["max"]) / 2
        return None

    @field_validator("unit", "qualifier", mode="before")
    @classmethod
    def coerce_nullable_str(cls, v):
        if isinstance(v, dict) and v.get("type") == "null":
            return None
        return v


class ProductIngredients(BaseModel):
    source_id: str
    ingredients: list[Ingredient]


class ExtractionResponse(BaseModel):
    products: list[ProductIngredients]


# ── Prompt ───────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """\
Ты парсер составов продуктов питания. Тебе дан список продуктов с полем "ingredients" (строка состава).

Для каждого продукта извлеки ВСЕ отдельные ингредиенты.

Правила парсинга:
1. Раскрывай скобки: "масло растительное (подсолнечное, пальмовое)" → "масло подсолнечное", "масло пальмовое".
2. "загуститель пектин" → name="пектин". "консервант сорбат калия" → name="сорбат калия". \
Функция (загуститель, консервант, краситель, эмульгатор, стабилизатор, антиокислитель, \
регулятор кислотности, разрыхлитель, фиксатор окраски, усилитель вкуса и аромата, \
глазирователь, подсластитель, желирующий агент, агент влагоудерживающий, уплотнитель) — \
НЕ часть названия. Убирай её.
3. Если указана ТОЛЬКО функция без конкретики ("ароматизаторы", "красители", "специи") → \
name = функция в единственном числе ("ароматизатор", "краситель", "специя").
4. "перец черный, белый, зеленый" → "перец черный", "перец белый", "перец зеленый".
6. qty/unit/qualifier — если указано количество: "не менее 25%" → qty=25, unit="%", qualifier="min". \
"не более 1%" → qty=1, unit="%", qualifier="max". Иначе null.
7. is_transparent — false если производитель использует общую формулировку без конкретики: \
"ароматизатор" (какой?), "красители" (какие?), "специи" (какие?), "растительные масла" (какие?). \
Если указано конкретно ("ароматизатор ванилин", "масло подсолнечное") → true.
8. Все названия в нижнем регистре.
9. Текст после точки вне скобок — не ингредиенты (информация о составе), игнорируй.
10. "содержит следы" / "может содержать" — не ингредиенты, игнорируй.
"""


# ── Helpers ──────────────────────────────────────────────────────────────────

def text_hash(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()[:24]


def load_progress() -> set[str]:
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, "r", encoding="utf-8") as f:
            return set(json.load(f).get("done_source_ids", []))
    return set()


def save_progress(done_ids: set[str]):
    with open(PROGRESS_FILE, "w", encoding="utf-8") as f:
        json.dump({"done_source_ids": sorted(done_ids)}, f)


def load_batch_state() -> dict:
    if os.path.exists(BATCH_STATE_FILE):
        with open(BATCH_STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_batch_state(state: dict):
    with open(BATCH_STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False)


def build_jsonl_request(text_id: str, ingredients_text: str) -> dict:
    return {
        "custom_id": text_id,
        "method": "POST",
        "url": "/v1/chat/completions",
        "body": {
            "model": MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": json.dumps(
                    {"products": [{"source_id": text_id, "ingredients": ingredients_text}]},
                    ensure_ascii=False,
                )},
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "ExtractionResponse",
                    "schema": ExtractionResponse.model_json_schema(),
                    "strict": False,
                },
            },
            "temperature": 0.0,
        },
    }


# ── Submit ────────────────────────────────────────────────────────────────────

def _upload_and_create_batch(client: OpenAI, requests: list[dict], index: int) -> tuple[str, str]:
    """Upload a JSONL chunk and create one OpenAI batch. Returns (batch_id, file_id)."""
    import io
    jsonl_bytes = "\n".join(json.dumps(r, ensure_ascii=False) for r in requests).encode("utf-8")
    uploaded = client.files.create(
        file=io.BytesIO(jsonl_bytes),
        purpose="batch",
    )
    log.info("  Chunk %d: uploaded file %s (%d requests)", index, uploaded.id, len(requests))
    batch = client.batches.create(
        input_file_id=uploaded.id,
        endpoint="/v1/chat/completions",
        completion_window="24h",
    )
    log.info("  Chunk %d: batch %s  status=%s", index, batch.id, batch.status)
    return batch.id, uploaded.id


def submit(conn, client: OpenAI):
    # Already done: from progress file + staging table
    done_ids = load_progress()
    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT source_id FROM staging.raw_product_ingredients")
        done_ids |= {row[0] for row in cur.fetchall()}

    with conn.cursor() as cur:
        cur.execute("""
            SELECT source_id, ingredients
            FROM product_catalog.product
            WHERE source IN ('rosqual', 'kuper')
              AND ingredients IS NOT NULL
        """)
        all_products = cur.fetchall()

    to_process = [(sid, ing) for sid, ing in all_products if sid not in done_ids]
    log.info(
        "Products: %d total, %d already done, %d to process",
        len(all_products), len(done_ids), len(to_process),
    )

    if not to_process:
        log.info("Nothing to process")
        return

    # Deduplicate by ingredients text
    text_to_source_ids: dict[str, list[str]] = {}
    for sid, ing in to_process:
        text_to_source_ids.setdefault(ing, []).append(sid)

    unique_texts = list(text_to_source_ids.items())
    unique_count = len(unique_texts)
    log.info(
        "Unique ingredient texts: %d (from %d products, saved %d LLM calls)",
        unique_count, len(to_process), len(to_process) - unique_count,
    )

    # Split unique texts into chunks of BATCH_SIZE and submit each as a separate OpenAI batch
    submitted_batches = []
    for chunk_start in range(0, unique_count, BATCH_SIZE):
        chunk = unique_texts[chunk_start:chunk_start + BATCH_SIZE]
        chunk_index = chunk_start // BATCH_SIZE + 1
        total_chunks = (unique_count + BATCH_SIZE - 1) // BATCH_SIZE

        hash_to_source_ids: dict[str, list[str]] = {}
        requests = []
        for text, sids in chunk:
            h = text_hash(text)
            hash_to_source_ids[h] = sids
            requests.append(build_jsonl_request(h, text))

        log.info("Submitting chunk %d/%d (%d requests)...", chunk_index, total_chunks, len(requests))
        batch_id, file_id = _upload_and_create_batch(client, requests, chunk_index)
        submitted_batches.append({
            "batch_id": batch_id,
            "file_id": file_id,
            "hash_to_source_ids": hash_to_source_ids,
        })

    save_batch_state({
        "batches": submitted_batches,
        "done_source_ids": sorted(done_ids),
    })
    log.info(
        "Submitted %d batch(es). State saved to %s",
        len(submitted_batches), BATCH_STATE_FILE,
    )
    log.info("Run with 'collect' once batches are complete (check at platform.openai.com/batches)")


# ── Collect ───────────────────────────────────────────────────────────────────

def _collect_one_batch(conn, client: OpenAI, batch_info: dict, done_ids: set[str]) -> tuple[int, int]:
    """Download and process one completed batch. Returns (rows_inserted, failed_count)."""
    batch_id = batch_info["batch_id"]
    hash_to_source_ids: dict[str, list[str]] = batch_info["hash_to_source_ids"]

    raw = client.files.content(batch_info["output_file_id"]).content
    lines = raw.decode("utf-8").strip().splitlines()
    log.info("  Batch %s: downloaded %d result lines", batch_id, len(lines))

    total_rows = 0
    failed = 0

    for line in lines:
        result = json.loads(line)
        custom_id = result["custom_id"]

        if result.get("error"):
            log.warning("  Request %s failed: %s", custom_id, result["error"])
            failed += 1
            continue

        content = result["response"]["body"]["choices"][0]["message"]["content"]
        try:
            parsed = ExtractionResponse.model_validate_json(content)
        except Exception as e:
            log.warning("  Parse error for %s: %s", custom_id, e)
            failed += 1
            continue

        if not parsed.products:
            continue

        ingredients = parsed.products[0].ingredients
        source_ids = hash_to_source_ids.get(custom_id, [])
        if not source_ids:
            log.warning("  No source_ids for hash %s", custom_id)
            continue

        staging_rows = []
        for sid in source_ids:
            for pos, ing in enumerate(ingredients, start=1):
                name = ing.name.strip().lower()
                if not name:
                    continue
                staging_rows.append((
                    sid, name, pos,
                    ing.is_transparent,
                    ing.qty, ing.unit, ing.qualifier,
                ))
            done_ids.add(sid)

        if staging_rows:
            with conn.cursor() as cur:
                execute_values(
                    cur,
                    """
                    INSERT INTO staging.raw_product_ingredients
                        (source_id, ingredient_name, position, is_transparent,
                         qty, unit, qualifier)
                    VALUES %s
                    """,
                    staging_rows,
                )
            total_rows += len(staging_rows)

    conn.commit()
    return total_rows, failed


def collect(conn, client: OpenAI):
    state = load_batch_state()
    if not state:
        log.error("No batch state found. Run 'submit' first.")
        return

    batches: list[dict] = state["batches"]
    done_ids = set(state.get("done_source_ids", []))

    total_rows = 0
    total_failed = 0
    still_pending = []

    for batch_info in batches:
        batch_id = batch_info["batch_id"]
        batch = client.batches.retrieve(batch_id)
        counts = batch.request_counts
        log.info(
            "Batch %s: status=%s  completed=%d/%d  failed=%d",
            batch_id, batch.status,
            counts.completed, counts.total, counts.failed,
        )

        if batch.status not in ("completed", "failed", "expired", "cancelled"):
            still_pending.append(batch_info)
            continue

        if batch.status in ("failed", "cancelled"):
            log.error("Batch %s ended with status=%s, skipping.", batch_id, batch.status)
            continue

        if batch.status == "expired":
            if not batch.output_file_id:
                log.error("Batch %s expired with no partial output, skipping.", batch_id)
                continue
            log.warning(
                "Batch %s expired (%d/%d completed) — collecting partial results.",
                batch_id, counts.completed, counts.total,
            )

        batch_info["output_file_id"] = batch.output_file_id
        rows, failed = _collect_one_batch(conn, client, batch_info, done_ids)
        total_rows += rows
        total_failed += failed
        log.info("  Batch %s: +%d rows, %d failed", batch_id, rows, failed)

    save_progress(done_ids)

    if still_pending:
        state["batches"] = still_pending
        state["done_source_ids"] = sorted(done_ids)
        save_batch_state(state)
        log.info("%d batch(es) still pending — run 'collect' again later.", len(still_pending))
    else:
        os.remove(BATCH_STATE_FILE)
        log.info("All batches collected and state cleared.")

    log.info(
        "Done. Inserted %d rows total. Failed requests: %d",
        total_rows, total_failed,
    )


def recover(conn, client: OpenAI, batch_id: str):
    """Collect partial results from an expired/lost batch by batch_id alone."""
    batch = client.batches.retrieve(batch_id)
    counts = batch.request_counts
    log.info(
        "Batch %s: status=%s  completed=%d/%d",
        batch_id, batch.status, counts.completed, counts.total,
    )

    if not batch.output_file_id:
        log.error("No output file available for batch %s.", batch_id)
        return

    # Rebuild hash_to_source_ids from local state history or progress file.
    # Without the original mapping we use hash==source_id fallback:
    # each result's custom_id IS the hash, and source_ids must be re-derived
    # from the DB by matching the ingredient text hash.
    with conn.cursor() as cur:
        cur.execute("""
            SELECT source_id, ingredients FROM product_catalog.product
            WHERE source IN ('rosqual', 'kuper') AND ingredients IS NOT NULL
        """)
        rows = cur.fetchall()

    hash_to_source_ids: dict[str, list[str]] = {}
    for sid, ing in rows:
        h = text_hash(ing)
        hash_to_source_ids.setdefault(h, []).append(sid)

    done_ids = load_progress()
    batch_info = {
        "batch_id": batch_id,
        "output_file_id": batch.output_file_id,
        "hash_to_source_ids": hash_to_source_ids,
    }
    rows_inserted, failed = _collect_one_batch(conn, client, batch_info, done_ids)
    save_progress(done_ids)
    log.info("Recovered %d rows, %d failed.", rows_inserted, failed)


# ── Entry point ───────────────────────────────────────────────────────────────

def run():
    if len(sys.argv) > 1:
        mode = sys.argv[1]
    elif load_batch_state():
        mode = "collect"
    else:
        log.info("No pending batches. Run with 'submit' to start a new batch, or 'collect' to force-collect.")
        return

    log.info("Mode: %s", mode)

    client = OpenAI(api_key=OPENAI_API_KEY)
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS staging.raw_product_ingredients (
                source_id TEXT NOT NULL,
                ingredient_name TEXT NOT NULL,
                position INT,
                is_transparent BOOLEAN DEFAULT true,
                qty NUMERIC,
                unit TEXT,
                qualifier TEXT
            )
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_raw_pi_source_id
            ON staging.raw_product_ingredients (source_id)
        """)
    conn.commit()

    if mode == "submit":
        submit(conn, client)
    elif mode == "collect":
        collect(conn, client)
    elif mode == "recover":
        if len(sys.argv) < 3:
            log.error("Usage: recover <batch_id>")
        else:
            recover(conn, client, sys.argv[2])
    else:
        log.error("Unknown mode '%s'. Use: submit | collect | recover <batch_id>", mode)

    conn.close()


if __name__ == "__main__":
    run()
