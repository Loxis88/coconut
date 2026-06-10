# Data Pipeline: Rosqual + Kuper → DDS

## Разовая настройка (один раз при новой БД)

```bash
python dds/dict_categories.py        # загрузить OFF-таксономию категорий в product_catalog.category
python dds/dds_nutra_dict.py         # загрузить справочник микронутриентов
```

---

## Rosqual

### 1. Сырые данные
```bash
python raw_rosqual.py                # скрейпинг rskrf.ru → staging.raw_rosqual_producs
```

### 2. Маппинг категорий (повторять при изменении категорий)
```bash
python map_rosqual_categories.py          # RSKRF → Kuper категории → rosqual_category_mapping.json
python staging/map_rosqual_off_categories.py  # RSKRF имена → OFF таксономия → rosqual_off_category_mapping.json
```

### 3. Загрузка в DDS
```bash
python dds/dds_rosqual.py            # staging → product_catalog.product + nutrition_facts + barcodes
```

---

## Kuper

### 1. Сырые данные
```bash
python parse_kuper_barcodes.py       # скрейпинг штрихкодов → staging.raw_kuper
python enrich_kuper.py               # обогащение через multicards API → staging.raw_kuper_enriched
# или: python enrich_kuper_pw.py    # то же через Playwright (если нужна браузерная сессия)
```

### 2. Маппинг категорий (повторять при изменении категорий)
```bash
python staging/map_kuper_off_categories.py   # Kuper leaf-категории → OFF таксономия → kuper_off_category_mapping.json
```

### 3. Загрузка в DDS
```bash
python dds/dds_kuper.py              # staging → product_catalog.product + nutrition_facts + barcodes
```

---

## Общие шаги (rosqual + kuper)

### 4. Ингредиенты
```bash
python staging/extract_ingredients.py submit    # отправить батч в OpenAI Batch API
# ... ждать до 24 часов ...
python staging/extract_ingredients.py collect   # скачать результаты → staging.raw_product_ingredients

python staging/normalize_ingredients.py         # нормализовать имена → product_catalog.ingredient_alias
python dds/dds_ingredients.py                   # заполнить product_catalog.product_ingredient
```

### 5. Обогащение нутриентов (сахар, соль, насыщенные жиры)
```bash
python dds/enrich_nutrition.py       # barcode-match + категорийные медианы из OFF → nutrition_facts
```

### 6. Рейтинг купера (Nutri-Score → 0-100)
```bash
python dds/calc_nutriscore_kuper.py  # считает Nutri-Score → product.total_rating
```

### 7. Микронутриенты (только rosqual — нужны PDF-документы)
```bash
python dds/dds_nutra_llm_rosqual.py  # OCR PDF + LLM → product_catalog.product_micronutrients
```

---

## Полный порядок с нуля

```
dict_categories.py
dds_nutra_dict.py

raw_rosqual.py
map_rosqual_categories.py
map_rosqual_off_categories.py
dds_rosqual.py

parse_kuper_barcodes.py
enrich_kuper.py
map_kuper_off_categories.py
dds_kuper.py

extract_ingredients.py submit
  ... ждать ...
extract_ingredients.py collect
normalize_ingredients.py
dds_ingredients.py

enrich_nutrition.py
dds_nutra_llm_rosqual.py
```

---

## Примечания

- `extract_ingredients.py` идемпотентен — уже обработанные продукты пропускает автоматически (по `staging.raw_product_ingredients` + `.ingredients_progress.json`)
- `enrich_nutrition.py` заполняет только NULL-поля, существующие данные не перезаписывает
- Кэш эмбеддингов OFF-категорий `.off_category_embeddings.npz` общий для `map_rosqual_off_categories.py` и `map_kuper_off_categories.py`
- При переобходе (повторный запуск dds_kuper.py / dds_rosqual.py) старые данные удаляются и вставляются заново; после этого нужно перезапустить `dds_ingredients.py` и `enrich_nutrition.py`
