-- Bagwise: reagent-to-profession mapping with recipe stats
-- For each reagent item: which professions use it, how many
-- recipes, and the skill level range.
-- Generated from wago.tools DB2 build 1.15.9.70576. Do not edit by hand.
--
-- 501 reagent items across 9 professions.

Bagwise                         = Bagwise or {}
Bagwise.Data                    = Bagwise.Data or {}

-- Format: [itemID] = { { profession, recipe_count, min_level, max_level }, ... }
Bagwise.Data.ReagentProfessions = {
  -- Alchemy
  [118] = { { "Alchemy", 1, 85, 85 } },  -- Minor Healing Potion
  [765] = { { "Alchemy", 5, 55, 80 } },  -- Silverleaf
  [785] = { { "Alchemy", 6, 65, 145 } },  -- Mageroyal
  [2447] = { { "Alchemy", 5, 55, 80 } },  -- Peacebloom
  [2449] = { { "Alchemy", 6, 55, 175 } },  -- Earthroot
  [2450] = { { "Alchemy", 6, 85, 150 } },  -- Briarthorn
  [2453] = { { "Alchemy", 5, 130, 200 } },  -- Bruiseweed
  [2456] = { { "Alchemy", 1, 225, 225 } },  -- Minor Rejuvenation Potion
  [3164] = { { "Alchemy", 1, 80, 80 } },  -- Discolored Worg Heart
  [3355] = { { "Alchemy", 6, 135, 215 } },  -- Wild Steelbloom
  [3357] = { { "Alchemy", 4, 175, 210 } },  -- Liferoot
  [3358] = { { "Alchemy", 7, 210, 250 } },  -- Khadgar's Whisker
  [3369] = { { "Alchemy", 3, 90, 190 } },  -- Grave Moss
  [3818] = { { "Alchemy", 4, 185, 220 } },  -- Fadeleaf
  [3820] = { { "Alchemy", 8, 90, 210 } },  -- Stranglekelp
  [5636] = { { "Alchemy", 1, 150, 150 } },  -- Delicate Feather
  [6358] = { { "Alchemy", 1, 80, 80 } },  -- Oily Blackmouth
  [6359] = { { "Alchemy", 1, 150, 150 } },  -- Firefin Snapper
  [8836] = { { "Alchemy", 2, 245, 255 } },  -- Arthas' Tears
  [8839] = { { "Alchemy", 5, 250, 275 } },  -- Blindweed
  [8845] = { { "Alchemy", 5, 250, 275 } },  -- Ghost Mushroom
  [8846] = { { "Alchemy", 7, 260, 315 } },  -- Gromsblood
  [9260] = { { "Alchemy", 1, 225, 225 } },  -- Volatile Rum
  [13422] = { { "Alchemy", 1, 250, 250 } },  -- Stonescale Eel
  [13423] = { { "Alchemy", 4, 280, 315 } },  -- Stonescale Oil
  [13463] = { { "Alchemy", 15, 285, 315 } },  -- Dreamfoil
  [13464] = { { "Alchemy", 3, 290, 310 } },  -- Golden Sansam
  [13465] = { { "Alchemy", 8, 290, 315 } },  -- Mountain Silversage
  [13466] = { { "Alchemy", 8, 270, 315 } },  -- Plaguebloom
  [13511] = { { "Alchemy", 1, 315, 315 } },  -- Flask of Distilled Wisdom
  [13513] = { { "Alchemy", 1, 315, 315 } },  -- Flask of Chromatic Resistance
  [19943] = { { "Alchemy", 1, 315, 315 } },  -- Massive Mojo
  [213371] = { { "Alchemy", 2, 200, 225 } },  -- Crate of Tainted Gniodine Solution
  [221312] = { { "Alchemy", 1, 250, 250 } },  -- Flask of Atal'ai Mojo
  [241652] = { { "Alchemy", 1, 270, 270 } },  -- Discolored Beast Heart

  -- Alchemy, Blacksmithing
  [5635] = { { "Alchemy", 1, 90, 90 }, { "Blacksmithing", 2, 185, 200 } },  -- Sharp Claw
  [13510] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 1, 320, 320 } },  -- Flask of the Titans
  [13512] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 4, 320, 320 } },  -- Flask of Supreme Power

  -- Alchemy, Blacksmithing, Enchanting
  [234006] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 3, 320, 320 }, { "Enchanting", 2, 320, 320 } },  -- Monstrous Silithid Chitin

  -- Alchemy, Blacksmithing, Enchanting, Engineering
  [12359] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 75, 260, 320 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 9, 270, 320 } },  -- Thorium Bar

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [7067] = { { "Alchemy", 2, 225, 305 }, { "Blacksmithing", 3, 205, 300 }, { "Enchanting", 1, 195, 195 }, { "Engineering", 3, 225, 320 }, { "Leatherworking", 4, 160, 210 }, { "Tailoring", 5, 190, 215 } },  -- Elemental Earth
  [7076] = { { "Alchemy", 3, 275, 315 }, { "Blacksmithing", 16, 295, 320 }, { "Enchanting", 3, 310, 320 }, { "Engineering", 3, 320, 320 }, { "Leatherworking", 5, 305, 320 }, { "Tailoring", 3, 305, 315 } },  -- Essence of Earth
  [7077] = { { "Alchemy", 1, 301, 301 }, { "Blacksmithing", 15, 260, 320 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 3, 205, 285 }, { "Leatherworking", 1, 270, 270 }, { "Tailoring", 5, 240, 290 } },  -- Heart of Fire
  [7078] = { { "Alchemy", 2, 275, 315 }, { "Blacksmithing", 5, 305, 325 }, { "Enchanting", 9, 285, 320 }, { "Engineering", 2, 280, 320 }, { "Leatherworking", 14, 290, 320 }, { "Tailoring", 13, 290, 320 } },  -- Essence of Fire
  [7080] = { { "Alchemy", 3, 275, 315 }, { "Blacksmithing", 12, 310, 320 }, { "Enchanting", 9, 305, 320 }, { "Engineering", 1, 310, 310 }, { "Leatherworking", 19, 250, 320 }, { "Tailoring", 18, 250, 315 } },  -- Essence of Water
  [8153] = { { "Alchemy", 1, 240, 240 }, { "Blacksmithing", 2, 290, 295 }, { "Enchanting", 1, 270, 270 }, { "Engineering", 1, 265, 265 }, { "Leatherworking", 6, 240, 270 }, { "Tailoring", 3, 240, 265 } },  -- Wildvine
  [12803] = { { "Alchemy", 2, 275, 315 }, { "Blacksmithing", 11, 290, 320 }, { "Enchanting", 4, 320, 320 }, { "Engineering", 3, 285, 320 }, { "Leatherworking", 19, 290, 320 }, { "Tailoring", 12, 250, 320 } },  -- Living Essence

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Tailoring
  [7068] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 215, 215 }, { "Enchanting", 1, 195, 195 }, { "Engineering", 5, 225, 320 }, { "Tailoring", 5, 210, 290 } },  -- Elemental Fire
  [7972] = { { "Alchemy", 1, 230, 230 }, { "Blacksmithing", 1, 275, 275 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 1, 260, 260 }, { "Tailoring", 1, 275, 275 } },  -- Ichor of Undeath
  [12808] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 4, 315, 320 }, { "Enchanting", 4, 315, 320 }, { "Engineering", 2, 260, 320 }, { "Tailoring", 4, 300, 315 } },  -- Essence of Undeath

  -- Alchemy, Blacksmithing, Enchanting, Leatherworking
  [5637] = { { "Alchemy", 1, 195, 195 }, { "Blacksmithing", 3, 200, 210 }, { "Enchanting", 2, 195, 200 }, { "Leatherworking", 2, 170, 175 } },  -- Large Fang

  -- Alchemy, Blacksmithing, Enchanting, Leatherworking, Tailoring
  [12938] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 3, 280, 285 }, { "Enchanting", 6, 305, 320 }, { "Leatherworking", 6, 280, 285 }, { "Tailoring", 4, 280, 300 } },  -- Blood of Heroes

  -- Alchemy, Blacksmithing, Engineering
  [3860] = { { "Alchemy", 1, 240, 240 }, { "Blacksmithing", 36, 225, 285 }, { "Engineering", 34, 1, 285 } },  -- Mithril Bar

  -- Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring
  [12804] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 5, 305, 325 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 4, 310, 320 }, { "Tailoring", 2, 315, 315 } },  -- Powerful Mojo
  [220688] = { { "Alchemy", 2, 250, 250 }, { "Blacksmithing", 3, 250, 250 }, { "Engineering", 3, 250, 250 }, { "Leatherworking", 7, 250, 250 }, { "Tailoring", 3, 250, 250 } },  -- Inert Mantle of Nightmares
  [221021] = { { "Alchemy", 3, 250, 250 }, { "Blacksmithing", 3, 250, 250 }, { "Engineering", 3, 250, 250 }, { "Leatherworking", 7, 250, 250 }, { "Tailoring", 3, 250, 250 } },  -- Nightmare Seed

  -- Alchemy, Blacksmithing, Engineering, Mining
  [3575] = { { "Alchemy", 2, 240, 240 }, { "Blacksmithing", 23, 150, 210 }, { "Engineering", 6, 160, 215 }, { "Mining", 1, 165, 165 } },  -- Iron Bar

  -- Alchemy, Blacksmithing, Engineering, Tailoring
  [7069] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 215, 215 }, { "Engineering", 1, 270, 270 }, { "Tailoring", 1, 210, 210 } },  -- Elemental Air

  -- Alchemy, Blacksmithing, Leatherworking, Tailoring
  [3824] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 225, 225 }, { "Leatherworking", 3, 195, 220 }, { "Tailoring", 1, 190, 190 } },  -- Shadow Oil
  [7070] = { { "Alchemy", 1, 305, 305 }, { "Blacksmithing", 1, 215, 215 }, { "Leatherworking", 1, 200, 200 }, { "Tailoring", 2, 195, 210 } },  -- Elemental Water

  -- Alchemy, Cooking
  [3821] = { { "Alchemy", 12, 195, 255 }, { "Cooking", 1, 215, 215 } },  -- Goldthorn
  [6522] = { { "Alchemy", 1, 120, 120 }, { "Cooking", 1, 125, 125 } },  -- Deviate Fish

  -- Alchemy, Cooking, Enchanting
  [2452] = { { "Alchemy", 5, 80, 165 }, { "Cooking", 1, 100, 100 }, { "Enchanting", 1, 320, 320 } },  -- Swiftthistle

  -- Alchemy, Cooking, Engineering
  [4402] = { { "Alchemy", 1, 210, 210 }, { "Cooking", 1, 240, 240 }, { "Engineering", 1, 125, 125 } },  -- Small Flame Sac

  -- Alchemy, Enchanting
  [3371] = { { "Alchemy", 21, 55, 150 }, { "Enchanting", 1, 55, 55 } },  -- Empty Vial
  [3372] = { { "Alchemy", 33, 90, 250 }, { "Enchanting", 3, 100, 210 } },  -- Leaded Vial
  [3819] = { { "Alchemy", 3, 205, 220 }, { "Enchanting", 1, 210, 210 } },  -- Wintersbite
  [6370] = { { "Alchemy", 4, 120, 190 }, { "Enchanting", 1, 170, 170 } },  -- Blackmouth Oil
  [8838] = { { "Alchemy", 6, 230, 280 }, { "Enchanting", 1, 245, 245 } },  -- Sungrass
  [8925] = { { "Alchemy", 61, 210, 315 }, { "Enchanting", 3, 260, 285 } },  -- Crystal Vial
  [11083] = { { "Alchemy", 1, 90, 90 }, { "Enchanting", 18, 155, 190 } },  -- Soul Dust
  [18256] = { { "Alchemy", 1, 310, 310 }, { "Enchanting", 3, 310, 310 } },  -- Imbued Vial

  -- Alchemy, Enchanting, Engineering
  [13467] = { { "Alchemy", 6, 300, 315 }, { "Enchanting", 1, 305, 305 }, { "Engineering", 1, 280, 280 } },  -- Icecap
  [234010] = { { "Alchemy", 1, 315, 315 }, { "Enchanting", 9, 320, 320 }, { "Engineering", 1, 315, 315 } },  -- Ancient Sandworm Bile
  [234011] = { { "Alchemy", 5, 315, 315 }, { "Enchanting", 8, 320, 320 }, { "Engineering", 2, 315, 315 } },  -- Qiraji Stalker Venom
  [234012] = { { "Alchemy", 5, 315, 315 }, { "Enchanting", 11, 320, 320 }, { "Engineering", 1, 315, 315 } },  -- Hive Thistle

  -- Alchemy, Enchanting, Engineering, Leatherworking, Tailoring
  [7082] = { { "Alchemy", 2, 275, 315 }, { "Enchanting", 9, 305, 320 }, { "Engineering", 1, 320, 320 }, { "Leatherworking", 7, 295, 320 }, { "Tailoring", 1, 315, 315 } },  -- Essence of Air

  -- Alchemy, Enchanting, Leatherworking
  [3356] = { { "Alchemy", 8, 150, 210 }, { "Enchanting", 1, 170, 170 }, { "Leatherworking", 1, 160, 160 } },  -- Kingsblood

  -- Alchemy, Enchanting, Tailoring
  [4625] = { { "Alchemy", 4, 220, 265 }, { "Enchanting", 3, 285, 310 }, { "Tailoring", 2, 265, 265 } },  -- Firebloom
  [6371] = { { "Alchemy", 3, 165, 265 }, { "Enchanting", 1, 150, 150 }, { "Tailoring", 4, 200, 225 } },  -- Fire Oil
  [8831] = { { "Alchemy", 6, 225, 255 }, { "Enchanting", 4, 260, 320 }, { "Tailoring", 1, 290, 290 } },  -- Purple Lotus
  [11176] = { { "Alchemy", 1, 305, 305 }, { "Enchanting", 15, 200, 290 }, { "Tailoring", 3, 290, 315 } },  -- Dream Dust
  [13468] = { { "Alchemy", 7, 315, 315 }, { "Enchanting", 1, 320, 320 }, { "Tailoring", 1, 315, 315 } },  -- Black Lotus
  [16203] = { { "Alchemy", 4, 315, 315 }, { "Enchanting", 29, 295, 320 }, { "Tailoring", 1, 290, 290 } },  -- Greater Eternal Essence

  -- Alchemy, Engineering
  [9262] = { { "Alchemy", 2, 240, 315 }, { "Engineering", 1, 205, 205 } },  -- Black Vitriol
  [12363] = { { "Alchemy", 1, 275, 275 }, { "Engineering", 1, 320, 320 } },  -- Arcane Crystal
  [215430] = { { "Alchemy", 1, 225, 225 }, { "Engineering", 2, 225, 225 } },  -- Gnomeregan Fallout

  -- Alchemy, Engineering, Tailoring
  [10286] = { { "Alchemy", 2, 300, 310 }, { "Engineering", 1, 265, 265 }, { "Tailoring", 3, 240, 265 } },  -- Heart of the Wild

  -- Alchemy, First Aid
  [1288] = { { "Alchemy", 1, 145, 145 }, { "First Aid", 1, 130, 130 } },  -- Large Venom Sac

  -- Alchemy, Leatherworking
  [15410] = { { "Alchemy", 1, 315, 315 }, { "Leatherworking", 2, 320, 320 } },  -- Scale of Onyxia

  -- Alchemy, Mining
  [3858] = { { "Alchemy", 1, 230, 230 }, { "Mining", 1, 175, 175 } },  -- Mithril Ore
  [10620] = { { "Alchemy", 1, 295, 295 }, { "Mining", 1, 250, 250 } },  -- Thorium Ore

  -- Alchemy, Tailoring
  [4342] = { { "Alchemy", 1, 260, 260 }, { "Tailoring", 2, 195, 235 } },  -- Purple Dye

  -- Blacksmithing
  [2863] = { { "Blacksmithing", 1, 100, 100 } },  -- Coarse Sharpening Stone
  [2870] = { { "Blacksmithing", 1, 175, 175 } },  -- Shining Silver Breastplate
  [3391] = { { "Blacksmithing", 1, 175, 175 } },  -- Elixir of Ogre's Strength
  [3466] = { { "Blacksmithing", 18, 140, 225 } },  -- Strong Flux
  [3470] = { { "Blacksmithing", 15, 70, 140 } },  -- Rough Grinding Stone
  [3478] = { { "Blacksmithing", 18, 140, 190 } },  -- Coarse Grinding Stone
  [3486] = { { "Blacksmithing", 34, 150, 225 } },  -- Heavy Grinding Stone
  [3823] = { { "Blacksmithing", 1, 270, 270 } },  -- Lesser Invisibility Potion
  [4255] = { { "Blacksmithing", 1, 205, 205 } },  -- Green Leather Armor
  [5966] = { { "Blacksmithing", 1, 245, 245 } },  -- Guardian Gloves
  [7966] = { { "Blacksmithing", 22, 200, 285 } },  -- Solid Grinding Stone
  [11184] = { { "Blacksmithing", 1, 275, 275 } },  -- Blue Power Crystal
  [11185] = { { "Blacksmithing", 1, 300, 300 } },  -- Green Power Crystal
  [11186] = { { "Blacksmithing", 2, 270, 320 } },  -- Red Power Crystal
  [11188] = { { "Blacksmithing", 2, 270, 300 } },  -- Yellow Power Crystal
  [12644] = { { "Blacksmithing", 20, 275, 325 } },  -- Dense Grinding Stone
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

  -- Blacksmithing, Enchanting
  [7081] = { { "Blacksmithing", 2, 270, 285 }, { "Enchanting", 1, 285, 285 } },  -- Breath of Wind
  [10938] = { { "Blacksmithing", 1, 100, 100 }, { "Enchanting", 9, 5, 115 } },  -- Lesser Magic Essence
  [11382] = { { "Blacksmithing", 6, 320, 325 }, { "Enchanting", 1, 285, 285 } },  -- Blood of the Mountain
  [234004] = { { "Blacksmithing", 7, 320, 320 }, { "Enchanting", 1, 320, 320 } },  -- Obsidian Grinding Stone

  -- Blacksmithing, Enchanting, Engineering
  [7909] = { { "Blacksmithing", 9, 240, 315 }, { "Enchanting", 1, 245, 245 }, { "Engineering", 5, 230, 285 } },  -- Aquamarine
  [20725] = { { "Blacksmithing", 3, 320, 320 }, { "Enchanting", 38, 305, 320 }, { "Engineering", 2, 315, 320 } },  -- Nexus Crystal
  [234003] = { { "Blacksmithing", 10, 320, 320 }, { "Enchanting", 12, 320, 320 }, { "Engineering", 3, 315, 320 } },  -- Obsidian-Infused Thorium Bar

  -- Blacksmithing, Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [14047] = { { "Blacksmithing", 1, 255, 255 }, { "Enchanting", 1, 320, 320 }, { "Engineering", 11, 250, 320 }, { "First Aid", 3, 260, 300 }, { "Leatherworking", 7, 290, 320 }, { "Tailoring", 1, 255, 255 } },  -- Runecloth

  -- Blacksmithing, Enchanting, Engineering, Leatherworking
  [7075] = { { "Blacksmithing", 2, 260, 270 }, { "Enchanting", 1, 285, 285 }, { "Engineering", 2, 205, 285 }, { "Leatherworking", 4, 250, 290 } },  -- Core of Earth

  -- Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [1210] = { { "Blacksmithing", 7, 120, 255 }, { "Enchanting", 1, 130, 130 }, { "Engineering", 3, 145, 205 }, { "Leatherworking", 1, 210, 210 }, { "Tailoring", 1, 170, 170 } },  -- Shadowgem
  [8170] = { { "Blacksmithing", 15, 285, 315 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 10, 275, 320 }, { "Leatherworking", 99, 250, 320 }, { "Tailoring", 9, 275, 315 } },  -- Rugged Leather
  [12810] = { { "Blacksmithing", 27, 320, 320 }, { "Enchanting", 12, 320, 320 }, { "Engineering", 6, 290, 320 }, { "Leatherworking", 33, 315, 320 }, { "Tailoring", 19, 300, 320 } },  -- Enchanted Leather
  [12811] = { { "Blacksmithing", 10, 260, 320 }, { "Enchanting", 8, 305, 320 }, { "Engineering", 1, 305, 305 }, { "Leatherworking", 16, 260, 285 }, { "Tailoring", 10, 260, 315 } },  -- Righteous Orb

  -- Blacksmithing, Enchanting, Engineering, Tailoring
  [3829] = { { "Blacksmithing", 2, 215, 225 }, { "Enchanting", 1, 255, 255 }, { "Engineering", 3, 175, 280 }, { "Tailoring", 1, 220, 220 } },  -- Frost Oil
  [6037] = { { "Blacksmithing", 27, 200, 320 }, { "Enchanting", 1, 235, 235 }, { "Engineering", 12, 200, 295 }, { "Tailoring", 1, 265, 265 } },  -- Truesilver Bar

  -- Blacksmithing, Enchanting, Leatherworking
  [2459] = { { "Blacksmithing", 1, 155, 155 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 1, 220, 220 } },  -- Swiftness Potion
  [11754] = { { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 1, 320, 320 } },  -- Black Diamond
  [12753] = { { "Blacksmithing", 1, 320, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 2, 320, 320 } },  -- Skin of Shadow

  -- Blacksmithing, Enchanting, Leatherworking, Tailoring
  [5500] = { { "Blacksmithing", 3, 140, 175 }, { "Enchanting", 1, 175, 175 }, { "Leatherworking", 1, 205, 205 }, { "Tailoring", 3, 150, 150 } },  -- Iridescent Pearl
  [7971] = { { "Blacksmithing", 3, 255, 265 }, { "Enchanting", 1, 220, 220 }, { "Leatherworking", 3, 210, 295 }, { "Tailoring", 1, 295, 295 } },  -- Black Pearl
  [12809] = { { "Blacksmithing", 4, 320, 320 }, { "Enchanting", 1, 320, 320 }, { "Leatherworking", 4, 310, 320 }, { "Tailoring", 3, 305, 315 } },  -- Guardian Stone

  -- Blacksmithing, Engineering
  [774] = { { "Blacksmithing", 4, 75, 110 }, { "Engineering", 4, 90, 250 } },  -- Malachite
  [818] = { { "Blacksmithing", 5, 100, 205 }, { "Engineering", 3, 130, 250 } },  -- Tigerseye
  [1705] = { { "Blacksmithing", 13, 140, 265 }, { "Engineering", 2, 170, 220 } },  -- Lesser Moonstone
  [2835] = { { "Blacksmithing", 3, 15, 45 }, { "Engineering", 1, 20, 20 } },  -- Rough Stone
  [2836] = { { "Blacksmithing", 3, 65, 75 }, { "Engineering", 1, 85, 85 } },  -- Coarse Stone
  [2838] = { { "Blacksmithing", 3, 125, 125 }, { "Engineering", 1, 125, 125 } },  -- Heavy Stone
  [2841] = { { "Blacksmithing", 25, 125, 180 }, { "Engineering", 10, 105, 150 } },  -- Bronze Bar
  [2842] = { { "Blacksmithing", 12, 100, 320 }, { "Engineering", 2, 110, 155 } },  -- Silver Bar
  [2880] = { { "Blacksmithing", 13, 55, 150 }, { "Engineering", 3, 80, 115 } },  -- Weak Flux
  [3859] = { { "Blacksmithing", 22, 200, 235 }, { "Engineering", 1, 175, 175 } },  -- Steel Bar
  [7912] = { { "Blacksmithing", 3, 200, 200 }, { "Engineering", 1, 175, 175 } },  -- Solid Stone
  [11371] = { { "Blacksmithing", 23, 285, 325 }, { "Engineering", 5, 295, 320 } },  -- Dark Iron Bar
  [12361] = { { "Blacksmithing", 15, 270, 320 }, { "Engineering", 2, 280, 295 } },  -- Blue Sapphire
  [12365] = { { "Blacksmithing", 4, 255, 300 }, { "Engineering", 2, 250, 315 } },  -- Dense Stone
  [12799] = { { "Blacksmithing", 17, 295, 320 }, { "Engineering", 3, 295, 320 } },  -- Large Opal
  [19774] = { { "Blacksmithing", 6, 320, 320 }, { "Engineering", 2, 320, 320 } },  -- Souldarite
  [22202] = { { "Blacksmithing", 13, 315, 320 }, { "Engineering", 1, 315, 315 } },  -- Small Obsidian Shard
  [213383] = { { "Blacksmithing", 1, 225, 225 }, { "Engineering", 2, 225, 225 } },  -- Polished Truesilver Gears

  -- Blacksmithing, Engineering, First Aid, Leatherworking, Tailoring
  [4338] = { { "Blacksmithing", 5, 225, 265 }, { "Engineering", 5, 200, 255 }, { "First Aid", 2, 210, 240 }, { "Leatherworking", 1, 230, 230 }, { "Tailoring", 1, 180, 180 } },  -- Mageweave Cloth

  -- Blacksmithing, Engineering, First Aid, Tailoring
  [2589] = { { "Blacksmithing", 4, 15, 65 }, { "Engineering", 4, 30, 95 }, { "First Aid", 2, 30, 50 }, { "Tailoring", 1, 25, 25 } },  -- Linen Cloth
  [2592] = { { "Blacksmithing", 2, 65, 125 }, { "Engineering", 7, 115, 175 }, { "First Aid", 2, 80, 115 }, { "Tailoring", 1, 90, 90 } },  -- Wool Cloth
  [4306] = { { "Blacksmithing", 1, 200, 200 }, { "Engineering", 5, 160, 185 }, { "First Aid", 2, 150, 180 }, { "Tailoring", 1, 135, 135 } },  -- Silk Cloth

  -- Blacksmithing, Engineering, Leatherworking
  [1206] = { { "Blacksmithing", 6, 140, 265 }, { "Engineering", 5, 135, 175 }, { "Leatherworking", 1, 190, 190 } },  -- Moss Agate
  [213376] = { { "Blacksmithing", 2, 225, 225 }, { "Engineering", 1, 225, 225 }, { "Leatherworking", 2, 225, 225 } },  -- Low-Background Truesilver Plates

  -- Blacksmithing, Engineering, Leatherworking, Mining, Tailoring
  [17010] = { { "Blacksmithing", 15, 315, 325 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 6, 315, 320 }, { "Mining", 1, 310, 310 }, { "Tailoring", 5, 315, 320 } },  -- Fiery Core

  -- Blacksmithing, Engineering, Leatherworking, Tailoring
  [1529] = { { "Blacksmithing", 6, 200, 260 }, { "Engineering", 6, 180, 265 }, { "Leatherworking", 3, 205, 310 }, { "Tailoring", 1, 265, 265 } },  -- Jade
  [2318] = { { "Blacksmithing", 5, 70, 110 }, { "Engineering", 2, 130, 130 }, { "Leatherworking", 28, 30, 125 }, { "Tailoring", 6, 50, 120 } },  -- Light Leather
  [2319] = { { "Blacksmithing", 12, 135, 175 }, { "Engineering", 9, 125, 185 }, { "Leatherworking", 22, 115, 170 }, { "Tailoring", 3, 145, 160 } },  -- Medium Leather
  [3864] = { { "Blacksmithing", 13, 195, 285 }, { "Engineering", 10, 195, 260 }, { "Leatherworking", 1, 205, 205 }, { "Tailoring", 1, 220, 220 } },  -- Citrine
  [4234] = { { "Blacksmithing", 16, 180, 240 }, { "Engineering", 16, 135, 245 }, { "Leatherworking", 39, 150, 220 }, { "Tailoring", 8, 165, 220 } },  -- Heavy Leather
  [4304] = { { "Blacksmithing", 13, 245, 285 }, { "Engineering", 8, 225, 265 }, { "Leatherworking", 43, 210, 275 }, { "Tailoring", 5, 225, 265 } },  -- Thick Leather
  [17011] = { { "Blacksmithing", 15, 315, 325 }, { "Engineering", 3, 320, 320 }, { "Leatherworking", 6, 315, 320 }, { "Tailoring", 3, 315, 315 } },  -- Lava Core
  [19726] = { { "Blacksmithing", 10, 320, 320 }, { "Engineering", 2, 320, 320 }, { "Leatherworking", 12, 320, 320 }, { "Tailoring", 9, 315, 315 } },  -- Bloodvine
  [213369] = { { "Blacksmithing", 1, 225, 225 }, { "Engineering", 2, 225, 225 }, { "Leatherworking", 4, 225, 225 }, { "Tailoring", 1, 225, 225 } },  -- Faintly Glowing Leather
  [213379] = { { "Blacksmithing", 2, 225, 225 }, { "Engineering", 1, 225, 225 }, { "Leatherworking", 2, 225, 225 }, { "Tailoring", 1, 225, 225 } },  -- Hyperconductive Arcano-Filament

  -- Blacksmithing, Engineering, Mining
  [2840] = { { "Blacksmithing", 23, 15, 140 }, { "Engineering", 9, 30, 105 }, { "Mining", 1, 65, 65 } },  -- Copper Bar
  [12655] = { { "Blacksmithing", 39, 290, 325 }, { "Engineering", 1, 320, 320 }, { "Mining", 1, 315, 315 } },  -- Enchanted Thorium Bar

  -- Blacksmithing, Engineering, Mining, Tailoring
  [12360] = { { "Blacksmithing", 61, 275, 325 }, { "Engineering", 6, 305, 320 }, { "Mining", 1, 310, 310 }, { "Tailoring", 1, 315, 315 } },  -- Arcanite Bar

  -- Blacksmithing, Engineering, Tailoring
  [3577] = { { "Blacksmithing", 21, 150, 320 }, { "Engineering", 2, 150, 225 }, { "Tailoring", 4, 285, 305 } },  -- Gold Bar
  [7910] = { { "Blacksmithing", 22, 265, 325 }, { "Engineering", 11, 245, 310 }, { "Tailoring", 2, 315, 315 } },  -- Star Ruby
  [12364] = { { "Blacksmithing", 19, 290, 325 }, { "Engineering", 1, 310, 310 }, { "Tailoring", 1, 315, 315 } },  -- Huge Emerald
  [12800] = { { "Blacksmithing", 15, 305, 325 }, { "Engineering", 4, 275, 320 }, { "Tailoring", 2, 315, 315 } },  -- Azerothian Diamond

  -- Blacksmithing, Leatherworking
  [8146] = { { "Blacksmithing", 5, 320, 320 }, { "Leatherworking", 1, 245, 245 } },  -- Wicked Claw
  [8168] = { { "Blacksmithing", 2, 320, 320 }, { "Leatherworking", 1, 270, 270 } },  -- Jet Black Feather
  [15417] = { { "Blacksmithing", 1, 320, 320 }, { "Leatherworking", 4, 310, 320 } },  -- Devilsaur Leather

  -- Blacksmithing, Leatherworking, Tailoring
  [2321] = { { "Blacksmithing", 1, 85, 85 }, { "Leatherworking", 54, 105, 210 }, { "Tailoring", 58, 95, 205 } },  -- Fine Thread
  [2605] = { { "Blacksmithing", 6, 175, 195 }, { "Leatherworking", 3, 175, 200 }, { "Tailoring", 9, 85, 200 } },  -- Green Dye
  [5498] = { { "Blacksmithing", 2, 140, 180 }, { "Leatherworking", 2, 115, 175 }, { "Tailoring", 2, 115, 125 } },  -- Small Lustrous Pearl
  [17012] = { { "Blacksmithing", 2, 320, 320 }, { "Leatherworking", 5, 315, 320 }, { "Tailoring", 3, 315, 315 } },  -- Core Leather
  [20381] = { { "Blacksmithing", 1, 320, 320 }, { "Leatherworking", 3, 320, 320 }, { "Tailoring", 2, 320, 320 } },  -- Dreamscale
  [22682] = { { "Blacksmithing", 3, 320, 320 }, { "Leatherworking", 6, 320, 320 }, { "Tailoring", 4, 315, 315 } },  -- Frozen Rune
  [211422] = { { "Blacksmithing", 1, 175, 175 }, { "Leatherworking", 2, 160, 160 }, { "Tailoring", 1, 150, 150 } },  -- Shard of the Void
  [236656] = { { "Blacksmithing", 3, 320, 320 }, { "Leatherworking", 6, 320, 320 }, { "Tailoring", 7, 315, 315 } },  -- Frozen Rune

  -- Blacksmithing, Mining
  [22203] = { { "Blacksmithing", 8, 320, 320 }, { "Mining", 1, 315, 315 } },  -- Large Obsidian Shard

  -- Blacksmithing, Tailoring
  [12662] = { { "Blacksmithing", 4, 305, 325 }, { "Tailoring", 4, 315, 315 } },  -- Demonic Rune
  [20520] = { { "Blacksmithing", 4, 320, 320 }, { "Tailoring", 4, 300, 315 } },  -- Dark Rune

  -- Cooking
  [723] = { { "Cooking", 1, 90, 90 } },  -- Goretusk Liver
  [729] = { { "Cooking", 1, 115, 115 } },  -- Stringy Vulture Meat
  [730] = { { "Cooking", 1, 115, 115 } },  -- Murloc Eye
  [731] = { { "Cooking", 1, 115, 115 } },  -- Goretusk Snout
  [769] = { { "Cooking", 1, 45, 45 } },  -- Chunk of Boar Meat
  [1015] = { { "Cooking", 2, 140, 165 } },  -- Lean Wolf Flank
  [1080] = { { "Cooking", 1, 135, 135 } },  -- Tough Condor Meat
  [1081] = { { "Cooking", 1, 135, 135 } },  -- Crisp Spider Meat
  [1179] = { { "Cooking", 3, 75, 265 } },  -- Ice Cold Milk
  [1468] = { { "Cooking", 1, 130, 130 } },  -- Murloc Fin
  [2251] = { { "Cooking", 1, 150, 150 } },  -- Gooey Spider Leg
  [2596] = { { "Cooking", 1, 215, 215 } },  -- Skin of Dwarven Stout
  [2665] = { { "Cooking", 1, 140, 140 } },  -- Stormwind Seasoning Herbs
  [2672] = { { "Cooking", 2, 45, 50 } },  -- Stringy Wolf Meat
  [2673] = { { "Cooking", 1, 90, 90 } },  -- Coyote Meat
  [2674] = { { "Cooking", 1, 115, 115 } },  -- Crawler Meat
  [2675] = { { "Cooking", 1, 125, 125 } },  -- Crawler Claw
  [2677] = { { "Cooking", 2, 120, 130 } },  -- Boar Ribs
  [2678] = { { "Cooking", 16, 45, 165 } },  -- Mild Spices
  [2692] = { { "Cooking", 21, 130, 325 } },  -- Hot Spices
  [2886] = { { "Cooking", 1, 60, 60 } },  -- Crag Boar Rib
  [2894] = { { "Cooking", 1, 60, 60 } },  -- Rhapsody Malt
  [2924] = { { "Cooking", 1, 120, 120 } },  -- Crocolisk Meat
  [3172] = { { "Cooking", 1, 100, 100 } },  -- Boar Intestines
  [3173] = { { "Cooking", 2, 80, 100 } },  -- Bear Meat
  [3174] = { { "Cooking", 1, 100, 100 } },  -- Spider Ichor
  [3404] = { { "Cooking", 2, 215, 290 } },  -- Buzzard Wing
  [3667] = { { "Cooking", 2, 160, 160 } },  -- Tender Crocolisk Meat
  [3685] = { { "Cooking", 1, 170, 170 } },  -- Raptor Egg
  [3712] = { { "Cooking", 2, 215, 290 } },  -- Turtle Meat
  [3713] = { { "Cooking", 12, 160, 325 } },  -- Soothing Spices
  [3730] = { { "Cooking", 1, 150, 150 } },  -- Big Bear Meat
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
  [5471] = { { "Cooking", 1, 150, 150 } },  -- Stag Meat
  [5503] = { { "Cooking", 2, 90, 130 } },  -- Clam Meat
  [5504] = { { "Cooking", 1, 165, 165 } },  -- Tangy Clam Meat
  [6289] = { { "Cooking", 1, 90, 90 } },  -- Raw Longjaw Mud Snapper
  [6291] = { { "Cooking", 1, 45, 45 } },  -- Raw Brilliant Smallfish
  [6303] = { { "Cooking", 1, 45, 45 } },  -- Raw Slitherskin Mackerel
  [6308] = { { "Cooking", 1, 140, 140 } },  -- Raw Bristle Whisker Catfish
  [6317] = { { "Cooking", 1, 90, 90 } },  -- Raw Loch Frenzy
  [6361] = { { "Cooking", 1, 90, 90 } },  -- Raw Rainbow Fin Albacore
  [6362] = { { "Cooking", 2, 190, 290 } },  -- Raw Rockscale Cod
  [6889] = { { "Cooking", 3, 45, 75 } },  -- Small Egg
  [7974] = { { "Cooking", 1, 265, 265 } },  -- Zesty Clam Meat
  [8365] = { { "Cooking", 1, 215, 215 } },  -- Raw Mithril Head Trout
  [12037] = { { "Cooking", 3, 215, 240 } },  -- Mystery Meat
  [12184] = { { "Cooking", 2, 215, 290 } },  -- Raptor Flesh
  [12202] = { { "Cooking", 2, 215, 260 } },  -- Tiger Meat
  [12203] = { { "Cooking", 2, 215, 260 } },  -- Red Wolf Meat
  [12204] = { { "Cooking", 1, 240, 240 } },  -- Heavy Kodo Meat
  [12205] = { { "Cooking", 1, 240, 240 } },  -- White Spider Meat
  [12206] = { { "Cooking", 1, 265, 265 } },  -- Tender Crab Meat
  [12207] = { { "Cooking", 2, 260, 265 } },  -- Giant Egg
  [12208] = { { "Cooking", 1, 265, 265 } },  -- Tender Wolf Meat
  [12223] = { { "Cooking", 1, 45, 45 } },  -- Meaty Bat Wing
  [13754] = { { "Cooking", 1, 265, 265 } },  -- Raw Glossy Mightfish
  [13755] = { { "Cooking", 1, 280, 280 } },  -- Winter Squid
  [13756] = { { "Cooking", 1, 280, 280 } },  -- Raw Summer Bass
  [13758] = { { "Cooking", 2, 265, 325 } },  -- Raw Redgill
  [13759] = { { "Cooking", 1, 290, 290 } },  -- Raw Nightfin Snapper
  [13760] = { { "Cooking", 1, 290, 290 } },  -- Raw Sunscale Salmon
  [13888] = { { "Cooking", 3, 290, 325 } },  -- Darkclaw Lobster
  [13889] = { { "Cooking", 1, 315, 315 } },  -- Raw Whitescale Salmon
  [13893] = { { "Cooking", 1, 315, 315 } },  -- Large Raw Mightfish
  [17194] = { { "Cooking", 2, 45, 75 } },  -- Holiday Spices
  [17196] = { { "Cooking", 1, 75, 75 } },  -- Holiday Spirits
  [18255] = { { "Cooking", 1, 315, 315 } },  -- Runn Tum Tuber
  [20424] = { { "Cooking", 1, 325, 325 } },  -- Sandworm Meat
  [21024] = { { "Cooking", 1, 325, 325 } },  -- Chimaerok Tenderloin
  [21071] = { { "Cooking", 1, 120, 120 } },  -- Raw Sagefish
  [21153] = { { "Cooking", 1, 215, 215 } },  -- Raw Greater Sagefish
  [227813] = { { "Cooking", 1, 325, 325 } },  -- Drinkable Stratholme Holy Water
  [239016] = { { "Cooking", 3, 260, 260 } },  -- Holy Salts
  [239017] = { { "Cooking", 2, 290, 290 } },  -- Exquisite Spices

  -- Cooking, Enchanting
  [4470] = { { "Cooking", 1, 25, 25 }, { "Enchanting", 3, 75, 120 } },  -- Simple Wood

  -- Cooking, Engineering
  [159] = { { "Cooking", 7, 90, 315 }, { "Engineering", 3, 130, 275 } },  -- Refreshing Spring Water
  [9061] = { { "Cooking", 1, 325, 325 }, { "Engineering", 7, 235, 295 } },  -- Goblin Rocket Fuel

  -- Cooking, Engineering, Leatherworking
  [8150] = { { "Cooking", 2, 325, 325 }, { "Engineering", 1, 250, 250 }, { "Leatherworking", 1, 200, 200 } },  -- Deeprock Salt

  -- Cooking, First Aid
  [23567] = { { "Cooking", 1, 325, 325 }, { "First Aid", 1, 300, 300 } },  -- [PH] Silithus PvP Dust [DEP]

  -- Enchanting
  [6217] = { { "Enchanting", 1, 5, 5 } },  -- Copper Rod
  [6338] = { { "Enchanting", 1, 130, 130 } },  -- Silver Rod
  [9224] = { { "Enchanting", 1, 250, 250 } },  -- Elixir of Demonslaying
  [10939] = { { "Enchanting", 9, 100, 130 } },  -- Greater Magic Essence
  [10940] = { { "Enchanting", 27, 5, 165 } },  -- Strange Dust
  [10978] = { { "Enchanting", 4, 120, 140 } },  -- Small Glimmering Shard
  [10998] = { { "Enchanting", 10, 130, 170 } },  -- Lesser Astral Essence
  [11082] = { { "Enchanting", 6, 160, 175 } },  -- Greater Astral Essence
  [11084] = { { "Enchanting", 4, 165, 175 } },  -- Large Glimmering Shard
  [11128] = { { "Enchanting", 1, 175, 175 } },  -- Golden Rod
  [11134] = { { "Enchanting", 9, 175, 210 } },  -- Lesser Mystic Essence
  [11135] = { { "Enchanting", 10, 195, 220 } },  -- Greater Mystic Essence
  [11138] = { { "Enchanting", 3, 175, 195 } },  -- Small Glowing Shard
  [11139] = { { "Enchanting", 5, 210, 220 } },  -- Large Glowing Shard
  [11144] = { { "Enchanting", 1, 220, 220 } },  -- Truesilver Rod
  [11174] = { { "Enchanting", 9, 200, 250 } },  -- Lesser Nether Essence
  [11175] = { { "Enchanting", 7, 250, 265 } },  -- Greater Nether Essence
  [11177] = { { "Enchanting", 5, 200, 285 } },  -- Small Radiant Shard
  [11178] = { { "Enchanting", 6, 255, 270 } },  -- Large Radiant Shard
  [11291] = { { "Enchanting", 3, 175, 195 } },  -- Star Wood
  [12735] = { { "Enchanting", 1, 320, 320 } },  -- Frayed Abomination Stitching
  [13180] = { { "Enchanting", 1, 320, 320 } },  -- Stratholme Holy Water
  [13458] = { { "Enchanting", 1, 320, 320 } },  -- Greater Nature Protection Potion
  [14343] = { { "Enchanting", 5, 285, 310 } },  -- Small Brilliant Shard
  [16202] = { { "Enchanting", 6, 250, 295 } },  -- Lesser Eternal Essence
  [16204] = { { "Enchanting", 34, 285, 320 } },  -- Illusion Dust
  [16206] = { { "Enchanting", 1, 310, 310 } },  -- Arcanite Rod
  [17034] = { { "Enchanting", 2, 55, 160 } },  -- Maple Seed
  [17035] = { { "Enchanting", 1, 210, 210 } },  -- Stranglethorn Seed
  [17967] = { { "Enchanting", 1, 320, 320 } },  -- Refined Scale of Onyxia

  -- Enchanting, Engineering
  [234005] = { { "Enchanting", 1, 320, 320 }, { "Engineering", 4, 315, 315 } },  -- Obsidian Blasting Powder

  -- Enchanting, Engineering, Leatherworking
  [8151] = { { "Enchanting", 1, 310, 310 }, { "Engineering", 2, 225, 230 }, { "Leatherworking", 4, 235, 240 } },  -- Flask of Mojo

  -- Enchanting, Engineering, Leatherworking, Tailoring
  [7079] = { { "Enchanting", 1, 285, 285 }, { "Engineering", 2, 285, 320 }, { "Leatherworking", 1, 250, 250 }, { "Tailoring", 8, 235, 270 } },  -- Globe of Water
  [234007] = { { "Enchanting", 2, 320, 320 }, { "Engineering", 3, 315, 315 }, { "Leatherworking", 5, 320, 320 }, { "Tailoring", 4, 320, 320 } },  -- Spiked Silithid Chitin

  -- Enchanting, Engineering, Tailoring
  [234008] = { { "Enchanting", 4, 320, 320 }, { "Engineering", 1, 315, 315 }, { "Tailoring", 1, 315, 315 } },  -- Qiraji Silk

  -- Enchanting, Leatherworking
  [7392] = { { "Enchanting", 1, 220, 220 }, { "Leatherworking", 2, 195, 210 } },  -- Green Whelp Scale
  [8152] = { { "Enchanting", 1, 310, 310 }, { "Leatherworking", 2, 260, 260 } },  -- Flask of Big Mojo
  [18512] = { { "Enchanting", 1, 320, 320 }, { "Leatherworking", 11, 320, 320 } },  -- Larval Acid

  -- Enchanting, Mining
  [2772] = { { "Enchanting", 1, 170, 170 }, { "Mining", 1, 130, 130 } },  -- Iron Ore

  -- Enchanting, Tailoring
  [6048] = { { "Enchanting", 1, 160, 160 }, { "Tailoring", 2, 160, 165 } },  -- Shadow Protection Potion
  [11137] = { { "Enchanting", 21, 195, 245 }, { "Tailoring", 2, 225, 240 } },  -- Vision Dust
  [13926] = { { "Enchanting", 2, 310, 320 }, { "Tailoring", 6, 305, 315 } },  -- Golden Pearl
  [14344] = { { "Enchanting", 43, 305, 320 }, { "Tailoring", 5, 315, 315 } },  -- Large Brilliant Shard

  -- Engineering
  [3030] = { { "Engineering", 1, 210, 210 } },  -- Razor Arrow
  [4357] = { { "Engineering", 3, 30, 60 } },  -- Rough Blasting Powder
  [4359] = { { "Engineering", 9, 60, 145 } },  -- Handful of Copper Bolts
  [4361] = { { "Engineering", 3, 80, 130 } },  -- Copper Tube
  [4363] = { { "Engineering", 4, 105, 160 } },  -- Copper Modulator
  [4364] = { { "Engineering", 10, 85, 150 } },  -- Coarse Blasting Powder
  [4368] = { { "Engineering", 1, 175, 175 } },  -- Flying Tiger Goggles
  [4371] = { { "Engineering", 9, 135, 200 } },  -- Bronze Tube
  [4375] = { { "Engineering", 11, 125, 180 } },  -- Whirring Bronze Gizmo
  [4377] = { { "Engineering", 15, 125, 215 } },  -- Heavy Blasting Powder
  [4382] = { { "Engineering", 6, 135, 255 } },  -- Bronze Framework
  [4385] = { { "Engineering", 1, 225, 225 } },  -- Green Tinted Goggles
  [4387] = { { "Engineering", 6, 175, 280 } },  -- Iron Strut
  [4389] = { { "Engineering", 11, 175, 245 } },  -- Gyrochronatom
  [4394] = { { "Engineering", 1, 205, 205 } },  -- Big Iron Bomb
  [4399] = { { "Engineering", 2, 80, 130 } },  -- Wooden Stock
  [4400] = { { "Engineering", 5, 145, 240 } },  -- Heavy Stock
  [4404] = { { "Engineering", 4, 105, 190 } },  -- Silver Contact
  [4407] = { { "Engineering", 1, 230, 230 } },  -- Accurate Scope
  [4611] = { { "Engineering", 1, 185, 185 } },  -- Blue Pearl
  [6530] = { { "Engineering", 1, 150, 150 } },  -- Nightcrawlers
  [7191] = { { "Engineering", 8, 160, 320 } },  -- Fused Wiring
  [7387] = { { "Engineering", 1, 235, 235 } },  -- Dusky Belt
  [9060] = { { "Engineering", 6, 245, 295 } },  -- Inlaid Mithril Cylinder
  [10026] = { { "Engineering", 2, 245, 245 } },  -- Black Mageweave Boots
  [10500] = { { "Engineering", 2, 230, 310 } },  -- Fire Goggles
  [10502] = { { "Engineering", 1, 290, 290 } },  -- Spellpower Goggles Xtreme
  [10505] = { { "Engineering", 23, 1, 245 } },  -- Solid Blasting Powder
  [10507] = { { "Engineering", 1, 235, 235 } },  -- Solid Dynamite
  [10543] = { { "Engineering", 1, 265, 265 } },  -- Goblin Construction Helmet
  [10546] = { { "Engineering", 2, 280, 295 } },  -- Deadly Scope
  [10558] = { { "Engineering", 16, 170, 320 } },  -- Gold Power Core
  [10559] = { { "Engineering", 14, 205, 280 } },  -- Mithril Tube
  [10560] = { { "Engineering", 25, 205, 305 } },  -- Unstable Trigger
  [10561] = { { "Engineering", 19, 215, 305 } },  -- Mithril Casing
  [10576] = { { "Engineering", 1, 320, 320 } },  -- Mithril Mechanical Dragonling
  [10577] = { { "Engineering", 1, 1, 1 } },  -- Goblin Mortar
  [10586] = { { "Engineering", 1, 285, 285 } },  -- The Big One
  [10588] = { { "Engineering", 1, 305, 305 } },  -- Goblin Rocket Helmet
  [10592] = { { "Engineering", 1, 240, 240 } },  -- Catseye Elixir
  [10647] = { { "Engineering", 2, 205, 205 } },  -- Engineer's Ink
  [10648] = { { "Engineering", 2, 205, 205 } },  -- Blank Parchment
  [15992] = { { "Engineering", 10, 250, 305 } },  -- Dense Blasting Powder
  [15994] = { { "Engineering", 18, 250, 320 } },  -- Thorium Widget
  [16000] = { { "Engineering", 11, 250, 320 } },  -- Thorium Tube
  [16006] = { { "Engineering", 14, 280, 320 } },  -- Delicate Arcanite Converter
  [16583] = { { "Engineering", 1, 205, 205 } },  -- Demonic Figurine
  [17202] = { { "Engineering", 1, 190, 190 } },  -- Snowball
  [18168] = { { "Engineering", 1, 315, 315 } },  -- Force Reactive Disk
  [18631] = { { "Engineering", 10, 280, 320 } },  -- Truesilver Transformer
  [20868] = { { "Engineering", 1, 320, 320 } },  -- Lambent Idol
  [20870] = { { "Engineering", 1, 320, 320 } },  -- Jasper Idol
  [20881] = { { "Engineering", 1, 320, 320 } },  -- Idol of Strife
  [213381] = { { "Engineering", 1, 200, 200 } },  -- Pile of Tarnished Gears
  [220689] = { { "Engineering", 3, 250, 250 } },  -- Void-Powered Vambraces
  [238737] = { { "Engineering", 6, 270, 280 } },  -- Tinkerbox

  -- Engineering, Leatherworking, Tailoring
  [4337] = { { "Engineering", 1, 230, 230 }, { "Leatherworking", 1, 220, 220 }, { "Tailoring", 6, 185, 220 } },  -- Thick Spider's Silk
  [14227] = { { "Engineering", 2, 285, 305 }, { "Leatherworking", 21, 320, 320 }, { "Tailoring", 48, 260, 320 } },  -- Ironweb Spider Silk
  [15407] = { { "Engineering", 1, 320, 320 }, { "Leatherworking", 86, 250, 320 }, { "Tailoring", 5, 315, 320 } },  -- Cured Rugged Hide
  [234009] = { { "Engineering", 1, 315, 315 }, { "Leatherworking", 3, 320, 320 }, { "Tailoring", 7, 315, 320 } },  -- Bolt of Qiraji Silk

  -- Engineering, Tailoring
  [814] = { { "Engineering", 2, 150, 160 }, { "Tailoring", 1, 125, 125 } },  -- Flask of Oil
  [4339] = { { "Engineering", 1, 245, 245 }, { "Tailoring", 50, 200, 265 } },  -- Bolt of Mageweave
  [10285] = { { "Engineering", 2, 230, 245 }, { "Tailoring", 6, 225, 260 } },  -- Shadow Silk

  -- First Aid
  [1475] = { { "First Aid", 1, 80, 80 } },  -- Small Venom Sac
  [14530] = { { "First Aid", 1, 315, 315 } },  -- Heavy Runecloth Bandage
  [19441] = { { "First Aid", 1, 300, 300 } },  -- Huge Venom Sac

  -- Leatherworking
  [783] = { { "Leatherworking", 1, 55, 55 } },  -- Light Hide
  [2312] = { { "Leatherworking", 1, 155, 155 } },  -- Fine Leather Gloves
  [2457] = { { "Leatherworking", 1, 145, 145 } },  -- Elixir of Minor Agility
  [2934] = { { "Leatherworking", 1, 20, 20 } },  -- Ruined Leather Scraps
  [3389] = { { "Leatherworking", 1, 160, 160 } },  -- Elixir of Defense
  [3390] = { { "Leatherworking", 1, 165, 165 } },  -- Elixir of Lesser Agility
  [4096] = { { "Leatherworking", 1, 220, 220 } },  -- Coarse Gorilla Hair
  [4231] = { { "Leatherworking", 10, 105, 145 } },  -- Cured Light Hide
  [4232] = { { "Leatherworking", 1, 115, 115 } },  -- Medium Hide
  [4233] = { { "Leatherworking", 4, 150, 160 } },  -- Cured Medium Hide
  [4235] = { { "Leatherworking", 1, 160, 160 } },  -- Heavy Hide
  [4236] = { { "Leatherworking", 16, 175, 220 } },  -- Cured Heavy Hide
  [4243] = { { "Leatherworking", 1, 125, 125 } },  -- Fine Leather Tunic
  [4246] = { { "Leatherworking", 1, 150, 150 } },  -- Fine Leather Belt
  [4253] = { { "Leatherworking", 2, 160, 160 } },  -- Toughened Leather Gloves
  [4289] = { { "Leatherworking", 3, 55, 160 } },  -- Salt
  [4461] = { { "Leatherworking", 3, 175, 185 } },  -- Raptor Hide
  [5082] = { { "Leatherworking", 1, 70, 70 } },  -- Thin Kodo Leather
  [5116] = { { "Leatherworking", 1, 150, 150 } },  -- Long Tail Feather
  [5373] = { { "Leatherworking", 1, 165, 165 } },  -- Lucky Charm
  [5633] = { { "Leatherworking", 1, 220, 220 } },  -- Great Rage Potion
  [5784] = { { "Leatherworking", 2, 120, 125 } },  -- Slimy Murloc Scale
  [5785] = { { "Leatherworking", 3, 190, 225 } },  -- Thick Murloc Scale
  [6470] = { { "Leatherworking", 3, 120, 140 } },  -- Deviate Scale
  [6471] = { { "Leatherworking", 2, 130, 140 } },  -- Perfect Deviate Scale
  [7286] = { { "Leatherworking", 2, 125, 125 } },  -- Black Whelp Scale
  [7287] = { { "Leatherworking", 1, 145, 145 } },  -- Red Whelp Scale
  [7428] = { { "Leatherworking", 2, 210, 220 } },  -- Shadowcat Hide
  [8154] = { { "Leatherworking", 7, 240, 270 } },  -- Scorpid Scale
  [8165] = { { "Leatherworking", 2, 245, 275 } },  -- Worn Dragonscale
  [8167] = { { "Leatherworking", 7, 225, 255 } },  -- Turtle Scale
  [8169] = { { "Leatherworking", 1, 200, 200 } },  -- Thick Hide
  [8171] = { { "Leatherworking", 1, 250, 250 } },  -- Rugged Hide
  [8172] = { { "Leatherworking", 18, 200, 275 } },  -- Cured Thick Hide
  [8368] = { { "Leatherworking", 1, 245, 245 } },  -- Thick Wolfhide
  [8949] = { { "Leatherworking", 1, 245, 245 } },  -- Elixir of Agility
  [8951] = { { "Leatherworking", 1, 245, 245 } },  -- Elixir of Greater Defense
  [12607] = { { "Leatherworking", 3, 320, 320 } },  -- Brilliant Chromatic Scale
  [14044] = { { "Leatherworking", 1, 320, 320 } },  -- Cindercloth Cloak
  [15408] = { { "Leatherworking", 22, 260, 320 } },  -- Heavy Scorpid Scale
  [15409] = { { "Leatherworking", 1, 250, 250 } },  -- Refined Deeprock Salt
  [15412] = { { "Leatherworking", 8, 250, 300 } },  -- Green Dragonscale
  [15414] = { { "Leatherworking", 3, 320, 320 } },  -- Red Dragonscale
  [15415] = { { "Leatherworking", 6, 305, 320 } },  -- Blue Dragonscale
  [15416] = { { "Leatherworking", 12, 250, 320 } },  -- Black Dragonscale
  [15419] = { { "Leatherworking", 2, 295, 305 } },  -- Warbear Leather
  [15420] = { { "Leatherworking", 4, 290, 320 } },  -- Ironfeather
  [15422] = { { "Leatherworking", 4, 295, 320 } },  -- Frostsaber Leather
  [15423] = { { "Leatherworking", 5, 250, 310 } },  -- Chimera Leather
  [18251] = { { "Leatherworking", 2, 320, 320 } },  -- Core Armor Kit
  [19767] = { { "Leatherworking", 3, 320, 320 } },  -- Primal Bat Leather
  [19768] = { { "Leatherworking", 2, 320, 320 } },  -- Primal Tiger Leather
  [20498] = { { "Leatherworking", 12, 320, 320 } },  -- Silithid Chitin
  [20500] = { { "Leatherworking", 6, 320, 320 } },  -- Light Silithid Carapace
  [20501] = { { "Leatherworking", 6, 320, 320 } },  -- Heavy Silithid Carapace
  [213370] = { { "Leatherworking", 1, 200, 200 } },  -- Irradiated Leather Scraps

  -- Leatherworking, Tailoring
  [2320] = { { "Leatherworking", 24, 40, 125 }, { "Tailoring", 22, 35, 95 } },  -- Coarse Thread
  [2324] = { { "Leatherworking", 1, 90, 90 }, { "Tailoring", 10, 35, 255 } },  -- Bleach
  [2325] = { { "Leatherworking", 9, 185, 320 }, { "Tailoring", 3, 205, 240 } },  -- Black Dye
  [2997] = { { "Leatherworking", 2, 130, 170 }, { "Tailoring", 27, 100, 150 } },  -- Bolt of Woolen Cloth
  [3182] = { { "Leatherworking", 1, 160, 160 }, { "Tailoring", 4, 150, 170 } },  -- Spider's Silk
  [3383] = { { "Leatherworking", 1, 145, 145 }, { "Tailoring", 1, 150, 150 } },  -- Elixir of Wisdom
  [4291] = { { "Leatherworking", 25, 205, 255 }, { "Tailoring", 32, 170, 240 } },  -- Silken Thread
  [4305] = { { "Leatherworking", 4, 180, 215 }, { "Tailoring", 52, 145, 225 } },  -- Bolt of Silk Cloth
  [4340] = { { "Leatherworking", 7, 125, 165 }, { "Tailoring", 7, 110, 170 } },  -- Gray Dye
  [7071] = { { "Leatherworking", 6, 180, 220 }, { "Tailoring", 7, 195, 220 } },  -- Iron Buckle
  [8343] = { { "Leatherworking", 24, 210, 275 }, { "Tailoring", 41, 200, 265 } },  -- Heavy Silken Thread
  [14048] = { { "Leatherworking", 2, 285, 285 }, { "Tailoring", 110, 250, 320 } },  -- Bolt of Runecloth
  [14256] = { { "Leatherworking", 1, 320, 320 }, { "Tailoring", 16, 250, 315 } },  -- Felcloth
  [14341] = { { "Leatherworking", 93, 275, 320 }, { "Tailoring", 76, 265, 320 } },  -- Rune Thread
  [14342] = { { "Leatherworking", 2, 320, 320 }, { "Tailoring", 36, 295, 320 } },  -- Mooncloth
  [18240] = { { "Leatherworking", 2, 285, 285 }, { "Tailoring", 1, 285, 285 } },  -- Ogre Tannin
  [213372] = { { "Leatherworking", 3, 225, 225 }, { "Tailoring", 1, 225, 225 } },  -- Insulating Gniodine

  -- Mining
  [2770] = { { "Mining", 1, 25, 25 } },  -- Copper Ore
  [2771] = { { "Mining", 1, 50, 50 } },  -- Tin Ore
  [2775] = { { "Mining", 1, 100, 100 } },  -- Silver Ore
  [2776] = { { "Mining", 1, 170, 170 } },  -- Gold Ore
  [3576] = { { "Mining", 1, 65, 65 } },  -- Tin Bar
  [3857] = { { "Mining", 1, 165, 165 } },  -- Coal
  [7911] = { { "Mining", 1, 230, 230 } },  -- Truesilver Ore
  [11370] = { { "Mining", 1, 230, 230 } },  -- Dark Iron Ore
  [18562] = { { "Mining", 1, 310, 310 } },  -- Elementium Ore
  [18567] = { { "Mining", 1, 310, 310 } },  -- Elemental Flux

  -- Tailoring
  [929] = { { "Tailoring", 1, 170, 170 } },  -- Healing Potion
  [2604] = { { "Tailoring", 30, 65, 300 } },  -- Red Dye
  [2996] = { { "Tailoring", 28, 35, 105 } },  -- Bolt of Linen Cloth
  [3827] = { { "Tailoring", 4, 205, 220 } },  -- Mana Potion
  [4320] = { { "Tailoring", 1, 150, 150 } },  -- Spidersilk Boots
  [4341] = { { "Tailoring", 1, 145, 145 } },  -- Yellow Dye
  [4589] = { { "Tailoring", 1, 255, 255 } },  -- Long Elegant Feather
  [6260] = { { "Tailoring", 14, 65, 210 } },  -- Blue Dye
  [6261] = { { "Tailoring", 2, 220, 225 } },  -- Orange Dye
  [7072] = { { "Tailoring", 1, 210, 210 } },  -- Naga Scale
  [9210] = { { "Tailoring", 8, 280, 315 } },  -- Ghost Dye
  [10290] = { { "Tailoring", 1, 240, 240 } },  -- Pink Dye
  [11040] = { { "Tailoring", 1, 290, 290 } },  -- Morrowgrain
  [213378] = { { "Tailoring", 1, 200, 200 } },  -- Unstable Microfilament
}
