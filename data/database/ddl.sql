CREATE SCHEMA IF NOT EXISTS product_catalog;

DROP TABLE IF EXISTS product_catalog.health_risks;
DROP TABLE IF EXISTS product_catalog.product_micronutrients;
DROP TABLE IF EXISTS product_catalog.micronutrients;
DROP TABLE IF EXISTS product_catalog.nutrition_facts;
DROP TABLE IF EXISTS product_catalog.product_barcode;
DROP TABLE IF EXISTS product_catalog.product_documents;
DROP TABLE IF EXISTS product_catalog.product;
DROP TABLE IF EXISTS product_catalog.category_parent;
DROP TABLE IF EXISTS product_catalog.category;

CREATE TABLE product_catalog.category (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE,
    name_ru TEXT
);

CREATE TABLE product_catalog.category_parent (
    category_id BIGINT NOT NULL REFERENCES product_catalog.category(id),
    parent_id BIGINT NOT NULL REFERENCES product_catalog.category(id),
    PRIMARY KEY (category_id, parent_id)
);

CREATE TABLE product_catalog.product (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id TEXT,
    source TEXT,
    category_id BIGINT,
    total_rating NUMERIC,
    brand TEXT,
    image_link TEXT,
    name TEXT,
    description TEXT,
    ingredients TEXT
);

CREATE TABLE product_catalog.product_barcode (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    barcode TEXT NOT NULL
);

CREATE TABLE product_catalog.product_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT,
    doc_link TEXT
);

CREATE TABLE product_catalog.nutrition_facts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT,
    serving_size_g NUMERIC,
    calories_kcal NUMERIC,
    protein_g NUMERIC,
    fat_g NUMERIC,
    saturated_fat_g NUMERIC,
    carbs_g NUMERIC,
    fiber_g NUMERIC,
    sugar_g NUMERIC,
    salt_g NUMERIC,
    sodium_mg NUMERIC
);

CREATE TABLE product_catalog.micronutrients (
    id BIGINT PRIMARY KEY,
    name TEXT,
    code TEXT,
    unit TEXT
);

CREATE TABLE product_catalog.product_micronutrients (
    product_id BIGINT,
    nutrient_id BIGINT,
    amount NUMERIC
);

CREATE TABLE product_catalog.health_risks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT,
    fact TEXT
);

CREATE TABLE product_catalog.ingredient (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE,
    name_ru TEXT,
    description TEXT,
    e_number TEXT,
    category TEXT,
    is_allergen BOOLEAN DEFAULT false
);

CREATE TABLE product_catalog.product_ingredient (
    product_id BIGINT NOT NULL,
    ingredient_id BIGINT,
    original_name TEXT,
    qty NUMERIC,
    unit TEXT,
    qualifier TEXT
);

-- Indexes on product lookup columns
CREATE INDEX idx_product_source_id ON product_catalog.product (source_id);
CREATE INDEX idx_product_source ON product_catalog.product (source);
CREATE INDEX idx_product_source_source_id ON product_catalog.product (source, source_id);

-- Indexes on barcode table
CREATE INDEX idx_product_barcode_product_id ON product_catalog.product_barcode (product_id);
CREATE INDEX idx_product_barcode_barcode ON product_catalog.product_barcode (barcode);

-- Indexes on FK columns (not auto-created in PostgreSQL)
CREATE INDEX idx_product_documents_product_id ON product_catalog.product_documents (product_id);
CREATE INDEX idx_nutrition_facts_product_id ON product_catalog.nutrition_facts (product_id);
CREATE INDEX idx_product_micronutrients_product_id ON product_catalog.product_micronutrients (product_id);
CREATE INDEX idx_product_micronutrients_nutrient_id ON product_catalog.product_micronutrients (nutrient_id);
CREATE INDEX idx_health_risks_product_id ON product_catalog.health_risks (product_id);

-- Indexes on ingredient tables
CREATE INDEX idx_ingredient_name ON product_catalog.ingredient (name);
CREATE INDEX idx_product_ingredient_product_id ON product_catalog.product_ingredient (product_id);
CREATE INDEX idx_product_ingredient_ingredient_id ON product_catalog.product_ingredient (ingredient_id);
