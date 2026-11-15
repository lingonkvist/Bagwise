# Make Space

Debloat your bags. Colored dots on your bag items that show what to delete, vendor, bank or keep. Never deletes anything.

## The problem

Bags fill up with items you are not sure about. A quest item with no quest left. A reagent for a profession you do not have. Armor your class cannot wear. A green you could sell, but is it worth a trip to the auction house? None of it is gray, so junk addons ignore it, and nothing on the item tells you what to do.

## What it does

Make Space checks every item against your quests, professions, class, level and what it sells for, and puts a small dot in the corner when it has a clear answer.

| Dot | Meaning |
|---|---|
| Green (round) | Safe to delete, or safe to vendor when it has a sell price. The tooltip says which, and why. |
| Yellow (diamond) | Worth a glance. The tooltip says what to look at. |
| None | No signal. Make Space does not know, or you still need the item. |

Hover an item and the tooltip explains the dot. On an item with no dot it names the quest that still needs the item, or the professions that use it. Prices show the numbers in white and `g`, `s` and `c` in the usual coin colours.

You make every deletion yourself. Make Space has no delete button, no auto-destroy and no popups.

## What gets a dot

Green:
- Quest items whose quests are all done.
- Reagents sold by vendors, for professions you do not have.
- Class reagents for other classes.
- Bound gear 20 or more levels below you (rare and better are at most yellow). Gear with a Use effect, an on-hit proc or a special Equip effect (trinkets, rocket boots, speed procs) is left alone, since it is worth keeping for what it does.
- White armor your class cannot wear, or cannot wear yet.
- White weapons of a type your class can never learn (a priest with an axe), and arrows or bullets for a class with no bow, crossbow or gun. This comes from the game's own skill data for Forever, so it follows its differences (rogues use axes there). A pricey one is still held back by the auction check.
- White armor you have outgrown, because you wear green or better in that slot.
- Cheap gray items. Only the cheapest shows a dot, and deleting it lights the next.
- Trade goods that no recipe or quest uses.
- Recipes and reagents for professions you do not have, and reagents you have outleveled, when the price is known, the auction pays too little to list, and the whole slot is worth under 50c (5c per level above level 10). The tooltip shows the price line under "Safe to vendor", or says "Worth very little" when there is no price line. A missing price never counts: an item nobody lists may be rare.
- Tradable green gear (not for Enchanters) that auctions for about what a vendor pays. The tooltip says "Safe to vendor" and shows both prices, for example `Vendor 1s 92c, auction up to 3s`.

A tradable green loses its dot when the auction pays clearly more than a vendor (finished quest items, unused trade goods, vendor and class reagents, white gear you cannot use). The tooltip then says why in one blue line, for example `Vendor 5c, auction up to 8s`, so a missing dot is not a mystery.

Yellow:
- Bound gear 10 to 19 levels below you.
- Rare and better gear far below you.
- Unused trade goods that sell for a fair price.
- A gray that is worth some silver (the cheapest one only).
- Things you open: clams and bags of loot, and lockboxes for a rogue who has learned Pick Lock. Nobody else gets the hint on a lockbox, since they cannot open it. The list of locked items is `data/locked_items.lua` (`tools/build_locked_items.py`).
- Recipes for a profession you do not have (unbound ones only). "Try the auction house" shows only while the price does not say otherwise, with the prices shown when it pays.
- "Bank it" for recipes and reagents far above your skill. A recipe is far above you when it needs more than 25 skill points. A reagent needs more than 50, or more than 25 once you have stopped leveling that profession for 6 hours. A profession counts as idle after 12 hours without a skill gain (and a new play session), and then any recipe out of reach is banked.
- "Bank it" for a reagent when your skill is past one of its uses and the next one is far ahead, since every use is judged on its own (Linen Cloth with First Aid done and Blacksmithing 200 far off).
- A reagent stack worth under the same 50c bar gets no bank hint, since banking it is only clutter. It needs a known price.
- Reagents you have outleveled. Make Space follows the whole chain, so copper bars stay safe while bronze or a later recipe still uses them. The hint appears once the last recipe that needs the item, directly or through what it is turned into, has turned green (the skill-up chance is then under half), and the tooltip says "Recipes turn green at Profession N", the skill where the color changes in your profession window. Data built before 0.6.1 uses the skill the best recipe is learned at instead. An open quest that wants the item holds the hint back, unless that quest is 10 or more levels below you (the same goes for the hint on reagents only other professions use).
- Food, drink, potions, elixirs, flasks and stat scrolls (Strength, Agility, Stamina, Intellect, Spirit, Protection) that need a level 20 or more below yours. Elixirs and flasks count only when they give stats, health or mana, so water breathing, speed and the like are left alone, and so is anything whose tooltip carries its own level limit ("cannot be used above level 20", "cures diseases up to level 25"). Food with an effect is left alone, and Enchanters keep scrolls that are Enchanting reagents. When the auction house pays clearly more than a vendor for one of these, the tooltip adds the price line (for example `Vendor 5c, auction about 8s`), so the hint never reads as "throw it away".
- Bandages that heal under 15% of your health. The tooltip says what it heals, for example `Heals 9% of your health (400 of 4500)`. Without that to go on, a bandage follows its required level like other consumables.
- Mana potions and drinks, if your class has no mana.
- Crafting materials that drop (no vendor sells them) and that none of your professions use. It waits until both primary profession slots are taken, and stays quiet for anything Cooking, First Aid or Fishing uses (anyone can learn those) and for characters with only gathering professions. The tooltip shows the vendor and auction prices when there is one on file. The bank does not show it.
- Library books, with who to hand them in to (Garion Wendell in Stormwind, Owen Thadd in Undercity). A deleted book cannot be looted again.
- Blood Shards on a Horde character: trade 4 to Mangletooth for a buff.
- Quest items for a quest far below your level, and a hint to bank items that only quests you cannot accept for another 10 levels or more want. It goes by the level you need to accept the quest, not the quest's own level, so a level 60 quest that opens at level 30 is left alone, and so is any quest without data. Items for a Darkmoon Faire or holiday quest get the same hint at any level, naming the event (`Darkmoon Faire: [60] Vibrant Plumes`), since those quests can only be done while the event runs. Make Space cannot see whether the event is on. Neither shows while the quest is in your log, and the bank does not show the second. Repeatable quests do not count, since they want the item at any level.
- Anything you flag yourself.

## Auction prices

Make Space ships with auction price data for Forever, so it can tell vendor trash from gear that is worth listing. It never reads the auction house in game and never needs a scan.

- Prices come from the Blizzard auction API and are kept per region and faction. A Horde player on EU is judged by EU Horde listings only, never by US or Alliance ones. The price used is the cheap end of each auction house (the 25th percentile), since the cheapest listings sell first, and the middle of the houses in your market, so one odd listing or house does not move it. Gear with random versions is judged by its own version, nearer the pricey end.
- If Make Space cannot tell your region or faction, tradable items get no green at all.
- Ordinary auctions and commodities (stackable materials) are both read. Items that sell for more than the price cap get no price but are marked as above it, so "worth a lot" is told apart from "nobody lists it".
- Enchanters are never told to vendor green gear, since it can be disenchanted.
- Versions the price build saw too few times to price are remembered in `tools/variant_memory.json` between runs, so a few weekly runs can add up to enough (8 listings in 2 houses, each auction counted once). Anything not seen for 6 weeks is forgotten, and a market holds at most 5000 remembered listings, oldest first out (within a day, the versions closest to qualifying stay). The file is committed with the weekly pull request and is not shipped in the addon.
- The price data goes stale: after 14 days a tradeable item gets no green that rests on it, so a player who has not updated the addon gets silence instead of confident wrong greens. Items that cannot be sold at auction, and items with a fresh Auctionator price, are unaffected. From day 8 the login message says how many days are left to update, and `/makespace status` shows the age.
- Gear with random suffixes (of the Eagle, of the Whale) is priced per version. A version with no price of its own is judged on the dearest of the versions that have one, as long as at least 3 are listed, so it only gets a dot when even the dearest version would. With fewer, it gets no dot.
- The auction is worth a trip when 95% of its price (after the cut) clears the vendor price by a margin: a share of the vendor price, big for cheap items and small for dear ones, plus 1s for the trip. The limit rises smoothly with the vendor price, so there are no cliffs. Above it, the green is held back.
- A live Auctionator price is taken as it is. The shipped snapshot is read as 10 to 15% higher, since another realm can cost more (measured on the data: one item in four is that much dearer somewhere else), and a little more for every day beyond a week since it was read.
- Stackables, gear and the rest (bags, recipes, quest items) are configured separately in `src/curves.lua`, and one function decides which an item is. A stack shares the trip across 20 units, stackables are trimmed of lone high listings harder than the rest, and the thin markets of the rest are read as less certain than gear.
- The snapshot builder counts listings in units, so a lone 1-unit listing at ten times the price never moves the price next to stacks of 200. It drops listings above 2x (commodities) or 3x (ordinary auctions) the median.
- The price line on the reagent and recipe hints (outleveled, and used only by professions you don't have) shows only when the auction is worth it: at least 50c an item and clearly above what the sell check allows over a vendor. Otherwise the line is left out and the hint stops saying "May sell at the auction house". With no price data the hint stays as it is.
- If you also run Auctionator, Make Space uses it for live prices. An item Auctionator saw at the auction house in the last 3 days is judged on that price, and the tooltip says "auction about 8s" where the snapshot says "auction up to 8s". Live prices only come in through Auctionator's public API, and every other check (safety, upgrades, Enchanting) still applies. They also reach further than the snapshot:
  - Gear you can still sell (not soulbound) can get "Safe to vendor" at blue quality too, not just green, never epic.
  - Items the snapshot has no price for, or has no price for your region and faction, can still be judged.
  - Auctionator records the lowest listing, so one cheap listing can make an item look worth less than it is. A live price far below the snapshot (under half of it) is ignored and the careful snapshot rules decide, unless the last days agree on it (two or more days within a quarter of each other): prices differ between realms, and a price several days agree on is not a one-off lowball. `/makespace why` says when that happens.
  - The price Auctionator shows is its last reading, and for busy items it swings by half from one scan to the next. Make Space reads Auctionator's recorded daily history too and judges on the typical reading of the last 3 days: the median of the current price and each day's lowest and highest reading, with hopeful highs left out first (a reading above 2x the median for stackables, 3x for the rest is one lone listing after the cheap ones sold out). A lone overpriced listing therefore never lifts the price, and with fewer than three readings the lowest is used. Auctionator does not give listing sizes, so live prices are per unit as it reports them. If the history cannot be read, the shown price is used.
  - Auctionator files all versions of a random-suffix item (of the Eagle, of the Whale) under one key, so its price is the cheapest version's. For items whose link carries a version, Make Space lets it lower the snapshot's price only to 60% of it (the snapshot is the pricey end of that version), and uses it for nothing when the snapshot has no price for the item.
  - Auctionator keeps the last price it saw until the item is seen again, and it can file a price under the wrong item. So a live price must belong to exactly this item, and when the snapshot has no price to compare against it must have been seen today or yesterday, not 3 days ago.
  - A price 4 to 14 days old is too old to judge by, but a clearly low one still takes the "May sell at the auction house" suffix off a hint, and its price is shown ("auction about 26c") instead of the snapshot's. A small stack of such an item reads green "Worth very little", with the old price raised for its age. The loss is capped by the worth-little bar either way.
  - Without Auctionator, or for items it has not seen lately, nothing changes.
- The data is refreshed with each release. `tools/build_auction_prices.py` rebuilds it, one file per region and faction (`data/auction_prices_eu_horde.lua` and so on, because the packager skips any file over 500 KB; the build prints each size and flags one near the limit), and a weekly workflow opens a pull request with new prices.

## What never gets a dot

Anything that could still matter:
- Reagents used by a recipe, and spell reagents, apart from the hints above.
- Items a quest still needs, and items that start an open quest.
- Items a quest also asks for but that have other uses, such as Thieves' Tools.
- Profession tools, the Hearthstone and soul shards.
- Containers, gems, keys and ammo your class can use. Recipes are yellow, and green only as "Worth very little".
- Consumables, other than the yellow cases above.
- Anything you have told Make Space to keep.

## Item links in chat

Click an item link in chat and the pop-out tooltip gets the general blue info: what a crafting item is used for and which quests need it. There is no verdict, since it is not your item.

## In the bank

Dots work in the bank and the warband bank too. People bank things on purpose, so a verdict only stays as it is when it holds for any character. Anything that depends on your professions, class or quests is at most yellow, "Bank it" hints are dropped because the item is already there, and vendor suggestions are not shown.

## Making room for loot

When the loot window is open and your bags cannot hold everything:
- The cheapest junk in your bags gets a soft green glow around its slot.
- Every other dot goes quiet, so the glow is the only thing to act on.
- Loot worth less than your cheapest junk gets a red X in the loot window, and its tooltip says "Skip it".
- Loot worth a slot gets a green check, and its tooltip says "Take it". That includes quest items and loot you must make room for by hand. Reagents are weighed by what they sell for (vendor or auction), so a cheap or outleveled reagent never pushes out a gray that is worth more.
- Deleting the glowing item moves the glow to the next cheapest.

Loot that joins a stack you already carry does not count as needing a slot. Quiver, ammo and profession bags are not counted as room.

## Commands

`/makespace`, `/ms` and `/bagwise` do the same thing. The examples below use `/makespace`.

Everyday:
- `/makespace keep [item]`: never show a dot on this item.
- `/makespace flag [item]`: always show a yellow dot on this item.
- `/makespace reset [item]`: return this item to the normal rules.
- `/makespace list`: show your kept and flagged items.
- `/makespace summary`: what the dots in your bags add up to, for example `9 green (2g 14s at a vendor), 5 yellow`. Make Space also says this when you level up, if anything is marked.

`[item]` can be a shift-clicked link, an item ID or an item name.

Troubleshooting:
- `/makespace report`: copyable report of your bags, verdicts and setup. Paste it into a bug report.
- `/makespace why [item]`: why an item does or does not get a dot, and which protection applied.
- `/makespace loot`: what the make-room plan sees. Run it with a loot window open.
- `/makespace glow`: test the delete glow on your first item.
- `/makespace status`: version, bag UI and counts.
- `/makespace bank`: what Make Space sees of the bank.

## Compatibility

- Blizzard bags and bank, Baganator (with Syndicator), EllesmereUI Bags and Bagnon.
- WoW Forever (Interface 16001).

## Reporting a bug

1. Run `/makespace report` and copy the text.
2. If one item looks wrong, also run `/makespace why [item]`.
3. If the glow is missing, run `/makespace loot` with the loot window open.
4. Say which bag addon you use.

## Development

- Tests: `python3 -I tests/run_tests.py` (needs `lupa`). `node tools/check_globals.js` catches stray globals, and CI runs both.
- Data: `tools/build_auction_prices.py` (needs `BNET_CLIENT_ID` and `BNET_CLIENT_SECRET`) and `tools/build_reagent_professions.py` regenerate the files in `data/`. `tools/build_weapon_skills.py` builds which classes can use each weapon type (from the game's skill data), and `tools/build_locked_items.py` the list of locked items. Every tool has a `--selftest`. `tools/build_library_books.py` rebuilds the library book list from the quest data, and `tools/build_quest_availability.py --source <foreverQuestDB.lua>` when quests open and which events offer them (use the same Questie export as `build_quest_items.py`).
- `src/verdict.lua` decides, and is pure. It never calls the game. Callers use `Verdict.Judge`, which answers by name; `Evaluate` returns the same values by position.
- `src/auction.lua` joins the live price, the snapshot and the curves in `src/curves.lua` into one answer per item. A new price rule goes there, a new per-kind setting in `curves.lua`.
- `src/notes.lua` holds the words behind every yellow. `src/bank.lua` turns a verdict into what the bank shows.
- `src/safety.lua` holds the protections. A rule can propose a green, and a protection can veto it.
- `src/scanner.lua` is the only module that reads the game and caches verdicts.
- `src/overlay.lua` paints dots and glows. `src/tooltip.lua` adds hover text.
- `src/makeroom.lua` plans which junk to delete for loot. It is pure.
- `tools/` regenerates the textures. Run `make_dot_textures.py` for the dots and glow and `make_icon.py` for the icon.
- Release: bump `## Version` in `Bagwise.toc`, tag, and let the packager build it.

## License

Make Space is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This addon includes data derived from QuestieDB (https://github.com/Questie/QuestieDB), which is also licensed under the GPLv3.

Copyright (C) 2026 lingonkvist
