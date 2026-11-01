-- Bagwise: reagent-to-profession mapping with recipe stats
-- For each reagent item: which professions use it, how many
-- recipes, and the skill level range.
-- Generated from Vanilla recipe data. Do not edit by hand.
--
-- 419 reagent items across 9 professions.

Bagwise                         = Bagwise or {}
Bagwise.Data                    = Bagwise.Data or {}

-- Format: [itemID] = { { profession, recipe_count, min_level, max_level }, ... }
Bagwise.Data.ReagentProfessions = {
  -- Alchemy
  [118] = { { "Alchemy", 1, 55, 55 } },      -- Minor Healing Potion
  [765] = { { "Alchemy", 5, 1, 50 } },       -- Silverleaf
  [785] = { { "Alchemy", 5, 25, 120 } },     -- Mageroyal
  [2447] = { { "Alchemy", 5, 1, 50 } },      -- Peacebloom
  [2449] = { { "Alchemy", 5, 1, 150 } },     -- Earthroot
  [2450] = { { "Alchemy", 6, 55, 125 } },    -- Briarthorn
  [2453] = { { "Alchemy", 5, 100, 180 } },   -- Bruiseweed
  [3164] = { { "Alchemy", 1, 50, 50 } },     -- Discolored Worg Heart
  [3355] = { { "Alchemy", 6, 110, 195 } },   -- Wild Steelbloom
  [3357] = { { "Alchemy", 3, 155, 190 } },   -- Liferoot
  [3358] = { { "Alchemy", 7, 190, 235 } },   -- Khadgar's Whisker
  [3369] = { { "Alchemy", 2, 135, 165 } },   -- Grave Moss
  [3818] = { { "Alchemy", 4, 165, 200 } },   -- Fadeleaf
  [3819] = { { "Alchemy", 3, 190, 200 } },   -- Wintersbite
  [3820] = { { "Alchemy", 7, 90, 190 } },    -- Stranglekelp
  [6358] = { { "Alchemy", 1, 80, 80 } },     -- Oily Blackmouth
  [6359] = { { "Alchemy", 1, 130, 130 } },   -- Firefin Snapper
  [6370] = { { "Alchemy", 3, 90, 150 } },    -- Blackmouth Oil
  [8836] = { { "Alchemy", 2, 230, 240 } },   -- Arthas' Tears
  [8838] = { { "Alchemy", 6, 215, 265 } },   -- Sungrass
  [8839] = { { "Alchemy", 5, 235, 260 } },   -- Blindweed
  [8845] = { { "Alchemy", 5, 235, 250 } },   -- Ghost Mushroom
  [8846] = { { "Alchemy", 7, 245, 300 } },   -- Gromsblood
  [9260] = { { "Alchemy", 1, 210, 210 } },   -- Volatile Rum
  [9262] = { { "Alchemy", 2, 225, 300 } },   -- Black Vitriol
  [12363] = { { "Alchemy", 1, 275, 275 } },  -- Arcane Crystal
  [12938] = { { "Alchemy", 1, 315, 315 } },  -- Blood of Heroes
  [13422] = { { "Alchemy", 1, 250, 250 } },  -- Stonescale Eel
  [13423] = { { "Alchemy", 4, 265, 300 } },  -- Stonescale Oil
  [13463] = { { "Alchemy", 13, 270, 300 } }, -- Dreamfoil
  [13464] = { { "Alchemy", 3, 275, 300 } },  -- Golden Sansam
  [13465] = { { "Alchemy", 7, 275, 300 } },  -- Mountain Silversage
  [13466] = { { "Alchemy", 6, 270, 290 } },  -- Plaguebloom
  [19943] = { { "Alchemy", 1, 315, 315 } },  -- Massive Mojo

  -- Alchemy, Blacksmithing
  [5635] = { { "Alchemy", 1, 60, 60 }, { "Blacksmithing", 2, 160, 175 } }, -- Sharp Claw

  -- Alchemy, Blacksmithing, Enchanting, Engineering
  [12359] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 55, 250, 300 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 9, 250, 300 } }, -- Thorium Bar

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [7078] = { { "Alchemy", 2, 275, 300 }, { "Blacksmithing", 3, 280, 300 }, { "Enchanting", 1, 265, 265 }, { "Engineering", 2, 260, 300 }, { "Leatherworking", 6, 270, 300 }, { "Tailoring", 12, 275, 300 } }, -- Essence of Fire

  -- Alchemy, Blacksmithing, Engineering
  [3860] = { { "Alchemy", 1, 225, 225 }, { "Blacksmithing", 32, 205, 260 }, { "Engineering", 25, 190, 285 } }, -- Mithril Bar

  -- Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring
  [7067] = { { "Alchemy", 2, 215, 290 }, { "Blacksmithing", 3, 180, 300 }, { "Engineering", 3, 205, 300 }, { "Leatherworking", 4, 135, 190 }, { "Tailoring", 3, 170, 195 } },   -- Elemental Earth
  [7076] = { { "Alchemy", 3, 275, 300 }, { "Blacksmithing", 12, 275, 300 }, { "Engineering", 3, 300, 300 }, { "Leatherworking", 3, 285, 300 }, { "Tailoring", 3, 290, 300 } },  -- Essence of Earth
  [7077] = { { "Alchemy", 1, 300, 300 }, { "Blacksmithing", 14, 240, 300 }, { "Engineering", 3, 205, 285 }, { "Leatherworking", 1, 250, 250 }, { "Tailoring", 5, 225, 275 } },  -- Heart of Fire
  [7080] = { { "Alchemy", 3, 275, 300 }, { "Blacksmithing", 8, 290, 300 }, { "Engineering", 1, 290, 290 }, { "Leatherworking", 12, 275, 300 }, { "Tailoring", 9, 265, 300 } },  -- Essence of Water
  [8153] = { { "Alchemy", 1, 225, 225 }, { "Blacksmithing", 1, 270, 270 }, { "Engineering", 1, 245, 245 }, { "Leatherworking", 6, 220, 250 }, { "Tailoring", 3, 225, 250 } },   -- Wildvine
  [12803] = { { "Alchemy", 2, 275, 300 }, { "Blacksmithing", 6, 270, 300 }, { "Engineering", 3, 265, 300 }, { "Leatherworking", 14, 270, 300 }, { "Tailoring", 6, 290, 300 } }, -- Living Essence
  [12804] = { { "Alchemy", 1, 315, 315 }, { "Blacksmithing", 2, 280, 285 }, { "Engineering", 2, 300, 300 }, { "Leatherworking", 3, 290, 300 }, { "Tailoring", 2, 300, 300 } },  -- Powerful Mojo

  -- Alchemy, Blacksmithing, Engineering, Mining
  [3575] = { { "Alchemy", 2, 225, 225 }, { "Blacksmithing", 22, 145, 185 }, { "Engineering", 6, 160, 195 }, { "Mining", 1, 165, 165 } }, -- Iron Bar

  -- Alchemy, Blacksmithing, Engineering, Tailoring
  [7068] = { { "Alchemy", 1, 290, 290 }, { "Blacksmithing", 1, 190, 190 }, { "Engineering", 5, 205, 300 }, { "Tailoring", 4, 190, 275 } },  -- Elemental Fire
  [7972] = { { "Alchemy", 1, 215, 215 }, { "Blacksmithing", 1, 250, 250 }, { "Engineering", 1, 240, 240 }, { "Tailoring", 1, 260, 260 } },  -- Ichor of Undeath
  [12808] = { { "Alchemy", 1, 275, 275 }, { "Blacksmithing", 3, 290, 300 }, { "Engineering", 2, 240, 300 }, { "Tailoring", 3, 285, 300 } }, -- Essence of Undeath

  -- Alchemy, Blacksmithing, Leatherworking
  [5637] = { { "Alchemy", 1, 175, 175 }, { "Blacksmithing", 3, 175, 185 }, { "Leatherworking", 2, 150, 155 } }, -- Large Fang

  -- Alchemy, Blacksmithing, Leatherworking, Tailoring
  [3824] = { { "Alchemy", 1, 290, 290 }, { "Blacksmithing", 1, 200, 200 }, { "Leatherworking", 3, 175, 200 }, { "Tailoring", 1, 170, 170 } }, -- Shadow Oil
  [7070] = { { "Alchemy", 1, 290, 290 }, { "Blacksmithing", 1, 190, 190 }, { "Leatherworking", 1, 180, 180 }, { "Tailoring", 2, 175, 190 } }, -- Elemental Water

  -- Alchemy, Cooking
  [2452] = { { "Alchemy", 5, 50, 140 }, { "Cooking", 1, 60, 60 } },     -- Swiftthistle
  [3821] = { { "Alchemy", 11, 175, 240 }, { "Cooking", 1, 175, 175 } }, -- Goldthorn
  [6522] = { { "Alchemy", 1, 90, 90 }, { "Cooking", 1, 85, 85 } },      -- Deviate Fish

  -- Alchemy, Cooking, Engineering
  [4402] = { { "Alchemy", 1, 165, 165 }, { "Cooking", 1, 200, 200 }, { "Engineering", 1, 125, 125 } }, -- Small Flame Sac

  -- Alchemy, Enchanting
  [3371] = { { "Alchemy", 20, 1, 130 }, { "Enchanting", 1, 45, 45 } },     -- Empty Vial
  [3372] = { { "Alchemy", 29, 110, 250 }, { "Enchanting", 2, 150, 200 } }, -- Leaded Vial
  [8925] = { { "Alchemy", 46, 205, 300 }, { "Enchanting", 2, 250, 275 } }, -- Crystal Vial
  [18256] = { { "Alchemy", 1, 300, 300 }, { "Enchanting", 2, 300, 300 } }, -- Imbued Vial

  -- Alchemy, Enchanting, Tailoring
  [4625] = { { "Alchemy", 4, 205, 250 }, { "Enchanting", 2, 275, 300 }, { "Tailoring", 2, 250, 250 } },  -- Firebloom
  [8831] = { { "Alchemy", 6, 210, 240 }, { "Enchanting", 2, 250, 300 }, { "Tailoring", 1, 275, 275 } },  -- Purple Lotus
  [11176] = { { "Alchemy", 1, 290, 290 }, { "Enchanting", 2, 250, 250 }, { "Tailoring", 3, 275, 300 } }, -- Dream Dust

  -- Alchemy, Engineering
  [13467] = { { "Alchemy", 5, 285, 300 }, { "Engineering", 1, 260, 260 } }, -- Icecap

  -- Alchemy, Engineering, Leatherworking, Tailoring
  [7082] = { { "Alchemy", 2, 275, 300 }, { "Engineering", 1, 300, 300 }, { "Leatherworking", 6, 275, 300 }, { "Tailoring", 1, 300, 300 } }, -- Essence of Air

  -- Alchemy, Engineering, Tailoring
  [10286] = { { "Alchemy", 2, 285, 300 }, { "Engineering", 1, 245, 245 }, { "Tailoring", 3, 225, 250 } }, -- Heart of the Wild

  -- Alchemy, First Aid
  [1288] = { { "Alchemy", 1, 120, 120 }, { "First Aid", 1, 130, 130 } }, -- Large Venom Sac

  -- Alchemy, Leatherworking
  [3356] = { { "Alchemy", 6, 135, 175 }, { "Leatherworking", 1, 135, 135 } }, -- Kingsblood

  -- Alchemy, Mining
  [3858] = { { "Alchemy", 1, 215, 215 }, { "Mining", 1, 175, 175 } },  -- Mithril Ore
  [10620] = { { "Alchemy", 1, 280, 280 }, { "Mining", 1, 250, 250 } }, -- Thorium Ore

  -- Alchemy, Tailoring
  [4342] = { { "Alchemy", 1, 245, 245 }, { "Tailoring", 2, 185, 230 } },  -- Purple Dye
  [6371] = { { "Alchemy", 3, 140, 250 }, { "Tailoring", 3, 180, 210 } },  -- Fire Oil
  [13468] = { { "Alchemy", 7, 300, 315 }, { "Tailoring", 1, 300, 300 } }, -- Black Lotus

  -- Blacksmithing
  [3391] = { { "Blacksmithing", 1, 145, 145 } },   -- Elixir of Ogre's Strength
  [3466] = { { "Blacksmithing", 17, 110, 200 } },  -- Strong Flux
  [3470] = { { "Blacksmithing", 14, 30, 105 } },   -- Rough Grinding Stone
  [3478] = { { "Blacksmithing", 17, 110, 165 } },  -- Coarse Grinding Stone
  [3486] = { { "Blacksmithing", 27, 150, 205 } },  -- Heavy Grinding Stone
  [3823] = { { "Blacksmithing", 1, 245, 245 } },   -- Lesser Invisibility Potion
  [4255] = { { "Blacksmithing", 1, 180, 180 } },   -- Green Leather Armor
  [5966] = { { "Blacksmithing", 1, 225, 225 } },   -- Guardian Gloves
  [7081] = { { "Blacksmithing", 2, 245, 260 } },   -- Breath of Wind
  [7966] = { { "Blacksmithing", 22, 200, 260 } },  -- Solid Grinding Stone
  [11184] = { { "Blacksmithing", 1, 255, 255 } },  -- Blue Power Crystal
  [11185] = { { "Blacksmithing", 1, 280, 280 } },  -- Green Power Crystal
  [11186] = { { "Blacksmithing", 2, 250, 300 } },  -- Red Power Crystal
  [11188] = { { "Blacksmithing", 2, 250, 280 } },  -- Yellow Power Crystal
  [12644] = { { "Blacksmithing", 13, 275, 300 } }, -- Dense Grinding Stone
  [13510] = { { "Blacksmithing", 1, 300, 300 } },  -- Flask of the Titans
  [13512] = { { "Blacksmithing", 2, 300, 300 } },  -- Flask of Supreme Power
  [17203] = { { "Blacksmithing", 1, 300, 300 } },  -- Sulfuron Ingot
  [20725] = { { "Blacksmithing", 1, 300, 300 } },  -- Nexus Crystal
  [22202] = { { "Blacksmithing", 6, 300, 300 } },  -- Small Obsidian Shard
  [22203] = { { "Blacksmithing", 4, 300, 300 } },  -- Large Obsidian Shard

  -- Blacksmithing, Enchanting
  [11382] = { { "Blacksmithing", 5, 300, 300 }, { "Enchanting", 1, 265, 265 } }, -- Blood of the Mountain

  -- Blacksmithing, Enchanting, Engineering, Leatherworking
  [1210] = { { "Blacksmithing", 6, 80, 230 }, { "Enchanting", 1, 100, 100 }, { "Engineering", 2, 120, 165 }, { "Leatherworking", 1, 200, 200 } }, -- Shadowgem

  -- Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [8170] = { { "Blacksmithing", 9, 265, 290 }, { "Enchanting", 1, 250, 250 }, { "Engineering", 9, 265, 300 }, { "Leatherworking", 62, 250, 300 }, { "Tailoring", 8, 260, 300 } }, -- Rugged Leather

  -- Blacksmithing, Enchanting, Leatherworking, Tailoring
  [5500] = { { "Blacksmithing", 2, 140, 145 }, { "Enchanting", 1, 150, 150 }, { "Leatherworking", 1, 185, 185 }, { "Tailoring", 3, 125, 125 } }, -- Iridescent Pearl
  [7971] = { { "Blacksmithing", 3, 230, 245 }, { "Enchanting", 1, 200, 200 }, { "Leatherworking", 3, 200, 275 }, { "Tailoring", 1, 290, 290 } }, -- Black Pearl

  -- Blacksmithing, Engineering
  [774] = { { "Blacksmithing", 3, 35, 60 }, { "Engineering", 4, 60, 230 } },       -- Malachite
  [818] = { { "Blacksmithing", 5, 60, 180 }, { "Engineering", 3, 100, 230 } },     -- Tigerseye
  [1705] = { { "Blacksmithing", 11, 130, 240 }, { "Engineering", 2, 145, 200 } },  -- Lesser Moonstone
  [2835] = { { "Blacksmithing", 3, 1, 25 }, { "Engineering", 1, 1, 1 } },          -- Rough Stone
  [2836] = { { "Blacksmithing", 3, 65, 75 }, { "Engineering", 1, 75, 75 } },       -- Coarse Stone
  [2838] = { { "Blacksmithing", 3, 125, 125 }, { "Engineering", 1, 125, 125 } },   -- Heavy Stone
  [2841] = { { "Blacksmithing", 22, 95, 155 }, { "Engineering", 10, 85, 150 } },   -- Bronze Bar
  [2842] = { { "Blacksmithing", 11, 70, 300 }, { "Engineering", 2, 90, 130 } },    -- Silver Bar
  [2880] = { { "Blacksmithing", 13, 15, 120 }, { "Engineering", 3, 50, 105 } },    -- Weak Flux
  [3859] = { { "Blacksmithing", 16, 175, 215 }, { "Engineering", 1, 175, 175 } },  -- Steel Bar
  [7909] = { { "Blacksmithing", 9, 220, 295 }, { "Engineering", 5, 210, 285 } },   -- Aquamarine
  [7912] = { { "Blacksmithing", 3, 200, 200 }, { "Engineering", 1, 175, 175 } },   -- Solid Stone
  [11371] = { { "Blacksmithing", 21, 265, 300 }, { "Engineering", 5, 275, 300 } }, -- Dark Iron Bar
  [12361] = { { "Blacksmithing", 10, 250, 300 }, { "Engineering", 2, 260, 275 } }, -- Blue Sapphire
  [12365] = { { "Blacksmithing", 4, 250, 300 }, { "Engineering", 1, 250, 250 } },  -- Dense Stone
  [12655] = { { "Blacksmithing", 23, 270, 300 }, { "Engineering", 1, 300, 300 } }, -- Enchanted Thorium Bar
  [12799] = { { "Blacksmithing", 11, 275, 300 }, { "Engineering", 3, 275, 300 } }, -- Large Opal
  [19774] = { { "Blacksmithing", 6, 300, 300 }, { "Engineering", 2, 300, 300 } },  -- Souldarite

  -- Blacksmithing, Engineering, First Aid, Leatherworking, Tailoring
  [4338] = { { "Blacksmithing", 4, 205, 240 }, { "Engineering", 5, 200, 235 }, { "First Aid", 2, 210, 240 }, { "Leatherworking", 1, 210, 210 }, { "Tailoring", 1, 175, 175 } },  -- Mageweave Cloth
  [14047] = { { "Blacksmithing", 1, 250, 250 }, { "Engineering", 9, 250, 300 }, { "First Aid", 2, 260, 290 }, { "Leatherworking", 7, 270, 300 }, { "Tailoring", 1, 250, 250 } }, -- Runecloth

  -- Blacksmithing, Engineering, First Aid, Tailoring
  [2589] = { { "Blacksmithing", 4, 1, 25 }, { "Engineering", 4, 1, 75 }, { "First Aid", 2, 1, 40 }, { "Tailoring", 1, 1, 1 } },              -- Linen Cloth
  [2592] = { { "Blacksmithing", 2, 65, 125 }, { "Engineering", 7, 85, 150 }, { "First Aid", 2, 80, 115 }, { "Tailoring", 1, 75, 75 } },      -- Wool Cloth
  [4306] = { { "Blacksmithing", 1, 200, 200 }, { "Engineering", 5, 160, 185 }, { "First Aid", 2, 150, 180 }, { "Tailoring", 1, 125, 125 } }, -- Silk Cloth

  -- Blacksmithing, Engineering, Leatherworking
  [1206] = { { "Blacksmithing", 5, 130, 240 }, { "Engineering", 5, 110, 150 }, { "Leatherworking", 1, 170, 170 } }, -- Moss Agate
  [7075] = { { "Blacksmithing", 2, 235, 245 }, { "Engineering", 2, 205, 285 }, { "Leatherworking", 3, 230, 270 } }, -- Core of Earth

  -- Blacksmithing, Engineering, Leatherworking, Mining, Tailoring
  [17010] = { { "Blacksmithing", 14, 295, 300 }, { "Engineering", 1, 300, 300 }, { "Leatherworking", 6, 295, 300 }, { "Mining", 1, 310, 310 }, { "Tailoring", 5, 300, 300 } }, -- Fiery Core

  -- Blacksmithing, Engineering, Leatherworking, Tailoring
  [1529] = { { "Blacksmithing", 5, 175, 235 }, { "Engineering", 6, 160, 245 }, { "Leatherworking", 3, 185, 290 }, { "Tailoring", 1, 250, 250 } },     -- Jade
  [2318] = { { "Blacksmithing", 5, 30, 70 }, { "Engineering", 2, 100, 100 }, { "Leatherworking", 28, 1, 100 }, { "Tailoring", 6, 20, 95 } },          -- Light Leather
  [2319] = { { "Blacksmithing", 12, 95, 145 }, { "Engineering", 9, 105, 165 }, { "Leatherworking", 22, 100, 150 }, { "Tailoring", 2, 120, 125 } },    -- Medium Leather
  [3864] = { { "Blacksmithing", 11, 170, 265 }, { "Engineering", 10, 175, 260 }, { "Leatherworking", 1, 185, 185 }, { "Tailoring", 1, 200, 200 } },   -- Citrine
  [4234] = { { "Blacksmithing", 14, 155, 210 }, { "Engineering", 15, 150, 225 }, { "Leatherworking", 36, 150, 200 }, { "Tailoring", 7, 145, 200 } },  -- Heavy Leather
  [4304] = { { "Blacksmithing", 13, 220, 260 }, { "Engineering", 8, 210, 245 }, { "Leatherworking", 38, 200, 255 }, { "Tailoring", 4, 210, 245 } },   -- Thick Leather
  [12810] = { { "Blacksmithing", 15, 300, 300 }, { "Engineering", 6, 270, 300 }, { "Leatherworking", 19, 295, 300 }, { "Tailoring", 11, 285, 300 } }, -- Enchanted Leather
  [17011] = { { "Blacksmithing", 14, 295, 300 }, { "Engineering", 2, 300, 300 }, { "Leatherworking", 6, 295, 300 }, { "Tailoring", 3, 300, 300 } },   -- Lava Core
  [19726] = { { "Blacksmithing", 5, 300, 300 }, { "Engineering", 2, 300, 300 }, { "Leatherworking", 3, 300, 300 }, { "Tailoring", 6, 300, 300 } },    -- Bloodvine

  -- Blacksmithing, Engineering, Mining
  [2840] = { { "Blacksmithing", 22, 1, 100 }, { "Engineering", 9, 1, 105 }, { "Mining", 1, 65, 65 } }, -- Copper Bar

  -- Blacksmithing, Engineering, Mining, Tailoring
  [12360] = { { "Blacksmithing", 37, 275, 300 }, { "Engineering", 4, 285, 300 }, { "Mining", 1, 310, 310 }, { "Tailoring", 1, 300, 300 } }, -- Arcanite Bar

  -- Blacksmithing, Engineering, Tailoring
  [3577] = { { "Blacksmithing", 13, 150, 300 }, { "Engineering", 1, 150, 150 }, { "Tailoring", 4, 270, 290 } },  -- Gold Bar
  [3829] = { { "Blacksmithing", 2, 190, 200 }, { "Engineering", 3, 155, 260 }, { "Tailoring", 1, 200, 200 } },   -- Frost Oil
  [6037] = { { "Blacksmithing", 24, 200, 300 }, { "Engineering", 11, 205, 275 }, { "Tailoring", 1, 250, 250 } }, -- Truesilver Bar
  [7069] = { { "Blacksmithing", 1, 190, 190 }, { "Engineering", 1, 260, 260 }, { "Tailoring", 1, 190, 190 } },   -- Elemental Air
  [7910] = { { "Blacksmithing", 19, 245, 300 }, { "Engineering", 10, 225, 290 }, { "Tailoring", 2, 300, 300 } }, -- Star Ruby
  [12364] = { { "Blacksmithing", 13, 270, 300 }, { "Engineering", 1, 290, 290 }, { "Tailoring", 1, 300, 300 } }, -- Huge Emerald
  [12800] = { { "Blacksmithing", 11, 280, 300 }, { "Engineering", 3, 290, 300 }, { "Tailoring", 1, 300, 300 } }, -- Azerothian Diamond

  -- Blacksmithing, Leatherworking
  [2459] = { { "Blacksmithing", 1, 125, 125 }, { "Leatherworking", 1, 200, 200 } },  -- Swiftness Potion
  [8146] = { { "Blacksmithing", 1, 300, 300 }, { "Leatherworking", 1, 225, 225 } },  -- Wicked Claw
  [8168] = { { "Blacksmithing", 1, 300, 300 }, { "Leatherworking", 1, 250, 250 } },  -- Jet Black Feather
  [11754] = { { "Blacksmithing", 1, 300, 300 }, { "Leatherworking", 1, 300, 300 } }, -- Black Diamond
  [12753] = { { "Blacksmithing", 1, 300, 300 }, { "Leatherworking", 1, 300, 300 } }, -- Skin of Shadow
  [15417] = { { "Blacksmithing", 1, 300, 300 }, { "Leatherworking", 2, 290, 300 } }, -- Devilsaur Leather

  -- Blacksmithing, Leatherworking, Tailoring
  [2321] = { { "Blacksmithing", 1, 45, 45 }, { "Leatherworking", 52, 85, 190 }, { "Tailoring", 51, 70, 185 } },    -- Fine Thread
  [2605] = { { "Blacksmithing", 6, 145, 170 }, { "Leatherworking", 3, 155, 180 }, { "Tailoring", 8, 60, 190 } },   -- Green Dye
  [5498] = { { "Blacksmithing", 2, 110, 150 }, { "Leatherworking", 2, 90, 155 }, { "Tailoring", 2, 90, 100 } },    -- Small Lustrous Pearl
  [12809] = { { "Blacksmithing", 3, 300, 300 }, { "Leatherworking", 3, 290, 300 }, { "Tailoring", 3, 290, 300 } }, -- Guardian Stone
  [17012] = { { "Blacksmithing", 2, 300, 300 }, { "Leatherworking", 5, 295, 300 }, { "Tailoring", 2, 300, 300 } }, -- Core Leather
  [22682] = { { "Blacksmithing", 3, 300, 300 }, { "Leatherworking", 6, 300, 300 }, { "Tailoring", 4, 300, 300 } }, -- Frozen Rune

  -- Blacksmithing, Tailoring
  [12662] = { { "Blacksmithing", 2, 285, 290 }, { "Tailoring", 4, 300, 300 } }, -- Demonic Rune
  [12811] = { { "Blacksmithing", 3, 290, 300 }, { "Tailoring", 1, 300, 300 } }, -- Righteous Orb
  [20520] = { { "Blacksmithing", 4, 300, 300 }, { "Tailoring", 4, 285, 300 } }, -- Dark Rune

  -- Cooking
  [723] = { { "Cooking", 1, 50, 50 } },     -- Goretusk Liver
  [729] = { { "Cooking", 1, 75, 75 } },     -- Stringy Vulture Meat
  [730] = { { "Cooking", 1, 75, 75 } },     -- Murloc Eye
  [731] = { { "Cooking", 1, 75, 75 } },     -- Goretusk Snout
  [769] = { { "Cooking", 1, 1, 1 } },       -- Chunk of Boar Meat
  [1015] = { { "Cooking", 2, 100, 125 } },  -- Lean Wolf Flank
  [1080] = { { "Cooking", 1, 100, 100 } },  -- Tough Condor Meat
  [1081] = { { "Cooking", 1, 100, 100 } },  -- Crisp Spider Meat
  [1179] = { { "Cooking", 3, 35, 225 } },   -- Ice Cold Milk
  [1468] = { { "Cooking", 1, 90, 90 } },    -- Murloc Fin
  [2251] = { { "Cooking", 1, 110, 110 } },  -- Gooey Spider Leg
  [2596] = { { "Cooking", 1, 175, 175 } },  -- Skin of Dwarven Stout
  [2665] = { { "Cooking", 1, 100, 100 } },  -- Stormwind Seasoning Herbs
  [2672] = { { "Cooking", 2, 1, 10 } },     -- Stringy Wolf Meat
  [2673] = { { "Cooking", 1, 50, 50 } },    -- Coyote Meat
  [2674] = { { "Cooking", 1, 75, 75 } },    -- Crawler Meat
  [2675] = { { "Cooking", 1, 85, 85 } },    -- Crawler Claw
  [2677] = { { "Cooking", 2, 80, 110 } },   -- Boar Ribs
  [2678] = { { "Cooking", 16, 1, 125 } },   -- Mild Spices
  [2692] = { { "Cooking", 21, 90, 300 } },  -- Hot Spices
  [2886] = { { "Cooking", 1, 25, 25 } },    -- Crag Boar Rib
  [2894] = { { "Cooking", 1, 25, 25 } },    -- Rhapsody Malt
  [2924] = { { "Cooking", 1, 80, 80 } },    -- Crocolisk Meat
  [3172] = { { "Cooking", 1, 60, 60 } },    -- Boar Intestines
  [3173] = { { "Cooking", 2, 40, 60 } },    -- Bear Meat
  [3174] = { { "Cooking", 1, 60, 60 } },    -- Spider Ichor
  [3404] = { { "Cooking", 1, 175, 175 } },  -- Buzzard Wing
  [3667] = { { "Cooking", 2, 120, 150 } },  -- Tender Crocolisk Meat
  [3685] = { { "Cooking", 1, 130, 130 } },  -- Raptor Egg
  [3712] = { { "Cooking", 1, 175, 175 } },  -- Turtle Meat
  [3713] = { { "Cooking", 12, 150, 285 } }, -- Soothing Spices
  [3730] = { { "Cooking", 1, 110, 110 } },  -- Big Bear Meat
  [3731] = { { "Cooking", 2, 125, 150 } },  -- Lion Meat
  [4536] = { { "Cooking", 2, 50, 175 } },   -- Shiny Red Apple
  [4603] = { { "Cooking", 1, 225, 225 } },  -- Raw Spotted Yellowtail
  [4655] = { { "Cooking", 1, 175, 175 } },  -- Giant Clam Meat
  [5051] = { { "Cooking", 1, 90, 90 } },    -- Dig Rat
  [5465] = { { "Cooking", 1, 10, 10 } },    -- Small Spider Leg
  [5466] = { { "Cooking", 1, 20, 20 } },    -- Scorpid Stinger
  [5467] = { { "Cooking", 1, 35, 35 } },    -- Kodo Meat
  [5468] = { { "Cooking", 1, 50, 50 } },    -- Soft Frenzy Flesh
  [5469] = { { "Cooking", 1, 50, 50 } },    -- Strider Meat
  [5470] = { { "Cooking", 1, 100, 100 } },  -- Thunder Lizard Tail
  [5471] = { { "Cooking", 1, 110, 110 } },  -- Stag Meat
  [5503] = { { "Cooking", 2, 50, 90 } },    -- Clam Meat
  [5504] = { { "Cooking", 1, 125, 125 } },  -- Tangy Clam Meat
  [6289] = { { "Cooking", 1, 50, 50 } },    -- Raw Longjaw Mud Snapper
  [6291] = { { "Cooking", 1, 1, 1 } },      -- Raw Brilliant Smallfish
  [6303] = { { "Cooking", 1, 1, 1 } },      -- Raw Slitherskin Mackerel
  [6308] = { { "Cooking", 1, 100, 100 } },  -- Raw Bristle Whisker Catfish
  [6317] = { { "Cooking", 1, 50, 50 } },    -- Raw Loch Frenzy
  [6361] = { { "Cooking", 1, 50, 50 } },    -- Raw Rainbow Fin Albacore
  [6362] = { { "Cooking", 1, 175, 175 } },  -- Raw Rockscale Cod
  [6889] = { { "Cooking", 3, 1, 35 } },     -- Small Egg
  [7974] = { { "Cooking", 1, 225, 225 } },  -- Zesty Clam Meat
  [8365] = { { "Cooking", 1, 175, 175 } },  -- Raw Mithril Head Trout
  [12037] = { { "Cooking", 3, 175, 200 } }, -- Mystery Meat
  [12184] = { { "Cooking", 1, 175, 175 } }, -- Raptor Flesh
  [12202] = { { "Cooking", 1, 175, 175 } }, -- Tiger Meat
  [12203] = { { "Cooking", 1, 175, 175 } }, -- Red Wolf Meat
  [12204] = { { "Cooking", 1, 200, 200 } }, -- Heavy Kodo Meat
  [12205] = { { "Cooking", 1, 200, 200 } }, -- White Spider Meat
  [12206] = { { "Cooking", 1, 225, 225 } }, -- Tender Crab Meat
  [12207] = { { "Cooking", 1, 225, 225 } }, -- Giant Egg
  [12208] = { { "Cooking", 1, 225, 225 } }, -- Tender Wolf Meat
  [12223] = { { "Cooking", 1, 1, 1 } },     -- Meaty Bat Wing
  [13754] = { { "Cooking", 1, 225, 225 } }, -- Raw Glossy Mightfish
  [13755] = { { "Cooking", 1, 240, 240 } }, -- Winter Squid
  [13756] = { { "Cooking", 1, 240, 240 } }, -- Raw Summer Bass
  [13758] = { { "Cooking", 1, 225, 225 } }, -- Raw Redgill
  [13759] = { { "Cooking", 1, 250, 250 } }, -- Raw Nightfin Snapper
  [13760] = { { "Cooking", 1, 250, 250 } }, -- Raw Sunscale Salmon
  [13888] = { { "Cooking", 1, 275, 275 } }, -- Darkclaw Lobster
  [13889] = { { "Cooking", 1, 275, 275 } }, -- Raw Whitescale Salmon
  [13893] = { { "Cooking", 1, 275, 275 } }, -- Large Raw Mightfish
  [17194] = { { "Cooking", 2, 1, 35 } },    -- Holiday Spices
  [17196] = { { "Cooking", 1, 35, 35 } },   -- Holiday Spirits
  [18255] = { { "Cooking", 1, 275, 275 } }, -- Runn Tum Tuber
  [20424] = { { "Cooking", 1, 285, 285 } }, -- Sandworm Meat
  [21024] = { { "Cooking", 1, 300, 300 } }, -- Chimaerok Tenderloin
  [21071] = { { "Cooking", 1, 80, 80 } },   -- Raw Sagefish
  [21153] = { { "Cooking", 1, 175, 175 } }, -- Raw Greater Sagefish

  -- Cooking, Engineering
  [159] = { { "Cooking", 7, 50, 275 }, { "Engineering", 3, 100, 275 } },   -- Refreshing Spring Water
  [9061] = { { "Cooking", 1, 300, 300 }, { "Engineering", 7, 225, 275 } }, -- Goblin Rocket Fuel

  -- Cooking, Engineering, Leatherworking
  [8150] = { { "Cooking", 1, 300, 300 }, { "Engineering", 1, 250, 250 }, { "Leatherworking", 1, 200, 200 } }, -- Deeprock Salt

  -- Enchanting
  [4470] = { { "Enchanting", 2, 10, 70 } },    -- Simple Wood
  [6217] = { { "Enchanting", 1, 1, 1 } },      -- Copper Rod
  [6338] = { { "Enchanting", 1, 100, 100 } },  -- Silver Rod
  [10938] = { { "Enchanting", 2, 1, 10 } },    -- Lesser Magic Essence
  [10939] = { { "Enchanting", 2, 70, 100 } },  -- Greater Magic Essence
  [10940] = { { "Enchanting", 3, 1, 100 } },   -- Strange Dust
  [11082] = { { "Enchanting", 1, 150, 150 } }, -- Greater Astral Essence
  [11083] = { { "Enchanting", 3, 150, 155 } }, -- Soul Dust
  [11128] = { { "Enchanting", 1, 150, 150 } }, -- Golden Rod
  [11134] = { { "Enchanting", 1, 155, 155 } }, -- Lesser Mystic Essence
  [11135] = { { "Enchanting", 2, 175, 200 } }, -- Greater Mystic Essence
  [11144] = { { "Enchanting", 1, 200, 200 } }, -- Truesilver Rod
  [11291] = { { "Enchanting", 2, 155, 175 } }, -- Star Wood
  [14343] = { { "Enchanting", 2, 265, 290 } }, -- Small Brilliant Shard
  [16202] = { { "Enchanting", 1, 250, 250 } }, -- Lesser Eternal Essence
  [16204] = { { "Enchanting", 2, 275, 290 } }, -- Illusion Dust
  [16206] = { { "Enchanting", 1, 290, 290 } }, -- Arcanite Rod
  [17034] = { { "Enchanting", 2, 45, 150 } },  -- Maple Seed
  [17035] = { { "Enchanting", 1, 200, 200 } }, -- Stranglethorn Seed

  -- Enchanting, Tailoring
  [11137] = { { "Enchanting", 3, 175, 200 }, { "Tailoring", 1, 225, 225 } }, -- Vision Dust
  [13926] = { { "Enchanting", 1, 290, 290 }, { "Tailoring", 5, 290, 300 } }, -- Golden Pearl
  [14344] = { { "Enchanting", 3, 290, 300 }, { "Tailoring", 3, 300, 300 } }, -- Large Brilliant Shard
  [16203] = { { "Enchanting", 1, 290, 290 }, { "Tailoring", 1, 275, 275 } }, -- Greater Eternal Essence

  -- Engineering
  [814] = { { "Engineering", 2, 125, 165 } },    -- Flask of Oil
  [4357] = { { "Engineering", 3, 1, 30 } },      -- Rough Blasting Powder
  [4359] = { { "Engineering", 9, 30, 120 } },    -- Handful of Copper Bolts
  [4361] = { { "Engineering", 3, 50, 105 } },    -- Copper Tube
  [4363] = { { "Engineering", 4, 75, 135 } },    -- Copper Modulator
  [4364] = { { "Engineering", 10, 75, 150 } },   -- Coarse Blasting Powder
  [4368] = { { "Engineering", 1, 150, 150 } },   -- Flying Tiger Goggles
  [4371] = { { "Engineering", 9, 110, 180 } },   -- Bronze Tube
  [4375] = { { "Engineering", 10, 125, 165 } },  -- Whirring Bronze Gizmo
  [4377] = { { "Engineering", 15, 125, 195 } },  -- Heavy Blasting Powder
  [4382] = { { "Engineering", 4, 150, 200 } },   -- Bronze Framework
  [4385] = { { "Engineering", 1, 205, 205 } },   -- Green Tinted Goggles
  [4387] = { { "Engineering", 4, 165, 200 } },   -- Iron Strut
  [4389] = { { "Engineering", 8, 175, 225 } },   -- Gyrochronatom
  [4394] = { { "Engineering", 1, 205, 205 } },   -- Big Iron Bomb
  [4399] = { { "Engineering", 2, 50, 105 } },    -- Wooden Stock
  [4400] = { { "Engineering", 5, 120, 220 } },   -- Heavy Stock
  [4404] = { { "Engineering", 4, 105, 190 } },   -- Silver Contact
  [4407] = { { "Engineering", 1, 230, 230 } },   -- Accurate Scope
  [4611] = { { "Engineering", 1, 185, 185 } },   -- Blue Pearl
  [6530] = { { "Engineering", 1, 150, 150 } },   -- Nightcrawlers
  [7191] = { { "Engineering", 8, 165, 300 } },   -- Fused Wiring
  [7387] = { { "Engineering", 1, 215, 215 } },   -- Dusky Belt
  [9060] = { { "Engineering", 6, 225, 285 } },   -- Inlaid Mithril Cylinder
  [10026] = { { "Engineering", 2, 225, 225 } },  -- Black Mageweave Boots
  [10500] = { { "Engineering", 2, 210, 290 } },  -- Fire Goggles
  [10502] = { { "Engineering", 1, 270, 270 } },  -- Spellpower Goggles Xtreme
  [10505] = { { "Engineering", 18, 175, 245 } }, -- Solid Blasting Powder
  [10507] = { { "Engineering", 1, 235, 235 } },  -- Solid Dynamite
  [10543] = { { "Engineering", 1, 245, 245 } },  -- Goblin Construction Helmet
  [10546] = { { "Engineering", 2, 260, 275 } },  -- Deadly Scope
  [10558] = { { "Engineering", 12, 170, 300 } }, -- Gold Power Core
  [10559] = { { "Engineering", 13, 205, 260 } }, -- Mithril Tube
  [10560] = { { "Engineering", 17, 205, 260 } }, -- Unstable Trigger
  [10561] = { { "Engineering", 13, 215, 275 } }, -- Mithril Casing
  [10576] = { { "Engineering", 1, 300, 300 } },  -- Mithril Mechanical Dragonling
  [10586] = { { "Engineering", 1, 285, 285 } },  -- The Big One
  [10592] = { { "Engineering", 1, 220, 220 } },  -- Catseye Elixir
  [10647] = { { "Engineering", 2, 205, 205 } },  -- Engineer's Ink
  [10648] = { { "Engineering", 2, 205, 205 } },  -- Blank Parchment
  [15992] = { { "Engineering", 9, 250, 285 } },  -- Dense Blasting Powder
  [15994] = { { "Engineering", 14, 250, 300 } }, -- Thorium Widget
  [16000] = { { "Engineering", 6, 275, 300 } },  -- Thorium Tube
  [16006] = { { "Engineering", 8, 290, 300 } },  -- Delicate Arcanite Converter
  [17202] = { { "Engineering", 1, 190, 190 } },  -- Snowball
  [18631] = { { "Engineering", 9, 250, 300 } },  -- Truesilver Transformer

  -- Engineering, Leatherworking
  [8151] = { { "Engineering", 2, 205, 210 }, { "Leatherworking", 2, 215, 220 } },   -- Flask of Mojo
  [15407] = { { "Engineering", 1, 250, 250 }, { "Leatherworking", 53, 280, 300 } }, -- Cured Rugged Hide

  -- Engineering, Leatherworking, Tailoring
  [4337] = { { "Engineering", 1, 210, 210 }, { "Leatherworking", 1, 200, 200 }, { "Tailoring", 4, 165, 200 } },    -- Thick Spider's Silk
  [7079] = { { "Engineering", 2, 250, 285 }, { "Leatherworking", 1, 230, 230 }, { "Tailoring", 2, 255, 255 } },    -- Globe of Water
  [14227] = { { "Engineering", 2, 265, 285 }, { "Leatherworking", 13, 300, 300 }, { "Tailoring", 35, 260, 300 } }, -- Ironweb Spider Silk

  -- Engineering, Tailoring
  [4339] = { { "Engineering", 1, 225, 225 }, { "Tailoring", 40, 190, 250 } }, -- Bolt of Mageweave
  [10285] = { { "Engineering", 2, 210, 225 }, { "Tailoring", 6, 210, 245 } }, -- Shadow Silk

  -- First Aid
  [1475] = { { "First Aid", 1, 80, 80 } },    -- Small Venom Sac
  [19441] = { { "First Aid", 1, 300, 300 } }, -- Huge Venom Sac

  -- Leatherworking
  [783] = { { "Leatherworking", 1, 35, 35 } },      -- Light Hide
  [2312] = { { "Leatherworking", 1, 120, 120 } },   -- Fine Leather Gloves
  [2457] = { { "Leatherworking", 1, 120, 120 } },   -- Elixir of Minor Agility
  [2934] = { { "Leatherworking", 1, 1, 1 } },       -- Ruined Leather Scraps
  [3389] = { { "Leatherworking", 1, 135, 135 } },   -- Elixir of Defense
  [3390] = { { "Leatherworking", 1, 140, 140 } },   -- Elixir of Lesser Agility
  [4096] = { { "Leatherworking", 1, 200, 200 } },   -- Coarse Gorilla Hair
  [4231] = { { "Leatherworking", 10, 75, 120 } },   -- Cured Light Hide
  [4232] = { { "Leatherworking", 1, 100, 100 } },   -- Medium Hide
  [4233] = { { "Leatherworking", 4, 120, 135 } },   -- Cured Medium Hide
  [4235] = { { "Leatherworking", 1, 150, 150 } },   -- Heavy Hide
  [4236] = { { "Leatherworking", 14, 155, 200 } },  -- Cured Heavy Hide
  [4243] = { { "Leatherworking", 1, 100, 100 } },   -- Fine Leather Tunic
  [4246] = { { "Leatherworking", 1, 125, 125 } },   -- Fine Leather Belt
  [4289] = { { "Leatherworking", 3, 35, 150 } },    -- Salt
  [4461] = { { "Leatherworking", 3, 155, 165 } },   -- Raptor Hide
  [5082] = { { "Leatherworking", 1, 40, 40 } },     -- Thin Kodo Leather
  [5116] = { { "Leatherworking", 1, 125, 125 } },   -- Long Tail Feather
  [5373] = { { "Leatherworking", 1, 140, 140 } },   -- Lucky Charm
  [5633] = { { "Leatherworking", 1, 200, 200 } },   -- Great Rage Potion
  [5784] = { { "Leatherworking", 2, 90, 95 } },     -- Slimy Murloc Scale
  [5785] = { { "Leatherworking", 2, 170, 190 } },   -- Thick Murloc Scale
  [6470] = { { "Leatherworking", 3, 90, 115 } },    -- Deviate Scale
  [6471] = { { "Leatherworking", 2, 105, 115 } },   -- Perfect Deviate Scale
  [7286] = { { "Leatherworking", 2, 100, 100 } },   -- Black Whelp Scale
  [7287] = { { "Leatherworking", 1, 120, 120 } },   -- Red Whelp Scale
  [7392] = { { "Leatherworking", 2, 175, 190 } },   -- Green Whelp Scale
  [7428] = { { "Leatherworking", 2, 200, 200 } },   -- Shadowcat Hide
  [8152] = { { "Leatherworking", 2, 240, 240 } },   -- Flask of Big Mojo
  [8154] = { { "Leatherworking", 7, 220, 250 } },   -- Scorpid Scale
  [8165] = { { "Leatherworking", 2, 225, 255 } },   -- Worn Dragonscale
  [8167] = { { "Leatherworking", 5, 205, 235 } },   -- Turtle Scale
  [8169] = { { "Leatherworking", 1, 200, 200 } },   -- Thick Hide
  [8171] = { { "Leatherworking", 1, 250, 250 } },   -- Rugged Hide
  [8172] = { { "Leatherworking", 14, 220, 255 } },  -- Cured Thick Hide
  [8368] = { { "Leatherworking", 1, 225, 225 } },   -- Thick Wolfhide
  [8949] = { { "Leatherworking", 1, 225, 225 } },   -- Elixir of Agility
  [8951] = { { "Leatherworking", 1, 225, 225 } },   -- Elixir of Greater Defense
  [12607] = { { "Leatherworking", 2, 300, 300 } },  -- Brilliant Chromatic Scale
  [14044] = { { "Leatherworking", 1, 300, 300 } },  -- Cindercloth Cloak
  [15408] = { { "Leatherworking", 10, 255, 300 } }, -- Heavy Scorpid Scale
  [15409] = { { "Leatherworking", 1, 250, 250 } },  -- Refined Deeprock Salt
  [15410] = { { "Leatherworking", 1, 300, 300 } },  -- Scale of Onyxia
  [15412] = { { "Leatherworking", 3, 260, 280 } },  -- Green Dragonscale
  [15414] = { { "Leatherworking", 2, 300, 300 } },  -- Red Dragonscale
  [15415] = { { "Leatherworking", 3, 285, 300 } },  -- Blue Dragonscale
  [15416] = { { "Leatherworking", 5, 290, 300 } },  -- Black Dragonscale
  [15419] = { { "Leatherworking", 1, 275, 275 } },  -- Warbear Leather
  [15420] = { { "Leatherworking", 3, 270, 300 } },  -- Ironfeather
  [15422] = { { "Leatherworking", 4, 275, 300 } },  -- Frostsaber Leather
  [15423] = { { "Leatherworking", 4, 265, 290 } },  -- Chimera Leather
  [18512] = { { "Leatherworking", 6, 300, 300 } },  -- Larval Acid
  [19767] = { { "Leatherworking", 3, 300, 300 } },  -- Primal Bat Leather
  [19768] = { { "Leatherworking", 2, 300, 300 } },  -- Primal Tiger Leather
  [20381] = { { "Leatherworking", 1, 300, 300 } },  -- Dreamscale
  [20498] = { { "Leatherworking", 6, 300, 300 } },  -- Silithid Chitin
  [20500] = { { "Leatherworking", 3, 300, 300 } },  -- Light Silithid Carapace
  [20501] = { { "Leatherworking", 3, 300, 300 } },  -- Heavy Silithid Carapace

  -- Leatherworking, Tailoring
  [2320] = { { "Leatherworking", 24, 1, 100 }, { "Tailoring", 22, 1, 70 } },       -- Coarse Thread
  [2324] = { { "Leatherworking", 1, 60, 60 }, { "Tailoring", 10, 1, 250 } },       -- Bleach
  [2325] = { { "Leatherworking", 9, 165, 300 }, { "Tailoring", 3, 185, 235 } },    -- Black Dye
  [2997] = { { "Leatherworking", 2, 105, 145 }, { "Tailoring", 25, 75, 130 } },    -- Bolt of Woolen Cloth
  [3182] = { { "Leatherworking", 1, 135, 135 }, { "Tailoring", 4, 125, 150 } },    -- Spider's Silk
  [3383] = { { "Leatherworking", 1, 120, 120 }, { "Tailoring", 1, 130, 130 } },    -- Elixir of Wisdom
  [4291] = { { "Leatherworking", 22, 185, 235 }, { "Tailoring", 24, 160, 225 } },  -- Silken Thread
  [4305] = { { "Leatherworking", 3, 160, 195 }, { "Tailoring", 41, 125, 210 } },   -- Bolt of Silk Cloth
  [4340] = { { "Leatherworking", 7, 100, 140 }, { "Tailoring", 5, 100, 155 } },    -- Gray Dye
  [7071] = { { "Leatherworking", 5, 160, 200 }, { "Tailoring", 5, 175, 200 } },    -- Iron Buckle
  [8343] = { { "Leatherworking", 20, 200, 255 }, { "Tailoring", 34, 210, 250 } },  -- Heavy Silken Thread
  [14048] = { { "Leatherworking", 1, 285, 285 }, { "Tailoring", 78, 250, 300 } },  -- Bolt of Runecloth
  [14256] = { { "Leatherworking", 1, 300, 300 }, { "Tailoring", 14, 250, 300 } },  -- Felcloth
  [14341] = { { "Leatherworking", 72, 255, 300 }, { "Tailoring", 62, 250, 300 } }, -- Rune Thread
  [14342] = { { "Leatherworking", 1, 300, 300 }, { "Tailoring", 23, 290, 300 } },  -- Mooncloth
  [18240] = { { "Leatherworking", 1, 285, 285 }, { "Tailoring", 1, 285, 285 } },   -- Ogre Tannin

  -- Mining
  [2770] = { { "Mining", 1, 1, 1 } },      -- Copper Ore
  [2771] = { { "Mining", 1, 75, 75 } },    -- Tin Ore
  [2772] = { { "Mining", 1, 125, 125 } },  -- Iron Ore
  [2775] = { { "Mining", 1, 75, 75 } },    -- Silver Ore
  [2776] = { { "Mining", 1, 155, 155 } },  -- Gold Ore
  [3576] = { { "Mining", 1, 65, 65 } },    -- Tin Bar
  [3857] = { { "Mining", 1, 165, 165 } },  -- Coal
  [7911] = { { "Mining", 1, 230, 230 } },  -- Truesilver Ore
  [11370] = { { "Mining", 1, 230, 230 } }, -- Dark Iron Ore
  [18562] = { { "Mining", 1, 310, 310 } }, -- Elementium Ore
  [18567] = { { "Mining", 1, 310, 310 } }, -- Elemental Flux

  -- Tailoring
  [929] = { { "Tailoring", 1, 150, 150 } },   -- Healing Potion
  [2604] = { { "Tailoring", 25, 40, 250 } },  -- Red Dye
  [2996] = { { "Tailoring", 28, 1, 80 } },    -- Bolt of Linen Cloth
  [3827] = { { "Tailoring", 2, 185, 205 } },  -- Mana Potion
  [4341] = { { "Tailoring", 1, 135, 135 } },  -- Yellow Dye
  [4589] = { { "Tailoring", 1, 240, 240 } },  -- Long Elegant Feather
  [6048] = { { "Tailoring", 1, 145, 145 } },  -- Shadow Protection Potion
  [6260] = { { "Tailoring", 13, 40, 190 } },  -- Blue Dye
  [6261] = { { "Tailoring", 2, 215, 220 } },  -- Orange Dye
  [7072] = { { "Tailoring", 1, 190, 190 } },  -- Naga Scale
  [9210] = { { "Tailoring", 7, 265, 300 } },  -- Ghost Dye
  [10290] = { { "Tailoring", 1, 235, 235 } }, -- Pink Dye
  [11040] = { { "Tailoring", 1, 275, 275 } }, -- Morrowgrain

}
