#!/usr/bin/env python3
"""
Build two data files from wago.tools DB2 tables:

  data/reagent_recipes.lua    reagents that only recipes you must FIND use,
                              with the recipes to look for
  data/mana_consumables.lua   consumables that restore mana and nothing else

Recipe logic. A recipe is "default" unless it is taught by an item (a
"Recipe: ..." item whose use effect is LEARN_SPELL) and not by a trainer. A
reagent is listed only when every recipe that uses it is non-default, so it has
no use until you find one of those recipes.

Mana logic. A consumable counts when one of its use spells restores mana
(ENERGIZE, or a periodic energize aura) and none heals, so Rejuvenation potions,
which restore both, are left out.

Re-run this whenever a new Forever build ships.

Usage:
    python3 tools/build_recipe_data.py
    python3 tools/build_recipe_data.py --build 1.15.6.58893
    python3 tools/build_recipe_data.py --cache-dir .cache/db2
    python3 tools/build_recipe_data.py --selftest        (no network)

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
EFFECT_LEARN_SPELL = 36
EFFECT_HEAL_MAX_HEALTH = 67
EFFECT_HEAL_PCT = 136
EFFECT_ENERGIZE_PCT = 137
AURA_PERIODIC_HEAL = 8
AURA_PERIODIC_ENERGIZE = 24
POWER_MANA = 0
CONSUMABLE_CLASS = 0

MANA_EFFECTS = {EFFECT_ENERGIZE, EFFECT_ENERGIZE_PCT}
HEAL_EFFECTS = {EFFECT_HEAL, EFFECT_HEAL_MAX_HEALTH, EFFECT_HEAL_PCT}

MAX_RECIPES_PER_REAGENT = 6

# Potions, flasks and finished gear are real reagents for some recipes (4 Healing
# Potions go into Truefaith Gloves), so nothing is filtered by item class. Only
# unused test items are dropped.
PLACEHOLDER_MARKERS = ("[PH]", "[DEP]", "DEPRECATED", "UNUSED")

REQUIRED_TABLES = ["SpellEffect", "ItemEffect", "Item", "SpellName",
                   "SpellReagents", "SkillLineAbility", "SkillLine", "ItemSparse"]
OPTIONAL_TABLES = ["TrainerSpell"]


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


def parse_item_effects(rows):
    """Return {itemID: [spellID, ...]} for every item that has a use effect."""
    parent = find_column(rows, "ItemEffect", "ParentItemID", "ItemID")
    spell = find_column(rows, "ItemEffect", "SpellID")
    result = {}
    for row in rows:
        item_id = to_int(row.get(parent))
        spell_id = to_int(row.get(spell))
        if item_id > 0 and spell_id > 0:
            result.setdefault(item_id, []).append(spell_id)
    return result


def parse_item_classes(rows):
    """Return {itemID: classID}."""
    item = find_column(rows, "Item", "ID")
    klass = find_column(rows, "Item", "ClassID")
    return {to_int(r.get(item)): to_int(r.get(klass)) for r in rows if to_int(r.get(item)) > 0}


def parse_spell_names(rows):
    """Return {spellID: English name}."""
    spell = find_column(rows, "SpellName", "ID")
    name = find_column(rows, "SpellName", "Name_lang", "Name")
    return {to_int(r.get(spell)): r.get(name) for r in rows
            if to_int(r.get(spell)) > 0 and r.get(name)}


def parse_trainer_spells(rows):
    """Return the set of spell IDs a trainer teaches, or None without the table."""
    if not rows:
        return None
    spell = find_column(rows, "TrainerSpell", "SpellID", required=False)
    if not spell:
        return None
    return {to_int(r.get(spell)) for r in rows if to_int(r.get(spell)) > 0}


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def learned_by(spell_effects, spell_id):
    """The spells that casting spell_id teaches (empty for most spells)."""
    return [e["trigger"] for e in spell_effects.get(spell_id, [])
            if e["effect"] == EFFECT_LEARN_SPELL and e["trigger"] > 0]


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


def build_item_taught(item_effects, spell_effects):
    """Return {craftSpellID: [recipeItemID, ...]} for recipes an item teaches."""
    taught = {}
    for item_id, spells in item_effects.items():
        for spell_id in spells:
            for target in learned_by(spell_effects, spell_id):
                taught.setdefault(target, []).append(item_id)
    return taught


def build_trainer_taught(trainer_spells, spell_effects):
    """Spells a trainer teaches, counting what a trainer's learn spell triggers."""
    if trainer_spells is None:
        return set()
    taught = set(trainer_spells)
    for spell_id in trainer_spells:
        taught.update(learned_by(spell_effects, spell_id))
    return taught


def recipe_skill(ability):
    skill_line, min_rank, trivial_low, _high = ability
    return min_rank if min_rank > 1 else trivial_low


def usable_reagent(item_id, item_names):
    """Not a placeholder or deprecated test item."""
    name = item_names.get(item_id, "")
    return bool(name) and not any(m in name.upper() for m in PLACEHOLDER_MARKERS)


def dedupe_by_name(entries):
    """The same recipe can come from several items (older and newer copies).
    Keep one per spell name and profession, the lowest item ID."""
    best = {}
    for entry in entries:
        key = (entry[0], entry[1])
        if key not in best or entry[3] < best[key][3]:
            best[key] = entry
    return list(best.values())


def build_reagent_recipes(spell_reagents, abilities, prof_names, spell_names,
                          item_taught, trainer_taught, item_names=None):
    """
    Return {reagentItemID: [(spellName, profession, skill, recipeItemID), ...]}
    for reagents whose recipes are ALL taught by items and not by a trainer.
    """
    uses = {}
    for spell_id, reagents in spell_reagents.items():
        if spell_id not in abilities:
            continue
        for item_id, _count in reagents:
            uses.setdefault(item_id, []).append(spell_id)

    def is_default(spell_id):
        return spell_id not in item_taught or spell_id in trainer_taught

    result = {}
    for reagent_id, spells in uses.items():
        if item_names is not None and not usable_reagent(reagent_id, item_names):
            continue
        if any(is_default(s) for s in spells):
            continue
        entries = []
        for spell_id in spells:
            skill_line = abilities[spell_id][0]
            profession = prof_names.get(skill_line) or base.FALLBACK_NAMES.get(skill_line, "?")
            name = spell_names.get(spell_id, f"Spell {spell_id}")
            entries.append((name, profession, recipe_skill(abilities[spell_id]),
                            min(item_taught[spell_id]), spell_id))
        entries = dedupe_by_name(entries)
        entries.sort(key=lambda e: (e[2], e[0]))
        result[reagent_id] = entries[:MAX_RECIPES_PER_REAGENT]
    return result


# ---------------------------------------------------------------------------
# Lua output
# ---------------------------------------------------------------------------


def lua_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def generate_recipes_lua(reagent_recipes, item_names, build):
    out = [
        "-- Bagwise: reagents that only recipes you must find use",
        "-- A reagent is listed only when every recipe that uses it is taught by an",
        "-- item and not by a trainer. Each entry: spell name, profession, skill,",
        "-- recipe item ID, spell ID (to check if the player already knows it).",
        f"-- Generated from wago.tools DB2 build {build}. Do not edit by hand.",
        f"-- {len(reagent_recipes)} reagents.",
        "",
        "Bagwise      = Bagwise or {}",
        "Bagwise.Data = Bagwise.Data or {}",
        "",
        "Bagwise.Data.ReagentRecipes = {",
    ]
    for reagent_id in sorted(reagent_recipes):
        rows = ", ".join(
            "{ %s, %s, %d, %d, %d }" % (lua_string(n), lua_string(p), s, i, sp)
            for n, p, s, i, sp in reagent_recipes[reagent_id])
        out.append("  [%d] = { %s }, -- %s" % (
            reagent_id, rows, item_names.get(reagent_id, "?")))
    out.append("}")
    out.append("")
    return "\n".join(out)


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


def run(tables, build, out_dir):
    spell_effects = parse_spell_effects(tables["SpellEffect"])
    item_effects = parse_item_effects(tables["ItemEffect"])
    item_classes = parse_item_classes(tables["Item"])
    spell_names = parse_spell_names(tables["SpellName"])
    spell_reagents = base.parse_spell_reagents(tables["SpellReagents"])
    abilities = base.parse_skill_line_ability(tables["SkillLineAbility"])
    prof_names = base.parse_skill_line(tables["SkillLine"])
    item_names = base.parse_item_sparse(tables["ItemSparse"])
    trainer_spells = parse_trainer_spells(tables.get("TrainerSpell"))

    mana_only = build_mana_only(item_effects, spell_effects, item_classes)
    item_taught = build_item_taught(item_effects, spell_effects)
    trainer_taught = build_trainer_taught(trainer_spells, spell_effects)
    reagent_recipes = build_reagent_recipes(
        spell_reagents, abilities, prof_names, spell_names, item_taught, trainer_taught,
        item_names)

    print(f"Mana-only consumables: {len(mana_only)}")
    print(f"Recipes taught by an item: {len(item_taught)}")
    print(f"Reagents with only find-it recipes: {len(reagent_recipes)}")
    if trainer_spells is None:
        print("NOTE: no TrainerSpell table. A recipe that is both item-taught and "
              "trainer-taught would be listed as find-it. Check the output by eye.")
    if len(mana_only) < 3:
        print("WARNING: very few mana consumables found; check the SpellEffect "
              "columns before trusting mana_consumables.lua.")
    if not item_taught:
        print("WARNING: no item-taught recipes found; the LEARN_SPELL link is "
              "probably wrong for this build.")

    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "reagent_recipes.lua"), "w", encoding="utf-8") as fh:
        fh.write(generate_recipes_lua(reagent_recipes, item_names, build))
    with open(os.path.join(out_dir, "mana_consumables.lua"), "w", encoding="utf-8") as fh:
        fh.write(generate_mana_lua(mana_only, item_names, build))
    print(f"Wrote {out_dir}/reagent_recipes.lua and {out_dir}/mana_consumables.lua")
    return mana_only, reagent_recipes


def selftest():
    """Run the logic on a tiny made-up dataset. No network."""
    spell_effect = [
        # Potion 1000: restores mana only. Potion 1001: mana and health.
        {"SpellID": 1, "Effect": 30, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 0, "DifficultyID": 0},
        {"SpellID": 2, "Effect": 30, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 0, "DifficultyID": 0},
        {"SpellID": 2, "Effect": 10, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 0, "DifficultyID": 0},
        # Recipe item 2000 teaches craft spell 10 (use spell 3 triggers it).
        {"SpellID": 3, "Effect": 36, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 10, "DifficultyID": 0},
        # Recipe item 2001 teaches craft spell 11, which a trainer also teaches.
        {"SpellID": 4, "Effect": 36, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 11, "DifficultyID": 0},
        # A second recipe item (newer copy) teaching the same craft spell 10.
        {"SpellID": 5, "Effect": 36, "EffectAura": 0, "EffectMiscValue_0": 0, "EffectTriggerSpell": 10, "DifficultyID": 0},
    ]
    item_effect = [
        {"ParentItemID": 1000, "SpellID": 1}, {"ParentItemID": 1001, "SpellID": 2},
        {"ParentItemID": 2000, "SpellID": 3}, {"ParentItemID": 2001, "SpellID": 4},
        {"ParentItemID": 2002, "SpellID": 5},
    ]
    item = [{"ID": 1000, "ClassID": 0}, {"ID": 1001, "ClassID": 0},
            {"ID": 2000, "ClassID": 9}, {"ID": 2001, "ClassID": 9}, {"ID": 2002, "ClassID": 9},
            {"ID": 5000, "ClassID": 7}, {"ID": 5001, "ClassID": 7},
            {"ID": 5002, "ClassID": 0}, {"ID": 5003, "ClassID": 7}]
    spell_name = [{"ID": 10, "Name_lang": "Elixir of Finding"}, {"ID": 11, "Name_lang": "Elixir of Trainers"}]
    spell_reagents = [
        {"SpellID": 10, "Reagent_0": 5000, "ReagentCount_0": 1, "Reagent_1": 5001, "ReagentCount_1": 1,
         "Reagent_2": 5002, "ReagentCount_2": 1, "Reagent_3": 5003, "ReagentCount_3": 1},
        {"SpellID": 11, "Reagent_0": 5001, "ReagentCount_0": 1},
    ]
    ability = [
        {"Spell": 10, "SkillLine": 171, "MinSkillLineRank": 250, "TrivialSkillLineRankLow": 270, "TrivialSkillLineRankHigh": 290},
        {"Spell": 11, "SkillLine": 171, "MinSkillLineRank": 100, "TrivialSkillLineRankLow": 120, "TrivialSkillLineRankHigh": 140},
    ]
    skill_line = [{"ID": 171, "DisplayName_lang": "Alchemy"}]
    sparse = [{"ID": 5000, "Display_lang": "Rare Herb"}, {"ID": 5001, "Display_lang": "Common Herb"},
              {"ID": 5002, "Display_lang": "Healing Potion"}, {"ID": 5003, "Display_lang": "[PH] Test Dust [DEP]"},
              {"ID": 1000, "Display_lang": "Mana Potion"}]
    trainer = [{"SpellID": 11}]

    tables = {"SpellEffect": spell_effect, "ItemEffect": item_effect, "Item": item,
              "SpellName": spell_name, "SpellReagents": spell_reagents,
              "SkillLineAbility": ability, "SkillLine": skill_line, "ItemSparse": sparse,
              "TrainerSpell": trainer}
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        mana, recipes = run(tables, "selftest", tmp)

    assert mana == {1000}, mana                      # the rejuvenation-style item is out
    # 5001 also feeds a trainer recipe, 5003 is a placeholder, and the duplicate
    # recipe item 2002 collapses into 2000. A potion (5002) is a real reagent.
    assert sorted(recipes) == [5000, 5002], recipes
    assert recipes[5000] == [("Elixir of Finding", "Alchemy", 250, 2000, 10)], recipes
    print("selftest ok")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--build", help="exact build (default: latest)")
    ap.add_argument("--cache-dir", help="cache downloaded tables here")
    ap.add_argument("--out-dir", default="data", help="where to write the Lua files")
    ap.add_argument("--selftest", action="store_true", help="check the logic offline")
    args = ap.parse_args()

    if args.selftest:
        selftest()
        return

    build = args.build or base.resolve_build("forever")
    print(f"Build: {build}")

    tables = {}
    for name in REQUIRED_TABLES + OPTIONAL_TABLES:
        try:
            tables[name] = base.fetch_csv_table(name, build, args.cache_dir)
        except SystemExit:
            if name in REQUIRED_TABLES:
                print(f"Could not fetch required table {name}. Nothing written.")
                sys.exit(1)
            print(f"Optional table {name} not available, continuing without it.")

    try:
        run(tables, build, args.out_dir)
    except MissingColumns as err:
        print(f"\nStopped, nothing written: {err}")
        print("Send this message back and the column names get fixed in one line.")
        sys.exit(1)


if __name__ == "__main__":
    main()
