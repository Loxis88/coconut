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

EFFICIENCY_WINDOW = 100
EFFICIENCY_THRESHOLD = 0.5
INTER_STORE_SLEEP = 5.0
SWEEP_MIN_SLEEP = 300.0
SOCKS5_PORT = 1080


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

        # Use the standalone hysteria SOCKS5 (run separately, e.g. hysteria-client.service)
        # when USE_PROXY=1. This script no longer launches its own hysteria.
        if os.environ.get("USE_PROXY", "").strip().lower() in ("1", "true", "yes"):
            self.proxies = {
                "https": f"socks5://127.0.0.1:{SOCKS5_PORT}",
                "http": f"socks5://127.0.0.1:{SOCKS5_PORT}",
            }
            log.info("Using SOCKS5 proxy 127.0.0.1:%d (USE_PROXY)", SOCKS5_PORT)
        else:
            self.proxies = {}

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

    def get_recommendations(self, sku: str, store_id: int) -> dict:
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
                        "store_id": store_id,
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
            resp = self.session.post(self.API_URL, json=payload, headers=headers, timeout=30, proxies=self.proxies)

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

        raise Exception(f"Rate limited after 4 retries for SKU {sku} store {store_id}")


class KuperGraphParser:

    def __init__(self, parser: KuperParser):
        self.parser = parser
        self.conn = psycopg2.connect(**DB_CONFIG)
        self.conn.autocommit = True
        self._ensure_tables()

        self.saved_skus: set[str] = set()
        self.visited_skus: set[str] = set()

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
                ALTER TABLE staging.raw_kuper
                ADD COLUMN IF NOT EXISTS visited BOOLEAN DEFAULT FALSE
            """)
            cur.execute("""
                ALTER TABLE dds.kuper_store
                ADD COLUMN IF NOT EXISTS last_crawl_efficiency FLOAT
            """)
            cur.execute("""
                ALTER TABLE dds.kuper_store
                ADD COLUMN IF NOT EXISTS last_crawled_at TIMESTAMP
            """)

    def _load_global_state(self):
        with self.conn.cursor() as cur:
            cur.execute("SELECT sku, visited FROM staging.raw_kuper")
            rows = cur.fetchall()

        self.saved_skus = set()
        self.visited_skus = set()
        for sku, visited in rows:
            self.saved_skus.add(sku)
            if visited:
                self.visited_skus.add(sku)

        log.info("Global state: %d saved, %d visited", len(self.saved_skus), len(self.visited_skus))

    def _load_stores_bfs_order(self) -> list[dict]:
        """
        Возвращает магазины в BFS-порядке по ритейлерам:
        [ритейлер_A магазин_1, ритейлер_B магазин_1, ..., ритейлер_A магазин_2, ...]
        """
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT store_id, retailer_id, retailer_slug, seed_skus
                FROM (
                    SELECT store_id, retailer_id, retailer_slug, seed_skus,
                           ROW_NUMBER() OVER (PARTITION BY retailer_id ORDER BY store_id) AS rn
                    FROM dds.kuper_store
                    WHERE seed_skus IS NOT NULL
                      AND array_length(seed_skus, 1) > 0
                ) ranked
                ORDER BY rn, retailer_id
            """)
            rows = cur.fetchall()

        stores = [
            {
                "store_id": r[0],
                "retailer_id": r[1],
                "retailer_slug": r[2],
                "seed_skus": r[3],
            }
            for r in rows
        ]
        log.info("Loaded %d stores for BFS sweep", len(stores))
        return stores

    def _reset_seed_visited(self, stores: list[dict]):
        """Сбрасывает visited для seed SKU чтобы следующий обход мог заново обойти граф."""
        all_seeds = set()
        for store in stores:
            all_seeds.update(store["seed_skus"] or [])

        if not all_seeds:
            return

        with self.conn.cursor() as cur:
            cur.execute(
                "UPDATE staging.raw_kuper SET visited = FALSE WHERE sku = ANY(%s)",
                (list(all_seeds),),
            )
        for sku in all_seeds:
            self.visited_skus.discard(sku)
        log.info("Reset visited for %d seed SKUs", len(all_seeds))

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

    def save_store_stats(self, store_id: int, efficiency: float):
        with self.conn.cursor() as cur:
            cur.execute("""
                UPDATE dds.kuper_store
                SET last_crawl_efficiency = %s, last_crawled_at = now()
                WHERE store_id = %s
            """, (efficiency, store_id))

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

    def parse_store(self, store: dict) -> float:
        """
        BFS-обход одного магазина. Возвращает итоговую эффективность.
        Останавливается когда efficiency < EFFICIENCY_THRESHOLD.
        """
        store_id = store["store_id"]
        slug = store["retailer_slug"]
        seed_skus = store["seed_skus"] or []

        queue = deque(s for s in seed_skus if s not in self.visited_skus)
        if not queue:
            log.info("[store=%d/%s] Все seeds уже посещены, пропуск", store_id, slug)
            return 1.0

        log.info("[store=%d/%s] BFS start, %d seeds в очереди", store_id, slug, len(queue))

        iteration = 0
        recent_new: list[int] = []
        total_new = 0
        final_efficiency = 1.0

        while queue:
            sku = queue.popleft()

            if sku in self.visited_skus:
                continue

            self.mark_visited(sku)
            iteration += 1

            try:
                data = self.parser.get_recommendations(sku, store_id)
            except SessionExpiredError:
                raise
            except Exception as e:
                log.warning("[store=%d] Ошибка SKU %s: %s", store_id, sku, e)
                continue

            items = self.extract_from_response(data)
            new_count = 0

            for item in items:
                item_sku = item["sku"]
                if item_sku not in self.visited_skus and item_sku not in self.saved_skus:
                    queue.append(item_sku)
                if item_sku not in self.saved_skus:
                    self.save_item(item_sku, item["raw"])
                    new_count += 1

            total_new += new_count
            recent_new.append(new_count)
            if len(recent_new) > EFFICIENCY_WINDOW:
                recent_new.pop(0)

            efficiency = sum(recent_new) / len(recent_new) if recent_new else 0.0
            final_efficiency = efficiency

            log.info(
                "[store=%d/%s] [%d] sku=%s recs=%d new=%d queue=%d eff=%.2f",
                store_id, slug, iteration, sku, len(items), new_count, len(queue), efficiency,
            )

            if len(recent_new) >= EFFICIENCY_WINDOW and efficiency < EFFICIENCY_THRESHOLD:
                log.info(
                    "[store=%d/%s] Efficiency %.2f < %.2f — переход к следующему магазину",
                    store_id, slug, efficiency, EFFICIENCY_THRESHOLD,
                )
                break

            time.sleep(random.uniform(0.5, 1.5))

        self.save_store_stats(store_id, final_efficiency)
        log.info(
            "[store=%d/%s] Завершён. итераций=%d новых=%d eff=%.2f",
            store_id, slug, iteration, total_new, final_efficiency,
        )
        return final_efficiency

    def parse_all_stores(self):
        """Бесконечный BFS-обход всех магазинов всех ритейлеров."""
        while True:
            self._load_global_state()
            stores = self._load_stores_bfs_order()

            if not stores:
                log.warning("Нет магазинов с seed_skus в dds.kuper_store. Ожидание 60s...")
                time.sleep(60)
                continue

            log.info("=== Начало нового обхода: %d магазинов ===", len(stores))
            sweep_start = time.time()

            for store in stores:
                try:
                    self.parse_store(store)
                except SessionExpiredError as e:
                    log.error("Сессия истекла: %s", e)
                    return
                except Exception as e:
                    log.error("Критическая ошибка на store=%d: %s", store["store_id"], e)

                time.sleep(INTER_STORE_SLEEP)

            elapsed = time.time() - sweep_start
            log.info("=== Обход завершён за %.0fs ===", elapsed)

            self._reset_seed_visited(stores)

            sleep_time = max(0.0, SWEEP_MIN_SLEEP - elapsed)
            if sleep_time > 0:
                log.info("Пауза %.0fs перед следующим обходом...", sleep_time)
                time.sleep(sleep_time)


if __name__ == "__main__":
    parser = KuperParser()
    graph = KuperGraphParser(parser)
    graph.parse_all_stores()
