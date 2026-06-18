# Data Quality (`data/dq`)

Catalog data-quality checks for the `product_catalog` schema. Each check runs as
SQL **inside Postgres** (data never leaves the DB) and writes one row per check to
`dq.check_result`, which Grafana reads.

## Why not Great Expectations?

GE was deliberately not used:

- It wants its own Data Context / Checkpoint / metadata-store ceremony and does
  **not** naturally write tidy result rows into *our* Postgres for Grafana — the
  one thing we actually need.
- The rest of `data/` is plain `psycopg2` scripts; a ~250-line runner matches the
  codebase and runs checks as set-based SQL over 500k+ rows in seconds.
- The hardest requirement — per-category nutrition bounds across ~9k categories —
  is custom logic GE doesn't provide anyway.

## Layout

| File | Role |
|---|---|
| `../database/dq_ddl.sql` | Creates the `dq` schema: `category_nutrition_range`, `check_run`, `check_result`, `v_latest_results` view |
| `rules.yaml` | Declarative non-LLM rules (completeness, validity, consistency, uniqueness) |
| `dq_lib.py` | Engine — check primitives + `DQRunner`, persists results |
| `run_dq.py` | Entrypoint — runs all checks, exits non-zero if any hard invariant fails |
| `build_category_ranges.py` | LLM script — fills `dq.category_nutrition_range` |
| `grafana/dashboard.json` | Importable Grafana dashboard |

## Dimensions

- **completeness** — mandatory/recommended fields are non-null & non-empty.
  Mandatory fields are a business judgement declared in `rules.yaml` (the DDL has
  almost no `NOT NULL`). `fail` = hard invariant; `warn` = coverage target.
- **validity** — numeric values within physically possible per-100g bounds
  (e.g. `protein_g ∈ [0,100]`). Nulls ignored here.
- **consistency** — cross-column invariants (macro sum ≤ 105, sugar ≤ carbs,
  Atwater calories, salt↔sodium).
- **uniqueness** — key columns don't repeat (`(source, source_id)`, `barcode`).
- **category_nutrition** — per-category bounds from the LLM dict. A value of `0`
  or `NULL` is **never** a violation (so "tea has no protein" is fine); only an
  implausible amount outside `[min, max]` is flagged.

Every result also carries a **`scope`** column. Global checks use `scope='all'`;
the `by_source` block in `rules.yaml` re-runs a configured subset of
product/nutrition checks once per product source (`kuper`, `openfood`,
`rosqual`, …) and stores them with `scope=<source>`, so quality can be compared
across sources (e.g. openfood completeness lags kuper). Dashboard panels filter
`scope='all'` for global views and pivot on `scope` for the per-source section.

A check is `pass` when `pass_rate >= min_pass_rate`, else its `severity`
(`warn`/`fail`).

## Usage

```powershell
# One-time / idempotent: create the dq schema
python dq/run_dq.py --init --note "init"

# Build the per-category range dictionary (LLM). Resumable; skips covered cats.
python dq/build_category_ranges.py --limit 16 --batch-size 8   # try small first
python dq/build_category_ranges.py --limit 500                 # top-500 by product count
python dq/build_category_ranges.py                             # all remaining
python dq/build_category_ranges.py --refresh                   # regenerate existing

# Run the checks (e.g. nightly via cron). Non-zero exit if any `fail`.
python dq/run_dq.py --note "nightly"
```

`build_category_ranges.py` notes: the model is asked for per-100g `[min, max]` per
nutrient per category; it tends to drop the `en:` prefix and shorten nutrient
names, so results are matched back by a normalized key and stored under the
**original** category name. Keep `--batch-size` small (~8) — large batches stall
`gpt-4o-mini`.

## Grafana

Import `grafana/dashboard.json`. It targets **Grafana 6.7** (schemaVersion 22,
matching `deploy/grafana-dashboard.json`) and uses only panel types that version
ships: `singlestat`, classic `table` (threshold-coloured cells), and `graph`.
Panels reference the datasource by name (`"PostgreSQL"`), so it binds with no
datasource prompt — just point that datasource at the DB holding the `dq` schema.
Panels read `dq.check_result` / `dq.v_latest_results`; the time column is
`checked_at`. If your datasource is named differently, find-and-replace
`"PostgreSQL"`.

> Note: `barchart`/`timeseries`/new-`table` cell styling are Grafana ≥7.x panels
> and will NOT load on 6.7. If/when Grafana is upgraded, the bars/tables can be
> modernised. See [[grafana-version-6-7]].

Useful queries:

```sql
-- latest status board
SELECT dimension, check_name, status, pass_rate, rows_failed, rows_total
FROM dq.v_latest_results ORDER BY status DESC, pass_rate;

-- pass_rate trend for one check
SELECT checked_at AS time, pass_rate
FROM dq.check_result WHERE check_name = $check ORDER BY 1;

-- worst category offenders for a nutrient (latest run)
SELECT jsonb_array_elements(details->'top_offenders')
FROM dq.v_latest_results WHERE check_name = 'category_nutrition.protein_g';
```
