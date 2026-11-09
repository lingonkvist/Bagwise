#!/usr/bin/env python3
"""
Build data/mana_consumables.lua from wago.tools DB2 tables.

It lists consumables that restore mana and nothing else, so Rejuvenation-style
items that also heal are left out. Bagwise uses it to hint that classes without
mana can sell mana potions. Re-run it when a new Forever build ships.

Usage:
    python3 tools/build_mana_consumables.py
    python3 tools/build_mana_consumables.py --build 1.15.9.70576
    python3 tools/build_mana_consumables.py --cache-dir tools/source
    python3 tools/build_mana_consumables.py --selftest        (no network)

If a table's columns are not what this expects, the script says which ones it
could not find and lists what the table has, then stops without writing.

Requirements: Python 3.8+, stdlib only.
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_reagent_professions as base  # noqa: E402

# Spell effect and aura IDs (stable across builds).
EFFECT_APPLY_AURA = 6
EFFECT_HEAL = 10
EFFECT_ENERGIZE = 30
EFFECT_HEAL_MAX_HEALTH = 67
EFFECT_HEAL_PCT = 136
EFFECT_ENERGIZE_PCT = 137
AURA_PERIODIC_HEAL = 8
AURA_PERIODIC_ENERGIZE = 24
POWER_MANA = 0
CONSUMABLE_CLASS = 0

MANA_EFFECTS = {EFFECT_ENERGIZE, EFFECT_ENERGIZE_PCT}
HEAL_EFFECTS = {EFFECT_HEAL, EFFECT_HEAL_MAX_HEALTH, EFFECT_HEAL_PCT}

TABLES = ["SpellEffect", "ItemEffect", "Item", "ItemSparse"]
OPTIONAL_TABLES = ["ItemXItemEffect"]  # needed when ItemEffect has no item column


# ---------------------------------------------------------------------------
# Tolerant column access and parsers
# ---------------------------------------------------------------------------


class MissingColumns(Exception):
    pass


# ---------------------------------------------------------------------------
# Tolerant column access
# ---------------------------------------------------------------------------


def norm(name):
    """'EffectMiscValue[0]', 'EffectMiscValue_0' and 'effectmiscvalue0' match."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


def find_column(rows, table, *candidates, required=True):
    """The real column name for the first candidate present, or None."""
    if not rows:
        raise MissingColumns(f"{table}: table is empty")
    wanted = [norm(c) for c in candidates]
    by_norm = {norm(key): key for key in rows[0].keys()}
    for want in wanted:
        if want in by_norm:
            return by_norm[want]
    if required:
        raise MissingColumns(
            f"{table}: none of {list(candidates)} found. "
            f"Columns present: {list(rows[0].keys())}")
    return None


def to_int(value, default=0):
    return base.int_or(value, default) if hasattr(base, "int_or") else int(value or default)


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------


def parse_spell_effects(rows):
    """Return {spellID: [{"effect", "aura", "misc", "trigger"}, ...]}."""
    spell = find_column(rows, "SpellEffect", "SpellID")
    effect = find_column(rows, "SpellEffect", "Effect")
    aura = find_column(rows, "SpellEffect", "EffectAura", required=False)
    misc = find_column(rows, "SpellEffect", "EffectMiscValue0", "EffectMiscValue1",
                       "EffectMiscValue", required=False)
    trigger = find_column(rows, "SpellEffect", "EffectTriggerSpell")
    difficulty = find_column(rows, "SpellEffect", "DifficultyID", required=False)

    result = {}
    for row in rows:
        if difficulty and to_int(row.get(difficulty)) != 0:
            continue
        spell_id = to_int(row.get(spell))
        if spell_id <= 0:
            continue
        result.setdefault(spell_id, []).append({
            "effect": to_int(row.get(effect)),
            "aura": to_int(row.get(aura)) if aura else 0,
            "misc": to_int(row.get(misc)) if misc else 0,
            "trigger": to_int(row.get(trigger)),
        })
    return result


def parse_item_effects(rows, link_rows=None):
    """Return {itemID: [spellID, ...]} for every item that has a use effect.

    Older builds name the item right in ItemEffect (ParentItemID). Newer ones,
    Forever included, leave it out and link items to effects through a separate
    ItemXItemEffect table (ItemID, ItemEffectID).
    """
    spell = find_column(rows, "ItemEffect", "SpellID")
    parent = find_column(rows, "ItemEffect", "ParentItemID", "ItemID", required=False)
    result = {}

    if parent:
        for row in rows:
            item_id, spell_id = to_int(row.get(parent)), to_int(row.get(spell))
            if item_id > 0 and spell_id > 0:
                result.setdefault(item_id, []).append(spell_id)
        return result

    if not link_rows:
        raise MissingColumns(
            "ItemEffect has no item column and ItemXItemEffect was not provided. "
            f"ItemEffect columns: {list(rows[0].keys()) if rows else []}")
    effect_id = find_column(rows, "ItemEffect", "ID")
    link_item = find_column(link_rows, "ItemXItemEffect", "ItemID")
    link_effect = find_column(link_rows, "ItemXItemEffect", "ItemEffectID")
    spell_by_effect = {to_int(r.get(effect_id)): to_int(r.get(spell)) for r in rows}
    for row in link_rows:
        item_id = to_int(row.get(link_item))
        spell_id = spell_by_effect.get(to_int(row.get(link_effect)), 0)
        if item_id > 0 and spell_id > 0:
            result.setdefault(item_id, []).append(spell_id)
    return result


def parse_item_classes(rows):
    """Return {itemID: classID}."""
    item = find_column(rows, "Item", "ID")
    klass = find_column(rows, "Item", "ClassID")
    return {to_int(r.get(item)): to_int(r.get(klass)) for r in rows if to_int(r.get(item)) > 0}


def build_mana_only(item_effects, spell_effects, item_classes):
    """Consumables with a use spell that restores mana and no spell that heals."""
    result = set()
    for item_id, spells in item_effects.items():
        if item_classes.get(item_id) != CONSUMABLE_CLASS:
            continue
        restores_mana = heals = False
        for spell_id in spells:
            for e in spell_effects.get(spell_id, []):
                if e["effect"] in MANA_EFFECTS and e["misc"] == POWER_MANA:
                    restores_mana = True
                if (e["effect"] == EFFECT_APPLY_AURA and e["aura"] == AURA_PERIODIC_ENERGIZE
                        and e["misc"] == POWER_MANA):
                    restores_mana = True
                if e["effect"] in HEAL_EFFECTS:
                    heals = True
                if e["effect"] == EFFECT_APPLY_AURA and e["aura"] == AURA_PERIODIC_HEAL:
                    heals = True
        if restores_mana and not heals:
            result.add(item_id)
    return result


def generate_mana_lua(mana_only, item_names, build):
    out = [
        "-- Bagwise: consumables that restore mana and nothing else",
        "-- Rejuvenation-style items that also heal are left out on purpose.",
        f"-- Generated from wago.tools DB2 build {build}. Do not edit by hand.",
        f"-- {len(mana_only)} items.",
        "",
        "Bagwise      = Bagwise or {}",
        "Bagwise.Data = Bagwise.Data or {}",
        "",
        "Bagwise.Data.ManaOnlyConsumables = {",
    ]
    for item_id in sorted(mana_only):
        out.append("  [%d] = true, -- %s" % (item_id, item_names.get(item_id, "?")))
    out.append("}")
    out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


def run(tables, build, out_dir):
    spell_effects = parse_spell_effects(tables["SpellEffect"])
    item_effects = parse_item_effects(tables["ItemEffect"], tables.get("ItemXItemEffect"))
    item_classes = parse_item_classes(tables["Item"])
    item_names = base.parse_item_sparse(tables["ItemSparse"])

    mana_only = build_mana_only(item_effects, spell_effects, item_classes)
    print(f"Mana-only consumables: {len(mana_only)}")
    if len(mana_only) < 3:
        print("WARNING: very few mana consumables found; check the SpellEffect "
              "columns before trusting the output.")

    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, "mana_consumables.lua")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(generate_mana_lua(mana_only, item_names, build))
    print(f"Wrote {path}")
    return mana_only


def selftest():
    """Run the logic on a tiny made-up dataset. No network."""
    zero = {"EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 0, "DifficultyID": 0}
    spell_effect = [
        dict(zero, SpellID=1, Effect=30),                       # mana only
        dict(zero, SpellID=2, Effect=30), dict(zero, SpellID=2, Effect=10),  # mana and health
    ]
    item_effect = [{"ParentItemID": 1000, "SpellID": 1}, {"ParentItemID": 1001, "SpellID": 2}]
    item = [{"ID": 1000, "ClassID": 0}, {"ID": 1001, "ClassID": 0}]
    sparse = [{"ID": 1000, "Display_lang": "Mana Potion"}, {"ID": 1001, "Display_lang": "Rejuvenation"}]
    tables = {"SpellEffect": spell_effect, "ItemEffect": item_effect, "Item": item, "ItemSparse": sparse}
    # Newer layout: ItemEffect names no item, ItemXItemEffect links them.
    linked = {"SpellEffect": spell_effect, "Item": item, "ItemSparse": sparse,
              "ItemEffect": [{"ID": 71, "SpellID": 1}, {"ID": 72, "SpellID": 2}],
              "ItemXItemEffect": [{"ID": 1, "ItemID": 1000, "ItemEffectID": 71},
                                  {"ID": 2, "ItemID": 1001, "ItemEffectID": 72}]}

    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        mana = run(tables, "selftest", tmp)
        mana_linked = run(linked, "selftest", tmp)
    assert mana == {1000}, mana  # the item that also heals is out
    assert mana_linked == {1000}, mana_linked  # same answer through the link table
    print("selftest ok")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--build", help="exact build (default: latest)")
    ap.add_argument("--cache-dir", help="cache downloaded tables here")
    ap.add_argument("--out-dir", default="data", help="where to write the Lua file")
    ap.add_argument("--selftest", action="store_true", help="check the logic offline")
    args = ap.parse_args()

    if args.selftest:
        selftest()
        return

    build = args.build or base.resolve_build("forever")
    print(f"Build: {build}")

    tables = {name: base.fetch_csv_table(name, build, args.cache_dir) for name in TABLES}
    for name in OPTIONAL_TABLES:
        try:
            tables[name] = base.fetch_csv_table(name, build, args.cache_dir)
        except SystemExit:
            print(f"  {name} is not available for this build, continuing without it.")
    try:
        run(tables, build, args.out_dir)
    except MissingColumns as err:
        print(f"\nStopped, nothing written: {err}")
        print("Send this message back and the column names get fixed in one line.")
        sys.exit(1)


if __name__ == "__main__":
    main()
