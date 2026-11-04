-- Bagwise: reagent-to-profession mapping with recipe stats
-- For each reagent item: which professions use it, how many
-- recipes, and the skill level range.
-- Generated from wago.tools DB2 build 1.60.1.69893. Do not edit by hand.
--
-- 593 reagent items across 9 professions.

Bagwise                         = Bagwise or {}
Bagwise.Data                    = Bagwise.Data or {}

-- Format: [itemID] = { { profession, recipe_count, min_level, max_level }, ... }
Bagwise.Data.ReagentProfessions = {
  -- Alchemy
  [765] = { { "Alchemy", 7, 10, 90 } },  -- Silverleaf
  [2449] = { { "Alchemy", 9, 20, 175 } },  -- Earthroot
  [2456] = { { "Alchemy", 1, 225, 225 } },  -- Minor Rejuvenation Potion
  [3355] = { { "Alchemy", 9, 70, 215 } },  -- Wild Steelbloom
  [3358] = { { "Alchemy", 10, 120, 250 } },  -- Khadgar's Whisker
  [3369] = { { "Alchemy", 6, 90, 270 } },  -- Grave Moss
  [3820] = { { "Alchemy", 8, 90, 210 } },  -- Stranglekelp
  [6358] = { { "Alchemy", 1, 80, 80 } },  -- Oily Blackmouth
  [6359] = { { "Alchemy", 1, 150, 150 } },  -- Firefin Snapper
  [8836] = { { "Alchemy", 7, 170, 255 } },  -- Arthas' Tears
  [8839] = { { "Alchemy", 9, 180, 305 } },  -- Blindweed
  [8845] = { { "Alchemy", 8, 185, 280 } },  -- Ghost Mushroom
  [8846] = { { "Alchemy", 14, 260, 315 } },  -- Gromsblood
  [9260] = { { "Alchemy", 1, 225, 225 } },  -- Volatile Rum
  [13422] = { { "Alchemy", 1, 250, 250 } },  -- Stonescale Eel
  [13463] = { { "Alchemy", 24, 280, 320 } },  -- Dreamfoil
  [13466] = { { "Alchemy", 11, 280, 315 } },  -- Plaguebloom
  [13513] = { { "Alchemy", 1, 315, 315 } },  -- Flask of Chromatic Resistance
  [19943] = { { "Alchemy", 1, 315, 315 } },  -- Massive Mojo
  [213371] = { { "Alchemy", 2, 200, 225 } },  -- Crate of Tainted Gniodine Solution
  [221312] = { { "Alchemy", 1, 250, 250 } },
  [248821] = { { "Alchemy", 2, 320, 320 } },  -- Demonsage
  [273125] = { { "Alchemy", 1, 300, 300 } },  -- Lich's Index Finger

  -- Alchemy, Blacksmithing
  [5635] = { { "Alchemy", 1, 90, 90 }, { "Blacksmithing", 2, 160, 175 } },  -- Sharp Claw
  [13510] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 1, 320, 320 } },  -- Flask of the Titans
  [13511] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 1, 320, 320 } },  -- Flask of Distilled Wisdom
  [13512] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 5, 320, 320 } },  -- Flask of Supreme Power

  -- Alchemy, Blacksmithing, Cooking, Enchanting, Leatherworking
  [5637] = { { "Alchemy", 1, 195, 195 }, { "Blacksmithing", 3, 175, 185 }, { "Cooking", 1, 185, 185 }, { "Enchanting", 2, 195, 200 }, { "Leatherworking", 2, 150, 155 } },  -- Large Fang

  -- Alchemy, Blacksmithing, Enchanting
  [234006] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 3, 320, 320 }, { "Enchanting", 2, 320, 320 } },

  -- Alchemy, Blacksmithing, Enchanting, Engineering
  [248822] = { { "Alchemy", 4, 320, 320 }, { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 2, 285, 320 }, { "Engineering", 2, 320, 320 } },  -- Death Lotus

  -- Alchemy, Blacksmithing, Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [7080] = { { "Alchemy", 3, 275, 315 }, { "Blacksmithing", 11, 285, 320 }, { "Enchanting", 10, 285, 320 }, { "Engineering", 2, 310, 320 }, { "First Aid", 1, 295, 295 }, { "Leatherworking", 25, 250, 320 }, { "Tailoring", 23, 1, 315 } },  -- Essence of Water

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [7067] = { { "Alchemy", 2, 225, 305 }, { "Blacksmithing", 3, 180, 275 }, { "Enchanting", 1, 195, 195 }, { "Engineering", 4, 225, 320 }, { "Leatherworking", 14, 1, 270 }, { "Tailoring", 11, 155, 215 } },  -- Elemental Earth
  [7076] = { { "Alchemy", 3, 275, 315 }, { "Blacksmithing", 18, 270, 320 }, { "Enchanting", 6, 285, 320 }, { "Engineering", 4, 320, 320 }, { "Leatherworking", 12, 1, 320 }, { "Tailoring", 11, 230, 310 } },  -- Essence of Earth
  [7077] = { { "Alchemy", 1, 301, 301 }, { "Blacksmithing", 17, 1, 305 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 3, 205, 285 }, { "Leatherworking", 1, 245, 245 }, { "Tailoring", 13, 145, 250 } },  -- Heart of Fire
  [7078] = { { "Alchemy", 2, 275, 315 }, { "Blacksmithing", 13, 1, 325 }, { "Enchanting", 8, 285, 320 }, { "Engineering", 3, 280, 320 }, { "Leatherworking", 17, 265, 320 }, { "Tailoring", 13, 245, 320 } },  -- Essence of Fire
  [7082] = { { "Alchemy", 2, 275, 315 }, { "Blacksmithing", 6, 235, 320 }, { "Enchanting", 9, 305, 320 }, { "Engineering", 4, 320, 320 }, { "Leatherworking", 12, 1, 320 }, { "Tailoring", 4, 290, 310 } },  -- Essence of Air
  [8153] = { { "Alchemy", 1, 225, 225 }, { "Blacksmithing", 1, 270, 270 }, { "Enchanting", 1, 270, 270 }, { "Engineering", 1, 265, 265 }, { "Leatherworking", 7, 215, 265 }, { "Tailoring", 3, 205, 220 } },  -- Wildvine
  [12803] = { { "Alchemy", 2, 275, 315 }, { "Blacksmithing", 9, 270, 320 }, { "Enchanting", 4, 320, 320 }, { "Engineering", 3, 285, 320 }, { "Leatherworking", 24, 265, 320 }, { "Tailoring", 12, 250, 320 } },  -- Living Essence

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Mining
  [12359] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 119, 1, 320 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 16, 270, 320 }, { "Mining", 1, 300, 300 } },  -- Thorium Bar

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Tailoring
  [7068] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 3, 1, 190 }, { "Enchanting", 1, 195, 195 }, { "Engineering", 5, 225, 320 }, { "Tailoring", 5, 175, 250 } },  -- Elemental Fire
  [7972] = { { "Alchemy", 1, 230, 230 }, { "Blacksmithing", 1, 250, 250 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 1, 260, 260 }, { "Tailoring", 1, 230, 230 } },  -- Ichor of Undeath
  [12808] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 4, 290, 320 }, { "Enchanting", 6, 285, 320 }, { "Engineering", 2, 260, 320 }, { "Tailoring", 4, 260, 310 } },  -- Essence of Undeath

  -- Alchemy, Blacksmithing, Enchanting, Leatherworking, Tailoring
  [12938] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 3, 280, 285 }, { "Enchanting", 6, 305, 320 }, { "Leatherworking", 6, 280, 285 }, { "Tailoring", 4, 280, 300 } },  -- Blood of Heroes

  -- Alchemy, Blacksmithing, Enchanting, Tailoring
  [8831] = { { "Alchemy", 9, 170, 255 }, { "Blacksmithing", 8, 155, 270 }, { "Enchanting", 4, 260, 320 }, { "Tailoring", 1, 245, 245 } },  -- Purple Lotus

  -- Alchemy, Blacksmithing, Engineering
  [3860] = { { "Alchemy", 1, 240, 240 }, { "Blacksmithing", 54, 200, 260 }, { "Engineering", 37, 1, 320 } },  -- Mithril Bar
  [251291] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 37, 270, 320 }, { "Engineering", 4, 310, 310 } },  -- Heavy Thorium Bar

  -- Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring
  [7069] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 2, 185, 190 }, { "Engineering", 2, 270, 310 }, { "Leatherworking", 17, 1, 300 }, { "Tailoring", 1, 175, 175 } },  -- Elemental Air
  [12804] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 5, 280, 325 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 5, 285, 320 }, { "Tailoring", 2, 315, 315 } },  -- Powerful Mojo
  [220688] = { { "Alchemy", 2, 250, 250 }, { "Blacksmithing", 3, 250, 250 }, { "Engineering", 3, 250, 250 }, { "Leatherworking", 7, 250, 250 }, { "Tailoring", 3, 250, 250 } },
  [221021] = { { "Alchemy", 3, 250, 250 }, { "Blacksmithing", 3, 250, 250 }, { "Engineering", 3, 250, 250 }, { "Leatherworking", 7, 250, 250 }, { "Tailoring", 3, 250, 250 } },

  -- Alchemy, Blacksmithing, Engineering, Mining
  [3575] = { { "Alchemy", 2, 240, 240 }, { "Blacksmithing", 34, 125, 195 }, { "Engineering", 10, 125, 215 }, { "Mining", 1, 165, 165 } },  -- Iron Bar

  -- Alchemy, Blacksmithing, First Aid, Leatherworking, Tailoring
  [7070] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 190, 190 }, { "First Aid", 1, 225, 225 }, { "Leatherworking", 15, 155, 270 }, { "Tailoring", 4, 1, 175 } },  -- Elemental Water

  -- Alchemy, Blacksmithing, Leatherworking, Tailoring
  [3824] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 200, 200 }, { "Leatherworking", 3, 170, 195 }, { "Tailoring", 1, 155, 155 } },  -- Shadow Oil

  -- Alchemy, Cooking
  [730] = { { "Alchemy", 6, 55, 290 }, { "Cooking", 2, 115, 220 } },  -- Murloc Eye
  [785] = { { "Alchemy", 11, 30, 145 }, { "Cooking", 1, 85, 85 } },  -- Mageroyal
  [3818] = { { "Alchemy", 9, 145, 220 }, { "Cooking", 1, 195, 195 } },  -- Fadeleaf
  [3821] = { { "Alchemy", 15, 155, 255 }, { "Cooking", 1, 215, 215 } },  -- Goldthorn
  [6522] = { { "Alchemy", 1, 120, 120 }, { "Cooking", 1, 125, 125 } },  -- Deviate Fish
  [13465] = { { "Alchemy", 11, 250, 320 }, { "Cooking", 1, 260, 260 } },  -- Mountain Silversage

  -- Alchemy, Cooking, Enchanting
  [2452] = { { "Alchemy", 6, 80, 165 }, { "Cooking", 1, 100, 100 }, { "Enchanting", 1, 320, 320 } },  -- Swiftthistle

  -- Alchemy, Cooking, Enchanting, First Aid
  [8838] = { { "Alchemy", 11, 205, 290 }, { "Cooking", 1, 220, 220 }, { "Enchanting", 1, 245, 245 }, { "First Aid", 1, 230, 230 } },  -- Sungrass

  -- Alchemy, Cooking, Engineering
  [4402] = { { "Alchemy", 1, 210, 210 }, { "Cooking", 2, 215, 240 }, { "Engineering", 1, 125, 125 } },  -- Small Flame Sac

  -- Alchemy, Cooking, First Aid
  [2447] = { { "Alchemy", 10, 10, 80 }, { "Cooking", 1, 25, 25 }, { "First Aid", 1, 55, 55 } },  -- Peacebloom
  [3357] = { { "Alchemy", 5, 85, 210 }, { "Cooking", 1, 155, 155 }, { "First Aid", 1, 175, 175 } },  -- Liferoot

  -- Alchemy, Enchanting
  [3819] = { { "Alchemy", 8, 135, 285 }, { "Enchanting", 1, 210, 210 } },  -- Wintersbite
  [6370] = { { "Alchemy", 4, 120, 190 }, { "Enchanting", 1, 170, 170 } },  -- Blackmouth Oil
  [18256] = { { "Alchemy", 11, 280, 320 }, { "Enchanting", 3, 310, 310 } },  -- Imbued Vial
  [248819] = { { "Alchemy", 1, 275, 275 }, { "Enchanting", 2, 320, 320 } },  -- Fel Crystal
  [249274] = { { "Alchemy", 1, 230, 230 }, { "Enchanting", 1, 320, 320 } },  -- Stranglevine
  [249399] = { { "Alchemy", 1, 50, 50 }, { "Enchanting", 1, 140, 140 } },  -- Frilled Lichen
  [249424] = { { "Alchemy", 1, 130, 130 }, { "Enchanting", 1, 225, 225 } },  -- Rosecap

  -- Alchemy, Enchanting, Engineering
  [12363] = { { "Alchemy", 1, 275, 275 }, { "Enchanting", 1, 290, 290 }, { "Engineering", 1, 320, 320 } },  -- Arcane Crystal
  [13467] = { { "Alchemy", 7, 300, 320 }, { "Enchanting", 1, 305, 305 }, { "Engineering", 1, 280, 280 } },  -- Icecap
  [234010] = { { "Alchemy", 1, 315, 315 }, { "Enchanting", 9, 320, 320 }, { "Engineering", 1, 315, 315 } },
  [234011] = { { "Alchemy", 5, 315, 315 }, { "Enchanting", 8, 320, 320 }, { "Engineering", 2, 315, 315 } },
  [234012] = { { "Alchemy", 5, 315, 315 }, { "Enchanting", 11, 320, 320 }, { "Engineering", 1, 315, 315 } },  -- Hive Thistle

  -- Alchemy, Enchanting, Engineering, Tailoring
  [16203] = { { "Alchemy", 4, 315, 315 }, { "Enchanting", 44, 285, 320 }, { "Engineering", 1, 275, 275 }, { "Tailoring", 1, 245, 245 } },  -- Greater Eternal Essence
  [249391] = { { "Alchemy", 1, 50, 50 }, { "Enchanting", 4, 140, 225 }, { "Engineering", 1, 125, 125 }, { "Tailoring", 9, 80, 145 } },  -- Pyrite

  -- Alchemy, Enchanting, First Aid
  [3371] = { { "Alchemy", 37, 10, 150 }, { "Enchanting", 1, 30, 30 }, { "First Aid", 2, 55, 85 } },  -- Empty Vial
  [3372] = { { "Alchemy", 51, 85, 260 }, { "Enchanting", 3, 100, 210 }, { "First Aid", 2, 135, 175 } },  -- Leaded Vial
  [8925] = { { "Alchemy", 81, 170, 315 }, { "Enchanting", 3, 260, 285 }, { "First Aid", 2, 230, 290 } },  -- Crystal Vial

  -- Alchemy, Enchanting, Leatherworking
  [3356] = { { "Alchemy", 15, 80, 210 }, { "Enchanting", 1, 170, 170 }, { "Leatherworking", 1, 135, 135 } },  -- Kingsblood
  [11083] = { { "Alchemy", 1, 90, 90 }, { "Enchanting", 20, 140, 190 }, { "Leatherworking", 2, 155, 155 } },  -- Soul Dust

  -- Alchemy, Enchanting, Leatherworking, Tailoring
  [11176] = { { "Alchemy", 1, 305, 305 }, { "Enchanting", 31, 200, 290 }, { "Leatherworking", 2, 235, 235 }, { "Tailoring", 3, 245, 275 } },  -- Dream Dust

  -- Alchemy, Enchanting, Tailoring
  [4625] = { { "Alchemy", 10, 135, 285 }, { "Enchanting", 3, 285, 310 }, { "Tailoring", 2, 220, 220 } },  -- Firebloom
  [6371] = { { "Alchemy", 3, 165, 265 }, { "Enchanting", 1, 150, 150 }, { "Tailoring", 13, 80, 210 } },  -- Fire Oil
  [13468] = { { "Alchemy", 7, 315, 315 }, { "Enchanting", 1, 320, 320 }, { "Tailoring", 1, 270, 270 } },  -- Black Lotus

  -- Alchemy, Engineering
  [9262] = { { "Alchemy", 2, 240, 315 }, { "Engineering", 1, 205, 205 } },  -- Black Vitriol
  [215430] = { { "Alchemy", 1, 225, 225 }, { "Engineering", 2, 225, 225 } },  -- Gnomeregan Fallout
  [248823] = { { "Alchemy", 2, 320, 320 }, { "Engineering", 1, 320, 320 } },  -- Marefoil

  -- Alchemy, Engineering, Tailoring
  [10286] = { { "Alchemy", 2, 300, 310 }, { "Engineering", 1, 265, 265 }, { "Tailoring", 3, 205, 220 } },  -- Heart of the Wild

  -- Alchemy, First Aid
  [1288] = { { "Alchemy", 1, 145, 145 }, { "First Aid", 1, 130, 130 } },  -- Large Venom Sac
  [2450] = { { "Alchemy", 7, 85, 150 }, { "First Aid", 1, 85, 85 } },  -- Briarthorn
  [2453] = { { "Alchemy", 7, 35, 200 }, { "First Aid", 1, 135, 135 } },  -- Bruiseweed
  [13464] = { { "Alchemy", 7, 255, 320 }, { "First Aid", 1, 290, 290 } },  -- Golden Sansam

  -- Alchemy, Leatherworking
  [13423] = { { "Alchemy", 4, 280, 315 }, { "Leatherworking", 1, 275, 275 } },  -- Stonescale Oil
  [15410] = { { "Alchemy", 1, 315, 315 }, { "Leatherworking", 2, 320, 320 } },  -- Scale of Onyxia

  -- Alchemy, Mining
  [3858] = { { "Alchemy", 1, 230, 230 }, { "Mining", 1, 175, 175 } },  -- Mithril Ore
  [10620] = { { "Alchemy", 1, 295, 295 }, { "Mining", 1, 250, 250 } },  -- Thorium Ore

  -- Alchemy, Tailoring
  [4342] = { { "Alchemy", 1, 260, 260 }, { "Tailoring", 2, 160, 195 } },  -- Purple Dye

  -- Blacksmithing
  [2863] = { { "Blacksmithing", 1, 100, 100 } },  -- Coarse Sharpening Stone
  [2870] = { { "Blacksmithing", 1, 175, 175 } },  -- Shining Silver Breastplate
  [3466] = { { "Blacksmithing", 22, 115, 205 } },  -- Strong Flux
  [3470] = { { "Blacksmithing", 31, 65, 115 } },  -- Rough Grinding Stone
  [3478] = { { "Blacksmithing", 54, 100, 165 } },  -- Coarse Grinding Stone
  [3486] = { { "Blacksmithing", 70, 125, 240 } },  -- Heavy Grinding Stone
  [3823] = { { "Blacksmithing", 1, 245, 245 } },  -- Lesser Invisibility Potion
  [4255] = { { "Blacksmithing", 1, 180, 180 } },  -- Green Leather Armor
  [5966] = { { "Blacksmithing", 1, 220, 220 } },  -- Guardian Gloves
  [7966] = { { "Blacksmithing", 52, 175, 270 } },  -- Solid Grinding Stone
  [11184] = { { "Blacksmithing", 1, 250, 250 } },  -- Blue Power Crystal
  [11185] = { { "Blacksmithing", 1, 275, 275 } },  -- Green Power Crystal
  [11186] = { { "Blacksmithing", 2, 245, 295 } },  -- Red Power Crystal
  [11188] = { { "Blacksmithing", 2, 245, 275 } },  -- Yellow Power Crystal
  [12644] = { { "Blacksmithing", 23, 250, 325 } },  -- Dense Grinding Stone
  [12784] = { { "Blacksmithing", 1, 320, 320 } },  -- Arcanite Reaper
  [12790] = { { "Blacksmithing", 1, 320, 320 } },  -- Arcanite Champion
  [12794] = { { "Blacksmithing", 1, 320, 320 } },  -- Masterwork Stormhammer
  [12796] = { { "Blacksmithing", 1, 320, 320 } },  -- Hammer of the Titans
  [12797] = { { "Blacksmithing", 1, 320, 320 } },  -- Frostguard
  [17203] = { { "Blacksmithing", 2, 325, 325 } },  -- Sulfuron Ingot
  [18262] = { { "Blacksmithing", 5, 320, 320 } },  -- Elemental Sharpening Stone
  [20867] = { { "Blacksmithing", 1, 320, 320 } },  -- Onyx Idol
  [20871] = { { "Blacksmithing", 4, 320, 320 } },  -- Obsidian Idol
  [20872] = { { "Blacksmithing", 3, 320, 320 } },  -- Vermillion Idol
  [20873] = { { "Blacksmithing", 2, 320, 320 } },  -- Alabaster Idol
  [20874] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of the Sun
  [20875] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of Night
  [20876] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of Death
  [20877] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of the Sage
  [20878] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of Rebirth
  [20879] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of Life
  [20882] = { { "Blacksmithing", 1, 320, 320 } },  -- Idol of War
  [213373] = { { "Blacksmithing", 1, 200, 200 } },  -- Reflective Scrapmetal
  [273127] = { { "Blacksmithing", 1, 300, 300 } },  -- Golem Heart

  -- Blacksmithing, Cooking, Leatherworking
  [8146] = { { "Blacksmithing", 5, 320, 320 }, { "Cooking", 1, 240, 240 }, { "Leatherworking", 1, 220, 220 } },  -- Wicked Claw

  -- Blacksmithing, Enchanting
  [10938] = { { "Blacksmithing", 11, 40, 155 }, { "Enchanting", 15, 75, 130 } },  -- Lesser Magic Essence
  [11139] = { { "Blacksmithing", 10, 230, 250 }, { "Enchanting", 7, 210, 240 } },  -- Large Glowing Shard
  [11382] = { { "Blacksmithing", 6, 320, 325 }, { "Enchanting", 4, 285, 285 } },  -- Blood of the Mountain
  [234004] = { { "Blacksmithing", 7, 320, 320 }, { "Enchanting", 1, 320, 320 } },

  -- Blacksmithing, Enchanting, Engineering
  [7909] = { { "Blacksmithing", 12, 185, 290 }, { "Enchanting", 1, 245, 245 }, { "Engineering", 5, 230, 285 } },  -- Aquamarine
  [20725] = { { "Blacksmithing", 3, 320, 320 }, { "Enchanting", 48, 305, 320 }, { "Engineering", 2, 315, 320 } },  -- Nexus Crystal
  [234003] = { { "Blacksmithing", 10, 320, 320 }, { "Enchanting", 12, 320, 320 }, { "Engineering", 3, 315, 320 } },
  [248820] = { { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 2, 320, 320 }, { "Engineering", 1, 320, 320 } },  -- Torbernite
  [249432] = { { "Blacksmithing", 25, 200, 270 }, { "Enchanting", 1, 225, 225 }, { "Engineering", 1, 175, 175 } },  -- Sandpaper
  [249726] = { { "Blacksmithing", 10, 270, 320 }, { "Enchanting", 1, 320, 320 }, { "Engineering", 3, 275, 320 } },  -- Azerothium Bar

  -- Blacksmithing, Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [8170] = { { "Blacksmithing", 21, 260, 315 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 14, 275, 320 }, { "First Aid", 1, 280, 280 }, { "Leatherworking", 175, 1, 320 }, { "Tailoring", 12, 230, 315 } },  -- Rugged Leather

  -- Blacksmithing, Enchanting, Engineering, Leatherworking
  [7075] = { { "Blacksmithing", 4, 235, 245 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 3, 205, 320 }, { "Leatherworking", 6, 1, 290 } },  -- Core of Earth
  [249410] = { { "Blacksmithing", 30, 110, 270 }, { "Enchanting", 4, 140, 225 }, { "Engineering", 2, 100, 320 }, { "Leatherworking", 9, 80, 150 } },  -- Sulfuric Acid

  -- Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [1210] = { { "Blacksmithing", 18, 85, 230 }, { "Enchanting", 2, 130, 140 }, { "Engineering", 3, 145, 205 }, { "Leatherworking", 10, 80, 185 }, { "Tailoring", 10, 80, 170 } },  -- Shadowgem
  [7079] = { { "Blacksmithing", 8, 155, 270 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 2, 285, 320 }, { "Leatherworking", 1, 225, 225 }, { "Tailoring", 18, 1, 250 } },  -- Globe of Water
  [12810] = { { "Blacksmithing", 27, 295, 320 }, { "Enchanting", 12, 320, 320 }, { "Engineering", 6, 290, 320 }, { "Leatherworking", 55, 265, 320 }, { "Tailoring", 19, 260, 320 } },  -- Enchanted Leather
  [12811] = { { "Blacksmithing", 10, 260, 320 }, { "Enchanting", 8, 305, 320 }, { "Engineering", 1, 305, 305 }, { "Leatherworking", 16, 260, 285 }, { "Tailoring", 10, 260, 310 } },  -- Righteous Orb
  [274030] = { { "Blacksmithing", 27, 310, 320 }, { "Enchanting", 6, 310, 310 }, { "Engineering", 1, 310, 310 }, { "Leatherworking", 42, 310, 320 }, { "Tailoring", 21, 310, 320 } },  -- Malleable Essence of Nature

  -- Blacksmithing, Enchanting, Engineering, Mining, Tailoring
  [6037] = { { "Blacksmithing", 33, 175, 320 }, { "Enchanting", 2, 225, 235 }, { "Engineering", 13, 200, 295 }, { "Mining", 1, 300, 300 }, { "Tailoring", 1, 220, 220 } },  -- Truesilver Bar

  -- Blacksmithing, Enchanting, Engineering, Tailoring
  [3829] = { { "Blacksmithing", 2, 190, 200 }, { "Enchanting", 1, 255, 255 }, { "Engineering", 3, 175, 280 }, { "Tailoring", 1, 185, 185 } },  -- Frost Oil

  -- Blacksmithing, Enchanting, Leatherworking
  [2459] = { { "Blacksmithing", 1, 130, 130 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 1, 195, 195 } },  -- Swiftness Potion
  [7081] = { { "Blacksmithing", 2, 245, 260 }, { "Enchanting", 1, 285, 285 }, { "Leatherworking", 2, 1, 1 } },  -- Breath of Wind
  [10940] = { { "Blacksmithing", 10, 40, 155 }, { "Enchanting", 31, 10, 165 }, { "Leatherworking", 2, 95, 95 } },  -- Strange Dust
  [11754] = { { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 1, 310, 310 } },  -- Black Diamond
  [12753] = { { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 2, 320, 320 } },  -- Skin of Shadow

  -- Blacksmithing, Enchanting, Leatherworking, Tailoring
  [5500] = { { "Blacksmithing", 3, 140, 150 }, { "Enchanting", 1, 175, 175 }, { "Leatherworking", 15, 155, 270 }, { "Tailoring", 3, 125, 125 } },  -- Iridescent Pearl
  [7971] = { { "Blacksmithing", 13, 155, 320 }, { "Enchanting", 1, 220, 220 }, { "Leatherworking", 3, 185, 270 }, { "Tailoring", 9, 145, 285 } },  -- Black Pearl
  [12809] = { { "Blacksmithing", 4, 295, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 5, 285, 320 }, { "Tailoring", 3, 270, 305 } },  -- Guardian Stone

  -- Blacksmithing, Enchanting, Tailoring
  [13926] = { { "Blacksmithing", 8, 155, 270 }, { "Enchanting", 2, 310, 320 }, { "Tailoring", 14, 145, 315 } },  -- Golden Pearl

  -- Blacksmithing, Engineering
  [774] = { { "Blacksmithing", 5, 40, 80 }, { "Engineering", 4, 90, 250 } },  -- Malachite
  [818] = { { "Blacksmithing", 16, 40, 180 }, { "Engineering", 3, 130, 250 } },  -- Tigerseye
  [1705] = { { "Blacksmithing", 14, 135, 240 }, { "Engineering", 2, 170, 220 } },  -- Lesser Moonstone
  [2836] = { { "Blacksmithing", 3, 40, 50 }, { "Engineering", 1, 85, 85 } },  -- Coarse Stone
  [2841] = { { "Blacksmithing", 69, 85, 155 }, { "Engineering", 12, 105, 175 } },  -- Bronze Bar
  [2880] = { { "Blacksmithing", 19, 55, 125 }, { "Engineering", 3, 80, 115 } },  -- Weak Flux
  [3859] = { { "Blacksmithing", 40, 170, 225 }, { "Engineering", 1, 175, 175 } },  -- Steel Bar
  [7912] = { { "Blacksmithing", 3, 175, 175 }, { "Engineering", 1, 175, 175 } },  -- Solid Stone
  [11371] = { { "Blacksmithing", 24, 260, 325 }, { "Engineering", 6, 295, 320 } },  -- Dark Iron Bar
  [19774] = { { "Blacksmithing", 6, 320, 320 }, { "Engineering", 2, 320, 320 } },  -- Souldarite
  [22202] = { { "Blacksmithing", 13, 315, 320 }, { "Engineering", 1, 315, 315 } },  -- Small Obsidian Shard
  [213383] = { { "Blacksmithing", 1, 225, 225 }, { "Engineering", 2, 225, 225 } },  -- Polished Truesilver Gears
  [251290] = { { "Blacksmithing", 17, 310, 320 }, { "Engineering", 5, 310, 320 } },  -- Legionite Bar
  [251652] = { { "Blacksmithing", 6, 1, 1 }, { "Engineering", 1, 1, 1 } },

  -- Blacksmithing, Engineering, First Aid, Leatherworking, Tailoring
  [4304] = { { "Blacksmithing", 15, 215, 260 }, { "Engineering", 12, 225, 265 }, { "First Aid", 1, 220, 220 }, { "Leatherworking", 79, 185, 255 }, { "Tailoring", 5, 190, 220 } },  -- Thick Leather
  [4338] = { { "Blacksmithing", 5, 200, 240 }, { "Engineering", 4, 200, 255 }, { "First Aid", 2, 210, 240 }, { "Leatherworking", 1, 205, 205 }, { "Tailoring", 1, 145, 145 } },  -- Mageweave Cloth

  -- Blacksmithing, Engineering, First Aid, Tailoring
  [2589] = { { "Blacksmithing", 3, 55, 65 }, { "Engineering", 6, 25, 115 }, { "First Aid", 2, 30, 50 }, { "Tailoring", 1, 25, 25 } },  -- Linen Cloth

  -- Blacksmithing, Engineering, Leatherworking
  [1206] = { { "Blacksmithing", 6, 135, 240 }, { "Engineering", 5, 135, 175 }, { "Leatherworking", 1, 165, 165 } },  -- Moss Agate
  [12361] = { { "Blacksmithing", 25, 245, 320 }, { "Engineering", 2, 280, 295 }, { "Leatherworking", 1, 290, 290 } },  -- Blue Sapphire
  [12799] = { { "Blacksmithing", 16, 270, 320 }, { "Engineering", 3, 295, 320 }, { "Leatherworking", 1, 290, 290 } },  -- Large Opal
  [213376] = { { "Blacksmithing", 2, 225, 225 }, { "Engineering", 1, 225, 225 }, { "Leatherworking", 2, 225, 225 } },  -- Low-Background Truesilver Plates

  -- Blacksmithing, Engineering, Leatherworking, Mining
  [2840] = { { "Blacksmithing", 51, 10, 155 }, { "Engineering", 11, 30, 130 }, { "Leatherworking", 1, 285, 285 }, { "Mining", 2, 20, 65 } },  -- Copper Bar

  -- Blacksmithing, Engineering, Leatherworking, Mining, Tailoring
  [17010] = { { "Blacksmithing", 15, 290, 325 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 6, 315, 320 }, { "Mining", 1, 310, 310 }, { "Tailoring", 5, 315, 320 } },  -- Fiery Core

  -- Blacksmithing, Engineering, Leatherworking, Tailoring
  [1529] = { { "Blacksmithing", 15, 155, 270 }, { "Engineering", 6, 180, 265 }, { "Leatherworking", 12, 155, 320 }, { "Tailoring", 1, 220, 220 } },  -- Jade
  [2318] = { { "Blacksmithing", 8, 40, 85 }, { "Engineering", 3, 90, 130 }, { "Leatherworking", 82, 20, 110 }, { "Tailoring", 6, 50, 95 } },  -- Light Leather
  [2319] = { { "Blacksmithing", 16, 110, 155 }, { "Engineering", 16, 125, 210 }, { "Leatherworking", 54, 90, 150 }, { "Tailoring", 3, 120, 135 } },  -- Medium Leather
  [3864] = { { "Blacksmithing", 15, 170, 260 }, { "Engineering", 10, 195, 260 }, { "Leatherworking", 9, 155, 270 }, { "Tailoring", 1, 185, 185 } },  -- Citrine
  [4234] = { { "Blacksmithing", 25, 155, 235 }, { "Engineering", 27, 135, 245 }, { "Leatherworking", 70, 125, 215 }, { "Tailoring", 10, 135, 215 } },  -- Heavy Leather
  [12364] = { { "Blacksmithing", 16, 280, 325 }, { "Engineering", 1, 310, 310 }, { "Leatherworking", 3, 265, 295 }, { "Tailoring", 1, 310, 310 } },  -- Huge Emerald
  [12800] = { { "Blacksmithing", 16, 280, 325 }, { "Engineering", 5, 275, 320 }, { "Leatherworking", 1, 295, 295 }, { "Tailoring", 2, 295, 315 } },  -- Azerothian Diamond
  [17011] = { { "Blacksmithing", 15, 290, 325 }, { "Engineering", 3, 320, 320 }, { "Leatherworking", 6, 315, 320 }, { "Tailoring", 3, 315, 315 } },  -- Lava Core
  [19726] = { { "Blacksmithing", 10, 320, 320 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 12, 320, 320 }, { "Tailoring", 9, 315, 315 } },  -- Bloodvine
  [213369] = { { "Blacksmithing", 1, 225, 225 }, { "Engineering", 2, 225, 225 }, { "Leatherworking", 4, 225, 225 }, { "Tailoring", 1, 225, 225 } },  -- Faintly Glowing Leather
  [213379] = { { "Blacksmithing", 2, 225, 225 }, { "Engineering", 1, 225, 225 }, { "Leatherworking", 2, 225, 225 }, { "Tailoring", 1, 225, 225 } },  -- Hyperconductive Arcano-Filament

  -- Blacksmithing, Engineering, Mining
  [2835] = { { "Blacksmithing", 4, 15, 45 }, { "Engineering", 1, 20, 20 }, { "Mining", 1, 20, 20 } },  -- Rough Stone
  [2838] = { { "Blacksmithing", 3, 100, 100 }, { "Engineering", 1, 125, 125 }, { "Mining", 1, 140, 140 } },  -- Heavy Stone
  [12365] = { { "Blacksmithing", 4, 230, 275 }, { "Engineering", 3, 250, 315 }, { "Mining", 1, 300, 300 } },  -- Dense Stone
  [12655] = { { "Blacksmithing", 41, 275, 325 }, { "Engineering", 2, 280, 320 }, { "Mining", 1, 315, 315 } },  -- Enchanted Thorium Bar

  -- Blacksmithing, Engineering, Mining, Tailoring
  [2842] = { { "Blacksmithing", 34, 75, 295 }, { "Engineering", 2, 110, 155 }, { "Mining", 1, 140, 140 }, { "Tailoring", 18, 125, 145 } },  -- Silver Bar
  [12360] = { { "Blacksmithing", 80, 250, 325 }, { "Engineering", 6, 305, 320 }, { "Mining", 1, 310, 310 }, { "Tailoring", 1, 295, 295 } },  -- Arcanite Bar

  -- Blacksmithing, Engineering, Tailoring
  [3577] = { { "Blacksmithing", 31, 125, 310 }, { "Engineering", 2, 150, 225 }, { "Tailoring", 12, 145, 260 } },  -- Gold Bar
  [7910] = { { "Blacksmithing", 26, 200, 325 }, { "Engineering", 11, 245, 310 }, { "Tailoring", 2, 275, 295 } },  -- Star Ruby

  -- Blacksmithing, Leatherworking
  [3391] = { { "Blacksmithing", 1, 150, 150 }, { "Leatherworking", 1, 205, 205 } },  -- Elixir of Ogre Strength
  [8168] = { { "Blacksmithing", 1, 320, 320 }, { "Leatherworking", 2, 245, 290 } },  -- Jet Black Feather
  [15417] = { { "Blacksmithing", 1, 320, 320 }, { "Leatherworking", 4, 285, 320 } },  -- Devilsaur Leather

  -- Blacksmithing, Leatherworking, Tailoring
  [2320] = { { "Blacksmithing", 1, 75, 75 }, { "Leatherworking", 55, 40, 100 }, { "Tailoring", 37, 20, 70 } },  -- Coarse Thread
  [2605] = { { "Blacksmithing", 6, 150, 170 }, { "Leatherworking", 3, 150, 175 }, { "Tailoring", 10, 60, 250 } },  -- Green Dye
  [5498] = { { "Blacksmithing", 13, 85, 185 }, { "Leatherworking", 12, 40, 155 }, { "Tailoring", 11, 80, 145 } },  -- Small Lustrous Pearl
  [7071] = { { "Blacksmithing", 1, 290, 290 }, { "Leatherworking", 6, 155, 195 }, { "Tailoring", 7, 160, 215 } },  -- Iron Buckle
  [17012] = { { "Blacksmithing", 2, 320, 320 }, { "Leatherworking", 5, 315, 320 }, { "Tailoring", 2, 315, 315 } },  -- Core Leather
  [20381] = { { "Blacksmithing", 1, 320, 320 }, { "Leatherworking", 3, 320, 320 }, { "Tailoring", 2, 320, 320 } },  -- Dreamscale
  [22682] = { { "Blacksmithing", 3, 320, 320 }, { "Leatherworking", 6, 320, 320 }, { "Tailoring", 4, 315, 315 } },  -- Frozen Rune
  [211422] = { { "Blacksmithing", 1, 175, 175 }, { "Leatherworking", 2, 160, 160 }, { "Tailoring", 1, 150, 150 } },
  [236656] = { { "Blacksmithing", 3, 320, 320 }, { "Leatherworking", 6, 320, 320 }, { "Tailoring", 7, 315, 315 } },
  [249427] = { { "Blacksmithing", 30, 85, 260 }, { "Leatherworking", 80, 90, 295 }, { "Tailoring", 16, 80, 315 } },  -- Pristine Leather

  -- Blacksmithing, Mining
  [18567] = { { "Blacksmithing", 26, 290, 320 }, { "Mining", 1, 310, 310 } },  -- Elemental Flux
  [22203] = { { "Blacksmithing", 8, 320, 320 }, { "Mining", 1, 315, 315 } },  -- Large Obsidian Shard

  -- Blacksmithing, Tailoring
  [12662] = { { "Blacksmithing", 5, 280, 325 }, { "Tailoring", 4, 275, 310 } },  -- Demonic Rune
  [20520] = { { "Blacksmithing", 4, 320, 320 }, { "Tailoring", 4, 260, 300 } },  -- Dark Rune

  -- Cooking
  [723] = { { "Cooking", 1, 90, 90 } },  -- Goretusk Liver
  [729] = { { "Cooking", 1, 115, 115 } },  -- Stringy Vulture Meat
  [731] = { { "Cooking", 1, 115, 115 } },  -- Goretusk Snout
  [769] = { { "Cooking", 2, 45, 200 } },  -- Chunk of Boar Meat
  [1015] = { { "Cooking", 2, 140, 165 } },  -- Lean Wolf Flank
  [1080] = { { "Cooking", 1, 135, 135 } },  -- Tough Condor Meat
  [1081] = { { "Cooking", 1, 135, 135 } },  -- Crisp Spider Meat
  [1179] = { { "Cooking", 5, 75, 265 } },  -- Ice Cold Milk
  [1205] = { { "Cooking", 2, 135, 155 } },  -- Melon Juice
  [1645] = { { "Cooking", 2, 215, 220 } },  -- Moonberry Juice
  [1708] = { { "Cooking", 2, 185, 195 } },  -- Sweet Nectar
  [2251] = { { "Cooking", 1, 150, 150 } },  -- Gooey Spider Leg
  [2672] = { { "Cooking", 2, 45, 50 } },  -- Stringy Wolf Meat
  [2673] = { { "Cooking", 1, 90, 90 } },  -- Coyote Meat
  [2674] = { { "Cooking", 1, 115, 115 } },  -- Crawler Meat
  [2675] = { { "Cooking", 2, 30, 125 } },  -- Crawler Claw
  [2677] = { { "Cooking", 2, 120, 130 } },  -- Boar Ribs
  [2886] = { { "Cooking", 1, 60, 60 } },  -- Crag Boar Rib
  [2894] = { { "Cooking", 1, 60, 60 } },  -- Rhapsody Malt
  [2924] = { { "Cooking", 1, 120, 120 } },  -- Crocolisk Meat
  [3172] = { { "Cooking", 1, 100, 100 } },  -- Boar Intestines
  [3173] = { { "Cooking", 2, 80, 100 } },  -- Bear Meat
  [3404] = { { "Cooking", 3, 215, 290 } },  -- Buzzard Wing
  [3667] = { { "Cooking", 2, 160, 160 } },  -- Tender Crocolisk Meat
  [3685] = { { "Cooking", 2, 35, 170 } },  -- Raptor Egg
  [3712] = { { "Cooking", 3, 215, 290 } },  -- Turtle Meat
  [3730] = { { "Cooking", 3, 150, 275 } },  -- Big Bear Meat
  [3731] = { { "Cooking", 2, 175, 190 } },  -- Lion Meat
  [4536] = { { "Cooking", 2, 90, 215 } },  -- Shiny Red Apple
  [4603] = { { "Cooking", 2, 265, 290 } },  -- Raw Spotted Yellowtail
  [4655] = { { "Cooking", 1, 215, 215 } },  -- Giant Clam Meat
  [5051] = { { "Cooking", 1, 130, 130 } },  -- Dig Rat
  [5465] = { { "Cooking", 1, 50, 50 } },  -- Small Spider Leg
  [5466] = { { "Cooking", 1, 60, 60 } },  -- Scorpid Stinger
  [5467] = { { "Cooking", 1, 75, 75 } },  -- Kodo Meat
  [5468] = { { "Cooking", 1, 90, 90 } },  -- Soft Frenzy Flesh
  [5469] = { { "Cooking", 1, 90, 90 } },  -- Strider Meat
  [5470] = { { "Cooking", 1, 140, 140 } },  -- Thunder Lizard Tail
  [5471] = { { "Cooking", 4, 1, 260 } },  -- Stag Meat
  [5503] = { { "Cooking", 2, 90, 130 } },  -- Clam Meat
  [5504] = { { "Cooking", 1, 165, 165 } },  -- Tangy Clam Meat
  [6289] = { { "Cooking", 1, 90, 90 } },  -- Raw Longjaw Mud Snapper
  [6291] = { { "Cooking", 1, 45, 45 } },  -- Raw Brilliant Smallfish
  [6303] = { { "Cooking", 1, 45, 45 } },  -- Raw Slitherskin Mackerel
  [6308] = { { "Cooking", 1, 140, 140 } },  -- Raw Bristle Whisker Catfish
  [6317] = { { "Cooking", 1, 90, 90 } },  -- Raw Loch Frenzy
  [6361] = { { "Cooking", 1, 90, 90 } },  -- Raw Rainbow Fin Albacore
  [6362] = { { "Cooking", 2, 190, 290 } },  -- Raw Rockscale Cod
  [6889] = { { "Cooking", 5, 20, 75 } },  -- Small Egg
  [7974] = { { "Cooking", 2, 200, 265 } },  -- Zesty Clam Meat
  [8365] = { { "Cooking", 1, 215, 215 } },  -- Raw Mithril Head Trout
  [8766] = { { "Cooking", 2, 240, 260 } },  -- Morning Glory Dew
  [8959] = { { "Cooking", 1, 210, 210 } },  -- Raw Spinefin Halibut
  [10284] = { { "Cooking", 4, 20, 300 } },  -- Simple Flour
  [12037] = { { "Cooking", 4, 140, 240 } },  -- Mystery Meat
  [12184] = { { "Cooking", 6, 115, 290 } },  -- Raptor Flesh
  [12202] = { { "Cooking", 3, 175, 260 } },  -- Tiger Meat
  [12203] = { { "Cooking", 3, 215, 285 } },  -- Red Wolf Meat
  [12204] = { { "Cooking", 2, 140, 240 } },  -- Heavy Kodo Meat
  [12205] = { { "Cooking", 1, 240, 240 } },  -- White Spider Meat
  [12206] = { { "Cooking", 2, 220, 265 } },  -- Tender Crab Meat
  [12207] = { { "Cooking", 4, 1, 265 } },  -- Giant Egg
  [12208] = { { "Cooking", 1, 265, 265 } },  -- Tender Wolf Meat
  [12223] = { { "Cooking", 2, 45, 280 } },  -- Meaty Bat Wing
  [13754] = { { "Cooking", 1, 265, 265 } },  -- Raw Glossy Mightfish
  [13755] = { { "Cooking", 1, 280, 280 } },  -- Raw Winter Squid
  [13756] = { { "Cooking", 1, 280, 280 } },  -- Raw Summer Bass
  [13758] = { { "Cooking", 2, 265, 325 } },  -- Raw Redgill
  [13759] = { { "Cooking", 1, 290, 290 } },  -- Raw Nightfin Snapper
  [13760] = { { "Cooking", 1, 290, 290 } },  -- Raw Sunscale Salmon
  [13888] = { { "Cooking", 3, 290, 325 } },  -- Darkclaw Lobster
  [13889] = { { "Cooking", 1, 315, 315 } },  -- Raw Whitescale Salmon
  [13890] = { { "Cooking", 1, 245, 245 } },  -- Raw Plated Armorfish
  [13893] = { { "Cooking", 1, 315, 315 } },  -- Large Raw Mightfish
  [17194] = { { "Cooking", 2, 45, 75 } },  -- Holiday Spices
  [17196] = { { "Cooking", 1, 75, 75 } },  -- Holiday Spirits
  [18255] = { { "Cooking", 1, 315, 315 } },  -- Runn Tum Tuber
  [20424] = { { "Cooking", 1, 325, 325 } },  -- Sandworm Meat
  [21024] = { { "Cooking", 1, 325, 325 } },  -- Chimaerok Tenderloin
  [21071] = { { "Cooking", 1, 120, 120 } },  -- Raw Sagefish
  [21153] = { { "Cooking", 1, 215, 215 } },  -- Raw Greater Sagefish
  [227813] = { { "Cooking", 1, 325, 325 } },
  [239016] = { { "Cooking", 3, 260, 260 } },  -- Holy Salts
  [239017] = { { "Cooking", 2, 290, 290 } },  -- Exquisite Spices
  [249796] = { { "Cooking", 1, 280, 280 } },  -- Hyjal Berries
  [251524] = { { "Cooking", 1, 125, 125 } },  -- Whimsyfin
  [252948] = { { "Cooking", 1, 1, 1 } },
  [272941] = { { "Cooking", 1, 200, 200 } },  -- Thick Logs

  -- Cooking, Enchanting
  [11291] = { { "Cooking", 1, 90, 90 }, { "Enchanting", 17, 140, 320 } },  -- Star Wood

  -- Cooking, Enchanting, First Aid, Leatherworking, Tailoring
  [4470] = { { "Cooking", 2, 1, 25 }, { "Enchanting", 6, 10, 140 }, { "First Aid", 2, 140, 300 }, { "Leatherworking", 1, 140, 140 }, { "Tailoring", 2, 140, 300 } },  -- Simple Wood

  -- Cooking, Engineering
  [9061] = { { "Cooking", 1, 325, 325 }, { "Engineering", 7, 235, 295 } },  -- Goblin Rocket Fuel

  -- Cooking, Engineering, First Aid
  [159] = { { "Cooking", 10, 5, 315 }, { "Engineering", 3, 130, 275 }, { "First Aid", 1, 20, 20 } },  -- Refreshing Spring Water

  -- Cooking, Engineering, Leatherworking
  [8150] = { { "Cooking", 1, 325, 325 }, { "Engineering", 1, 250, 250 }, { "Leatherworking", 1, 175, 175 } },  -- Deeprock Salt

  -- Cooking, First Aid
  [1468] = { { "Cooking", 2, 130, 135 }, { "First Aid", 1, 160, 160 } },  -- Murloc Fin
  [1475] = { { "Cooking", 1, 5, 5 }, { "First Aid", 1, 80, 80 } },  -- Small Venom Sac
  [2596] = { { "Cooking", 1, 215, 215 }, { "First Aid", 1, 225, 225 } },  -- Skin of Dwarven Stout
  [2678] = { { "Cooking", 24, 5, 200 }, { "First Aid", 3, 55, 90 } },  -- Mild Spices
  [2692] = { { "Cooking", 29, 130, 325 }, { "First Aid", 4, 135, 295 } },  -- Hot Spices
  [3174] = { { "Cooking", 2, 85, 100 }, { "First Aid", 1, 90, 90 } },  -- Spider Ichor
  [3713] = { { "Cooking", 27, 140, 325 }, { "First Aid", 3, 160, 290 } },  -- Soothing Spices

  -- Enchanting
  [2289] = { { "Enchanting", 1, 225, 225 } },  -- Scroll of Strength II
  [3013] = { { "Enchanting", 1, 140, 140 } },  -- Scroll of Protection
  [4605] = { { "Enchanting", 1, 140, 140 } },  -- Red-speckled Mushroom
  [6217] = { { "Enchanting", 1, 5, 5 } },  -- Copper Rod
  [6338] = { { "Enchanting", 1, 130, 130 } },  -- Silver Rod
  [9224] = { { "Enchanting", 1, 250, 250 } },  -- Potion of Demonslaying
  [10308] = { { "Enchanting", 1, 320, 320 } },  -- Scroll of Intellect IV
  [10939] = { { "Enchanting", 5, 100, 140 } },  -- Greater Magic Essence
  [10978] = { { "Enchanting", 9, 120, 140 } },  -- Small Glimmering Shard
  [10998] = { { "Enchanting", 11, 130, 175 } },  -- Lesser Astral Essence
  [11084] = { { "Enchanting", 11, 140, 175 } },  -- Large Glimmering Shard
  [11128] = { { "Enchanting", 1, 175, 175 } },  -- Golden Rod
  [11135] = { { "Enchanting", 7, 195, 225 } },  -- Greater Mystic Essence
  [11138] = { { "Enchanting", 3, 175, 195 } },  -- Small Glowing Shard
  [11144] = { { "Enchanting", 1, 220, 220 } },  -- Truesilver Rod
  [11174] = { { "Enchanting", 16, 140, 260 } },  -- Lesser Nether Essence
  [11177] = { { "Enchanting", 8, 200, 285 } },  -- Small Radiant Shard
  [12735] = { { "Enchanting", 1, 320, 320 } },  -- Frayed Abomination Stitching
  [13180] = { { "Enchanting", 1, 320, 320 } },  -- Stratholme Holy Water
  [13458] = { { "Enchanting", 1, 320, 320 } },  -- Greater Nature Protection Potion
  [16202] = { { "Enchanting", 9, 250, 310 } },  -- Lesser Eternal Essence
  [16206] = { { "Enchanting", 1, 310, 310 } },  -- Arcanite Rod
  [17034] = { { "Enchanting", 2, 30, 160 } },  -- Maple Seed
  [17035] = { { "Enchanting", 1, 210, 210 } },  -- Stranglethorn Seed
  [247786] = { { "Enchanting", 3, 5, 20 } },  -- Mote of Magic
  [273128] = { { "Enchanting", 1, 300, 300 } },  -- Maker's Spark

  -- Enchanting, Engineering
  [16204] = { { "Enchanting", 45, 285, 320 }, { "Engineering", 2, 320, 320 } },  -- Illusion Dust
  [234005] = { { "Enchanting", 1, 320, 320 }, { "Engineering", 4, 315, 315 } },
  [249425] = { { "Enchanting", 1, 225, 225 }, { "Engineering", 1, 130, 130 } },  -- Bauxite

  -- Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [14047] = { { "Enchanting", 1, 320, 320 }, { "Engineering", 16, 250, 320 }, { "First Aid", 4, 260, 300 }, { "Leatherworking", 7, 265, 305 }, { "Tailoring", 1, 210, 210 } },  -- Runecloth

  -- Enchanting, Engineering, Leatherworking
  [8151] = { { "Enchanting", 1, 310, 310 }, { "Engineering", 2, 225, 230 }, { "Leatherworking", 4, 210, 240 } },  -- Flask of Mojo

  -- Enchanting, Engineering, Leatherworking, Tailoring
  [15407] = { { "Enchanting", 1, 270, 270 }, { "Engineering", 1, 320, 320 }, { "Leatherworking", 137, 250, 320 }, { "Tailoring", 5, 315, 320 } },  -- Cured Rugged Hide
  [234007] = { { "Enchanting", 2, 320, 320 }, { "Engineering", 3, 315, 315 }, { "Leatherworking", 5, 320, 320 }, { "Tailoring", 4, 320, 320 } },
  [249409] = { { "Enchanting", 12, 140, 320 }, { "Engineering", 2, 25, 125 }, { "Leatherworking", 9, 80, 150 }, { "Tailoring", 108, 75, 270 } },  -- Cerulean Dye

  -- Enchanting, Engineering, Tailoring
  [11175] = { { "Enchanting", 17, 225, 265 }, { "Engineering", 1, 230, 230 }, { "Tailoring", 12, 210, 220 } },  -- Greater Nether Essence
  [14344] = { { "Enchanting", 53, 290, 320 }, { "Engineering", 1, 320, 320 }, { "Tailoring", 6, 270, 315 } },  -- Large Brilliant Shard
  [234008] = { { "Enchanting", 4, 320, 320 }, { "Engineering", 1, 315, 315 }, { "Tailoring", 1, 315, 315 } },
  [249430] = { { "Enchanting", 12, 225, 320 }, { "Engineering", 1, 145, 145 }, { "Tailoring", 52, 145, 270 } },  -- Magenta Dye
  [249431] = { { "Enchanting", 3, 320, 320 }, { "Engineering", 3, 240, 320 }, { "Tailoring", 9, 230, 315 } },  -- Viridian Dye

  -- Enchanting, Leatherworking
  [7392] = { { "Enchanting", 1, 220, 220 }, { "Leatherworking", 2, 170, 185 } },  -- Green Whelp Scale
  [8152] = { { "Enchanting", 1, 310, 310 }, { "Leatherworking", 2, 230, 235 } },  -- Flask of Big Mojo
  [18512] = { { "Enchanting", 1, 320, 320 }, { "Leatherworking", 11, 310, 320 } },  -- Larval Acid

  -- Enchanting, Leatherworking, Tailoring
  [11137] = { { "Enchanting", 26, 140, 245 }, { "Leatherworking", 2, 205, 205 }, { "Tailoring", 2, 205, 225 } },  -- Vision Dust

  -- Enchanting, Mining
  [2772] = { { "Enchanting", 1, 170, 170 }, { "Mining", 2, 130, 140 } },  -- Iron Ore
  [2775] = { { "Enchanting", 1, 140, 140 }, { "Mining", 1, 100, 100 } },  -- Silver Ore

  -- Enchanting, Tailoring
  [6048] = { { "Enchanting", 1, 160, 160 }, { "Tailoring", 2, 135, 140 } },  -- Shadow Protection Potion
  [11082] = { { "Enchanting", 10, 140, 175 }, { "Tailoring", 18, 125, 145 } },  -- Greater Astral Essence
  [11134] = { { "Enchanting", 11, 165, 225 }, { "Tailoring", 4, 185, 185 } },  -- Lesser Mystic Essence
  [11178] = { { "Enchanting", 18, 225, 270 }, { "Tailoring", 8, 145, 250 } },  -- Large Radiant Shard
  [14343] = { { "Enchanting", 9, 285, 310 }, { "Tailoring", 6, 290, 295 } },  -- Small Brilliant Shard

  -- Engineering
  [2570] = { { "Engineering", 2, 25, 55 } },  -- Linen Cloak
  [3030] = { { "Engineering", 1, 210, 210 } },  -- Razor Arrow
  [4357] = { { "Engineering", 5, 25, 60 } },  -- Rough Blasting Powder
  [4359] = { { "Engineering", 12, 20, 145 } },  -- Handful of Copper Bolts
  [4360] = { { "Engineering", 1, 90, 90 } },  -- Rough Copper Bomb
  [4361] = { { "Engineering", 4, 20, 130 } },  -- Copper Tube
  [4363] = { { "Engineering", 7, 65, 180 } },  -- Copper Modulator
  [4364] = { { "Engineering", 15, 85, 150 } },  -- Coarse Blasting Powder
  [4368] = { { "Engineering", 1, 175, 175 } },  -- Flying Tiger Goggles
  [4371] = { { "Engineering", 13, 135, 210 } },  -- Bronze Tube
  [4375] = { { "Engineering", 16, 125, 200 } },  -- Whirring Bronze Gizmo
  [4377] = { { "Engineering", 23, 125, 215 } },  -- Heavy Blasting Powder
  [4380] = { { "Engineering", 1, 170, 170 } },  -- Big Bronze Bomb
  [4382] = { { "Engineering", 10, 135, 255 } },  -- Bronze Framework
  [4385] = { { "Engineering", 1, 225, 225 } },  -- Green Tinted Goggles
  [4387] = { { "Engineering", 9, 150, 280 } },  -- Iron Strut
  [4389] = { { "Engineering", 18, 150, 245 } },  -- Gyrochronatom
  [4394] = { { "Engineering", 2, 205, 235 } },  -- Big Iron Bomb
  [4397] = { { "Engineering", 1, 245, 245 } },  -- Gnomish Cloaking Device
  [4399] = { { "Engineering", 2, 80, 130 } },  -- Wooden Stock
  [4400] = { { "Engineering", 5, 145, 240 } },  -- Heavy Stock
  [4404] = { { "Engineering", 8, 105, 215 } },  -- Silver Contact
  [4405] = { { "Engineering", 1, 65, 65 } },  -- Crude Scope
  [4407] = { { "Engineering", 1, 230, 230 } },  -- Accurate Scope
  [4611] = { { "Engineering", 1, 185, 185 } },  -- Blue Pearl
  [5507] = { { "Engineering", 4, 205, 205 } },  -- Ornate Spyglass
  [6530] = { { "Engineering", 1, 150, 150 } },  -- Nightcrawlers
  [7191] = { { "Engineering", 8, 160, 320 } },  -- Fused Wiring
  [7387] = { { "Engineering", 1, 235, 235 } },  -- Dusky Belt
  [9060] = { { "Engineering", 6, 245, 295 } },  -- Inlaid Mithril Cylinder
  [10026] = { { "Engineering", 2, 245, 245 } },  -- Black Mageweave Boots
  [10500] = { { "Engineering", 2, 230, 310 } },  -- Fire Goggles
  [10502] = { { "Engineering", 1, 290, 290 } },  -- Spellpower Goggles Xtreme
  [10505] = { { "Engineering", 27, 1, 245 } },  -- Solid Blasting Powder
  [10507] = { { "Engineering", 1, 235, 235 } },  -- Solid Dynamite
  [10518] = { { "Engineering", 1, 270, 270 } },  -- Parachute Cloak
  [10543] = { { "Engineering", 1, 265, 265 } },  -- Goblin Construction Helmet
  [10546] = { { "Engineering", 2, 280, 295 } },  -- Deadly Scope
  [10558] = { { "Engineering", 20, 150, 320 } },  -- Gold Power Core
  [10559] = { { "Engineering", 15, 205, 280 } },  -- Mithril Tube
  [10560] = { { "Engineering", 27, 205, 305 } },  -- Unstable Trigger
  [10561] = { { "Engineering", 22, 215, 305 } },  -- Mithril Casing
  [10576] = { { "Engineering", 1, 320, 320 } },  -- Mithril Mechanical Dragonling
  [10577] = { { "Engineering", 1, 1, 1 } },  -- Goblin Mortar
  [10586] = { { "Engineering", 1, 285, 285 } },  -- The Big One
  [10588] = { { "Engineering", 1, 305, 305 } },  -- Goblin Rocket Helmet
  [10592] = { { "Engineering", 1, 240, 240 } },  -- Catseye Draught
  [10647] = { { "Engineering", 2, 205, 205 } },  -- Engineer's Ink
  [10648] = { { "Engineering", 2, 205, 205 } },  -- Blank Parchment
  [15992] = { { "Engineering", 17, 250, 320 } },  -- Dense Blasting Powder
  [15994] = { { "Engineering", 22, 250, 320 } },  -- Thorium Widget
  [16000] = { { "Engineering", 11, 250, 320 } },  -- Thorium Tube
  [16005] = { { "Engineering", 1, 290, 290 } },  -- Dark Iron Bomb
  [16006] = { { "Engineering", 15, 280, 320 } },  -- Delicate Arcanite Converter
  [16583] = { { "Engineering", 1, 205, 205 } },  -- Demonic Figurine
  [17056] = { { "Engineering", 1, 310, 310 } },  -- Light Feather
  [17202] = { { "Engineering", 1, 190, 190 } },  -- Snowball
  [18168] = { { "Engineering", 1, 315, 315 } },  -- Force Reactive Disk
  [18631] = { { "Engineering", 12, 280, 320 } },  -- Truesilver Transformer
  [18984] = { { "Engineering", 1, 320, 320 } },  -- Dimensional Ripper - Everlook
  [18986] = { { "Engineering", 1, 320, 320 } },  -- Ultrasafe Transporter: Gadgetzan
  [20868] = { { "Engineering", 1, 320, 320 } },  -- Lambent Idol
  [20870] = { { "Engineering", 1, 320, 320 } },  -- Jasper Idol
  [20881] = { { "Engineering", 1, 320, 320 } },  -- Idol of Strife
  [213381] = { { "Engineering", 1, 200, 200 } },  -- Pile of Tarnished Gears
  [220689] = { { "Engineering", 3, 250, 250 } },
  [238737] = { { "Engineering", 6, 270, 280 } },  -- Tinkerbox
  [238780] = { { "Engineering", 3, 1, 1 } },
  [238786] = { { "Engineering", 1, 320, 320 } },  -- Schematic: Tinker: Teleport
  [238787] = { { "Engineering", 1, 320, 320 } },  -- Schematic: Tinker: Nitro Boosts
  [238788] = { { "Engineering", 1, 320, 320 } },  -- Schematic: Tinker: Magnetic Displacement
  [255007] = { { "Engineering", 1, 65, 65 } },  -- Golem Isospring
  [260784] = { { "Engineering", 1, 55, 55 } },  -- SAF-T Tabs
  [260794] = { { "Engineering", 2, 115, 130 } },  -- EZ-Thro Wrap
  [260796] = { { "Engineering", 2, 145, 150 } },  -- No Slip SAF-T Padding
  [260799] = { { "Engineering", 1, 200, 200 } },  -- SAF-T Bell
  [260801] = { { "Engineering", 3, 200, 210 } },  -- EZ-Thro Fireproof Fuse
  [260804] = { { "Engineering", 3, 215, 270 } },  -- SAF-T Casing
  [260808] = { { "Engineering", 1, 240, 240 } },  -- EZ-Thro Tru-Trigger
  [260813] = { { "Engineering", 5, 275, 320 } },  -- SAF-T Tube
  [260815] = { { "Engineering", 6, 285, 320 } },  -- EZ-Thro Shell
  [260823] = { { "Engineering", 1, 320, 320 } },  -- Dimensional Transporter - Mt. Hyjal
  [273129] = { { "Engineering", 1, 300, 300 } },  -- Essence of Anarchy

  -- Engineering, First Aid, Tailoring
  [2592] = { { "Engineering", 10, 100, 200 }, { "First Aid", 3, 80, 120 }, { "Tailoring", 1, 70, 70 } },  -- Wool Cloth
  [4306] = { { "Engineering", 7, 160, 200 }, { "First Aid", 2, 150, 180 }, { "Tailoring", 1, 110, 110 } },  -- Silk Cloth

  -- Engineering, Leatherworking
  [251651] = { { "Engineering", 1, 1, 1 }, { "Leatherworking", 12, 1, 1 } },

  -- Engineering, Leatherworking, Tailoring
  [4305] = { { "Engineering", 1, 180, 180 }, { "Leatherworking", 4, 155, 190 }, { "Tailoring", 100, 105, 220 } },  -- Bolt of Silk Cloth
  [4337] = { { "Engineering", 1, 230, 230 }, { "Leatherworking", 1, 195, 195 }, { "Tailoring", 6, 150, 195 } },  -- Thick Spider's Silk
  [14227] = { { "Engineering", 2, 285, 305 }, { "Leatherworking", 21, 310, 320 }, { "Tailoring", 53, 230, 320 } },  -- Ironweb Spider Silk
  [234009] = { { "Engineering", 1, 315, 315 }, { "Leatherworking", 3, 320, 320 }, { "Tailoring", 7, 315, 320 } },
  [249428] = { { "Engineering", 1, 190, 190 }, { "Leatherworking", 43, 195, 270 }, { "Tailoring", 2, 315, 315 } },  -- Pristine Hide
  [249429] = { { "Engineering", 2, 285, 320 }, { "Leatherworking", 12, 235, 320 }, { "Tailoring", 2, 315, 315 } },  -- Pristine Scale

  -- Engineering, Mining
  [249426] = { { "Engineering", 1, 320, 320 }, { "Mining", 1, 275, 275 } },  -- Pitchblende

  -- Engineering, Tailoring
  [814] = { { "Engineering", 2, 150, 160 }, { "Tailoring", 1, 125, 125 } },  -- Flask of Oil
  [2996] = { { "Engineering", 1, 130, 130 }, { "Tailoring", 45, 20, 80 } },  -- Bolt of Linen Cloth
  [4339] = { { "Engineering", 2, 205, 245 }, { "Tailoring", 81, 145, 225 } },  -- Bolt of Mageweave
  [10285] = { { "Engineering", 2, 230, 245 }, { "Tailoring", 6, 190, 215 } },  -- Shadow Silk
  [251650] = { { "Engineering", 1, 1, 1 }, { "Tailoring", 6, 1, 1 } },

  -- First Aid
  [1251] = { { "First Aid", 1, 20, 20 } },  -- Linen Bandage
  [2594] = { { "First Aid", 1, 295, 295 } },  -- Flagon of Dwarven Honeymead
  [2686] = { { "First Aid", 1, 160, 160 } },  -- Thunder Ale
  [2723] = { { "First Aid", 1, 90, 90 } },  -- Bottle of Dalaran Noir
  [6452] = { { "First Aid", 1, 140, 140 } },  -- Anti-Venom
  [6453] = { { "First Aid", 1, 300, 300 } },  -- Strong Anti-Venom
  [8544] = { { "First Aid", 1, 140, 140 } },  -- Mageweave Bandage
  [14530] = { { "First Aid", 2, 300, 315 } },  -- Heavy Runecloth Bandage
  [19441] = { { "First Aid", 1, 300, 300 } },  -- Huge Venom Sac
  [23567] = { { "First Aid", 1, 300, 300 } },  -- [PH] Silithus PvP Dust [DEP]
  [255645] = { { "First Aid", 1, 230, 230 } },  -- Swolen Venom Sac

  -- First Aid, Leatherworking, Tailoring
  [2321] = { { "First Aid", 1, 120, 120 }, { "Leatherworking", 86, 70, 190 }, { "Tailoring", 108, 55, 190 } },  -- Fine Thread
  [4291] = { { "First Aid", 1, 220, 220 }, { "Leatherworking", 41, 180, 230 }, { "Tailoring", 47, 125, 220 } },  -- Silken Thread
  [8343] = { { "First Aid", 1, 280, 280 }, { "Leatherworking", 59, 185, 270 }, { "Tailoring", 94, 145, 250 } },  -- Heavy Silken Thread

  -- Leatherworking
  [783] = { { "Leatherworking", 1, 50, 50 } },  -- Light Hide
  [2312] = { { "Leatherworking", 1, 140, 140 } },  -- Fine Leather Gloves
  [2313] = { { "Leatherworking", 2, 95, 95 } },  -- Medium Armor Kit
  [2454] = { { "Leatherworking", 1, 95, 95 } },  -- Elixir of Minor Strength
  [2457] = { { "Leatherworking", 1, 120, 120 } },  -- Elixir of Minor Agility
  [2458] = { { "Leatherworking", 9, 80, 150 } },  -- Elixir of Minor Fortitude
  [2934] = { { "Leatherworking", 1, 20, 20 } },  -- Ruined Leather Scraps
  [3385] = { { "Leatherworking", 1, 155, 155 } },  -- Lesser Mana Potion
  [3389] = { { "Leatherworking", 1, 135, 135 } },  -- Elixir of Lesser Defense
  [3390] = { { "Leatherworking", 1, 140, 140 } },  -- Elixir of Lesser Agility
  [4096] = { { "Leatherworking", 1, 195, 195 } },  -- Coarse Gorilla Hair
  [4231] = { { "Leatherworking", 49, 40, 120 } },  -- Cured Light Hide
  [4232] = { { "Leatherworking", 1, 90, 90 } },  -- Medium Hide
  [4233] = { { "Leatherworking", 45, 125, 205 } },  -- Cured Medium Hide
  [4235] = { { "Leatherworking", 1, 135, 135 } },  -- Heavy Hide
  [4236] = { { "Leatherworking", 49, 155, 245 } },  -- Cured Heavy Hide
  [4243] = { { "Leatherworking", 1, 100, 100 } },  -- Fine Leather Tunic
  [4246] = { { "Leatherworking", 1, 125, 125 } },  -- Fine Leather Belt
  [4253] = { { "Leatherworking", 2, 160, 160 } },  -- Toughened Leather Gloves
  [4265] = { { "Leatherworking", 2, 155, 155 } },  -- Heavy Armor Kit
  [4289] = { { "Leatherworking", 3, 50, 135 } },  -- Salt
  [4321] = { { "Leatherworking", 4, 65, 65 } },  -- Spider Silk Slippers
  [4461] = { { "Leatherworking", 3, 155, 160 } },  -- Raptor Hide
  [5082] = { { "Leatherworking", 1, 65, 65 } },  -- Thin Kodo Leather
  [5116] = { { "Leatherworking", 1, 125, 125 } },  -- Long Tail Feather
  [5373] = { { "Leatherworking", 1, 140, 140 } },  -- Lucky Charm
  [5633] = { { "Leatherworking", 1, 195, 195 } },  -- Great Rage Potion
  [5784] = { { "Leatherworking", 3, 40, 100 } },  -- Slimy Murloc Scale
  [5785] = { { "Leatherworking", 3, 165, 225 } },  -- Thick Murloc Scale
  [6470] = { { "Leatherworking", 12, 80, 150 } },  -- Deviate Scale
  [6471] = { { "Leatherworking", 2, 105, 115 } },  -- Perfect Deviate Scale
  [6662] = { { "Leatherworking", 1, 155, 155 } },  -- Elixir of Giant Growth
  [7286] = { { "Leatherworking", 3, 40, 100 } },  -- Black Whelp Scale
  [7287] = { { "Leatherworking", 1, 120, 120 } },  -- Red Whelp Scale
  [7428] = { { "Leatherworking", 2, 185, 195 } },  -- Shadowcat Hide
  [8154] = { { "Leatherworking", 7, 215, 245 } },  -- Scorpid Scale
  [8165] = { { "Leatherworking", 2, 220, 250 } },  -- Worn Dragonscale
  [8167] = { { "Leatherworking", 7, 200, 230 } },  -- Turtle Scale
  [8169] = { { "Leatherworking", 1, 175, 175 } },  -- Thick Hide
  [8171] = { { "Leatherworking", 1, 225, 225 } },  -- Rugged Hide
  [8172] = { { "Leatherworking", 45, 200, 270 } },  -- Cured Thick Hide
  [8173] = { { "Leatherworking", 2, 205, 205 } },  -- Thick Armor Kit
  [8368] = { { "Leatherworking", 1, 220, 220 } },  -- Thick Wolfhide
  [8949] = { { "Leatherworking", 1, 220, 220 } },  -- Elixir of Agility
  [8951] = { { "Leatherworking", 1, 220, 220 } },  -- Elixir of Defense
  [9206] = { { "Leatherworking", 1, 235, 235 } },  -- Elixir of Greater Strength
  [12607] = { { "Leatherworking", 3, 320, 320 } },  -- Brilliant Chromatic Scale
  [13444] = { { "Leatherworking", 1, 235, 235 } },  -- Major Mana Potion
  [14044] = { { "Leatherworking", 1, 320, 320 } },  -- Cindercloth Cloak
  [15408] = { { "Leatherworking", 46, 250, 320 } },  -- Heavy Scorpid Scale
  [15409] = { { "Leatherworking", 1, 225, 225 } },  -- Refined Deeprock Salt
  [15412] = { { "Leatherworking", 8, 250, 300 } },  -- Green Dragonscale
  [15414] = { { "Leatherworking", 4, 310, 320 } },  -- Red Dragonscale
  [15415] = { { "Leatherworking", 8, 280, 320 } },  -- Blue Dragonscale
  [15416] = { { "Leatherworking", 13, 250, 320 } },  -- Black Dragonscale
  [15419] = { { "Leatherworking", 3, 270, 320 } },  -- Warbear Leather
  [15420] = { { "Leatherworking", 5, 265, 320 } },  -- Ironfeather
  [15422] = { { "Leatherworking", 4, 270, 310 } },  -- Frostsaber Leather
  [15423] = { { "Leatherworking", 5, 250, 285 } },  -- Chimera Leather
  [15564] = { { "Leatherworking", 2, 235, 235 } },  -- Rugged Armor Kit
  [18251] = { { "Leatherworking", 2, 320, 320 } },  -- Core Armor Kit
  [19767] = { { "Leatherworking", 3, 320, 320 } },  -- Primal Bat Leather
  [19768] = { { "Leatherworking", 2, 320, 320 } },  -- Primal Tiger Leather
  [20498] = { { "Leatherworking", 12, 305, 320 } },  -- Silithid Chitin
  [20500] = { { "Leatherworking", 6, 305, 320 } },  -- Light Silithid Carapace
  [20501] = { { "Leatherworking", 6, 310, 320 } },  -- Heavy Silithid Carapace
  [213370] = { { "Leatherworking", 1, 200, 200 } },  -- Irradiated Leather Scraps
  [248824] = { { "Leatherworking", 8, 235, 310 } },  -- Fel Hide
  [248825] = { { "Leatherworking", 52, 310, 320 } },  -- Fel Leather
  [273130] = { { "Leatherworking", 1, 300, 300 } },  -- Undeath Engine

  -- Leatherworking, Tailoring
  [2324] = { { "Leatherworking", 5, 70, 185 }, { "Tailoring", 12, 35, 200 } },  -- Bleach
  [2325] = { { "Leatherworking", 11, 160, 300 }, { "Tailoring", 3, 170, 200 } },  -- Black Dye
  [2455] = { { "Leatherworking", 1, 95, 95 }, { "Tailoring", 1, 55, 55 } },  -- Minor Mana Potion
  [2997] = { { "Leatherworking", 3, 105, 285 }, { "Tailoring", 48, 75, 250 } },  -- Bolt of Woolen Cloth
  [3182] = { { "Leatherworking", 9, 135, 270 }, { "Tailoring", 13, 80, 145 } },  -- Spider's Silk
  [3383] = { { "Leatherworking", 1, 125, 125 }, { "Tailoring", 1, 125, 125 } },  -- Elixir of Wisdom
  [3827] = { { "Leatherworking", 1, 205, 205 }, { "Tailoring", 4, 170, 220 } },  -- Mana Potion
  [4340] = { { "Leatherworking", 8, 40, 140 }, { "Tailoring", 7, 90, 170 } },  -- Gray Dye
  [6260] = { { "Leatherworking", 12, 185, 300 }, { "Tailoring", 16, 50, 185 } },  -- Blue Dye
  [6261] = { { "Leatherworking", 8, 255, 300 }, { "Tailoring", 2, 185, 190 } },  -- Orange Dye
  [14048] = { { "Leatherworking", 2, 285, 285 }, { "Tailoring", 181, 1, 320 } },  -- Bolt of Runecloth
  [14256] = { { "Leatherworking", 1, 300, 300 }, { "Tailoring", 17, 245, 315 } },  -- Felcloth
  [14341] = { { "Leatherworking", 194, 250, 320 }, { "Tailoring", 116, 220, 320 } },  -- Rune Thread
  [14342] = { { "Leatherworking", 2, 310, 320 }, { "Tailoring", 59, 270, 320 } },  -- Mooncloth
  [18240] = { { "Leatherworking", 2, 285, 285 }, { "Tailoring", 1, 285, 285 } },  -- Ogre Tannin
  [213372] = { { "Leatherworking", 3, 225, 225 }, { "Tailoring", 1, 225, 225 } },

  -- Mining
  [2770] = { { "Mining", 1, 25, 25 } },  -- Copper Ore
  [2771] = { { "Mining", 1, 50, 50 } },  -- Tin Ore
  [2776] = { { "Mining", 1, 170, 170 } },  -- Gold Ore
  [3576] = { { "Mining", 1, 65, 65 } },  -- Tin Bar
  [3857] = { { "Mining", 2, 165, 275 } },  -- Coal
  [7911] = { { "Mining", 1, 230, 230 } },  -- Truesilver Ore
  [11370] = { { "Mining", 1, 230, 230 } },  -- Dark Iron Ore
  [18562] = { { "Mining", 1, 310, 310 } },  -- Elementium Ore
  [248815] = { { "Mining", 1, 300, 300 } },  -- Heavy Thorium Ore

  -- Tailoring
  [118] = { { "Tailoring", 1, 55, 55 } },  -- Minor Healing Potion
  [929] = { { "Tailoring", 1, 145, 145 } },  -- Healing Potion
  [2604] = { { "Tailoring", 31, 50, 300 } },  -- Red Dye
  [4320] = { { "Tailoring", 1, 150, 150 } },  -- Spidersilk Boots
  [4341] = { { "Tailoring", 1, 120, 120 } },  -- Yellow Dye
  [4589] = { { "Tailoring", 1, 215, 215 } },  -- Long Elegant Feather
  [7072] = { { "Tailoring", 1, 175, 175 } },  -- Naga Scale
  [9210] = { { "Tailoring", 12, 230, 315 } },  -- Ghost Dye
  [10290] = { { "Tailoring", 1, 200, 200 } },  -- Pink Dye
  [11040] = { { "Tailoring", 1, 245, 245 } },  -- Morrowgrain
  [213378] = { { "Tailoring", 1, 200, 200 } },  -- Unstable Microfilament
  [273131] = { { "Tailoring", 1, 300, 300 } },  -- Bottled Screams
}
