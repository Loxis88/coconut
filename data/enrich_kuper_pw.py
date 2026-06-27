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

# One worker thread per CDP endpoint. The browsers run at home and are reached over a
# reverse SSH tunnel on the VPS (e.g. autossh -R 9222 -R 9223 ...). Each home browser is
# launched against its own proxy: --proxy-server -> a LOCAL http_auth_relay.py front that
# injects auth for a commercial HTTP proxy (replaces the old ldns-socks -> hysteria SOCKS5).
# The enricher itself never touches the proxy — it only connects to the CDP endpoints.
#
# Endpoints are loaded dynamically so you can tunnel as many browsers as you have proxies,
# in priority order:
#   1. cdp_endpoints.txt   — one CDP URL per line (explicit override)
#   2. CDP_ENDPOINTS env   — comma-separated CDP URLs (explicit override)
#   3. AUTO from proxies.txt — one browser per proxy at CDP port CDP_PORT_BASE + i.
#      This matches launch_browsers.ps1 (ChromePortBase) and relay_service.py, so the
#      single source of truth is proxies.txt — no manual endpoint list to maintain.
#   4. the DEFAULT_ENDPOINTS list below
DEFAULT_ENDPOINTS = [
    "http://127.0.0.1:9222",
    "http://127.0.0.1:9223",
]
ENDPOINTS_FILE = os.environ.get("ENDPOINTS_FILE", os.path.join(SCRIPT_DIR, "cdp_endpoints.txt"))
PROXIES_FILE = os.environ.get("PROXIES_FILE", os.path.join(SCRIPT_DIR, "proxies.txt"))
CDP_PORT_BASE = int(os.environ.get("CDP_PORT_BASE", "9222"))

# Ramp-up: workers DON'T all start at once (that synchronized burst across one /24 is
# what gets the whole subnet flagged). Worker i waits ~i * RAMP_SECONDS (jittered)
# before connecting, so the browsers come online gradually. 0 disables. This is a
# one-time startup stagger — it does NOT touch the per-request pause.
RAMP_SECONDS = float(os.environ.get("RAMP_SECONDS", "90"))

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


def _count_proxies(path):
    """Number of non-blank, non-comment lines in a proxies file (0 if absent)."""
    if not os.path.exists(path):
        return 0
    n = 0
    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if line and not line.startswith("#"):
                n += 1
    return n


def load_endpoints():
    """CDP endpoints: cdp_endpoints.txt, else CDP_ENDPOINTS env, else AUTO from
    proxies.txt (CDP_PORT_BASE + i per proxy), else defaults."""
    if os.path.exists(ENDPOINTS_FILE):
        eps = []
        with open(ENDPOINTS_FILE, "r", encoding="utf-8-sig") as f:
            for raw in f:
                line = raw.strip()
                if line and not line.startswith("#"):
                    eps.append(line)
        if eps:
            log.info("Loaded %d CDP endpoints from %s", len(eps), ENDPOINTS_FILE)
            return eps
    env = os.environ.get("CDP_ENDPOINTS", "").strip()
    if env:
        eps = [e.strip() for e in env.split(",") if e.strip()]
        log.info("Loaded %d CDP endpoints from CDP_ENDPOINTS env", len(eps))
        return eps
    n = _count_proxies(PROXIES_FILE)
    if n:
        eps = [f"http://127.0.0.1:{CDP_PORT_BASE + i}" for i in range(n)]
        log.info("Auto-derived %d CDP endpoints from %s (CDP port base %d)",
                 n, PROXIES_FILE, CDP_PORT_BASE)
        return eps
    log.info("Using %d default CDP endpoints", len(DEFAULT_ENDPOINTS))
    return list(DEFAULT_ENDPOINTS)


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


def _warmup_goto(page, url, label):
    """Best-effort 'warm-up' navigation for anti-bot realism. NOT fatal: product data
    is fetched via page.evaluate(fetch), not page content, so a navigation timeout must
    not kill the worker (which would crash the whole process)."""
    try:
        page.goto(url, wait_until="domcontentloaded", timeout=45000)
        time.sleep(random.uniform(2.0, 4.0))
    except Exception as e:
        log.warning("[%s] warm-up goto failed (%s); continuing", label, str(e)[:100])


def worker(idx, endpoint, q, slug_map, default_slug, default_store_id):
    """One browser. Pulls products off the shared queue until empty.
    On captcha (401/403) the worker does NOT die: it re-pings the same request every
    90s (refreshing the page so a human can solve the captcha) until it recovers."""
    label = chr(65 + idx) if idx < 26 else f"#{idx}"  # A, B, ... then #26, #27

    # Ramp: stagger this worker's start so the browsers don't appear as a synchronized
    # swarm from one subnet (one-time delay; not the per-request pause).
    if idx > 0 and RAMP_SECONDS > 0:
        delay = idx * RAMP_SECONDS * random.uniform(0.8, 1.2)
        log.info("[%s] ramp: waiting %.0fs before connecting", label, delay)
        time.sleep(delay)

    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True

    with sync_playwright() as p:
        # A dead/missing endpoint (home Chrome not up, stale -R forward) must NOT crash
        # the run — just skip this browser; the other workers share the queue.
        browser = None
        for attempt in range(3):
            try:
                browser = p.chromium.connect_over_cdp(endpoint)
                break
            except Exception as e:
                if attempt < 2:
                    time.sleep(3)
                else:
                    log.warning("[%s] cannot connect to %s (%s) — skipping this browser",
                                label, endpoint, str(e)[:120])
        if browser is None:
            conn.close()
            return
        context = browser.contexts[0]
        page = context.new_page()
        _warmup_goto(page, f"{KUPER_BASE}/{default_slug}?referrer=landing_retailer_list", label)
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
                _warmup_goto(page, cur_catalog_url, label)
                batch_count = 0
                batch_size = random.randint(20, 25)
                next_catalog_visit = processed + random.randint(5, 10)
                log.info("[%s] new session started", label)
            elif processed == next_catalog_visit:
                log.info("[%s] visiting catalog page...", label)
                _warmup_goto(page, cur_catalog_url, label)
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

            # Captcha / anti-bot (401/403): do NOT kill the worker. Re-ping the same
            # request every 90s (refreshing the page so a human can solve the captcha
            # in that browser) until the session recovers, then handle the real result.
            while status in (401, 403):
                log.warning("[%s] captcha/anti-bot %d on %s — solve it in the browser; retry in 90s",
                            label, status, permalink)
                time.sleep(90)
                _warmup_goto(page, cur_catalog_url, label)  # surface/refresh so it can be solved
                try:
                    result = page.evaluate(FETCH_JS, url)
                    status = result["status"]
                except Exception as e:
                    log.warning("[%s] captcha retry fetch error: %s", label, str(e)[:120])

            remaining = q.qsize()

            if status == 200:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO staging.raw_kuper_enriched (id, data) VALUES (%s, %s) "
                        "ON CONFLICT (id) DO NOTHING",
                        (row_id, Json(result["body"])),
                    )
                log.info("[%s] %s -> OK (queue left: %d)", label, permalink, remaining)
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

    endpoints = load_endpoints()

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
    if missing and endpoints:
        slug_map.update(resolve_missing_slugs(endpoints[0], missing))
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
            log.exception("[%s] worker crashed", chr(65 + idx) if idx < 26 else f"#{idx}")
            errors.append(idx)

    log.info("Connecting %d browser worker(s) over CDP", len(endpoints))
    threads = []
    for idx, endpoint in enumerate(endpoints):
        t = threading.Thread(target=run, args=(idx, endpoint),
                             name=f"browser-{idx}")
        t.start()
        threads.append(t)
    for t in threads:
        t.join()

    log.info("Done. Queue remaining: %d", q.qsize())
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    enrich()
