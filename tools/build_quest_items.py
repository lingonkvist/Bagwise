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
QUEST_NAME = 1
STARTED_BY = 2        # table: {creatureStart, objectStart, itemStart}
ITEM_START = 3        # sub-index within startedBy
QUEST_LEVEL = 5       # int: quest level (not reqLevel)

OBJECTIVES = 10       # table: {creature, object, item, reputation, ...}
ITEM_OBJECTIVE = 3    # sub-index within objectives

SOURCE_ITEM_ID = 11   # int: item provided by quest giver
ZONE_OR_SORT = 17     # int: positive = AreaID, negative = QuestSortID
REQUIRED_SOURCE_ITEMS = 21  # table: {itemID, ...}


# ---------------------------------------------------------------------------
# Classic Era AreaID -> zone name mapping (from AreaTable)
# Only positive zoneOrSort values are real zones; negative = QuestSort categories.
# ---------------------------------------------------------------------------
AREA_ID_TO_ZONE: dict[int, str] = {
    1: "Dun Morogh",
    3: "Badlands",
    4: "Blasted Lands",
    8: "Swamp of Sorrows",
    9: "Northshire Valley",
    10: "Duskwood",
    11: "Wetlands",
    12: "Elwynn Forest",
    14: "Durotar",
    15: "Dustwallow Marsh",
    16: "Azshara",
    17: "The Barrens",
    19: "Zul'Gurub",
    25: "Blackrock Mountain",
    28: "Western Plaguelands",
    33: "Stranglethorn Vale",
    35: "Booty Bay",
    36: "Alterac Mountains",
    38: "Loch Modan",
    40: "Westfall",
    44: "Redridge Mountains",
    45: "Arathi Highlands",
    46: "Burning Steppes",
    47: "The Hinterlands",
    51: "Searing Gorge",
    85: "Tirisfal Glades",
    130: "Silverpine Forest",
    132: "Coldridge Valley",
    133: "Gnomeregan",
    139: "Eastern Plaguelands",
    141: "Teldrassil",
    148: "Darkshore",
    154: "Deathknell",
    188: "Shadowglen",
    209: "Shadowfang Keep",
    215: "Mulgore",
    220: "Red Cloud Mesa",
    221: "Camp Narache",
    267: "Hillsbrad Foothills",
    331: "Ashenvale",
    357: "Feralas",
    361: "Felwood",
    363: "Valley of Trials",
    400: "Thousand Needles",
    405: "Desolace",
    406: "Stonetalon Mountains",
    440: "Tanaris",
    490: "Un'Goro Crater",
    493: "Moonglade",
    618: "Winterspring",
    702: "Rut'theran Village",
    717: "The Stockade",
    718: "Wailing Caverns",
    719: "Blackfathom Deeps",
    722: "Razorfen Downs",
    796: "Scarlet Monastery",
    978: "Zul'Farrak",
    1116: "Feathermoon Stronghold",
    1377: "Silithus",
    1417: "Sunken Temple",
    1497: "Undercity",
    1517: "Uldaman",
    1519: "Stormwind City",
    1537: "Ironforge",
    1581: "The Deadmines",
    1583: "Blackrock Spire",
    1584: "Blackrock Depths",
    1637: "Orgrimmar",
    1638: "Thunder Bluff",
    1657: "Darnassus",
    1717: "Razorfen Kraul",
    1769: "Timbermaw Hold",
    1977: "Zul'Gurub",
    2017: "Stratholme",
    2057: "Scholomance",
    2079: "Alcaz Island",
    2100: "Maraudon",
    2159: "Onyxia's Lair",
    2257: "Deeprun Tram",
    2437: "Ragefire Chasm",
    2557: "Dire Maul",
    2597: "Alterac Valley",
    2677: "Blackwing Lair",
    2717: "Molten Core",
    2839: "Alterac Valley",
    3277: "Warsong Gulch",
    3358: "Arathi Basin",
    3428: "Ahn'Qiraj",
    3429: "Ruins of Ahn'Qiraj",
    3456: "Naxxramas",
}


# ---------------------------------------------------------------------------
# Lua text parser (stdlib only)
# ---------------------------------------------------------------------------

def split_top_level(s: str) -> list[str]:
    """Split a string on commas at brace-depth 0, respecting strings."""
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
        try:
            return int(float(s))
        except ValueError:
            return None


def extract_ints_flat(s: str) -> list[int]:
    """Extract all bare integers from a Lua table string."""
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
    """Extract item IDs from the objectives.itemObjective field."""
    if not obj_field or obj_field.strip() == 'nil':
        return []
    obj_field = obj_field.strip()
    if not obj_field.startswith('{') or not obj_field.endswith('}'):
        return []
    inner = obj_field[1:-1].strip()
    if not inner:
        return []

    entries = split_top_level(inner)
    item_ids = []
    for entry in entries:
        entry = entry.strip()
        if entry == 'nil' or not entry.startswith('{'):
            continue
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

QUEST_LINE_RE = re.compile(r'^\[(\d+)\]\s*=\s*\{(.+)\},?\s*$')


class QuestMeta:
    __slots__ = ('name', 'level', 'zone')

    def __init__(self, name: str | None, level: int | None, zone: str | None):
        self.name = name
        self.level = level
        self.zone = zone


def parse_quests(source_path: Path) -> tuple[dict[int, list[str]], dict[int, QuestMeta]]:
    text = source_path.read_text(encoding='utf-8')

    match = re.search(r'\.questData\s*=\s*\[\[return\s*\{(.*)\}\s*\]\]', text, re.S)
    if not match:
        print(f"Error: could not find questData in {source_path}", file=sys.stderr)
        sys.exit(1)

    data_block = match.group(1)

    quests: dict[int, list[str]] = {}
    quest_meta: dict[int, QuestMeta] = {}

    for line in data_block.splitlines():
        line = line.strip()
        m = QUEST_LINE_RE.match(line)
        if not m:
            continue

        quest_id = int(m.group(1))
        fields_str = m.group(2)
        fields = split_top_level(fields_str)
        quests[quest_id] = fields

        name = None
        if fields:
            name = parse_quest_name(fields[0])

        level = None
        if len(fields) >= QUEST_LEVEL:
            level = parse_int(fields[QUEST_LEVEL - 1])

        zone = None
        if len(fields) >= ZONE_OR_SORT:
            zone_id = parse_int(fields[ZONE_OR_SORT - 1])
            if zone_id is not None and zone_id > 0:
                zone = AREA_ID_TO_ZONE.get(zone_id)

        quest_meta[quest_id] = QuestMeta(name, level, zone)

    return quests, quest_meta


def extract_item_quests(quests: dict[int, list[str]]) -> dict[int, set[int]]:
    item_quests: dict[int, set[int]] = defaultdict(set)

    for quest_id, fields in quests.items():
        def field(idx: int) -> str | None:
            if idx <= len(fields):
                f = fields[idx - 1].strip()
                return None if f == 'nil' else f
            return None

        started_by = field(STARTED_BY)
        if started_by:
            item_start = get_sub_field(started_by, ITEM_START)
            if item_start and item_start != 'nil':
                for item_id in extract_ints_flat(item_start):
                    if item_id > 0:
                        item_quests[item_id].add(quest_id)

        objectives = field(OBJECTIVES)
        if objectives:
            item_obj_field = get_sub_field(objectives, ITEM_OBJECTIVE)
            if item_obj_field and item_obj_field != 'nil':
                for item_id in extract_item_objectives(item_obj_field):
                    item_quests[item_id].add(quest_id)

        source_item_str = field(SOURCE_ITEM_ID)
        if source_item_str:
            source_item = parse_int(source_item_str)
            if source_item and source_item > 0:
                item_quests[source_item].add(quest_id)

        req_sources = field(REQUIRED_SOURCE_ITEMS)
        if req_sources and req_sources.startswith('{'):
            for item_id in extract_ints_flat(req_sources):
                if item_id > 0:
                    item_quests[item_id].add(quest_id)

    return item_quests


# ---------------------------------------------------------------------------
# Lua output
# ---------------------------------------------------------------------------

FOOTER = "}\n"


def format_lua(item_quests: dict[int, set[int]],
               quest_meta: dict[int, QuestMeta],
               source_filename: str = "classicQuestDB.lua") -> str:
    """Format the item->questIDs map and quest info as Lua tables."""
    quest_count = len({qid for qids in item_quests.values() for qid in qids})

    # Notice the 'f' prefix on the string, and the double braces {{ }} for Lua tables!
    lines = [textwrap.dedent(f"""\
        -- Generated by tools/build_quest_items.py from Questie's {source_filename}.
        -- Questie data is licensed under GPL-3.0.  See COPYING and source/ATTRIBUTION.md.
        --
        -- QuestItems: item ID -> {{questID, ...}}
        -- QuestInfo:  quest ID -> {{level, "zoneName"}} for tooltip display
        --
        -- {len(item_quests)} items across {quest_count} quests.

        Bagwise = Bagwise or {{}}
        Bagwise.Data = Bagwise.Data or {{}}

        Bagwise.Data.QuestItems = {{
    """)]

    for item_id in sorted(item_quests):
        quest_ids = sorted(item_quests[item_id])
        quest_list = ", ".join(str(qid) for qid in quest_ids)

        names = []
        for qid in quest_ids[:3]:
            meta = quest_meta.get(qid)
            if meta and meta.name:
                names.append(meta.name)
        if len(quest_ids) > 3:
            names.append(f"+{len(quest_ids) - 3} more")
        comment = " -- " + "; ".join(names) if names else ""

        lines.append(f"    [{item_id}] = {{ {quest_list} }},{comment}")

    lines.append(FOOTER)

    referenced_quests = sorted({qid for qids in item_quests.values() for qid in qids})
    info_count = 0

    lines.append("Bagwise.Data.QuestInfo = {")
    for qid in referenced_quests:
        meta = quest_meta.get(qid)
        if not meta:
            continue
        if meta.level is None and meta.zone is None and meta.name is None:
            continue
        level_str = str(meta.level) if meta.level is not None else "nil"
        zone_str = f'"{meta.zone}"' if meta.zone else "nil"
        escaped_name = meta.name.replace('\\', '\\\\').replace('"', '\\"') if meta.name else None
        name_str = f'"{escaped_name}"' if escaped_name else "nil"
        name_comment = f" -- {meta.name}" if meta.name else ""
        lines.append(f"    [{qid}] = {{ {level_str}, {zone_str}, {name_str} }},{name_comment}")
        info_count += 1

    lines.append(FOOTER)

    print(f"  {info_count} quests with level/zone info for QuestInfo")
    return "\n".join(lines)


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

    print(f"Reading {source_path.name}...")
    quests, quest_meta = parse_quests(source_path)
    print(f"  Parsed {len(quests)} quests")

    print("Extracting item-quest relationships...")
    item_quests = extract_item_quests(quests)

    print(f"  {len(item_quests)} items referenced by quests")
    unique_quests = len({qid for qids in item_quests.values() for qid in qids})
    print(f"  {unique_quests} quests reference items")

    # Passing the actual filename to the formatter here!
    lua_output = format_lua(item_quests, quest_meta, source_path.name)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(lua_output, encoding="utf-8")
    print(f"\nWrote {output_path}")
    print(f"  {os.path.getsize(output_path):,} bytes")


if __name__ == "__main__":
    main()