#!/usr/bin/env python3
"""
Audit Trade Goods that Bagwise would call "Not used for any quest or recipe".

That is the green candidate list for the no_recipe_use rule: Trade Goods (item
class 7) that appear in none of Bagwise's data tables (recipe reagents, quest
items, vendor reagents, class reagents). If a real reagent or quest item is
missing from the data, it lands here and gets a wrong green. Read the report
and look for names that should not be on it. New Forever items are the likely
culprits.

Usage (from the repo root):
    python3 tools/audit_trade_goods.py
    python3 tools/audit_trade_goods.py --cache-dir tools/source
    python3 tools/audit_trade_goods.py --find "Herb Seeds"
    python3 tools/audit_trade_goods.py --selftest        (no network)

The full report is written to trade_goods_audit.txt. --find prints how Bagwise
treats every item whose name contains the text, whatever its item class, so you
can see why a given item gets the dot it does.

Requirements: Python 3.8+, stdlib only.
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_reagent_professions as base  # noqa: E402

TRADE_GOODS_CLASS = 7
REAGENT_CLASS = 5
QUEST_CLASS = 12

TABLES = ["Item", "ItemSparse"]

# Bagwise data tables that make an item "used": file, table name.
DATA_TABLES = [
    ("data/reagent_professions.lua", "ReagentProfessions", "recipe reagent"),
    ("data/quest_items.lua", "QuestItems", "quest item"),
    ("data/vendor_reagents.lua", "VendorReagents", "vendor reagent"),
    ("data/class_reagents.lua", "ClassReagents", "class reagent"),
    ("data/protected_items.lua", "ProtectedItems", "known-use list"),
]

PLACEHOLDER_MARKERS = ("[PH]", "[DEP]", "DEPRECATED", "UNUSED", "(OLD)")

SUBCLASS_NAMES = {
    0: "Trade Goods", 1: "Parts", 2: "Explosives", 3: "Devices",
    4: "Jewelcrafting", 5: "Cloth", 6: "Leather", 7: "Metal & Stone",
    8: "Meat", 9: "Herb", 10: "Elemental", 11: "Other", 12: "Enchanting",
    13: "Materials", 14: "Item Enchantment", 15: "Weapon Enchantment",
}


# ---------------------------------------------------------------------------
# Reading Bagwise's data tables
# ---------------------------------------------------------------------------


def read_lua_table_keys(path, table_name):
    """Item IDs used as [N] keys inside `Bagwise.Data.<table_name> = { ... }`."""
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    start = None
    for i, line in enumerate(lines):
        if re.match(r"\s*Bagwise\.Data\.%s\s*=\s*\{" % re.escape(table_name), line):
            start = i + 1
            break
    if start is None:
        raise ValueError(f"{path}: no table named {table_name}")
    keys = set()
    for line in lines[start:]:
        if line.startswith("}"):
            break
        match = re.match(r"\s*\[(\d+)\]\s*=", line)
        if match:
            keys.add(int(match.group(1)))
    return keys


def load_data_sources(repo_root):
    """{label: set(itemIDs)} for every Bagwise table that marks an item as used."""
    sources = {}
    for rel_path, table, label in DATA_TABLES:
        path = os.path.join(repo_root, rel_path)
        sources[label] = read_lua_table_keys(path, table)
    return sources


# ---------------------------------------------------------------------------
# Reading the game tables
# ---------------------------------------------------------------------------


def to_int(value, default=0):
    return base.int_or(value, default)


def parse_items(item_rows, sparse_rows):
    """Return {itemID: {name, class, subclass, quality, sell}}."""
    items = {}
    for row in item_rows:
        item_id = to_int(base.csv_get(row, "ID"))
        if item_id <= 0:
            continue
        items[item_id] = {
            "class": to_int(base.csv_get(row, "ClassID")),
            "subclass": to_int(base.csv_get(row, "SubclassID")),
            "name": "?", "quality": 0, "sell": 0,
        }
    for row in sparse_rows:
        item_id = to_int(base.csv_get(row, "ID"))
        if item_id not in items:
            continue
        name = base.csv_get(row, "Display_lang", "Display")
        if name:
            items[item_id]["name"] = name
        items[item_id]["quality"] = to_int(base.csv_get(row, "OverallQualityID", "Quality"))
        items[item_id]["sell"] = to_int(base.csv_get(row, "SellPrice"))
    return items


def is_placeholder(name):
    upper = name.upper()
    return any(marker in upper for marker in PLACEHOLDER_MARKERS)


def money(copper):
    gold, rest = divmod(copper, 10000)
    silver, cop = divmod(rest, 100)
    parts = []
    if gold:
        parts.append(f"{gold}g")
    if silver:
        parts.append(f"{silver}s")
    if cop or not parts:
        parts.append(f"{cop}c")
    return " ".join(parts)


# ---------------------------------------------------------------------------
# The audit
# ---------------------------------------------------------------------------


def used_by(item_id, sources):
    return [label for label, ids in sources.items() if item_id in ids]


def audit(items, sources):
    """Trade Goods in none of Bagwise's tables, grouped by subclass."""
    grouped = {}
    for item_id, info in items.items():
        if info["class"] != TRADE_GOODS_CLASS or is_placeholder(info["name"]):
            continue
        if info["name"] == "?" or used_by(item_id, sources):
            continue
        grouped.setdefault(info["subclass"], []).append((item_id, info))
    for rows in grouped.values():
        rows.sort(key=lambda r: r[0])
    return grouped


def class_label(class_id):
    return {TRADE_GOODS_CLASS: "Trade Goods", REAGENT_CLASS: "Reagent",
            QUEST_CLASS: "Quest"}.get(class_id, f"class {class_id}")


def describe_item(item_id, info, sources):
    """One --find line: what the item is and how Bagwise treats it."""
    found = used_by(item_id, sources)
    if info["class"] == REAGENT_CLASS:
        verdict = "protected (Reagent class)"
    elif info["class"] == QUEST_CLASS:
        verdict = "protected (Quest class)"
    elif info["class"] != TRADE_GOODS_CLASS:
        verdict = "not a Trade Goods item, so the no-recipe rule does not apply"
    elif found:
        verdict = "in data: " + ", ".join(found)
    else:
        verdict = "NOT IN ANY DATA TABLE, so it can read as 'Not used for any quest or recipe'"
    return (f"[{item_id}] {info['name']}  ({class_label(info['class'])}, "
            f"subclass {info['subclass']}, sells {money(info['sell'])})\n    {verdict}")


def render_report(grouped):
    total = sum(len(rows) for rows in grouped.values())
    out = [f"Trade Goods in none of Bagwise's data tables: {total}",
           "These can read as green 'Not used for any quest or recipe'.",
           "Look for anything that a recipe or quest actually uses.", ""]
    for subclass in sorted(grouped):
        rows = grouped[subclass]
        out.append(f"== {SUBCLASS_NAMES.get(subclass, f'subclass {subclass}')} ({len(rows)}) ==")
        for item_id, info in rows:
            out.append(f"  [{item_id}] {info['name']}  ({money(info['sell'])})")
        out.append("")
    return "\n".join(out)


def selftest():
    """Check the audit on a tiny made-up dataset. No network."""
    import tempfile
    items = parse_items(
        [{"ID": 1, "ClassID": 7, "SubclassID": 9}, {"ID": 2, "ClassID": 7, "SubclassID": 9},
         {"ID": 3, "ClassID": 7, "SubclassID": 11}, {"ID": 4, "ClassID": 5, "SubclassID": 0},
         {"ID": 5, "ClassID": 7, "SubclassID": 11}],
        [{"ID": 1, "Display_lang": "Known Herb", "SellPrice": "50", "OverallQualityID": "1"},
         {"ID": 2, "Display_lang": "Quest Herb"},
         {"ID": 3, "Display_lang": "Commonplace Herb Seeds", "SellPrice": "12"},
         {"ID": 4, "Display_lang": "Seed Reagent"},
         {"ID": 5, "Display_lang": "[PH] Test [DEP]"}])
    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "data"))
        for rel, table, ids in [("data/reagent_professions.lua", "ReagentProfessions", [1]),
                                ("data/quest_items.lua", "QuestItems", [2]),
                                ("data/vendor_reagents.lua", "VendorReagents", []),
                                ("data/class_reagents.lua", "ClassReagents", []),
                                ("data/protected_items.lua", "ProtectedItems", [])]:
            body = "\n".join(f"  [{i}] = {{ 1 }}, -- x" for i in ids)
            with open(os.path.join(tmp, rel), "w") as fh:
                fh.write(f"Bagwise.Data = Bagwise.Data or {{}}\nBagwise.Data.{table} = {{\n{body}\n}}\n")
        sources = load_data_sources(tmp)
    grouped = audit(items, sources)
    listed = [item_id for rows in grouped.values() for item_id, _ in rows]
    assert listed == [3], listed  # known, quest, reagent-class and placeholder are all out
    assert "NOT IN ANY DATA TABLE" in describe_item(3, items[3], sources)
    assert "protected (Reagent class)" in describe_item(4, items[4], sources)
    print("selftest ok")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--build", help="exact build (default: latest)")
    ap.add_argument("--cache-dir", help="cache downloaded tables here")
    ap.add_argument("--find", help="show how Bagwise treats items whose name contains this text")
    ap.add_argument("--out", default="trade_goods_audit.txt", help="report file")
    ap.add_argument("--selftest", action="store_true", help="check the logic offline")
    args = ap.parse_args()

    if args.selftest:
        selftest()
        return

    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sources = load_data_sources(repo_root)

    build = args.build or base.resolve_build("forever")
    print(f"Build: {build}")
    tables = {name: base.fetch_csv_table(name, build, args.cache_dir) for name in TABLES}
    items = parse_items(tables["Item"], tables["ItemSparse"])

    if args.find:
        needle = args.find.lower()
        hits = [(i, info) for i, info in sorted(items.items()) if needle in info["name"].lower()]
        print(f"\n{len(hits)} item(s) matching '{args.find}':")
        for item_id, info in hits:
            print(describe_item(item_id, info, sources))
        return

    grouped = audit(items, sources)
    report = render_report(grouped)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(report)
    print(report.split("\n")[0])
    print(f"Wrote {args.out}")


if __name__ == "__main__":
    main()
