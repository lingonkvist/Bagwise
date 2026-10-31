-- Items consumed by class-specific spells and abilities.
--
-- Maps itemID to:
--   classes  -- set of class tokens that use this item
--   name     -- display name for reason strings
--   verdict  -- "green" for cheap vendor-sold reagents (safe to delete),
--               "yellow" for world-drop reagents (may have AH value)
--
-- The verdict rule fires when the player's class is NOT in the set.
-- Items whose class matches the player produce no signal (nil).
--
-- Coverage: Classic Era (1.12 / Interface 11507-11509).
-- TBC and WotLK reagents (Flintweed Seed, Wild Quillvine, Wild Spineleaf,
-- Starleaf Seed, Devout Candle) are omitted. Add them when Forever ships
-- with a higher interface version.
--
-- Soul Shard (6265) is omitted: soulbound, created by Drain Soul, a
-- non-warlock can never have one.

Bagwise.Data = Bagwise.Data or {}

Bagwise.Data.ClassReagents = {

  -- Mage (all vendor-sold)
  [17020] = { classes = { MAGE = true }, name = "Arcane Powder", verdict = "green" },
  [17031] = { classes = { MAGE = true }, name = "Rune of Teleportation", verdict = "green" },
  [17032] = { classes = { MAGE = true }, name = "Rune of Portals", verdict = "green" },

  -- Mage and Priest: Light Feather drops from harpies, birds, hippogryphs
  [17056] = { classes = { MAGE = true, PRIEST = true }, name = "Light Feather", verdict = "yellow" },

  -- Priest (vendor-sold)
  [17028] = { classes = { PRIEST = true }, name = "Holy Candle", verdict = "green" },
  [17029] = { classes = { PRIEST = true }, name = "Sacred Candle", verdict = "green" },

  -- Paladin (vendor-sold)
  [17033] = { classes = { PALADIN = true }, name = "Symbol of Divinity", verdict = "green" },
  [21177] = { classes = { PALADIN = true }, name = "Symbol of Kings", verdict = "green" },

  -- Shaman: Ankh is vendor-sold; Fish Scales and Fish Oil drop from mobs
  [17030] = { classes = { SHAMAN = true }, name = "Ankh", verdict = "green" },
  [17057] = { classes = { SHAMAN = true }, name = "Shiny Fish Scales", verdict = "yellow" },
  [17058] = { classes = { SHAMAN = true }, name = "Fish Oil", verdict = "yellow" },

  -- Druid: Rebirth seeds (all vendor-sold)
  [17034] = { classes = { DRUID = true }, name = "Maple Seed", verdict = "green" },
  [17035] = { classes = { DRUID = true }, name = "Stranglethorn Seed", verdict = "green" },
  [17036] = { classes = { DRUID = true }, name = "Ashwood Seed", verdict = "green" },
  [17037] = { classes = { DRUID = true }, name = "Hornbeam Seed", verdict = "green" },
  [17038] = { classes = { DRUID = true }, name = "Ironwood Seed", verdict = "green" },

  -- Druid: Gift of the Wild (vendor-sold)
  [17021] = { classes = { DRUID = true }, name = "Wild Berries", verdict = "green" },
  [17026] = { classes = { DRUID = true }, name = "Wild Thornroot", verdict = "green" },

  -- Warlock (vendor-sold)
  [5565]  = { classes = { WARLOCK = true }, name = "Infernal Stone", verdict = "green" },
  [16583] = { classes = { WARLOCK = true }, name = "Demonic Figurine", verdict = "green" },

  -- Rogue: Flash Powder is vendor-sold; Blinding Powder is crafted/pickpocketed
  [5140]  = { classes = { ROGUE = true }, name = "Flash Powder", verdict = "green" },
  [5530]  = { classes = { ROGUE = true }, name = "Blinding Powder", verdict = "yellow" },
}
