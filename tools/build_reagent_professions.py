#!/usr/bin/env python3
"""
Build data/reagent_professions.lua from wago.tools DB2 tables.

Fetches SpellReagents, SkillLineAbility, SkillLine and ItemSparse from
wago.tools and generates a complete mapping of which professions use each
reagent item, with recipe count and skill-level range.

Re-run this whenever a new Classic Era or Forever build ships.

Usage:
    python3 tools/build_reagent_professions.py
    python3 tools/build_reagent_professions.py --build 1.15.6.58893
    python3 tools/build_reagent_professions.py --cache-dir .cache/db2

Requirements: Python 3.8+, stdlib only (no pip packages).
"""

import argparse
import csv
import io
import json
import re
import os
import sys
import urllib.request
import urllib.error

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

WAGO_BASE = "https://wago.tools"
DB2_CSV = WAGO_BASE + "/db2/{table}/csv?build={build}"
BUILDS_API = WAGO_BASE + "/api/builds"

# DB2 tables we need.
TABLES = ["SpellReagents", "SkillLineAbility", "SkillLine", "ItemSparse", "SpellEffect"]

# Crafting skill lines whose recipes consume reagents.
# Gathering-only skills (Herbalism 182, Skinning 393) and non-crafting
# skills (Fishing 356, Poisons 40, Survival 142) are excluded.
CRAFTING_LINES = {
    129,  # First Aid
    164,  # Blacksmithing
    165,  # Leatherworking
    171,  # Alchemy
    185,  # Cooking
    186,  # Mining (smelting recipes)
    197,  # Tailoring
    202,  # Engineering
    333,  # Enchanting
}

# Fallback English names, used only when SkillLine has no row for a line.
FALLBACK_NAMES = {
    129: "First Aid",
    164: "Blacksmithing",
    165: "Leatherworking",
    171: "Alchemy",
    185: "Cooking",
    186: "Mining",
    197: "Tailoring",
    202: "Engineering",
    333: "Enchanting",
}

# Default output path, relative to wherever the script is invoked.
DEFAULT_OUTPUT = "data/reagent_professions.lua"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def int_or(val, default=0):
    """Parse an int from a CSV cell, returning *default* on empty/bad data."""
    if val is None or val == "":
        return default
    try:
        return int(val)
    except (ValueError, TypeError):
        return default


def csv_get(row, *candidates, default=""):
    """Return the first non-None value from *candidates* column names."""
    for key in candidates:
        val = row.get(key)
        if val is not None:
            return val
    return default


# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------


def fetch_url(url):
    """GET *url* and return the body as a string."""
    req = urllib.request.Request(url)
    req.add_header("User-Agent", "bagwise-data-generator/1.0")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.read().decode("utf-8-sig")
    except urllib.error.HTTPError as exc:
        print(f"\n  HTTP {exc.code} from {url}")
        sys.exit(1)
    except urllib.error.URLError as exc:
        print(f"\n  Could not reach {url}: {exc.reason}")
        sys.exit(1)


def fetch_csv_table(table, build, cache_dir=None):
    """Download a DB2 CSV from wago.tools (or load from cache)."""
    if cache_dir:
        path = os.path.join(cache_dir, build, f"{table}.csv")
        if os.path.isfile(path):
            print(f"  {table}: cached", end="", flush=True)
            with open(path, "r", encoding="utf-8-sig") as fh:
                rows = list(csv.DictReader(fh))
            print(f" ({len(rows)} rows)")
            return rows

    url = DB2_CSV.format(table=table, build=build)
    print(f"  {table}: fetching...", end="", flush=True)
    body = fetch_url(url)

    rows = list(csv.DictReader(io.StringIO(body)))
    print(f" ({len(rows)} rows)")

    if cache_dir:
        dir_path = os.path.join(cache_dir, build)
        os.makedirs(dir_path, exist_ok=True)
        with open(os.path.join(dir_path, f"{table}.csv"), "w", encoding="utf-8") as fh:
            fh.write(body)

    return rows


FOREVER_VERSION_PREFIX = "1.60."


def version_key(version):
    """Sort key for '1.60.1.70862': compare the numbers, not the text."""
    return tuple(int(part) for part in re.findall(r"\d+", version))


def pick_forever_build(data):
    """The newest build whose version is in the Forever line (1.60.x), from
    either a flat list of builds or a dict of product -> list of builds."""
    if isinstance(data, dict):
        rows = [b for value in data.values() if isinstance(value, list) for b in value]
    else:
        rows = data
    versions = {str(b.get("version", "")) for b in rows
                if isinstance(b, dict) and str(b.get("version", "")).startswith(FOREVER_VERSION_PREFIX)}
    return max(versions, key=version_key) if versions else None


def resolve_build(expansion):
    """Ask the builds API for the latest build of *expansion*."""
    if expansion == "forever":
        print("Querying builds API for the Forever line (%s*)..." % FOREVER_VERSION_PREFIX)
        build = pick_forever_build(json.loads(fetch_url(BUILDS_API)))
        if not build:
            print("  No %s* build found. Pass the build yourself with --build." % FOREVER_VERSION_PREFIX)
            sys.exit(1)
        print(f"  Latest Forever build: {build}")
        return build

    products = {
        "classic_era": "wow_classic_era",
        "classic":     "wow_classic_era",
    }
    product = products.get(expansion)
    if not product:
        print(f"Unknown expansion '{expansion}'. "
              f"Use one of: {', '.join(products)}")
        sys.exit(1)

    print(f"Querying builds API for {expansion}...")
    body = fetch_url(BUILDS_API)
    data = json.loads(body)

    # The API returns either a flat list of build objects or a dict keyed by
    # product name (each value a list of builds).  Normalise to a flat list.
    if isinstance(data, dict):
        all_builds = []
        # Try direct key lookup, then partial match on "classic_era" / "classic"
        matched_key = None
        if product in data:
            matched_key = product
        else:
            for key in data:
                if "classic_era" in key or ("classic" in key and "era" in key):
                    matched_key = key
                    break
            if not matched_key:
                for key in data:
                    if "classic" in key:
                        matched_key = key
                        break
        if matched_key:
            all_builds = data[matched_key] if isinstance(data[matched_key], list) else []
            print(f"  Product key: {matched_key}")
        else:
            # Flatten everything so the fallback filters still work
            for key, value in data.items():
                if isinstance(value, list):
                    all_builds.extend(value)
        available_products = sorted(data.keys()) if not all_builds else None
    elif isinstance(data, list):
        all_builds = data
        available_products = None
    else:
        print(f"Unexpected API response type: {type(data).__name__}")
        sys.exit(1)

    # When we got builds by direct key, they already match.
    if isinstance(data, dict) and product in data:
        matches = all_builds
    else:
        matches = [
            b for b in all_builds
            if isinstance(b, dict) and b.get("product") == product
        ]

    if not matches:
        # Fallback: look for version prefix
        prefix = "1.15" if "classic" in expansion else "1."
        matches = [
            b for b in all_builds
            if isinstance(b, dict) and b.get("version", "").startswith(prefix)
        ]

    if not matches:
        if available_products is None:
            available_products = sorted(
                {b.get("product", "?") for b in all_builds if isinstance(b, dict)}
            )
        print(f"No builds found for '{expansion}'.")
        print(f"Available products: {available_products}")
        sys.exit(1)

    def sort_key(b):
        if not isinstance(b, dict):
            return ""
        v = b.get("version", "")
        # Sort by version string; longer dotted versions sort later
        return v

    matches.sort(key=sort_key, reverse=True)
    best = matches[0]
    version = best.get("version", "") if isinstance(best, dict) else str(best)
    # If there is a separate "build" field and the version does not already
    # include it as its last segment, append it.
    build_num = best.get("build") if isinstance(best, dict) else None
    if build_num and str(build_num) not in version.split("."):
        version = f"{version}.{build_num}"
    print(f"Latest: {version}")
    return version


# ---------------------------------------------------------------------------
# Parsers -- flexible about column names across DB2 versions
# ---------------------------------------------------------------------------


def parse_spell_reagents(rows):
    """
    Return {spellID: [(itemID, count), ...]}.

    Column names vary between DB2 versions:
      Reagent[0]..Reagent[7]   or   Reagent_0..Reagent_7
    Count columns follow the same pattern with ReagentCount.
    """
    if not rows:
        return {}

    # Detect naming convention from first row's keys.
    keys = list(rows[0].keys())
    reagent_cols = []
    count_cols = []
    for i in range(8):
        for pat in (f"Reagent[{i}]", f"Reagent_{i}", f"Reagent{i+1}"):
            if pat in keys:
                reagent_cols.append(pat)
                break
        for pat in (f"ReagentCount[{i}]", f"ReagentCount_{i}", f"ReagentCount{i+1}"):
            if pat in keys:
                count_cols.append(pat)
                break

    if not reagent_cols:
        print("  WARNING: could not detect Reagent columns in SpellReagents")
        print(f"    Available columns: {keys}")
        return {}

    result = {}
    for row in rows:
        spell_id = int_or(csv_get(row, "SpellID", "ID"))
        if spell_id <= 0:
            continue
        reagents = []
        for r_col, c_col in zip(reagent_cols, count_cols):
            item_id = int_or(row.get(r_col))
            count = int_or(row.get(c_col))
            if item_id > 0 and count > 0:
                reagents.append((item_id, count))
        if reagents:
            result[spell_id] = reagents
    return result


def parse_skill_line_ability(rows):
    """
    Return {spellID: (skillLineID, minSkill, trivialLow, trivialHigh)}.

    Only rows whose SkillLine is in CRAFTING_LINES are kept.
    """
    result = {}
    for row in rows:
        spell_id = int_or(csv_get(row, "Spell"))
        skill_line = int_or(csv_get(row, "SkillLine", "SkillupSkillLineID"))
        if spell_id <= 0 or skill_line not in CRAFTING_LINES:
            continue
        min_rank = int_or(csv_get(row, "MinSkillLineRank"))
        trivial_low = int_or(csv_get(row, "TrivialSkillLineRankLow"))
        trivial_high = int_or(csv_get(row, "TrivialSkillLineRankHigh"))
        result[spell_id] = (skill_line, min_rank, trivial_low, trivial_high)
    return result


def parse_skill_line(rows):
    """Return {skillLineID: English display name}."""
    result = {}
    for row in rows:
        sid = int_or(csv_get(row, "ID"))
        name = csv_get(row, "DisplayName_lang", "DisplayName")
        if sid > 0 and name:
            result[sid] = name
    return result


def parse_item_sparse(rows):
    """Return {itemID: name}."""
    result = {}
    for row in rows:
        iid = int_or(csv_get(row, "ID"))
        name = csv_get(row, "Display_lang", "Display")
        if iid > 0 and name:
            result[iid] = name
    return result


# Spell effects that create an item (CREATE_ITEM, CREATE_ITEM_2).
CREATE_ITEM_EFFECTS = {24, 157}

CHAINS_OUTPUT = "data/reagent_chains.lua"


def parse_spell_products(rows):
    """Return {spellID: itemID} for spells that create an item."""
    result = {}
    for row in rows:
        if int_or(csv_get(row, "Effect")) not in CREATE_ITEM_EFFECTS:
            continue
        spell_id = int_or(csv_get(row, "SpellID"))
        item_id = int_or(csv_get(row, "EffectItemType"))
        if spell_id > 0 and item_id > 0:
            result[spell_id] = item_id
    return result


def build_chains(spell_reagents, abilities, prof_names, products):
    """
    Downstream uses of a reagent through what it is turned into.

    A recipe that consumes item I and creates item P passes every use of P on
    to I: copper bar -> bronze bar -> the smithing and engineering recipes that
    use bronze bars. Returns {itemID: {profName: [minSkill, maxSkill, greenSkill]}} holding
    only uses reached through at least one intermediate (direct uses stay in
    ReagentProfessions). Cycles (transmutes both ways) are handled by iterating
    to a fixed point.
    """
    direct = build_reagent_map(spell_reagents, abilities, prof_names)
    # makes[I] = items made from I
    makes = {}
    for spell_id, reagents in spell_reagents.items():
        product = products.get(spell_id)
        if not product or spell_id not in abilities:
            continue
        for item_id, _qty in reagents:
            if item_id != product:
                makes.setdefault(item_id, set()).add(product)

    reach = {}  # itemID -> {prof: [min, max]} through intermediates
    changed = True
    while changed:
        changed = False
        for item_id, outputs in makes.items():
            for product in outputs:
                uses = {}
                for prof, entry in direct.get(product, {}).items():
                    uses[prof] = [entry["min"], entry["max"], entry["green"]]
                for prof, span in reach.get(product, {}).items():
                    if prof in uses:
                        uses[prof] = [min(uses[prof][0], span[0]), max(uses[prof][1], span[1]),
                                      max(uses[prof][2], span[2])]
                    else:
                        uses[prof] = list(span)
                mine = reach.setdefault(item_id, {})
                for prof, span in uses.items():
                    if prof not in mine:
                        mine[prof] = list(span)
                        changed = True
                    else:
                        lo = min(mine[prof][0], span[0])
                        hi = max(mine[prof][1], span[1])
                        gr = max(mine[prof][2], span[2])
                        if [lo, hi, gr] != mine[prof]:
                            mine[prof] = [lo, hi, gr]
                            changed = True
    # A green point below the highest skill means the merged uses disagree
    # (one use had no green data); treat it as unknown rather than wrong.
    for spans in reach.values():
        for span in spans.values():
            if span[2] < span[1]:
                span[2] = 0
    return reach


def generate_chains_lua(chains, build_version):
    out = [
        "-- Bagwise: reagent uses through what a reagent is made into.",
        "-- Copper Bar is smelted into Bronze Bar, which smithing uses far above",
        "-- what copper recipes do. Used so a material is never called outleveled",
        "-- while something made from it is still in demand. green_level is the",
        "-- skill where the last of those recipes turns green.",
        f"-- Generated from wago.tools DB2 build {build_version}. Do not edit by hand.",
        "",
        "Bagwise                      = Bagwise or {}",
        "Bagwise.Data                 = Bagwise.Data or {}",
        "",
        "-- Format: [itemID] = { { profession, min_level, max_level, green_level }, ... }",
        "Bagwise.Data.ReagentChains = {",
    ]
    for item_id in sorted(chains):
        parts = ", ".join('{ "%s", %d, %d, %d }' % (p, span[0], span[1], span[2])
                          for p, span in sorted(chains[item_id].items()))
        out.append(f"  [{item_id}] = {{ {parts} }},")
    out.append("}")
    out.append("")
    return "\n".join(out)


def selftest():
    """Copper bar is smelted into bronze bar, which smithing uses higher up."""
    # item ids: 98 ore, 99 copper bar, 101 tin bar, 200 bronze bar, 300 and 301 smithing items
    reagents = {
        1: [(98, 1)],              # ore -> copper bar
        2: [(99, 1), (101, 1)],    # copper bar + tin bar -> bronze bar
        3: [(200, 1)],             # bronze bar -> item 300
        4: [(300, 1)],             # item 300 -> item 301
    }
    abilities = {
        1: (186, 1, 1, 47), 2: (186, 65, 65, 110),
        3: (164, 85, 85, 130), 4: (164, 155, 155, 205),   # greens 24, 87, 107, 180
    }
    products = {1: 99, 2: 200, 3: 300, 4: 301}
    names = {186: "Mining", 164: "Blacksmithing"}
    chains = build_chains(reagents, abilities, names, products)
    assert chains[99]["Blacksmithing"] == [85, 155, 180], chains
    assert chains[200]["Blacksmithing"] == [155, 155, 180], chains
    assert chains[98]["Mining"] == [65, 65, 87] and chains[98]["Blacksmithing"] == [85, 155, 180], chains
    assert 301 not in chains and 300 in chains, chains
    direct = build_reagent_map(reagents, abilities, names)
    assert direct[99]["Mining"]["green"] == 87, direct  # copper bar: bronze recipe turns green at 87
    assert direct[300]["Blacksmithing"]["green"] == 180, direct
    print("selftest ok")


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def build_reagent_map(spell_reagents, abilities, prof_names):
    """
    Join SpellReagents with SkillLineAbility and SkillLine.

    Returns {itemID: {profName: {"count": N, "min": X, "max": Y, "green": Z}}}.
    "green" is the highest skill at which any of the recipes is still yellow or
    better: the point where it turns green, halfway between TrivialSkillLineRankLow
    and TrivialSkillLineRankHigh. Past it the skill-up chance is under 50%.

    For skill levels:
      - MinSkillLineRank is the orange threshold (recipe becomes available).
      - TrivialSkillLineRankLow is the yellow threshold.
      - TrivialSkillLineRankHigh is the gray threshold.
    The existing data uses the *learnable-at* level for each recipe (orange),
    so we prefer MinSkillLineRank and fall back to TrivialSkillLineRankLow
    when MinSkillLineRank is unreliable (0 or 1 for all rows).
    """
    # First pass: check whether MinSkillLineRank is populated.
    nonzero_min = sum(
        1 for (_sl, mr, _tl, _th) in abilities.values() if mr > 1
    )
    use_trivial = nonzero_min < len(abilities) * 0.05
    if use_trivial and abilities:
        print("  NOTE: MinSkillLineRank mostly zero/one; "
              "using TrivialSkillLineRankLow instead.")

    reagent_data = {}  # {itemID: {profName: {"count", "min", "max", "green"}}}

    for spell_id, reagents in spell_reagents.items():
        ability = abilities.get(spell_id)
        if not ability:
            continue
        skill_line, min_rank, trivial_low, trivial_high = ability
        name = prof_names.get(skill_line) or FALLBACK_NAMES.get(skill_line)
        if not name:
            continue

        if use_trivial:
            recipe_skill = trivial_low if trivial_low > 0 else min_rank
        else:
            recipe_skill = min_rank if min_rank > 0 else trivial_low

        for item_id, _qty in reagents:
            profs = reagent_data.setdefault(item_id, {})
            entry = profs.setdefault(name, {"count": 0, "min": 9999, "max": 0, "green": 0})
            entry["count"] += 1
            # The skill where this recipe turns green (the skill-up chance drops
            # under 50% from here, to 0% at gray).
            if trivial_low > 0 and trivial_high > trivial_low:
                entry["green"] = max(entry["green"], (trivial_low + trivial_high) // 2)
            if recipe_skill > 0:
                entry["min"] = min(entry["min"], recipe_skill)
                entry["max"] = max(entry["max"], recipe_skill)

    # Clean up sentinel values.
    for profs in reagent_data.values():
        for entry in profs.values():
            if entry["min"] == 9999:
                entry["min"] = 0
            if entry["max"] == 0:
                entry["max"] = entry["min"]
            if entry["green"] < entry["max"]:
                entry["green"] = 0  # no usable green point, the game falls back

    return reagent_data


# ---------------------------------------------------------------------------
# Lua generation
# ---------------------------------------------------------------------------


def generate_lua(reagent_data, item_names, build_version):
    """Produce the Lua source string in Bagwise's format."""
    out = []
    total = len(reagent_data)
    all_profs = sorted({p for profs in reagent_data.values() for p in profs})

    out.append("-- Bagwise: reagent-to-profession mapping with recipe stats")
    out.append("-- For each reagent item: which professions use it, how many")
    out.append("-- recipes, the skill range they are learnable at, and the skill")
    out.append("-- where the last of them turns green (0 when unknown).")
    out.append(f"-- Generated from wago.tools DB2 build {build_version}. "
               "Do not edit by hand.")
    out.append("--")
    out.append(f"-- {total} reagent items across {len(all_profs)} professions.")
    out.append("")
    out.append("Bagwise                         = Bagwise or {}")
    out.append("Bagwise.Data                    = Bagwise.Data or {}")
    out.append("")
    out.append("-- Format: [itemID] = { { profession, recipe_count, "
               "min_level, max_level, green_level }, ... }")
    out.append("Bagwise.Data.ReagentProfessions = {")

    # Group items by their sorted profession combo for readable sections.
    grouped = {}
    for item_id, profs in reagent_data.items():
        key = tuple(sorted(profs.keys()))
        grouped.setdefault(key, []).append(item_id)

    first_section = True
    for combo in sorted(grouped.keys()):
        items = sorted(grouped[combo])
        if not first_section:
            out.append("")
        first_section = False
        out.append(f"  -- {', '.join(combo)}")

        for item_id in items:
            profs = reagent_data[item_id]
            parts = []
            for pname in sorted(profs.keys()):
                e = profs[pname]
                parts.append(
                    f'{{ "{pname}", {e["count"]}, {e["min"]}, {e["max"]}, {e["green"]} }}'
                )
            entry = ", ".join(parts)
            name = item_names.get(item_id, "")
            comment = f"  -- {name}" if name else ""
            out.append(f"  [{item_id}] = {{ {entry} }},{comment}")

    out.append("}")
    out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------


def verify_known_reagents(reagent_data):
    """
    Spot-check a few known reagents from the old file.  Prints warnings
    for anything suspicious but never blocks the build.
    """
    # Hardcoded spot-checks from the original 419-item file.
    checks = {
        765:  ("Alchemy", 5),     # Silverleaf: 5 alchemy recipes
        2589: ("Tailoring", None), # Linen Cloth: used in Tailoring
        2841: ("Blacksmithing", None), # Bronze Bar: smithing (it is made by smelting, not used up by it)
        4338: ("Tailoring", None), # Mageweave Cloth
    }
    missing = []
    for item_id, (expected_prof, expected_count) in checks.items():
        profs = reagent_data.get(item_id, {})
        if expected_prof not in profs:
            missing.append(
                f"  item {item_id}: expected {expected_prof}, got "
                f"{list(profs.keys()) or 'nothing'}"
            )
        elif expected_count and profs[expected_prof]["count"] < expected_count:
            missing.append(
                f"  item {item_id}: expected >= {expected_count} "
                f"{expected_prof} recipes, got {profs[expected_prof]['count']}"
            )
    if missing:
        print("\nSpot-check warnings (may be fine for a different build):")
        for line in missing:
            print(line)
    else:
        print("\nSpot-checks passed.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    ap = argparse.ArgumentParser(
        description="Generate Bagwise reagent_professions.lua from wago.tools"
    )
    ap.add_argument(
        "--build",
        help="Exact build version, e.g. 1.15.6.58893. "
             "Omit to auto-detect the latest Classic Era build.",
    )
    ap.add_argument(
        "--expansion", default="forever",
        help="Which expansion to query for the latest build "
             "(classic_era, forever). Default: forever",
    )
    ap.add_argument(
        "--output", default=DEFAULT_OUTPUT,
        help=f"Output path. Default: {DEFAULT_OUTPUT}",
    )
    ap.add_argument(
        "--cache-dir",
        help="Cache downloaded CSVs here (keyed by build). "
             "Reuses them on subsequent runs.",
    )
    ap.add_argument("--selftest", action="store_true", help="Run the offline check and exit.")
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return

    # Resolve build.
    build = args.build or resolve_build(args.expansion)

    # Download tables.
    print(f"\nFetching DB2 tables for build {build}...")
    tables = {}
    for name in TABLES:
        tables[name] = fetch_csv_table(name, build, args.cache_dir)

    # Print column names once for diagnostics.
    for name in TABLES:
        if tables[name]:
            cols = list(tables[name][0].keys())
            print(f"  {name} columns: {', '.join(cols[:12])}"
                  f"{'...' if len(cols) > 12 else ''}")

    # Parse.
    print("\nParsing...")
    spell_reagents = parse_spell_reagents(tables["SpellReagents"])
    print(f"  {len(spell_reagents)} spells with reagents")

    abilities = parse_skill_line_ability(tables["SkillLineAbility"])
    print(f"  {len(abilities)} crafting-profession recipes")

    prof_names = parse_skill_line(tables["SkillLine"])
    for sl in CRAFTING_LINES:
        n = prof_names.get(sl) or FALLBACK_NAMES.get(sl, "?")
        print(f"    {sl} = {n}")

    item_names = parse_item_sparse(tables["ItemSparse"])
    print(f"  {len(item_names)} item names loaded")

    # Build the map.
    print("\nBuilding reagent-profession map...")
    reagent_data = build_reagent_map(spell_reagents, abilities, prof_names)

    # Summary.
    total = len(reagent_data)
    all_profs = sorted({p for profs in reagent_data.values() for p in profs})
    print(f"  {total} reagent items across {len(all_profs)} professions:")
    for prof in all_profs:
        count = sum(1 for profs in reagent_data.values() if prof in profs)
        print(f"    {prof}: {count} items")

    # Sanity: warn about zero-skill entries.
    zeros = sum(
        1 for profs in reagent_data.values()
        for e in profs.values()
        if e["min"] == 0 and e["max"] == 0
    )
    if zeros > total * 0.1:
        print(f"\n  WARNING: {zeros}/{total} entries have skill level 0.")
        print("  Skill data may be unreliable for this build.")

    # Verify against known data points.
    verify_known_reagents(reagent_data)

    # Chains: what each reagent is turned into, and where that is used.
    products = parse_spell_products(tables["SpellEffect"])
    chains = build_chains(spell_reagents, abilities, prof_names, products)
    print(f"  {len(chains)} reagents with downstream uses")
    chains_path = os.path.join(os.path.dirname(os.path.abspath(args.output)), "reagent_chains.lua")
    with open(chains_path, "w", encoding="utf-8") as fh:
        fh.write(generate_chains_lua(chains, build))
    print(f"Wrote {chains_path}")

    # Generate.
    print(f"\nWriting {args.output}...")
    lua = generate_lua(reagent_data, item_names, build)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as fh:
        fh.write(lua)
    print(f"Done. {total} items written.")


if __name__ == "__main__":
    main()