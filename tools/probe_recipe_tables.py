#!/usr/bin/env python3
"""
Print the columns and a few rows of the DB2 tables needed to tell which recipes
a trainer teaches and which have to be found. Run it once, paste the output file
into the chat, and the real builder gets written against the actual columns.

Usage:
    python3 tools/probe_recipe_tables.py
    python3 tools/probe_recipe_tables.py --build 1.15.6.58893

Writes db2_probe.txt next to where you run it. Stdlib only.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_reagent_professions as base  # noqa: E402

TABLES = ["TrainerSpell", "SpellEffect", "ItemEffect", "SpellName", "SkillLineAbility"]
SAMPLE_ROWS = 3


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--build", help="exact build, e.g. 1.15.6.58893 (default: latest Classic Era)")
    args = ap.parse_args()

    build = args.build or base.resolve_build("classic_era")
    print(f"Build: {build}")

    lines = [f"build {build}", ""]
    for table in TABLES:
        try:
            rows = base.fetch_csv_table(table, build)
        except SystemExit:
            lines += [f"== {table}: could not be fetched", ""]
            continue
        lines.append(f"== {table}: {len(rows)} rows")
        lines.append("columns: " + ", ".join(rows[0].keys()) if rows else "no rows")
        for row in rows[:SAMPLE_ROWS]:
            lines.append("  " + str(dict(row)))
        lines.append("")

    with open("db2_probe.txt", "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print("Wrote db2_probe.txt")


if __name__ == "__main__":
    main()
