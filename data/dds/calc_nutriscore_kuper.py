"""
calc_nutriscore_kuper.py

Calculates Nutri-Score for kuper products and writes it to
product_catalog.product.total_rating (0-100 scale, higher = healthier).

Formula: standard Nutri-Score (negative points - positive points),
mapped to 0-100 where score -10 (best) → 100, score +40 (worst) → 0.

Requires nutrition_facts to have at least calories_kcal populated.
Sugar, salt, saturated_fat improve accuracy (run enrich_nutrition.py first).

Usage:
    python dds/calc_nutriscore_kuper.py
"""

import logging
import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

from config import DB_CONFIG

# ── Nutri-Score lookup tables ─────────────────────────────────────────────────

# (threshold, points) — first threshold the value is <= gets that points value
ENERGY_KJ    = [(335,0),(670,1),(1005,2),(1340,3),(1675,4),(2010,5),(2345,6),(2680,7),(3015,8),(3350,9)]
SAT_FAT      = [(1,0),(2,1),(3,2),(4,3),(5,4),(6,5),(7,6),(8,7),(9,8),(10,9)]
SUGARS       = [(4.5,0),(9,1),(13.5,2),(18,3),(22.5,4),(27,5),(31,6),(36,7),(40,8),(45,9)]
SODIUM_MG    = [(90,0),(180,1),(270,2),(360,3),(450,4),(540,5),(630,6),(720,7),(810,8),(900,9)]
FIBER        = [(0.9,0),(1.9,1),(2.8,2),(3.7,3),(4.7,4)]
PROTEIN      = [(1.6,0),(3.2,1),(4.8,2),(6.4,3),(8.0,4)]

SCORE_MIN = -10   # theoretical best  → 100 pts
SCORE_MAX =  40   # theoretical worst → 0 pts


def lookup(value, table: list[tuple]) -> int:
    if value is None:
        return 0
    value = float(value)
    for threshold, pts in table:
        if value <= threshold:
            return pts
    return len(table)  # max points


def nutriscore(
    calories_kcal: float | None,
    saturated_fat_g: float | None,
    sugar_g: float | None,
    salt_g: float | None,
    sodium_mg: float | None,
    fiber_g: float | None,
    protein_g: float | None,
) -> int | None:
    if calories_kcal is None:
        return None

    energy_kj = float(calories_kcal) * 4.184

    # Derive sodium from salt if not available (sodium = salt / 2.5 → mg)
    if sodium_mg is None and salt_g is not None:
        sodium_mg = float(salt_g) * 400.0

    n = (
        lookup(energy_kj, ENERGY_KJ)
        + lookup(saturated_fat_g, SAT_FAT)
        + lookup(sugar_g, SUGARS)
        + lookup(sodium_mg, SODIUM_MG)
    )
    p = lookup(fiber_g, FIBER) + lookup(protein_g, PROTEIN)
    return n - p


def score_to_rating(score: int) -> int:
    clamped = max(SCORE_MIN, min(SCORE_MAX, score))
    return round((SCORE_MAX - clamped) / (SCORE_MAX - SCORE_MIN) * 100)


def run():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        cur.execute("""
            SELECT
                p.id,
                nf.calories_kcal,
                nf.saturated_fat_g,
                nf.sugar_g,
                nf.salt_g,
                nf.sodium_mg,
                nf.fiber_g,
                nf.protein_g
            FROM product_catalog.product p
            JOIN product_catalog.nutrition_facts nf ON nf.product_id = p.id
            WHERE p.source = 'kuper'
        """)
        rows = cur.fetchall()

    log.info("Fetched %d kuper products with nutrition data", len(rows))

    updates = []
    skipped = 0

    for product_id, calories, sat_fat, sugar, salt, sodium, fiber, protein in rows:
        score = nutriscore(calories, sat_fat, sugar, salt, sodium, fiber, protein)
        if score is None:
            skipped += 1
            continue
        rating = score_to_rating(score)
        updates.append((rating, product_id))

    log.info("Calculated ratings: %d products, %d skipped (no calories)", len(updates), skipped)

    if updates:
        with conn.cursor() as cur:
            execute_values(
                cur,
                """
                UPDATE product_catalog.product AS p
                SET total_rating = v.rating
                FROM (VALUES %s) AS v(rating, product_id)
                WHERE p.id = v.product_id::bigint
                """,
                updates,
            )
        conn.commit()
        log.info("Updated total_rating for %d kuper products", len(updates))

    conn.close()


if __name__ == "__main__":
    run()
