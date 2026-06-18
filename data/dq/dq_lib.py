"""
dq_lib.py

Core data-quality engine. Each check runs as SQL inside Postgres (the data
never leaves the database) and produces one or more CheckResult rows that are
written to dq.check_result.

Dimensions:
  completeness        — mandatory / recommended fields are present
  validity            — numeric values within physically possible bounds
  consistency         — cross-column invariants hold
  uniqueness          — key columns do not repeat
  category_nutrition  — per-category bounds from dq.category_nutrition_range

A check "passes" when pass_rate >= min_pass_rate; otherwise its status is the
rule's severity (warn or fail).
"""

import logging
import re
from dataclasses import dataclass, field
from typing import Any

from psycopg2.extras import Json

log = logging.getLogger(__name__)

# Only identifiers matching this may be interpolated into SQL. Rule files are
# trusted config, but this guards against typos becoming injection.
_IDENT = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_.]*$")


def _ident(name: str) -> str:
    if not _IDENT.match(name):
        raise ValueError(f"Unsafe SQL identifier in rules: {name!r}")
    return name


def _status(pass_rate: float | None, min_pass_rate: float, severity: str) -> str:
    if pass_rate is None:
        return "pass"
    return "pass" if pass_rate >= min_pass_rate else severity


@dataclass
class CheckResult:
    check_name: str
    dimension: str
    severity: str
    threshold: float
    rows_total: int
    rows_failed: int
    table_name: str | None = None
    column_name: str | None = None
    category: str | None = None
    scope: str = "all"
    details: dict | None = None
    status: str = field(init=False)
    pass_rate: float | None = field(init=False)

    def __post_init__(self):
        if self.rows_total and self.rows_total > 0:
            self.pass_rate = (self.rows_total - self.rows_failed) / self.rows_total
        else:
            self.pass_rate = None
        self.status = _status(self.pass_rate, self.threshold, self.severity)


# ── Runner ───────────────────────────────────────────────────────────────


class DQRunner:
    def __init__(self, conn):
        self.conn = conn
        self.run_id: int | None = None
        self.results: list[CheckResult] = []

    # -- run lifecycle --

    def start_run(self, note: str | None = None, git_sha: str | None = None) -> int:
        with self.conn.cursor() as cur:
            cur.execute(
                "INSERT INTO dq.check_run (note, git_sha) VALUES (%s, %s) RETURNING run_id",
                (note, git_sha),
            )
            self.run_id = cur.fetchone()[0]
        self.conn.commit()
        log.info("Started DQ run %d", self.run_id)
        return self.run_id

    def finish_run(self):
        counts = {"pass": 0, "warn": 0, "fail": 0}
        for r in self.results:
            counts[r.status] += 1
        with self.conn.cursor() as cur:
            cur.execute(
                "UPDATE dq.check_run SET finished_at = now(), "
                "n_pass = %s, n_warn = %s, n_fail = %s WHERE run_id = %s",
                (counts["pass"], counts["warn"], counts["fail"], self.run_id),
            )
        self.conn.commit()
        log.info(
            "Run %d finished: %d pass, %d warn, %d fail",
            self.run_id, counts["pass"], counts["warn"], counts["fail"],
        )
        return counts

    def _record(self, r: CheckResult):
        self.results.append(r)
        with self.conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO dq.check_result
                    (run_id, check_name, dimension, table_name, column_name,
                     category, scope, rows_total, rows_failed, pass_rate,
                     threshold, severity, status, details)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                """,
                (
                    self.run_id, r.check_name, r.dimension, r.table_name,
                    r.column_name, r.category, r.scope, r.rows_total,
                    r.rows_failed, r.pass_rate, r.threshold, r.severity,
                    r.status, Json(r.details) if r.details is not None else None,
                ),
            )
        self.conn.commit()
        flag = {"pass": "  ok", "warn": "WARN", "fail": "FAIL"}[r.status]
        pr = "n/a" if r.pass_rate is None else f"{r.pass_rate:6.2%}"
        log.info(
            "[%s] %-48s pass=%s  failed=%d/%d",
            flag, r.check_name, pr, r.rows_failed, r.rows_total,
        )

    # -- per-source scoping --

    @staticmethod
    def _scope(table: str, source: str | None) -> tuple[str, str, list, str]:
        """Resolve an optional per-source scope for a table.
        Returns (from_sql, source_predicate, params, col_prefix). Nutrition rows
        are joined back to product to reach `source`; product is filtered
        directly. Bare nutrient column names stay unambiguous under the join."""
        t = table.split(".")[-1]
        if source is None:
            return table, "", [], ""
        if t == "product":
            return table, "source = %s", [source], ""
        if t == "nutrition_facts":
            from_sql = (
                f"{table} nf "
                f"JOIN product_catalog.product p ON p.id = nf.product_id"
            )
            return from_sql, "p.source = %s", [source], "nf."
        raise ValueError(f"per-source scope not supported for {table}")

    # -- check primitives --

    def completeness(self, rule: dict, source: str | None = None):
        table = _ident(rule["table"])
        col = _ident(rule["column"])
        short = table.split(".")[-1]
        from_sql, pred, params, cp = self._scope(table, source)
        c = f"{cp}{col}"
        where = f"WHERE {pred}" if pred else ""
        with self.conn.cursor() as cur:
            cur.execute(
                f"SELECT count(*), "
                f"count(*) FILTER (WHERE {c} IS NULL OR ({c})::text = '') "
                f"FROM {from_sql} {where}",
                params,
            )
            total, failed = cur.fetchone()
        self._record(CheckResult(
            check_name=f"completeness.{short}.{col}",
            dimension="completeness",
            severity=rule["severity"],
            threshold=rule["min_pass_rate"],
            rows_total=total, rows_failed=failed,
            table_name=table, column_name=col,
            scope=source or "all",
        ))

    def validity(self, rule: dict, source: str | None = None):
        table = _ident(rule["table"])
        col = _ident(rule["column"])
        short = table.split(".")[-1]
        lo, hi = rule["min"], rule["max"]
        from_sql, pred, params, cp = self._scope(table, source)
        c = f"{cp}{col}"
        where = f"WHERE {pred}" if pred else ""
        with self.conn.cursor() as cur:
            cur.execute(
                f"SELECT count({c}), "
                f"count(*) FILTER (WHERE {c} < %s OR {c} > %s) "
                f"FROM {from_sql} {where}",
                [lo, hi] + params,  # FILTER placeholders precede the WHERE source predicate
            )
            total, failed = cur.fetchone()
        self._record(CheckResult(
            check_name=f"validity.{short}.{col}",
            dimension="validity",
            severity=rule["severity"],
            threshold=rule["min_pass_rate"],
            rows_total=total, rows_failed=failed,
            table_name=table, column_name=col,
            scope=source or "all",
            details={"min": lo, "max": hi},
        ))

    def consistency(self, rule: dict, source: str | None = None):
        table = _ident(rule["table"])
        short = table.split(".")[-1]
        violation = rule["violation"]
        denom = rule.get("denom")
        from_sql, pred, params, _ = self._scope(table, source)
        clauses = [p for p in (pred, denom) if p]
        where = f"WHERE {' AND '.join(clauses)}" if clauses else ""
        with self.conn.cursor() as cur:
            cur.execute(
                f"SELECT count(*), count(*) FILTER (WHERE {violation}) "
                f"FROM {from_sql} {where}",
                params,
            )
            total, failed = cur.fetchone()
        self._record(CheckResult(
            check_name=f"consistency.{rule['name']}",
            dimension="consistency",
            severity=rule["severity"],
            threshold=rule["min_pass_rate"],
            rows_total=total, rows_failed=failed,
            table_name=table,
            scope=source or "all",
            details={"violation": violation, "denom": denom},
        ))

    def nutrition_presence(self, source: str | None = None,
                           severity: str = "warn", min_pass_rate: float = 0.6):
        """Share of products that have a nutrition_facts row at all."""
        where = "WHERE p.source = %s" if source else ""
        params = [source] if source else []
        with self.conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT count(DISTINCT p.id),
                       count(DISTINCT p.id) FILTER (WHERE nf.product_id IS NULL)
                FROM product_catalog.product p
                LEFT JOIN product_catalog.nutrition_facts nf
                       ON nf.product_id = p.id
                {where}
                """,
                params,
            )
            total, failed = cur.fetchone()
        self._record(CheckResult(
            check_name="completeness.product.has_nutrition",
            dimension="completeness",
            severity=severity, threshold=min_pass_rate,
            rows_total=total, rows_failed=failed,
            table_name="product_catalog.product",
            column_name="has_nutrition",
            scope=source or "all",
        ))

    def uniqueness(self, rule: dict):
        table = _ident(rule["table"])
        short = table.split(".")[-1]
        keys = [_ident(k) for k in rule["key"]]
        key_sql = ", ".join(keys)
        with self.conn.cursor() as cur:
            cur.execute(
                f"SELECT count(*), count(*) - count(DISTINCT ({key_sql})) "
                f"FROM {table} WHERE {' AND '.join(f'{k} IS NOT NULL' for k in keys)}"
            )
            total, failed = cur.fetchone()
        self._record(CheckResult(
            check_name=f"uniqueness.{rule['name']}",
            dimension="uniqueness",
            severity=rule["severity"],
            threshold=rule["min_pass_rate"],
            rows_total=total, rows_failed=failed,
            table_name=table,
            details={"key": keys},
        ))

    def category_nutrition(self, cfg: dict, source: str | None = None):
        """Bound-check each nutrient against per-category ranges in
        dq.category_nutrition_range. Emits one result row per nutrient; the
        worst-offending categories go into `details`. When `source` is given,
        restricts to that product source and records scope=<source>."""
        severity = cfg["severity"]
        threshold = cfg["min_pass_rate"]
        src_pred = "AND p.source = %s" if source else ""
        for nutrient in cfg["nutrients"]:
            col = _ident(nutrient)
            base_params = [nutrient] + ([source] if source else [])
            with self.conn.cursor() as cur:
                cur.execute(
                    f"""
                    SELECT count(*),
                           count(*) FILTER (
                             WHERE nf.{col} < r.min_per_100g
                                OR nf.{col} > r.max_per_100g)
                    FROM dq.category_nutrition_range r
                    JOIN product_catalog.category c   ON c.name = r.category_name
                    JOIN product_catalog.product  p   ON p.category_id = c.id
                    JOIN product_catalog.nutrition_facts nf ON nf.product_id = p.id
                    WHERE r.nutrient = %s AND nf.{col} IS NOT NULL {src_pred}
                    """,
                    base_params,
                )
                total, failed = cur.fetchone()

                offenders = []
                if failed:
                    cur.execute(
                        f"""
                        SELECT r.category_name,
                               count(*) FILTER (
                                 WHERE nf.{col} < r.min_per_100g
                                    OR nf.{col} > r.max_per_100g) AS bad,
                               min(r.min_per_100g), max(r.max_per_100g)
                        FROM dq.category_nutrition_range r
                        JOIN product_catalog.category c ON c.name = r.category_name
                        JOIN product_catalog.product p ON p.category_id = c.id
                        JOIN product_catalog.nutrition_facts nf ON nf.product_id = p.id
                        WHERE r.nutrient = %s AND nf.{col} IS NOT NULL {src_pred}
                        GROUP BY r.category_name
                        HAVING count(*) FILTER (
                                 WHERE nf.{col} < r.min_per_100g
                                    OR nf.{col} > r.max_per_100g) > 0
                        ORDER BY bad DESC
                        LIMIT 10
                        """,
                        base_params,
                    )
                    offenders = [
                        {"category": c, "violations": b, "min": float(mn), "max": float(mx)}
                        for c, b, mn, mx in cur.fetchall()
                    ]

            self._record(CheckResult(
                check_name=f"category_nutrition.{nutrient}",
                dimension="category_nutrition",
                severity=severity,
                threshold=threshold,
                rows_total=total, rows_failed=failed,
                table_name="product_catalog.nutrition_facts",
                column_name=nutrient,
                scope=source or "all",
                details={"top_offenders": offenders} if offenders else None,
            ))

    def list_sources(self) -> list[str]:
        with self.conn.cursor() as cur:
            cur.execute(
                "SELECT source FROM product_catalog.product "
                "WHERE source IS NOT NULL AND source <> '' "
                "GROUP BY source ORDER BY count(*) DESC"
            )
            return [r[0] for r in cur.fetchall()]

    # Tables that carry (or can be joined to) a product source.
    SOURCE_TABLES = {"product", "nutrition_facts"}

    def by_source(self, rules: dict):
        """Re-run every product- and nutrition-level check once per product
        source so the same metrics can be compared across kuper / openfood /
        rosqual / etc. Results are stored with scope = <source>. Reuses the
        global rule lists, so per-source coverage matches the global checks."""
        sources = self.list_sources()
        log.info("Per-source profiling across %d sources: %s",
                 len(sources), ", ".join(sources))

        def supported(rule: dict) -> bool:
            return rule["table"].split(".")[-1] in self.SOURCE_TABLES

        for src in sources:
            for rule in rules.get("completeness", []):
                if supported(rule):
                    self.completeness(rule, source=src)
            for rule in rules.get("validity", []):
                if supported(rule):
                    self.validity(rule, source=src)
            for rule in rules.get("consistency", []):
                if supported(rule):
                    self.consistency(rule, source=src)
            self.nutrition_presence(source=src)
            if "category_nutrition" in rules:
                self.category_nutrition(rules["category_nutrition"], source=src)

    # -- orchestration --

    def run_all(self, rules: dict[str, Any]):
        for rule in rules.get("completeness", []):
            self.completeness(rule)
        for rule in rules.get("validity", []):
            self.validity(rule)
        for rule in rules.get("consistency", []):
            self.consistency(rule)
        for rule in rules.get("uniqueness", []):
            self.uniqueness(rule)
        if "category_nutrition" in rules:
            self.category_nutrition(rules["category_nutrition"])
        # Global nutrition-presence metric (also broken out per source below).
        self.nutrition_presence()
        if rules.get("by_source", {}).get("enabled"):
            self.by_source(rules)
