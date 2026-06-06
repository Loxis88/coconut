import logging
import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG

# (id, name, code, unit)
# code matches the column name in raw_openfood_products (without _100g suffix)
MICRONUTRIENTS = [
    # Vitamins
    (1, "Vitamin A", "vitamin_a", "µg"),
    (2, "Beta-carotene", "beta_carotene", "µg"),
    (3, "Vitamin D", "vitamin_d", "µg"),
    (4, "Vitamin E", "vitamin_e", "mg"),
    (5, "Vitamin K", "vitamin_k", "µg"),
    (6, "Vitamin C", "vitamin_c", "mg"),
    (7, "Vitamin B1 (Thiamine)", "vitamin_b1", "mg"),
    (8, "Vitamin B2 (Riboflavin)", "vitamin_b2", "mg"),
    (9, "Vitamin PP (Niacin)", "vitamin_pp", "mg"),
    (10, "Vitamin B6", "vitamin_b6", "mg"),
    (11, "Vitamin B9 (Folic acid)", "vitamin_b9", "µg"),
    (12, "Folates", "folates", "µg"),
    (13, "Vitamin B12", "vitamin_b12", "µg"),
    (14, "Biotin", "biotin", "µg"),
    (15, "Pantothenic acid", "pantothenic_acid", "mg"),
    (16, "Phylloquinone", "phylloquinone", "µg"),
    (17, "Choline", "choline", "mg"),

    # Minerals
    (18, "Potassium", "potassium", "mg"),
    (19, "Calcium", "calcium", "mg"),
    (20, "Phosphorus", "phosphorus", "mg"),
    (21, "Iron", "iron", "mg"),
    (22, "Magnesium", "magnesium", "mg"),
    (23, "Zinc", "zinc", "mg"),
    (24, "Copper", "copper", "mg"),
    (25, "Manganese", "manganese", "mg"),
    (26, "Selenium", "selenium", "µg"),
    (27, "Chromium", "chromium", "µg"),
    (28, "Molybdenum", "molybdenum", "µg"),
    (29, "Iodine", "iodine", "µg"),
    (30, "Fluoride", "fluoride", "mg"),
    (31, "Chloride", "chloride", "mg"),
    (32, "Sodium", "sodium", "mg"),
    (33, "Silica", "silica", "mg"),
    (34, "Bicarbonate", "bicarbonate", "mg"),
    (35, "Sulphate", "sulphate", "mg"),

    # Other
    (36, "Caffeine", "caffeine", "mg"),
    (37, "Taurine", "taurine", "mg"),
    (38, "Beta-glucan", "beta_glucan", "g"),
    (39, "Inositol", "inositol", "mg"),
    (40, "Carnitine", "carnitine", "mg"),
]


def seed():
    conn = psycopg2.connect(**DB_CONFIG)

    with conn.cursor() as cur:
        execute_values(
            cur,
            """
            INSERT INTO product_catalog.micronutrients (id, name, code, unit)
            VALUES %s
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                code = EXCLUDED.code,
                unit = EXCLUDED.unit
            """,
            MICRONUTRIENTS,
        )

    conn.commit()
    log.info("Seeded %d micronutrients", len(MICRONUTRIENTS))
    conn.close()


if __name__ == "__main__":
    seed()
