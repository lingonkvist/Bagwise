# Bagwise

Corner dots on your bag items that show what is safe to delete. Never deletes anything.

## The problem

Bags fill up with items you are not sure about. A quest item with no quest left. A reagent for a profession you do not have. Armor your class cannot wear. None of it is grey, so junk addons ignore it, and you hesitate to delete it yourself because nothing on the item tells you.

## What it does

Bagwise puts a small dot in the corner of an item when it has a clear answer.

| Dot | Meaning |
|---|---|
| Green | Safe to get rid of. The tooltip says whether to vendor it or delete it, and why. |
| Yellow | Worth a second look. |
| None | No signal. Bagwise does not know, or you still need the item. |

Hover an item and the tooltip explains the dot. On an item with no dot it names the quest that still needs the item, or the professions that use it.

You make every deletion yourself. Bagwise has no delete button, no auto-destroy and no popups.

## What gets a dot

Green:
- Quest items whose quests are all done.
- Reagents sold by vendors, for professions you do not have.
- Class reagents for other classes.
- Bound gear 20 or more levels below you (rare and better are at most yellow).
- White armor your class cannot wear, or cannot wear yet.
- White armor you have outgrown, because you wear green or better in that slot.
- Cheap gray items. Only the cheapest shows a dot, and deleting it lights the next.
- Trade goods that no recipe or quest uses.

Yellow:
- Bound gear 10 to 19 levels below you.
- Rare and better gear far below you.
- Unused trade goods that sell for a fair price.
- Anything you flag yourself.

## What never gets a dot

Anything that could still matter:
- Reagents used by a recipe, and spell reagents.
- Items a quest still needs, and items that start an open quest.
- Items a quest also asks for but that have other uses, such as Thieves' Tools.
- Profession tools, the Hearthstone and soul shards.
- Containers, gems, recipes, keys and ammo.
- Anything you right-click to open, such as clams and lockboxes.
- Consumables.
- Anything you have told Bagwise to keep.

## Making room for loot

When the loot window is open and your bags cannot hold everything:
- The cheapest junk in your bags gets a soft green glow around its slot.
- Every other dot goes quiet, so the glow is the only thing to act on.
- Loot worth less than your cheapest junk gets a green dot in the loot window.
- Deleting the glowing item moves the glow to the next cheapest.

Loot that joins a stack you already carry does not count as needing a slot. Quiver, ammo and profession bags are not counted as room.

## Commands

Everyday:
- `/bagwise keep [item]`: never show a dot on this item.
- `/bagwise flag [item]`: always show a yellow dot on this item.
- `/bagwise reset [item]`: return this item to the normal rules.
- `/bagwise list`: show your kept and flagged items.

`[item]` can be a shift-clicked link, an item ID or an item name.

Troubleshooting:
- `/bagwise report`: copyable report of your bags, verdicts and setup. Paste it into a bug report.
- `/bagwise why [item]`: why an item does or does not get a dot, and which protection applied.
- `/bagwise loot`: what the make-room plan sees. Run it with a loot window open.
- `/bagwise glow`: test the delete glow on your first item.
- `/bagwise status`: version, bag UI and counts.

## Compatibility

- Blizzard bags, Baganator and EllesmereUI Bags.
- WoW Forever and Classic Era (Interface 16001 and 11509).

## Reporting a bug

1. Run `/bagwise report` and copy the text.
2. If one item looks wrong, also run `/bagwise why [item]`.
3. If the glow is missing, run `/bagwise loot` with the loot window open.
4. Say which bag addon you use.

## Development

- Tests: `python3 -I tests/run_tests.py` (needs `lupa`).
- `src/verdict.lua` decides, and is pure. It never calls the game.
- `src/safety.lua` holds the protections. A rule can propose a green, and a protection can veto it.
- `src/scanner.lua` is the only module that reads the game and caches verdicts.
- `src/overlay.lua` paints dots and glows. `src/tooltip.lua` adds hover text.
- `src/makeroom.lua` plans which junk to delete for loot. It is pure.
- `tools/` regenerates the textures. Run `make_dot_textures.py` for the dots and glow and `make_icon.py` for the icon.
- Release: bump `## Version` in `Bagwise.toc`, tag, and let the packager build it.

## License

Bagwise is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This addon includes data derived from QuestieDB (https://github.com/Questie/QuestieDB), which is also licensed under the GPLv3.

Copyright (C) 2026 lingonkvist
