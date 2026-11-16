-- Items the game data cannot tell us are in use.
--
-- Hand-kept. Each entry is an item with a real use that no recipe, quest or
-- reagent table records: new Forever mechanics, camp objects and the like.
-- Safety never lets a rule call these safe to delete, and the tooltip shows
-- the note so the dot's silence is explained. Add an entry when the trade
-- goods audit (tools/audit_trade_goods.py) turns up something that is used.

MakeSpace      = MakeSpace or {}
MakeSpace.Data = MakeSpace.Data or {}

MakeSpace.Data.ProtectedItems = {
  -- Herbalism camp items (Forever): the Greenhouse (Herbalism 140) grows herbs
  -- from seeds, the Seed Hybridizer (Herbalism 300) combines seeds into the
  -- next tier. Both are placed beside a campfire.
  [268415] = "Plant in a Greenhouse, or combine in a Seed Hybridizer", -- Commonplace Herb Seeds
  [268416] = "Plant in a Greenhouse, or combine in a Seed Hybridizer", -- Uncommon Herb Seeds
  [268417] = "Plant in a Greenhouse, or combine in a Seed Hybridizer", -- Unusual Herb Seeds
  [268418] = "Plant in a Herbalism Greenhouse (camp item)", -- Scarce Herb Seeds
  -- Keys: a quest reward that does a job. Deleting it means going back for it.
  [9173] = "Needed to use the Gnomeregan teleporter in Booty Bay", -- Goblin Transponder
  -- Forever secrets and the like, from a community-researched list.
  -- The rules would call some of these safe (a level 15 sword at level 60, or a
  -- gray key), so each is held back and the tooltip says what it is. Where an
  -- item is not listed, its purpose was not confirmed.
  [276561] = "Secret: use in Ambermill Town Hall", -- Black Tome
  [275989] = "Secret: use at the rune in City of Dalaran", -- Tome of Dalaran
  [276188] = "Part of the Dawn Waker secret", -- Eluvi'ana
  [282315] = "Part of the Dawn Waker secret", -- Ancient Hilt
  [272313] = "Part of the Dawn Waker secret", -- Ancient Hilt (quest item)
  [282337] = "Part of the Dawn Waker secret", -- Befouled Water Globe
  [16408] = "Part of the Dawn Waker secret", -- Befouled Water Globe (older ID)
  [282699] = "Part of the Dawn Waker secret", -- Cleansed Water Globe
  [282406] = "Opens Narassin's Strongbox (Dawn Waker secret)", -- Azsharan Key
  [282404] = "Part of the Dawn Waker secret", -- Narassin's Tome
  [282548] = "Cleansing reagent, Dawn Waker secret", -- Star of Elune
  [282547] = "Cleansing reagent, Dawn Waker secret", -- Abyssal Mote
  [282431] = "Cleansing reagent, Dawn Waker secret", -- Tears of Anguish
  [211527] = "Unroll outdoors for bonus rested XP", -- Cozy Sleeping Bag
  [216619] = "Restores lost rest time when used", -- Student Fodder
  [281350] = "Part of an unsolved Forever secret", -- Keystone Fragment
  [284092] = "Part of an unsolved Forever secret", -- Keystone Fragment
  [284093] = "Part of an unsolved Forever secret", -- Keystone Fragment
  [281358] = "Part of an unsolved Forever secret", -- Stone Key
  [271745] = "Part of an unsolved Horde secret", -- Bloody Map
  -- Found by the trade goods audit
  [11099] = "Smelts into Dark Iron Bars at the Black Forge", -- Dark Iron Ore
  [273295] = "Forever seasonal item, use unknown", -- Seasonal Fish Steaks
}
