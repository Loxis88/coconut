import json
import os
import time
import queue
import random
import logging
import threading

import psycopg2
from psycopg2.extras import Json
from playwright.sync_api import sync_playwright

from config import DB_CONFIG

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Single switch for the Kuper host. The CDP-launched Chrome is detected as mobile and
# the site redirects to the mobile host, so flip this between the two as needed.
KUPER_BASE = "https://kuper.ru"        # mobile: "https://web.kuper.ru"
MULTICARDS_URL = f"{KUPER_BASE}/api/v3/multicards"

# One worker thread per CDP endpoint. Both reached over an SSH tunnel on the VPS
# (e.g. autossh -L 9222 -L 9223). First = direct browser, second = via hysteria.
CDP_ENDPOINTS = [
    "http://127.0.0.1:9222",   # direct
    "http://127.0.0.1:9223",   # via hysteria
]

# JS run inside the page (same origin) to call the multicards API with session cookies.
FETCH_JS = """
async (url) => {
    const resp = await fetch(url, {
        method: "GET",
        credentials: "include",
        headers: {
            "accept": "application/json, text/plain, */*",
            "client-id": "SbermarketPlatformWeb",
            "client-token": "7ba97b6f4049436dab90c789f946ee2f",
            "sbm-forward-tenant": "sbermarket"
        }
    });
    return { status: resp.status, body: resp.status === 200 ? await resp.json() : await resp.text() };
}
"""


def load_slug_map(conn, store_ids):
    """store_id -> retailer_slug from dds.kuper_store. Returns (slug_map, missing)."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT store_id::text, retailer_slug FROM dds.kuper_store WHERE store_id = ANY(%s)",
            ([int(s) for s in store_ids if s and s.isdigit()],),
        )
        slug_map = {sid: slug for sid, slug in cur.fetchall()}
    missing = [s for s in store_ids if s not in slug_map]
    return slug_map, missing


def resolve_missing_slugs(endpoint, missing):
    """Fallback: resolve slugs not in dds.kuper_store via the API on one browser."""
    out = {}
    try:
        with sync_playwright() as p:
            browser = p.chromium.connect_over_cdp(endpoint)
            page = browser.contexts[0].new_page()
            page.goto(KUPER_BASE, wait_until="domcontentloaded", timeout=30000)
            for sid in missing:
                info = page.evaluate(
                    "async (url) => { const r = await fetch(url, {credentials:'include'}); return await r.json(); }",
                    f"{KUPER_BASE}/api/stores/{sid}",
                )
                out[sid] = info["store"]["retailer_slug"]
                log.info("Store %s -> slug: %s (API)", sid, out[sid])
            page.close()
    except Exception as e:
        log.warning("Slug API fallback failed (%s); missing stores will use default slug", e)
    return out


def worker(idx, endpoint, q, slug_map, default_slug, default_store_id):
    """One browser. Pulls products off the shared queue until empty.
    On captcha (401/403) the thread RAISES and dies — no interactive prompt."""
    label = chr(65 + idx)  # A, B, ...
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True

    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(endpoint)
        context = browser.contexts[0]
        page = context.new_page()
        page.goto(f"{KUPER_BASE}/{default_slug}?referrer=landing_retailer_list",
                  wait_until="domcontentloaded", timeout=30000)
        log.info("[%s] connected to %s, starting", label, endpoint)

        processed = 0
        batch_count = 0
        batch_size = random.randint(20, 25)
        next_catalog_visit = random.randint(5, 10)

        while True:
            try:
                row_id, permalink, row_store_id = q.get_nowait()
            except queue.Empty:
                break

            processed += 1
            batch_count += 1
            sid = row_store_id or str(default_store_id)
            slug = slug_map.get(sid, default_slug)
            cur_catalog_url = f"{KUPER_BASE}/{slug}?referrer=landing_retailer_list"

            # Reset session every ~20-25 requests
            if batch_count >= batch_size:
                log.info("[%s] session reset: closing tab, waiting 60s...", label)
                page.close()
                time.sleep(60)
                page = context.new_page()
                page.goto(cur_catalog_url, wait_until="load", timeout=30000)
                time.sleep(random.uniform(2.0, 4.0))
                batch_count = 0
                batch_size = random.randint(20, 25)
                next_catalog_visit = processed + random.randint(5, 10)
                log.info("[%s] new session started", label)
            elif processed == next_catalog_visit:
                log.info("[%s] visiting catalog page...", label)
                page.goto(cur_catalog_url, wait_until="load", timeout=30000)
                time.sleep(random.uniform(2.0, 4.0))
                next_catalog_visit = processed + random.randint(5, 10)

            url = (f"{MULTICARDS_URL}?permalink={permalink}&store_id={sid}"
                   f"&tenant_id=sbermarket&is_seo=false")

            result = None
            for attempt in range(3):
                try:
                    result = page.evaluate(FETCH_JS, url)
                    break
                except Exception as e:
                    if attempt < 2:
                        time.sleep(2)
                    else:
                        log.warning("[%s] JS fetch error for %s: %s", label, permalink, e)
            if result is None:
                continue

            status = result["status"]
            remaining = q.qsize()

            if status == 200:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO staging.raw_kuper_enriched (id, data) VALUES (%s, %s) "
                        "ON CONFLICT (id) DO NOTHING",
                        (row_id, Json(result["body"])),
                    )
                log.info("[%s] %s -> OK (queue left: %d)", label, permalink, remaining)
            elif status in (401, 403):
                # No interactive captcha solving on the VPS: let the thread die loudly.
                raise RuntimeError(f"[{label}] captcha/anti-bot {status} on {permalink} — thread stopping")
            elif status == 429:
                log.warning("[%s] rate limited (429), waiting 60s...", label)
                time.sleep(60)
                continue
            elif status == 404:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO staging.raw_kuper_failed (id, status) VALUES (%s, 404) "
                        "ON CONFLICT (id) DO UPDATE "
                        "SET attempts = staging.raw_kuper_failed.attempts + 1, last_attempt = now()",
                        (row_id,),
                    )
                log.warning("[%s] %s -> 404 (marked, won't retry)", label, permalink)
            else:
                log.warning("[%s] %s -> HTTP %d", label, permalink, status)

            time.sleep(random.uniform(3.0, 6.0))

        page.close()
    conn.close()
    log.info("[%s] queue drained, finished (%d processed)", label, processed)


def enrich():
    with open(os.path.join(SCRIPT_DIR, "config.json"), "r", encoding="utf-8") as f:
        config = json.load(f)
    default_store_id = config["store_id"]

    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS staging.raw_kuper_enriched (
                id BIGINT PRIMARY KEY REFERENCES staging.raw_kuper(id),
                data JSONB NOT NULL,
                created_at TIMESTAMP DEFAULT now()
            )
        """)
        # Permanently-missing products (HTTP 404) so re-runs don't keep re-requesting them.
        cur.execute("""
            CREATE TABLE IF NOT EXISTS staging.raw_kuper_failed (
                id BIGINT PRIMARY KEY REFERENCES staging.raw_kuper(id),
                status INT NOT NULL,
                attempts INT NOT NULL DEFAULT 1,
                last_attempt TIMESTAMP DEFAULT now()
            )
        """)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT DISTINCT data->>'store_id' FROM staging.raw_kuper
            WHERE data->>'store_id' IS NOT NULL
        """)
        store_ids = [row[0] for row in cur.fetchall()]
    log.info("Found %d distinct store_ids: %s", len(store_ids), store_ids)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT r.id, r.data->>'permalink', r.data->>'store_id'
            FROM staging.raw_kuper r
            WHERE r.data->>'permalink' IS NOT NULL
              AND r.id NOT IN (SELECT id FROM staging.raw_kuper_enriched)
              AND r.id NOT IN (SELECT id FROM staging.raw_kuper_failed)
        """)
        rows = cur.fetchall()
    log.info("To enrich: %d products", len(rows))

    slug_map, missing = load_slug_map(conn, store_ids)
    log.info("Slugs from dds.kuper_store: %d; missing: %d", len(slug_map), len(missing))
    if missing and CDP_ENDPOINTS:
        slug_map.update(resolve_missing_slugs(CDP_ENDPOINTS[0], missing))
    default_slug = next(iter(slug_map.values()), "metro")
    conn.close()

    if not rows:
        log.info("Nothing to enrich.")
        return

    q = queue.Queue()
    for row in rows:
        q.put(row)

    errors = []

    def run(idx, endpoint):
        try:
            worker(idx, endpoint, q, slug_map, default_slug, default_store_id)
        except Exception:
            # Thread "falls" on captcha/other fatal error; record so the process can
            # exit non-zero (systemd Restart=on-failure / alerting).
            log.exception("[%s] worker crashed", chr(65 + idx))
            errors.append(idx)

    threads = []
    for idx, endpoint in enumerate(CDP_ENDPOINTS):
        t = threading.Thread(target=run, args=(idx, endpoint),
                             name=f"browser-{chr(65 + idx)}")
        t.start()
        threads.append(t)
    for t in threads:
        t.join()

    log.info("Done. Queue remaining: %d", q.qsize())
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    enrich()
