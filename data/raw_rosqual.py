import json
import os
import logging
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
import psycopg2
from psycopg2 import pool
from psycopg2.extras import Json as PgJson
from tqdm import tqdm

from config import DB_CONFIG

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(threadName)s] %(message)s",
)
log = logging.getLogger(__name__)

BASE_URL = "https://rskrf.ru/rest/1"
WORKERS = 1
CACHE_FILE = os.path.join(os.path.dirname(__file__), "scan_cache.json")

DDL = """
CREATE SCHEMA IF NOT EXISTS staging;
CREATE TABLE IF NOT EXISTS staging.raw_rosqual_producs (
    id    INTEGER PRIMARY KEY,
    data  JSONB NOT NULL
);
"""

session = requests.Session()
adapter = requests.adapters.HTTPAdapter(pool_connections=WORKERS, pool_maxsize=WORKERS)
session.mount("https://", adapter)


# --------------- HTTP ---------------

def fetch_json(url: str) -> dict | None:
    try:
        resp = session.get(url, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        log.error("Failed to fetch %s: %s", url, e)
        return None


def fetch_categories() -> list[dict]:
    data = fetch_json(f"{BASE_URL}/catalog/categories/8/")
    if not data:
        return []
    return data.get("response", [])


def fetch_product_groups(category_id: int) -> list[dict]:
    data = fetch_json(f"{BASE_URL}/catalog/categories/{category_id}/productGroups/")
    if not data:
        return []
    resp = data.get("response", {})
    if isinstance(resp, dict):
        return resp.get("productGroups", [])
    return []


def fetch_products_list(group_id: int) -> list[dict]:
    data = fetch_json(f"{BASE_URL}/catalog/products/{group_id}/")
    if not data:
        return []
    resp = data.get("response", {})
    if isinstance(resp, dict):
        return resp.get("products", [])
    return []


def fetch_product_detail(product_id: int) -> dict | None:
    data = fetch_json(f"{BASE_URL}/product/{product_id}/")
    if not data:
        return None
    return data.get("response")


# --------------- cache ---------------

def load_scan_cache() -> list[dict] | None:
    if not os.path.exists(CACHE_FILE):
        return None
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        log.info("Loaded scan cache from %s (%d tasks)", CACHE_FILE, len(data))
        return data
    except Exception as e:
        log.warning("Failed to read cache: %s", e)
        return None


def save_scan_cache(tasks: list[dict]):
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(tasks, f, ensure_ascii=False, indent=2)


def scan_all_products() -> list[dict]:
    categories = fetch_categories()
    log.info("Fetched %d categories", len(categories))

    all_tasks = []

    for cat in tqdm(categories, desc="Scanning categories", unit="cat"):
        cat_id = cat["id"]
        cat_title = cat["title"]

        try:
            groups = fetch_product_groups(cat_id)

            for group in groups:
                if "id" not in group:
                    continue

                group_id = group["id"]
                group_title = group.get("title", f"id={group_id}")

                products = fetch_products_list(group_id)

                log.info(
                    "  [%s] %s: %d products",
                    cat_title, group_title, len(products),
                )

                for p in products:
                    all_tasks.append({
                        "id": p["id"],
                        "category": cat_title,
                        "group": group_title,
                    })
        except Exception as e:
            log.error("Error scanning category '%s' (id=%d): %s", cat_title, cat_id, e)

        save_scan_cache(all_tasks)

    log.info("Total products found: %d", len(all_tasks))
    return all_tasks


# --------------- DB ---------------

db_pool: pool.ThreadedConnectionPool | None = None


def init_db_pool():
    global db_pool
    db_pool = pool.ThreadedConnectionPool(minconn=1, maxconn=WORKERS + 1, **DB_CONFIG)
    log.info("DB connection pool created (max=%d)", WORKERS + 1)


def create_tables():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(DDL)
        conn.commit()
        log.info("Table created / verified")
    finally:
        db_pool.putconn(conn)


def get_existing_ids(ids: list[int]) -> set[int]:
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id FROM staging.raw_rosqual_producs WHERE id = ANY(%s)",
                (ids,),
            )
            return {row[0] for row in cur.fetchall()}
    finally:
        db_pool.putconn(conn)


def save_product(product_id: int, data: dict):
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO staging.raw_rosqual_producs (id, data)
                VALUES (%s, %s)
                ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data
                """,
                (product_id, PgJson(data)),
            )
        conn.commit()
    finally:
        db_pool.putconn(conn)


# --------------- main ---------------

def load_all():
    init_db_pool()
    create_tables()

    # Phase 1: use cache or scan API
    all_tasks = load_scan_cache()
    if all_tasks is None:
        all_tasks = scan_all_products()

    # Filter out already existing
    all_ids = [t["id"] for t in all_tasks]
    existing = get_existing_ids(all_ids)
    to_fetch = [t for t in all_tasks if t["id"] not in existing]

    log.info(
        "Total: %d, already in DB: %d, to fetch: %d",
        len(all_tasks), len(existing), len(to_fetch),
    )

    if not to_fetch:
        log.info("Nothing to fetch, done.")
        db_pool.closeall()
        return

    # Phase 2: parallel fetch & save (each thread gets its own DB conn from pool)
    total_saved = 0
    total_errors = 0

    def worker(task):
        pid = task["id"]
        detail = fetch_product_detail(pid)
        if detail:
            save_product(pid, detail)
        return pid, detail

    with tqdm(total=len(to_fetch), desc="Fetching products", unit="prod") as pbar:
        with ThreadPoolExecutor(max_workers=WORKERS) as executor:
            futures = {executor.submit(worker, t): t for t in to_fetch}

            for future in as_completed(futures):
                task = futures[future]
                try:
                    pid, detail = future.result()
                    if detail:
                        total_saved += 1
                    else:
                        log.error("Empty response for product %d", task["id"])
                        total_errors += 1
                except Exception as e:
                    log.error("Error fetching product %d: %s", task["id"], e)
                    total_errors += 1

                pbar.update(1)

    log.info("Done. Saved: %d, Errors: %d", total_saved, total_errors)
    db_pool.closeall()


if __name__ == "__main__":
    load_all()
