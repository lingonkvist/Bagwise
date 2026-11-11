# Bagwise

Colored dots on your bag items that show what to delete, vendor or keep. Never deletes anything.

## The problem

Bags fill up with items you are not sure about. A quest item with no quest left. A reagent for a profession you do not have. Armor your class cannot wear. A green you could sell, but is it worth a trip to the auction house? None of it is gray, so junk addons ignore it, and nothing on the item tells you what to do.

## What it does

Bagwise checks every item against your quests, professions, class, level and what it sells for, and puts a small dot in the corner when it has a clear answer.

| Dot | Meaning |
|---|---|
| Green | Safe to delete, or safe to vendor when it has a sell price. The tooltip says which, and why. |
| Yellow | Worth a second look. The tooltip says what to look at. |
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
- Tradable items that are otherwise green (finished quest items, unused trade goods, vendor and class reagents, white gear you cannot use) lose the dot when the auction pays clearly more than a vendor.
- When the auction check takes a green away, the tooltip says why in one blue line, for example `Vendor 5c, auction about 8s`, so a missing dot is not a mystery.
- Tradable green gear (not for Enchanters) that auctions for about what a vendor pays. The tooltip says "Safe to vendor" and shows both prices, for example `Vendor 1s 92c, auction about 3s`.

Yellow:
- Bound gear 10 to 19 levels below you.
- Rare and better gear far below you.
- Unused trade goods that sell for a fair price.
- A gray that is worth some silver (the cheapest one only).
- Things you open: clams, lockboxes and bags of loot.
- Recipes for a profession you do not have (unbound ones only), and recipes or reagents far above your skill ("Bank it").
- Reagents you have outleveled. Bagwise follows the whole chain, so copper bars stay safe while bronze or a later recipe still uses them. The hint appears as soon as you pass the best recipe that needs the item, directly or through what it is turned into.
- Food, drink, potions and bandages made for a much lower level. Food with an effect is left alone.
- Mana potions and drinks, if your class has no mana.
- Crafting materials that drop (no vendor sells them) and that none of your professions use. It waits until both primary profession slots are taken, and stays quiet for anything Cooking, First Aid or Fishing uses (anyone can learn those) and for characters with only gathering professions. The tooltip shows the vendor and auction prices when there is one on file. The bank does not show it.
- Library books, with who to hand them in to (Garion Wendell in Stormwind, Owen Thadd in Undercity). A deleted book cannot be looted again.
- Blood Shards on a Horde character: trade 4 to Mangletooth for a buff.
- Quest items for a quest far below your level, and a hint to bank items that only quests you cannot accept for another 10 levels or more want. It goes by the level you need to accept the quest, not the quest's own level, so a level 60 quest that opens at level 30 is left alone, and so is any quest without data. Items for a Darkmoon Faire or holiday quest get the same hint at any level, naming the event (`Darkmoon Faire: [60] Vibrant Plumes`), since those quests can only be done while the event runs. Bagwise cannot see whether the event is on. Neither shows while the quest is in your log, and the bank does not show the second. Repeatable quests do not count, since they want the item at any level.
- Anything you flag yourself.

## Auction prices

Bagwise ships with auction price data for Forever, so it can tell vendor trash from gear that is worth listing. It never reads the auction house in game and never needs a scan.

- Prices come from the Blizzard auction API and are kept per region and faction. A Horde player on EU is judged by EU Horde listings only, never by US or Alliance ones. The price used is the cheap end of each auction house (the 25th percentile), since the cheapest listings sell first, and the middle of the houses in your market, so one odd listing or house does not move it. Gear with random versions is judged by its own version, nearer the pricey end.
- If Bagwise cannot tell your region or faction, tradable items get no green at all.
- Ordinary auctions and commodities (stackable materials) are both read. Items that sell for more than the price cap get no price but are marked as above it, so "worth a lot" is told apart from "nobody lists it".
- Enchanters are never told to vendor green gear, since it can be disenchanted.
- Gear with random suffixes (of the Eagle, of the Whale) is priced per version. A version with no data gets no dot.
- The more an item is worth, the closer the auction price has to be to the vendor price before Bagwise says to vendor it. Cheap items give more room, since listing costs time and fees.
- A few copper never decide it, so both prices are rounded first, towards "just vendor it": the vendor price up to the next half silver (3s 24c counts as 3s 50c, 3s 70c as 4s) and the auction price down to whole silver (7s 78c counts as 7s). Tooltips still show the real prices.
- The data is refreshed with each release. `tools/build_auction_prices.py` rebuilds it, and a weekly workflow opens a pull request with new prices.

## What never gets a dot

Anything that could still matter:
- Reagents used by a recipe, and spell reagents.
- Items a quest still needs, and items that start an open quest.
- Items a quest also asks for but that have other uses, such as Thieves' Tools.
- Profession tools, the Hearthstone and soul shards.
- Containers, gems, recipes, keys and ammo (recipes can be yellow, never green).
- Consumables, other than the yellow cases above.
- Anything you have told Bagwise to keep.

## In the bank

Dots work in the bank and the warband bank too. People bank things on purpose, so a verdict only stays as it is when it holds for any character. Anything that depends on your professions, class or quests is at most yellow, "Bank it" hints are dropped because the item is already there, and vendor suggestions are not shown.

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

- Blizzard bags, Baganator (with Syndicator), EllesmereUI Bags and Bagnon.
- WoW Forever (Interface 16001).

## Reporting a bug

1. Run `/bagwise report` and copy the text.
2. If one item looks wrong, also run `/bagwise why [item]`.
3. If the glow is missing, run `/bagwise loot` with the loot window open.
4. Say which bag addon you use.

## Development

- Tests: `python3 -I tests/run_tests.py` (needs `lupa`). `node tools/check_globals.js` catches stray globals, and CI runs both.
- Data: `tools/build_auction_prices.py` (needs `BNET_CLIENT_ID` and `BNET_CLIENT_SECRET`) and `tools/build_reagent_professions.py` regenerate the files in `data/`. Both have a `--selftest`. `tools/build_library_books.py` rebuilds the library book list from the quest data, and `tools/build_quest_availability.py --source <foreverQuestDB.lua>` when quests open and which events offer them (use the same Questie export as `build_quest_items.py`).
- `src/verdict.lua` decides, and is pure. It never calls the game.
- `src/notes.lua` holds the words behind every yellow. `src/bank.lua` turns a verdict into what the bank shows.
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
