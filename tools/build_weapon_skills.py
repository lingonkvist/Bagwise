#!/usr/bin/env python3
"""
Build data/weapon_skills.lua from wago.tools DB2 tables.

For every weapon type and for ammo, which classes can ever use it. The game
lists this in SkillRaceClassInfo (one row per skill, class mask and race
group), so it is read from the client data of the build instead of being typed
in from memory, and Forever's own differences show up (rogues use axes there).

Usage:
    python3 tools/build_weapon_skills.py
    python3 tools/build_weapon_skills.py --cache-dir tools/source
    python3 tools/build_weapon_skills.py --selftest
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_reagent_professions import fetch_csv_table, resolve_build  # noqa: E402

DEFAULT_OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                              "data", "weapon_skills.lua")

# Item subclass of a weapon (class 2) -> the skill line a character needs.
WEAPON_SKILLS = {
    0: 44,    # one-handed axes: Axes
    1: 172,   # two-handed axes
    2: 45,    # bows
    3: 46,    # guns
    4: 54,    # one-handed maces: Maces
    5: 160,   # two-handed maces
    6: 229,   # polearms
    7: 43,    # one-handed swords: Swords
    8: 55,    # two-handed swords
    10: 136,  # staves
    13: 473,  # fist weapons
    15: 173,  # daggers
    16: 176,  # thrown
    18: 226,  # crossbows
    19: 228,  # wands
}

# Ammo (item class 6): arrows need a bow or a crossbow, bullets a gun.
AMMO_SKILLS = {
    2: (45, 226),
    3: (46,),
}

CLASS_BITS = {
    1: "WARRIOR", 2: "PALADIN", 4: "HUNTER", 8: "ROGUE", 16: "PRIEST",
    64: "SHAMAN", 128: "MAGE", 256: "WARLOCK", 1024: "DRUID",
}
ALL_CLASSES = sum(CLASS_BITS)


def classes_by_skill(skill_race_class_rows):
    """{skillID: mask of every class with a row for that skill}."""
    masks = {}
    for row in skill_race_class_rows:
        skill = int(row["SkillID"])
        mask = int(row["ClassMask"])
        if mask == -1:
            mask = ALL_CLASSES
        masks[skill] = masks.get(skill, 0) | mask
    return masks


def class_names(mask):
    return [name for bit, name in CLASS_BITS.items() if mask & bit]


def build_tables(skill_race_class_rows):
    """-> (weapons {subclass: [classes]}, ammo {subclass: [classes]})."""
    masks = classes_by_skill(skill_race_class_rows)
    weapons = {}
    for subclass, skill in WEAPON_SKILLS.items():
        if skill in masks:
            weapons[subclass] = class_names(masks[skill])
    ammo = {}
    for subclass, skills in AMMO_SKILLS.items():
        if all(skill in masks for skill in skills):
            mask = 0
            for skill in skills:
                mask |= masks[skill]
            ammo[subclass] = class_names(mask)
    return weapons, ammo


def lua_class_set(names):
    return "{ " + ", ".join(f"{name} = true" for name in names) + " }"


def generate_lua(weapons, ammo, build):
    out = [
        "-- Bagwise: which classes can ever use each weapon type, and ammo.",
        "-- A class missing from a list can never learn that skill, so gear of that",
        "-- type is of no use to it. Read from SkillRaceClassInfo, not typed in.",
        f"-- Generated from wago.tools DB2 build {build}. Do not edit by hand.",
        "",
        "Bagwise                      = Bagwise or {}",
        "Bagwise.Data                 = Bagwise.Data or {}",
        "",
        "-- Format: [item subclass of a weapon] = { CLASS = true, ... }",
        "Bagwise.Data.WeaponClasses = {",
    ]
    for subclass in sorted(weapons):
        out.append(f"  [{subclass}] = {lua_class_set(weapons[subclass])},")
    out += ["}", "", "-- Format: [item subclass of ammo, 2 arrows 3 bullets] = { CLASS = true, ... }",
            "Bagwise.Data.AmmoClasses = {"]
    for subclass in sorted(ammo):
        out.append(f"  [{subclass}] = {lua_class_set(ammo[subclass])},")
    out += ["}", ""]
    return "\n".join(out)


def selftest():
    rows = [
        {"SkillID": "44", "ClassMask": "4"},
        {"SkillID": "44", "ClassMask": "9"},
        {"SkillID": "45", "ClassMask": "13"},
        {"SkillID": "226", "ClassMask": "-1"},
        {"SkillID": "46", "ClassMask": "4"},
    ]
    weapons, ammo = build_tables(rows)
    assert weapons[0] == ["WARRIOR", "HUNTER", "ROGUE"], weapons
    assert weapons[2] == ["WARRIOR", "HUNTER", "ROGUE"], weapons
    assert 4 not in weapons  # no row for Maces: no claim made
    assert ammo[2] == ["WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK",
                       "DRUID"], ammo
    assert ammo[3] == ["HUNTER"], ammo
    lua = generate_lua(weapons, ammo, "test")
    assert "[0] = { WARRIOR = true, HUNTER = true, ROGUE = true }," in lua
    print("selftest ok")


def main():
    ap = argparse.ArgumentParser(description="Generate Bagwise weapon_skills.lua from wago.tools")
    ap.add_argument("--build", help="Exact build, e.g. 1.60.1.70938. Omit to find the latest Forever build.")
    ap.add_argument("--expansion", default="forever")
    ap.add_argument("--output", default=DEFAULT_OUTPUT)
    ap.add_argument("--cache-dir", help="Cache downloaded CSVs here, keyed by build.")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return

    build = args.build or resolve_build(args.expansion)
    print(f"\nFetching DB2 tables for build {build}...")
    rows = fetch_csv_table("SkillRaceClassInfo", build, args.cache_dir)
    weapons, ammo = build_tables(rows)
    missing = [s for s in WEAPON_SKILLS if s not in weapons]
    if missing:
        print(f"  note: no skill data for weapon subclasses {missing}; they get no rule")
    with open(args.output, "w", encoding="utf-8") as fh:
        fh.write(generate_lua(weapons, ammo, build))
    print(f"Wrote {os.path.abspath(args.output)}")


if __name__ == "__main__":
    main()
