-- Bagwise: which classes can ever use each weapon type, and ammo.
-- A class missing from a list can never learn that skill, so gear of that
-- type is of no use to it. Read from SkillRaceClassInfo, not typed in.
-- Generated from wago.tools DB2 build 1.60.1.70938. Do not edit by hand.

Bagwise                      = Bagwise or {}
Bagwise.Data                 = Bagwise.Data or {}

-- Format: [item subclass of a weapon] = { CLASS = true, ... }
Bagwise.Data.WeaponClasses = {
  [0] = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, SHAMAN = true },
  [1] = { WARRIOR = true, PALADIN = true, HUNTER = true, SHAMAN = true },
  [2] = { WARRIOR = true, HUNTER = true, ROGUE = true },
  [3] = { WARRIOR = true, HUNTER = true, ROGUE = true },
  [4] = { WARRIOR = true, PALADIN = true, ROGUE = true, PRIEST = true, SHAMAN = true, DRUID = true },
  [5] = { WARRIOR = true, PALADIN = true, SHAMAN = true, DRUID = true },
  [6] = { WARRIOR = true, PALADIN = true, HUNTER = true, DRUID = true },
  [7] = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, MAGE = true, WARLOCK = true },
  [8] = { WARRIOR = true, PALADIN = true, HUNTER = true },
  [10] = { WARRIOR = true, HUNTER = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true },
  [13] = { WARRIOR = true, HUNTER = true, ROGUE = true, SHAMAN = true, DRUID = true },
  [15] = { WARRIOR = true, HUNTER = true, ROGUE = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true },
  [16] = { WARRIOR = true, HUNTER = true, ROGUE = true },
  [18] = { WARRIOR = true, HUNTER = true, ROGUE = true },
  [19] = { PRIEST = true, MAGE = true, WARLOCK = true },
}

-- Format: [item subclass of ammo, 2 arrows 3 bullets] = { CLASS = true, ... }
Bagwise.Data.AmmoClasses = {
  [2] = { WARRIOR = true, HUNTER = true, ROGUE = true },
  [3] = { WARRIOR = true, HUNTER = true, ROGUE = true },
}
