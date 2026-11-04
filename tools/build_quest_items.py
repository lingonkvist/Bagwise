#!/usr/bin/env python3
"""Generate data/quest_items.lua from Questie's classicQuestDB.lua.

Maps every item ID that any quest asks for (as an objective, a starter, or a
required-but-untracked source item) to the list of quest IDs that use it.
The addon can then ask the game for quest names at runtime.

No external dependencies -- uses only Python stdlib.

Usage:
    python3 tools/build_quest_items.py [--source path/to/classicQuestDB.lua]
                                       [--output data/quest_items.lua]

The source file is Questie's raw quest database, available at:
    https://github.com/Questie/QuestieDB
    data/Classic/classicQuestDB.lua

Questie data is GPL-3.0.  The generated file carries that license forward.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import textwrap
from collections import defaultdict
from pathlib import Path


# ---------------------------------------------------------------------------
# Questie quest-data field indices (1-based, matching Lua)
# ---------------------------------------------------------------------------
STARTED_BY = 2        # table: {creatureStart, objectStart, itemStart}
ITEM_START = 3        # sub-index within startedBy

OBJECTIVES = 10       # table: {creature, object, item, reputation, ...}
ITEM_OBJECTIVE = 3    # sub-index within objectives

SOURCE_ITEM_ID = 11   # int: item provided by quest giver
REQUIRED_SOURCE_ITEMS = 21  # table: {itemID, ...}

QUEST_NAME = 1


# ---------------------------------------------------------------------------
# Lua text parser (stdlib only)
# ---------------------------------------------------------------------------

def split_top_level(s: str) -> list[str]:
    """Split a string on commas at brace-depth 0, respecting strings.

    Given the interior of a Lua table (without the outer braces),
    returns a list of the top-level fields as raw strings.
    """
    fields: list[str] = []
    depth = 0
    in_string = False
    escape = False
    start = 0

    for i, ch in enumerate(s):
        if escape:
            escape = False
            continue
        if ch == '\\' and in_string:
            escape = True
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        elif ch == ',' and depth == 0:
            fields.append(s[start:i].strip())
            start = i + 1

    # Last field (no trailing comma, or empty trailing)
    tail = s[start:].strip()
    if tail:
        fields.append(tail)

    return fields


def parse_int(s: str) -> int | None:
    """Parse a bare integer from a field string, or None if nil/table/string."""
    s = s.strip()
    if s == 'nil' or s == '' or s.startswith('{') or s.startswith('"'):
        return None
    try:
        return int(s)
    except ValueError:
        # Could be a float like 1.0 from Lua
        try:
            return int(float(s))
        except ValueError:
            return None


def extract_ints_flat(s: str) -> list[int]:
    """Extract all bare integers from a Lua table string.

    Works for simple cases like {18}, {6383}, {itemID, itemID, ...}.
    Skips nested structure -- just grabs numbers at any depth.
    """
    return [int(m) for m in re.findall(r'\b(\d+)\b', s)]


def parse_quest_name(s: str) -> str | None:
    """Extract the string value from a quoted Lua string field."""
    m = re.match(r'^"((?:[^"\\]|\\.)*)"$', s.strip())
    if m:
        return m.group(1).replace('\\"', '"').replace('\\\\', '\\')
    return None


def get_sub_field(field_str: str, sub_index: int) -> str | None:
    """Given a field that is itself a table, return its Nth sub-field (1-based)."""
    field_str = field_str.strip()
    if not field_str.startswith('{') or not field_str.endswith('}'):
        return None
    inner = field_str[1:-1].strip()
    if not inner:
        return None
    subs = split_top_level(inner)
    if sub_index <= len(subs):
        return subs[sub_index - 1]
    return None


def extract_item_objectives(obj_field: str) -> list[int]:
    """Extract item IDs from the objectives.itemObjective field.

    The item objective sub-field (index 3 within objectives) looks like:
        {{itemID, "text", iconFile}, {itemID, "text", iconFile}, ...}
    Each entry's first element is the item ID.
    """
    if not obj_field or obj_field.strip() == 'nil':
        return []
    obj_field = obj_field.strip()
    if not obj_field.startswith('{') or not obj_field.endswith('}'):
        return []
    inner = obj_field[1:-1].strip()
    if not inner:
        return []

    # Each entry is a sub-table {itemID, ...}
    entries = split_top_level(inner)
    item_ids = []
    for entry in entries:
        entry = entry.strip()
        if entry == 'nil' or not entry.startswith('{'):
            continue
        # Get the first field of this sub-table
        entry_inner = entry[1:-1].strip() if entry.endswith('}') else ''
        if entry_inner:
            first = split_top_level(entry_inner)[0] if entry_inner else None
            if first:
                val = parse_int(first)
                if val and val > 0:
                    item_ids.append(val)
    return item_ids


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

# Matches one quest line: [questID] = {<fields>},
QUEST_LINE_RE = re.compile(r'^\[(\d+)\]\s*=\s*\{(.+)\},?\s*$')


def parse_quests(source_path: Path) -> tuple[dict[int, list[str]], dict[int, str]]:
    """Parse classicQuestDB.lua and return (quest_id -> fields[], quest_id -> name).

    Each quest is one line: [id] = {field1, field2, ...},
    We split into top-level fields and return them as raw strings for
    targeted extraction.
    """
    text = source_path.read_text(encoding='utf-8')

    # Find the data block inside [[return { ... }]]
    match = re.search(r'\.questData\s*=\s*\[\[return\s*\{(.*)\}\s*\]\]', text, re.S)
    if not match:
        print(f"Error: could not find questData in {source_path}", file=sys.stderr)
        sys.exit(1)

    data_block = match.group(1)

    quests: dict[int, list[str]] = {}
    quest_names: dict[int, str] = {}

    for line in data_block.splitlines():
        line = line.strip()
        m = QUEST_LINE_RE.match(line)
        if not m:
            continue

        quest_id = int(m.group(1))
        fields_str = m.group(2)
        fields = split_top_level(fields_str)
        quests[quest_id] = fields

        # Extract quest name (field 1)
        if fields:
            name = parse_quest_name(fields[0])
            if name:
                quest_names[quest_id] = name

    return quests, quest_names


def extract_item_quests(quests: dict[int, list[str]]) -> dict[int, set[int]]:
    """Walk every quest and collect item -> {questIDs} mappings."""
    item_quests: dict[int, set[int]] = defaultdict(set)

    for quest_id, fields in quests.items():
        # Helper: safely get a 1-based field
        def field(idx: int) -> str | None:
            if idx <= len(fields):
                f = fields[idx - 1].strip()
                return None if f == 'nil' else f
            return None

        # 1. Items that start the quest (startedBy.itemStart, index 2[3])
        started_by = field(STARTED_BY)
        if started_by:
            item_start = get_sub_field(started_by, ITEM_START)
            if item_start and item_start != 'nil':
                for item_id in extract_ints_flat(item_start):
                    if item_id > 0:
                        item_quests[item_id].add(quest_id)

        # 2. Item objectives (objectives.itemObjective, index 10[3])
        objectives = field(OBJECTIVES)
        if objectives:
            item_obj_field = get_sub_field(objectives, ITEM_OBJECTIVE)
            if item_obj_field and item_obj_field != 'nil':
                for item_id in extract_item_objectives(item_obj_field):
                    item_quests[item_id].add(quest_id)

        # 3. Source item provided by quest giver (index 11)
        source_item_str = field(SOURCE_ITEM_ID)
        if source_item_str:
            source_item = parse_int(source_item_str)
            if source_item and source_item > 0:
                item_quests[source_item].add(quest_id)

        # 4. Required source items (index 21) -- needed but not objectives
        req_sources = field(REQUIRED_SOURCE_ITEMS)
        if req_sources and req_sources.startswith('{'):
            for item_id in extract_ints_flat(req_sources):
                if item_id > 0:
                    item_quests[item_id].add(quest_id)

    return item_quests


# ---------------------------------------------------------------------------
# Lua output
# ---------------------------------------------------------------------------

def make_header(count: int, quest_count: int) -> str:
    return textwrap.dedent("""\
        -- Generated by tools/build_quest_items.py from Questie's classicQuestDB.lua.
        -- Questie data is licensed under GPL-3.0.  See COPYING and source/ATTRIBUTION.md.
        --
        -- Maps item IDs to the quest IDs that use them (as objectives, starters,
        -- or required source items).  Quest names and details are looked up at
        -- runtime via the WoW API.
        --
        -- %d items across %d quests.

        Bagwise = Bagwise or {}
        Bagwise.Data = Bagwise.Data or {}

        Bagwise.Data.QuestItems = {
    """) % (count, quest_count)


FOOTER = "}\n"


def format_lua(item_quests: dict[int, set[int]],
               quest_names: dict[int, str]) -> str:
    """Format the item->questIDs map as a Lua table."""
    quest_count = len({qid for qids in item_quests.values() for qid in qids})

    lines = [make_header(len(item_quests), quest_count)]

    for item_id in sorted(item_quests):
        quest_ids = sorted(item_quests[item_id])
        quest_list = ", ".join(str(qid) for qid in quest_ids)

        # Add quest names as a comment for readability
        names = []
        for qid in quest_ids[:3]:  # Cap comment at 3 quest names
            name = quest_names.get(qid)
            if name:
                names.append(name)
        if len(quest_ids) > 3:
            names.append(f"+{len(quest_ids) - 3} more")
        comment = " -- " + "; ".join(names) if names else ""

        lines.append(f"    [{item_id}] = {{ {quest_list} }},{comment}")

    lines.append(FOOTER)
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Spot checks
# ---------------------------------------------------------------------------

SPOT_CHECKS = [
    # (item_id, item_name, should_have_quests)
    (2589, "Linen Cloth", True),       # Lots of quests ask for this
    (4306, "Silk Cloth", True),         # A Donation of Silk, etc.
    (12359, "Thorium Bar", True),       # Various high-level quests
    (6948, "Hearthstone", False),       # Not a quest item
    (159, "Refreshing Spring Water", True),  # Quest 16: Give Gerard a Drink
]


def run_spot_checks(item_quests: dict[int, set[int]]) -> None:
    """Verify a few known items against expectations."""
    print("\nSpot checks:")
    passed = 0
    for item_id, name, should_have in SPOT_CHECKS:
        has_quests = item_id in item_quests
        ok = has_quests == should_have
        count = len(item_quests.get(item_id, set()))
        status = "OK" if ok else "FAIL"
        detail = f"{count} quests" if has_quests else "none"
        print(f"  [{status}] {name} ({item_id}): {detail}")
        if ok:
            passed += 1
    print(f"  {passed}/{len(SPOT_CHECKS)} passed")
    if passed < len(SPOT_CHECKS):
        print("  WARNING: some spot checks failed", file=sys.stderr)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate quest_items.lua from Questie's classicQuestDB.lua"
    )
    parser.add_argument(
        "--source",
        default=None,
        help="Path to classicQuestDB.lua (default: source/classicQuestDB.lua "
             "relative to this script's parent directory)",
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Output path (default: data/quest_items.lua relative to the "
             "project root)",
    )
    args = parser.parse_args()

    # Resolve paths
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent

    if args.source:
        source_path = Path(args.source)
    else:
        source_path = script_dir / "source" / "classicQuestDB.lua"

    if args.output:
        output_path = Path(args.output)
    else:
        output_path = project_root / "data" / "quest_items.lua"

    if not source_path.exists():
        print(f"Error: source file not found: {source_path}", file=sys.stderr)
        print(f"\nPlace Questie's classicQuestDB.lua at:\n  {source_path}")
        print(f"\nOr specify a path with --source")
        sys.exit(1)

    # Parse
    print(f"Reading {source_path.name}...")
    quests, quest_names = parse_quests(source_path)
    print(f"  Parsed {len(quests)} quests")

    # Extract
    print("Extracting item-quest relationships...")
    item_quests = extract_item_quests(quests)

    print(f"  {len(item_quests)} items referenced by quests")
    unique_quests = len({qid for qids in item_quests.values() for qid in qids})
    print(f"  {unique_quests} quests reference items")

    # Spot checks
    run_spot_checks(item_quests)

    # Write
    lua_output = format_lua(item_quests, quest_names)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(lua_output, encoding="utf-8")
    print(f"\nWrote {output_path}")
    print(f"  {os.path.getsize(output_path):,} bytes")


if __name__ == "__main__":
    main()