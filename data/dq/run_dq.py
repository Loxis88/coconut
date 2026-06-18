"""
run_dq.py

Run all data-quality checks and persist results to dq.check_result.

Usage:
    python dq/run_dq.py                 # run everything in rules.yaml
    python dq/run_dq.py --note "nightly"
    python dq/run_dq.py --init          # (re)apply dq schema first, then run

Grafana reads dq.check_result / dq.v_latest_results.
"""

import argparse
import logging
import subprocess
import sys
from pathlib import Path

import psycopg2
import yaml

# Make the data/ dir importable (for config) regardless of how this is invoked,
# matching the dds/ scripts which expect `from config import ...`.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

from config import DB_CONFIG
from dq_lib import DQRunner

HERE = Path(__file__).parent
RULES_PATH = HERE / "rules.yaml"
DDL_PATH = HERE.parent / "database" / "dq_ddl.sql"


def git_sha() -> str | None:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=HERE
        ).decode().strip()
    except Exception:
        return None


def apply_schema(conn):
    log.info("Applying DQ schema from %s", DDL_PATH)
    with conn.cursor() as cur:
        cur.execute(DDL_PATH.read_text(encoding="utf-8"))
    conn.commit()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--note", default=None, help="label stored on the run")
    ap.add_argument("--init", action="store_true", help="apply dq_ddl.sql before running")
    args = ap.parse_args()

    rules = yaml.safe_load(RULES_PATH.read_text(encoding="utf-8"))
    conn = psycopg2.connect(**DB_CONFIG)

    if args.init:
        apply_schema(conn)

    runner = DQRunner(conn)
    runner.start_run(note=args.note, git_sha=git_sha())
    try:
        runner.run_all(rules)
    finally:
        counts = runner.finish_run()

    conn.close()
    # Non-zero exit when any hard invariant failed (useful for CI / cron alerts).
    if counts["fail"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
