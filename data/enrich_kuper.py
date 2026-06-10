import json
import os
import time
import random
import logging

import psycopg2
from psycopg2.extras import Json
from curl_cffi import requests as curl_requests

from config import DB_CONFIG

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MULTICARDS_URL = "https://kuper.ru/api/v3/multicards"


def load_cookies():
    config_path = os.path.join(SCRIPT_DIR, "config.json")
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    cookies_file = os.path.join(SCRIPT_DIR, config["cookies_file"])
    with open(cookies_file, "r", encoding="utf-8") as f:
        raw_cookies = json.load(f)

    cookies = {}
    for cookie in raw_cookies:
        if cookie.get("domain", "").lstrip(".") == "kuper.ru":
            cookies[cookie["name"]] = cookie["value"]

    return config, cookies


def enrich():
    config, cookies = load_cookies()
    store_id = config["store_id"]
    anonymous_id = cookies.get("external_analytics_anonymous_id", "")

    session = curl_requests.Session(impersonate="chrome")
    session.cookies.update(cookies)

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

    with conn.cursor() as cur:
        cur.execute("""
            SELECT r.id, r.data->>'permalink'
            FROM staging.raw_kuper r
            WHERE r.data->>'permalink' IS NOT NULL
              AND r.id NOT IN (SELECT id FROM staging.raw_kuper_enriched)
        """)
        rows = cur.fetchall()

    log.info("To enrich: %d products", len(rows))

    headers = {
        "accept": "application/json, text/plain, */*",
        "accept-language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
        "client-id": "SbermarketPlatformWeb",
        "client-token": "7ba97b6f4049436dab90c789f946ee2f",
        "referer": "https://kuper.ru/",
        "sbm-forward-tenant": "sbermarket",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "same-origin",
    }

    for i, (row_id, permalink) in enumerate(rows, 1):
        params = {
            "permalink": permalink,
            "store_id": store_id,
            "anonymous_id": anonymous_id,
            "tenant_id": "sbermarket",
            "is_seo": "false",
        }

        backoff = 60
        success = False
        for attempt in range(4):
            try:
                resp = session.get(
                    MULTICARDS_URL, params=params, headers=headers, timeout=30
                )
            except Exception as e:
                log.warning("[%d] Network error for %s: %s", i, permalink, e)
                time.sleep(5)
                continue

            if resp.status_code == 401:
                log.error("Session expired (401). Update cookies.")
                conn.close()
                return

            if resp.status_code == 403:
                log.error("Anti-bot 403. Update cookies and restart.")
                conn.close()
                return

            if resp.status_code == 429:
                log.warning("[%d] Rate limited (429). Waiting %ds...", i, backoff)
                time.sleep(backoff)
                backoff *= 2
                continue

            if resp.status_code == 404:
                log.warning("[%d] Not found: %s", i, permalink)
                success = True
                break

            resp.raise_for_status()

            data = resp.json()
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO staging.raw_kuper_enriched (id, data) VALUES (%s, %s) ON CONFLICT (id) DO NOTHING",
                    (row_id, Json(data)),
                )
            log.info("[%d/%d] %s -> OK", i, len(rows), permalink)
            success = True
            break

        if not success:
            log.warning("[%d] Failed after retries: %s", i, permalink)

        time.sleep(random.uniform(3.0, 6.0))

    conn.close()
    log.info("Done. Enriched products.")


if __name__ == "__main__":
    enrich()
