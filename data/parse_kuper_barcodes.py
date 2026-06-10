import json
import os
import time
import random
import logging
from collections import deque

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


class SessionExpiredError(Exception):
    pass


class KuperParser:
    API_URL = "https://kuper.ru/api/v2/simple-recs/v4/card/"

    def __init__(self, config_path: str = None):
        if config_path is None:
            config_path = os.path.join(SCRIPT_DIR, "config.json")

        with open(config_path, "r", encoding="utf-8") as f:
            self.config = json.load(f)

        cookies_file = os.path.join(SCRIPT_DIR, self.config["cookies_file"])
        with open(cookies_file, "r", encoding="utf-8") as f:
            raw_cookies = json.load(f)

        if not isinstance(raw_cookies, list):
            raise ValueError("cookies.json must be a JSON array of cookie objects")

        self.cookies = self._cookies_to_dict(raw_cookies)
        self.csrf_token = self.config["csrf_token"]
        self.store_id = self.config["store_id"]

        self.session = curl_requests.Session(impersonate="chrome124")
        self.session.cookies.update(self.cookies)

        self.anonymous_id = self.cookies.get("external_analytics_anonymous_id", "")

    @staticmethod
    def _cookies_to_dict(cookies: list, domain_filter: str = "kuper.ru") -> dict:
        result = {}
        for cookie in cookies:
            if cookie.get("domain", "").lstrip(".") == domain_filter:
                result[cookie["name"]] = cookie["value"]
        return result

    def get_recommendations(self, sku: str) -> dict:
        headers = {
            "accept": "application/json, text/plain, */*",
            "accept-language": "ru-RU,ru;q=0.9,en-US;q=0.8",
            "content-type": "application/json",
            "client-id": "SbermarketPlatformWeb",
            "client-token": "7ba97b6f4049436dab90c789f946ee2f",
            "x-csrf-token": self.csrf_token,
            "origin": "https://kuper.ru",
            "referer": "https://kuper.ru/",
            "sbm-forward-tenant": "sbermarket",
        }

        payload = {
            "context": {
                "device": {"platform": "WEB"},
                "user": {"geo": {}, "ext": {"anonymous_id": self.anonymous_id}},
                "site": {
                    "domain": "",
                    "ext": {
                        "store_id": self.store_id,
                        "tenant_id": 0,
                        "tenant_name": "sbermarket",
                        "skus": [sku],
                    },
                },
            },
            "ext": {"place": "product_card"},
        }

        backoff = 60
        for attempt in range(4):
            resp = self.session.post(self.API_URL, json=payload, headers=headers, timeout=30)

            if resp.status_code in (401, 403):
                raise SessionExpiredError(
                    "Куки протухли. Обнови куки и csrf_token в config.json и перезапусти."
                )

            if resp.status_code == 429:
                log.warning("Rate limited (429). Waiting %ds...", backoff)
                time.sleep(backoff)
                backoff *= 2
                continue

            resp.raise_for_status()
            return resp.json()

        raise Exception(f"Rate limited after 4 retries for SKU {sku}")


class KuperGraphParser:

    def __init__(self, parser: KuperParser):
        self.parser = parser
        self.conn = psycopg2.connect(**DB_CONFIG)
        self.conn.autocommit = True
        self._ensure_tables()

    def _ensure_tables(self):
        with self.conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS staging.raw_kuper (
                    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                    sku TEXT NOT NULL UNIQUE,
                    data JSONB NOT NULL,
                    visited BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT now()
                )
            """)
            cur.execute("""
                ALTER TABLE staging.raw_kuper ADD COLUMN IF NOT EXISTS visited BOOLEAN DEFAULT FALSE
            """)

    def load_state(self):
        with self.conn.cursor() as cur:
            cur.execute("SELECT sku, visited FROM staging.raw_kuper")
            rows = cur.fetchall()

        self.saved_skus = set()
        self.visited_skus = set()
        for sku, visited in rows:
            self.saved_skus.add(sku)
            if visited:
                self.visited_skus.add(sku)

        seed_skus = self.parser.config.get("seed_skus", [])
        candidates = (self.saved_skus | set(seed_skus)) - self.visited_skus
        self.sku_queue = deque(candidates)

        log.info("DB state: %d visited, %d saved, %d in queue",
                 len(self.visited_skus), len(self.saved_skus), len(self.sku_queue))

    def mark_visited(self, sku: str):
        with self.conn.cursor() as cur:
            cur.execute(
                "UPDATE staging.raw_kuper SET visited = TRUE WHERE sku = %s",
                (sku,),
            )
        self.visited_skus.add(sku)

    def save_item(self, sku: str, data: dict):
        if sku not in self.saved_skus:
            with self.conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO staging.raw_kuper (sku, data) VALUES (%s, %s) ON CONFLICT (sku) DO NOTHING",
                    (sku, Json(data)),
                )
            self.saved_skus.add(sku)

    @staticmethod
    def extract_from_response(data: dict) -> list[dict]:
        items = []
        for block in data.get("blocks", []):
            for media in block.get("media", []):
                sku = media.get("sku")
                if sku:
                    items.append({
                        "sku": str(sku),
                        "eans": media.get("eans", []),
                        "name": media.get("name", ""),
                        "raw": media,
                    })
        return items

    def parse_from_seeds(self):
        self.load_state()

        iteration = 0
        recent_new = []
        total_new_products = 0

        try:
            while self.sku_queue:
                sku = self.sku_queue.popleft()

                if sku in self.visited_skus:
                    continue

                self.mark_visited(sku)
                iteration += 1

                try:
                    data = self.parser.get_recommendations(sku)
                except SessionExpiredError as e:
                    log.error(str(e))
                    return
                except Exception as e:
                    log.warning("[%d] Failed SKU %s: %s", iteration, sku, e)
                    continue

                items = self.extract_from_response(data)
                new_products = 0

                for item in items:
                    if item["sku"] not in self.visited_skus and item["sku"] not in self.saved_skus:
                        self.sku_queue.append(item["sku"])

                    if item["sku"] not in self.saved_skus:
                        self.save_item(item["sku"], item["raw"])
                        new_products += 1

                total_new_products += new_products
                recent_new.append(new_products)
                if len(recent_new) > 100:
                    recent_new.pop(0)

                efficiency = sum(recent_new) / len(recent_new) if recent_new else 0

                log.info("[%d] SKU %s -> %d recs, %d new | queue: %d | saved: %d | eff: %.1f",
                         iteration, sku, len(items), new_products,
                         len(self.sku_queue), len(self.saved_skus), efficiency)

                if efficiency < 0.5 and len(recent_new) >= 100:
                    log.warning("Efficiency below 0.5 — graph saturated. "
                                "Add new seed SKUs from other categories.")

                time.sleep(random.uniform(0.5, 1.5))

        except KeyboardInterrupt:
            log.info("Interrupted by user")

        self.conn.close()
        log.info("Done. %d iterations, %d new products saved", iteration, total_new_products)


if __name__ == "__main__":
    parser = KuperParser()
    graph = KuperGraphParser(parser)
    graph.parse_from_seeds()
