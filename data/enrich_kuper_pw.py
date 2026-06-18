import json
import os
import time
import random
import logging

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


def enrich():
    config_path = os.path.join(SCRIPT_DIR, "config.json")
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    store_id = config["store_id"]

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

    # Get distinct store_ids and map to retailer slugs
    with conn.cursor() as cur:
        cur.execute("""
            SELECT DISTINCT data->>'store_id'
            FROM staging.raw_kuper
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

    # Map store_id -> retailer_slug from dds.kuper_store (avoids per-store API calls).
    with conn.cursor() as cur:
        cur.execute(
            "SELECT store_id::text, retailer_slug FROM dds.kuper_store WHERE store_id = ANY(%s)",
            ([int(s) for s in store_ids if s and s.isdigit()],),
        )
        slug_map = {sid: slug for sid, slug in cur.fetchall()}
    missing_slugs = [s for s in store_ids if s not in slug_map]
    log.info("Slugs from dds.kuper_store: %d; missing (API fallback): %d",
             len(slug_map), len(missing_slugs))

    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp("http://127.0.0.1:9222")
        context = browser.contexts[0]
        page = context.new_page()

        # Resolve any slugs missing from dds.kuper_store via API (fallback only).
        if missing_slugs:
            page.goto(KUPER_BASE, wait_until="domcontentloaded", timeout=30000)
            for sid in missing_slugs:
                store_info = page.evaluate("""
                    async (url) => {
                        const resp = await fetch(url, { credentials: "include" });
                        return await resp.json();
                    }
                """, f"{KUPER_BASE}/api/stores/{sid}")
                slug_map[sid] = store_info["store"]["retailer_slug"]
                log.info("Store %s -> slug: %s (API)", sid, slug_map[sid])

        # Default to first slug for catalog navigation
        default_slug = list(slug_map.values())[0] if slug_map else "metro"
        catalog_url = f"{KUPER_BASE}/{default_slug}?referrer=landing_retailer_list"

        page.goto(catalog_url, wait_until="domcontentloaded", timeout=30000)
        log.info("Connected to Chrome. Page loaded. Starting enrichment...")

        batch_size = random.randint(20, 25)
        batch_count = 0
        next_catalog_visit = random.randint(5, 10)

        for i, (row_id, permalink, row_store_id) in enumerate(rows, 1):
            batch_count += 1
            sid = row_store_id or str(store_id)
            slug = slug_map.get(sid, default_slug)
            cur_catalog_url = f"{KUPER_BASE}/{slug}?referrer=landing_retailer_list"

            # Reset session every ~20-25 requests
            if batch_count >= batch_size:
                log.info("[%d] Session reset: closing tab, waiting 60s...", i)
                page.close()
                time.sleep(60)
                page = context.new_page()
                page.goto(cur_catalog_url, wait_until="load", timeout=30000)
                time.sleep(random.uniform(2.0, 4.0))
                batch_count = 0
                batch_size = random.randint(20, 25)
                next_catalog_visit = i + random.randint(5, 10)
                log.info("[%d] New session started.", i)
            elif i == next_catalog_visit:
                log.info("[%d] Visiting catalog page...", i)
                page.goto(cur_catalog_url, wait_until="load", timeout=30000)
                time.sleep(random.uniform(2.0, 4.0))
                next_catalog_visit = i + random.randint(5, 10)

            params = (
                f"permalink={permalink}"
                f"&store_id={sid}"
                f"&tenant_id=sbermarket"
                f"&is_seo=false"
            )
            url = f"{MULTICARDS_URL}?{params}"

            js = """
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

            for attempt in range(3):
                try:
                    result = page.evaluate(js, url)
                    break
                except Exception as e:
                    if attempt < 2:
                        time.sleep(2)
                    else:
                        log.warning("[%d] JS fetch error for %s: %s", i, permalink, e)
                        result = None
            if result is None:
                continue

            status = result["status"]

            if status == 200:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO staging.raw_kuper_enriched (id, data) VALUES (%s, %s) ON CONFLICT (id) DO NOTHING",
                        (row_id, Json(result["body"])),
                    )
                log.info("[%d/%d] %s -> OK", i, len(rows), permalink)
            elif status in (401, 403):
                log.warning("Captcha/anti-bot (%d). Solve captcha in browser, then press Enter...", status)
                input()
                # Reload the page to restore session after captcha
                page.goto(catalog_url, wait_until="domcontentloaded", timeout=30000)
                # Retry this product
                try:
                    result = page.evaluate(js, url)
                    if result["status"] == 200:
                        with conn.cursor() as cur:
                            cur.execute(
                                "INSERT INTO staging.raw_kuper_enriched (id, data) VALUES (%s, %s) ON CONFLICT (id) DO NOTHING",
                                (row_id, Json(result["body"])),
                            )
                        log.info("[%d/%d] %s -> OK (after captcha)", i, len(rows), permalink)
                except Exception:
                    log.warning("[%d] Retry failed after captcha for %s", i, permalink)
            elif status == 429:
                log.warning("[%d] Rate limited (429). Waiting 60s...", i)
                time.sleep(60)
                continue
            elif status == 404:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO staging.raw_kuper_failed (id, status) VALUES (%s, 404)
                        ON CONFLICT (id) DO UPDATE
                          SET attempts = staging.raw_kuper_failed.attempts + 1,
                              last_attempt = now()
                        """,
                        (row_id,),
                    )
                log.warning("[%d/%d] %s -> 404 not found (marked, won't retry)", i, len(rows), permalink)
            else:
                log.warning("[%d/%d] %s -> HTTP %d", i, len(rows), permalink, status)

            time.sleep(random.uniform(3.0, 6.0))

        page.close()

    conn.close()
    log.info("Done.")


if __name__ == "__main__":
    enrich()
