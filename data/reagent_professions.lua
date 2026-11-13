-- Bagwise: reagent-to-profession mapping with recipe stats
-- For each reagent item: which professions use it, how many
-- recipes, the skill range they are learnable at, and the skill
-- where the last of them turns green (0 when unknown).
-- Generated from wago.tools DB2 build 1.60.1.70938. Do not edit by hand.
--
-- 588 reagent items across 9 professions.

Bagwise                         = Bagwise or {}
Bagwise.Data                    = Bagwise.Data or {}

-- Format: [itemID] = { { profession, recipe_count, min_level, max_level, green_level }, ... }
Bagwise.Data.ReagentProfessions = {
  -- Alchemy
  [765] = { { "Alchemy", 7, 10, 90, 100 } },  -- Silverleaf
  [2449] = { { "Alchemy", 9, 20, 175, 195 } },  -- Earthroot
  [2456] = { { "Alchemy", 1, 225, 225, 230 } },  -- Minor Rejuvenation Potion
  [3355] = { { "Alchemy", 9, 70, 215, 235 } },  -- Wild Steelbloom
  [3358] = { { "Alchemy", 10, 120, 250, 270 } },  -- Khadgar's Whisker
  [3369] = { { "Alchemy", 5, 90, 270, 272 } },  -- Grave Moss
  [3820] = { { "Alchemy", 8, 90, 210, 230 } },  -- Stranglekelp
  [6358] = { { "Alchemy", 1, 80, 80, 90 } },  -- Oily Blackmouth
  [6359] = { { "Alchemy", 1, 150, 150, 160 } },  -- Firefin Snapper
  [8836] = { { "Alchemy", 7, 170, 255, 275 } },  -- Arthas' Tears
  [8839] = { { "Alchemy", 9, 180, 305, 307 } },  -- Blindweed
  [8845] = { { "Alchemy", 7, 250, 280, 295 } },  -- Ghost Mushroom
  [8846] = { { "Alchemy", 14, 260, 315, 325 } },  -- Gromsblood
  [9260] = { { "Alchemy", 1, 225, 225, 245 } },  -- Volatile Rum
  [13422] = { { "Alchemy", 1, 250, 250, 255 } },  -- Stonescale Eel
  [13463] = { { "Alchemy", 24, 280, 320, 330 } },  -- Dreamfoil
  [13466] = { { "Alchemy", 11, 280, 315, 325 } },  -- Plaguebloom
  [13513] = { { "Alchemy", 1, 315, 315, 322 } },  -- Flask of Chromatic Resistance
  [19943] = { { "Alchemy", 1, 315, 315, 322 } },  -- Massive Mojo
  [213371] = { { "Alchemy", 2, 200, 225, 230 } },  -- Crate of Tainted Gniodine Solution
  [221312] = { { "Alchemy", 1, 250, 250, 255 } },
  [248821] = { { "Alchemy", 2, 320, 320, 325 } },  -- Demonsage
  [273125] = { { "Alchemy", 1, 300, 300, 0 } },  -- Lich's Index Finger

  -- Alchemy, Blacksmithing
  [5635] = { { "Alchemy", 1, 90, 90, 110 }, { "Blacksmithing", 2, 160, 175, 187 } },  -- Sharp Claw
  [13510] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 1, 320, 320, 330 } },  -- Flask of the Titans
  [13511] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 1, 320, 320, 330 } },  -- Flask of Distilled Wisdom
  [13512] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 5, 320, 320, 330 } },  -- Flask of Supreme Power

  -- Alchemy, Blacksmithing, Cooking, Enchanting, Leatherworking
  [5637] = { { "Alchemy", 1, 195, 195, 215 }, { "Blacksmithing", 3, 175, 185, 197 }, { "Cooking", 1, 185, 185, 190 }, { "Enchanting", 2, 195, 200, 217 }, { "Leatherworking", 2, 150, 155, 165 } },  -- Large Fang

  -- Alchemy, Blacksmithing, Enchanting
  [234006] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 3, 320, 320, 330 }, { "Enchanting", 2, 320, 320, 340 } },

  -- Alchemy, Blacksmithing, Enchanting, Engineering
  [248822] = { { "Alchemy", 4, 320, 320, 325 }, { "Blacksmithing", 1, 320, 320, 330 }, { "Enchanting", 2, 295, 320, 340 }, { "Engineering", 2, 320, 320, 330 } },  -- Death Lotus

  -- Alchemy, Blacksmithing, Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [7080] = { { "Alchemy", 3, 275, 315, 322 }, { "Blacksmithing", 11, 285, 320, 330 }, { "Enchanting", 10, 285, 320, 340 }, { "Engineering", 2, 310, 320, 330 }, { "First Aid", 1, 295, 295, 325 }, { "Leatherworking", 25, 250, 320, 330 }, { "Tailoring", 21, 230, 315, 330 } },  -- Essence of Water

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [7067] = { { "Alchemy", 2, 225, 305, 325 }, { "Blacksmithing", 3, 180, 275, 285 }, { "Enchanting", 1, 195, 195, 215 }, { "Engineering", 4, 225, 320, 330 }, { "Leatherworking", 12, 135, 270, 280 }, { "Tailoring", 11, 155, 215, 230 } },  -- Elemental Earth
  [7076] = { { "Alchemy", 3, 275, 315, 322 }, { "Blacksmithing", 18, 270, 320, 330 }, { "Enchanting", 6, 285, 320, 340 }, { "Engineering", 4, 320, 320, 330 }, { "Leatherworking", 10, 280, 320, 330 }, { "Tailoring", 11, 230, 310, 325 } },  -- Essence of Earth
  [7077] = { { "Alchemy", 1, 301, 301, 305 }, { "Blacksmithing", 15, 235, 305, 315 }, { "Enchanting", 1, 285, 285, 305 }, { "Engineering", 3, 205, 285, 295 }, { "Leatherworking", 1, 245, 245, 255 }, { "Tailoring", 13, 145, 250, 265 } },  -- Heart of Fire
  [7078] = { { "Alchemy", 2, 275, 315, 322 }, { "Blacksmithing", 11, 280, 325, 337 }, { "Enchanting", 8, 285, 320, 340 }, { "Engineering", 3, 280, 320, 330 }, { "Leatherworking", 17, 265, 320, 330 }, { "Tailoring", 13, 245, 320, 335 } },  -- Essence of Fire
  [7082] = { { "Alchemy", 2, 275, 315, 322 }, { "Blacksmithing", 6, 235, 320, 330 }, { "Enchanting", 9, 305, 320, 340 }, { "Engineering", 4, 320, 320, 330 }, { "Leatherworking", 10, 270, 320, 330 }, { "Tailoring", 4, 290, 310, 325 } },  -- Essence of Air
  [8153] = { { "Alchemy", 1, 225, 225, 237 }, { "Blacksmithing", 1, 270, 270, 282 }, { "Enchanting", 1, 270, 270, 290 }, { "Engineering", 1, 265, 265, 275 }, { "Leatherworking", 7, 215, 265, 275 }, { "Tailoring", 3, 205, 220, 235 } },  -- Wildvine
  [12803] = { { "Alchemy", 2, 275, 315, 322 }, { "Blacksmithing", 9, 270, 320, 330 }, { "Enchanting", 4, 320, 320, 340 }, { "Engineering", 3, 285, 320, 330 }, { "Leatherworking", 24, 265, 320, 330 }, { "Tailoring", 12, 250, 320, 330 } },  -- Living Essence

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Mining
  [12359] = { { "Alchemy", 1, 275, 275, 282 }, { "Blacksmithing", 113, 245, 320, 330 }, { "Enchanting", 1, 250, 250, 255 }, { "Engineering", 16, 270, 320, 330 }, { "Mining", 1, 300, 300, 0 } },  -- Thorium Bar

  -- Alchemy, Blacksmithing, Enchanting, Engineering, Tailoring
  [7068] = { { "Alchemy", 1, 305, 305, 325 }, { "Blacksmithing", 1, 190, 190, 202 }, { "Enchanting", 1, 195, 195, 215 }, { "Engineering", 5, 225, 320, 330 }, { "Tailoring", 5, 175, 250, 265 } },  -- Elemental Fire
  [7972] = { { "Alchemy", 1, 230, 230, 250 }, { "Blacksmithing", 1, 250, 250, 262 }, { "Enchanting", 1, 285, 285, 305 }, { "Engineering", 1, 260, 260, 270 }, { "Tailoring", 1, 230, 230, 245 } },  -- Ichor of Undeath
  [12808] = { { "Alchemy", 1, 275, 275, 282 }, { "Blacksmithing", 4, 290, 320, 330 }, { "Enchanting", 6, 285, 320, 340 }, { "Engineering", 2, 260, 320, 330 }, { "Tailoring", 4, 260, 310, 325 } },  -- Essence of Undeath

  -- Alchemy, Blacksmithing, Enchanting, Leatherworking, Tailoring
  [12938] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 3, 280, 285, 295 }, { "Enchanting", 6, 305, 320, 340 }, { "Leatherworking", 6, 280, 285, 295 }, { "Tailoring", 4, 280, 300, 302 } },  -- Blood of Heroes

  -- Alchemy, Blacksmithing, Enchanting, Tailoring
  [8831] = { { "Alchemy", 9, 170, 255, 275 }, { "Blacksmithing", 8, 155, 270, 280 }, { "Enchanting", 4, 260, 320, 340 }, { "Tailoring", 1, 245, 245, 260 } },  -- Purple Lotus

  -- Alchemy, Blacksmithing, Engineering
  [3860] = { { "Alchemy", 1, 240, 240, 260 }, { "Blacksmithing", 54, 200, 260, 272 }, { "Engineering", 37, 1, 320, 330 } },  -- Mithril Bar
  [251291] = { { "Alchemy", 1, 275, 275, 282 }, { "Blacksmithing", 37, 270, 320, 330 }, { "Engineering", 4, 310, 310, 317 } },  -- Heavy Thorium Bar

  -- Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring
  [7069] = { { "Alchemy", 1, 305, 305, 325 }, { "Blacksmithing", 2, 185, 190, 202 }, { "Engineering", 2, 270, 310, 315 }, { "Leatherworking", 15, 155, 300, 310 }, { "Tailoring", 1, 175, 175, 190 } },  -- Elemental Air
  [12804] = { { "Alchemy", 1, 315, 315, 322 }, { "Blacksmithing", 5, 280, 325, 337 }, { "Engineering", 2, 320, 320, 330 }, { "Leatherworking", 5, 285, 320, 330 }, { "Tailoring", 2, 315, 315, 330 } },  -- Powerful Mojo
  [220688] = { { "Alchemy", 2, 250, 250, 255 }, { "Blacksmithing", 3, 250, 250, 255 }, { "Engineering", 3, 250, 250, 255 }, { "Leatherworking", 7, 250, 250, 255 }, { "Tailoring", 3, 250, 250, 255 } },
  [221021] = { { "Alchemy", 3, 250, 250, 255 }, { "Blacksmithing", 3, 250, 250, 255 }, { "Engineering", 3, 250, 250, 255 }, { "Leatherworking", 7, 250, 250, 255 }, { "Tailoring", 3, 250, 250, 255 } },

  -- Alchemy, Blacksmithing, Engineering, Mining
  [3575] = { { "Alchemy", 2, 240, 240, 260 }, { "Blacksmithing", 34, 125, 195, 207 }, { "Engineering", 10, 125, 215, 230 }, { "Mining", 1, 165, 165, 0 } },  -- Iron Bar

  -- Alchemy, Blacksmithing, First Aid, Leatherworking, Tailoring
  [7070] = { { "Alchemy", 1, 305, 305, 325 }, { "Blacksmithing", 1, 190, 190, 202 }, { "First Aid", 1, 225, 225, 255 }, { "Leatherworking", 15, 155, 270, 280 }, { "Tailoring", 2, 160, 175, 190 } },  -- Elemental Water

  -- Alchemy, Blacksmithing, Leatherworking, Tailoring
  [3824] = { { "Alchemy", 1, 305, 305, 325 }, { "Blacksmithing", 1, 200, 200, 212 }, { "Leatherworking", 3, 170, 195, 205 }, { "Tailoring", 1, 155, 155, 170 } },  -- Shadow Oil

  -- Alchemy, Cooking
  [730] = { { "Alchemy", 6, 55, 290, 310 }, { "Cooking", 2, 115, 220, 230 } },  -- Murloc Eye
  [785] = { { "Alchemy", 11, 30, 145, 165 }, { "Cooking", 1, 105, 105, 115 } },  -- Mageroyal
  [3818] = { { "Alchemy", 9, 145, 220, 240 }, { "Cooking", 1, 195, 195, 215 } },  -- Fadeleaf
  [3821] = { { "Alchemy", 15, 155, 255, 275 }, { "Cooking", 1, 215, 215, 235 } },  -- Goldthorn
  [6522] = { { "Alchemy", 1, 120, 120, 140 }, { "Cooking", 1, 125, 125, 145 } },  -- Deviate Fish
  [13465] = { { "Alchemy", 11, 250, 320, 325 }, { "Cooking", 1, 260, 260, 275 } },  -- Mountain Silversage

  -- Alchemy, Cooking, Enchanting
  [2452] = { { "Alchemy", 6, 80, 165, 185 }, { "Cooking", 1, 100, 100, 120 }, { "Enchanting", 1, 320, 320, 340 } },  -- Swiftthistle

  -- Alchemy, Cooking, Enchanting, First Aid
  [8838] = { { "Alchemy", 11, 205, 290, 300 }, { "Cooking", 1, 220, 220, 235 }, { "Enchanting", 1, 245, 245, 265 }, { "First Aid", 1, 230, 230, 250 } },  -- Sungrass

  -- Alchemy, Cooking, Engineering
  [4402] = { { "Alchemy", 1, 210, 210, 230 }, { "Cooking", 2, 215, 240, 260 }, { "Engineering", 1, 125, 125, 150 } },  -- Small Flame Sac

  -- Alchemy, Cooking, First Aid
  [2447] = { { "Alchemy", 10, 10, 80, 100 }, { "Cooking", 1, 30, 30, 37 }, { "First Aid", 1, 55, 55, 75 } },  -- Peacebloom
  [3357] = { { "Alchemy", 5, 85, 210, 230 }, { "Cooking", 1, 155, 155, 170 }, { "First Aid", 1, 175, 175, 195 } },  -- Liferoot

  -- Alchemy, Enchanting
  [3819] = { { "Alchemy", 8, 135, 285, 287 }, { "Enchanting", 1, 210, 210, 230 } },  -- Wintersbite
  [6370] = { { "Alchemy", 4, 120, 190, 210 }, { "Enchanting", 1, 170, 170, 190 } },  -- Blackmouth Oil
  [18256] = { { "Alchemy", 11, 280, 320, 325 }, { "Enchanting", 3, 310, 310, 320 } },  -- Imbued Vial
  [248819] = { { "Alchemy", 1, 275, 275, 282 }, { "Enchanting", 2, 320, 320, 340 } },  -- Fel Crystal
  [249274] = { { "Alchemy", 1, 230, 230, 250 }, { "Enchanting", 1, 320, 320, 340 } },  -- Stranglevine
  [249399] = { { "Alchemy", 1, 50, 50, 70 }, { "Enchanting", 1, 140, 140, 160 } },  -- Frilled Lichen
  [249424] = { { "Alchemy", 1, 130, 130, 142 }, { "Enchanting", 1, 225, 225, 245 } },  -- Rosecap

  -- Alchemy, Enchanting, Engineering
  [12363] = { { "Alchemy", 1, 275, 275, 282 }, { "Enchanting", 1, 295, 295, 297 }, { "Engineering", 1, 320, 320, 330 } },  -- Arcane Crystal
  [13467] = { { "Alchemy", 7, 300, 320, 330 }, { "Enchanting", 1, 305, 305, 325 }, { "Engineering", 1, 280, 280, 290 } },  -- Icecap
  [234010] = { { "Alchemy", 1, 315, 315, 322 }, { "Enchanting", 9, 320, 320, 340 }, { "Engineering", 1, 315, 315, 322 } },
  [234011] = { { "Alchemy", 5, 315, 315, 322 }, { "Enchanting", 8, 320, 320, 340 }, { "Engineering", 2, 315, 315, 322 } },
  [234012] = { { "Alchemy", 5, 315, 315, 322 }, { "Enchanting", 11, 320, 320, 340 }, { "Engineering", 1, 315, 315, 322 } },  -- Hive Thistle

  -- Alchemy, Enchanting, Engineering, Tailoring
  [16203] = { { "Alchemy", 4, 315, 315, 322 }, { "Enchanting", 44, 285, 320, 340 }, { "Engineering", 1, 275, 275, 277 }, { "Tailoring", 1, 245, 245, 260 } },  -- Greater Eternal Essence
  [249391] = { { "Alchemy", 1, 50, 50, 70 }, { "Enchanting", 4, 140, 225, 245 }, { "Engineering", 1, 125, 125, 135 }, { "Tailoring", 9, 80, 145, 160 } },  -- Pyrite

  -- Alchemy, Enchanting, First Aid
  [3371] = { { "Alchemy", 37, 10, 150, 165 }, { "Enchanting", 1, 30, 30, 47 }, { "First Aid", 2, 55, 85, 105 } },  -- Empty Vial
  [3372] = { { "Alchemy", 51, 85, 260, 265 }, { "Enchanting", 3, 100, 210, 220 }, { "First Aid", 2, 135, 175, 195 } },  -- Leaded Vial
  [8925] = { { "Alchemy", 80, 170, 315, 330 }, { "Enchanting", 3, 260, 285, 295 }, { "First Aid", 2, 230, 290, 310 } },  -- Crystal Vial

  -- Alchemy, Enchanting, Leatherworking
  [3356] = { { "Alchemy", 15, 80, 210, 215 }, { "Enchanting", 1, 170, 170, 190 }, { "Leatherworking", 1, 135, 135, 147 } },  -- Kingsblood
  [11083] = { { "Alchemy", 1, 90, 90, 100 }, { "Enchanting", 20, 140, 190, 210 }, { "Leatherworking", 2, 155, 155, 165 } },  -- Soul Dust

  -- Alchemy, Enchanting, Leatherworking, Tailoring
  [11176] = { { "Alchemy", 1, 305, 305, 325 }, { "Enchanting", 32, 200, 290, 310 }, { "Leatherworking", 2, 235, 235, 245 }, { "Tailoring", 3, 245, 275, 290 } },  -- Dream Dust

  -- Alchemy, Enchanting, Tailoring
  [4625] = { { "Alchemy", 10, 135, 285, 287 }, { "Enchanting", 3, 285, 310, 320 }, { "Tailoring", 2, 220, 220, 235 } },  -- Firebloom
  [6371] = { { "Alchemy", 3, 165, 265, 285 }, { "Enchanting", 1, 150, 150, 170 }, { "Tailoring", 13, 80, 210, 225 } },  -- Fire Oil
  [13468] = { { "Alchemy", 7, 315, 315, 322 }, { "Enchanting", 1, 320, 320, 340 }, { "Tailoring", 1, 270, 270, 285 } },  -- Black Lotus

  -- Alchemy, Engineering
  [9262] = { { "Alchemy", 2, 240, 315, 322 }, { "Engineering", 1, 205, 205, 210 } },  -- Black Vitriol
  [215430] = { { "Alchemy", 1, 225, 225, 230 }, { "Engineering", 2, 225, 225, 230 } },  -- Gnomeregan Fallout
  [248823] = { { "Alchemy", 2, 320, 320, 325 }, { "Engineering", 1, 320, 320, 330 } },  -- Marefoil

  -- Alchemy, Engineering, Tailoring
  [10286] = { { "Alchemy", 2, 300, 310, 320 }, { "Engineering", 1, 265, 265, 275 }, { "Tailoring", 3, 205, 220, 235 } },  -- Heart of the Wild

  -- Alchemy, First Aid
  [1288] = { { "Alchemy", 1, 145, 145, 165 }, { "First Aid", 1, 130, 130, 165 } },  -- Large Venom Sac
  [2450] = { { "Alchemy", 7, 85, 150, 170 }, { "First Aid", 1, 85, 85, 105 } },  -- Briarthorn
  [2453] = { { "Alchemy", 7, 35, 200, 220 }, { "First Aid", 1, 135, 135, 155 } },  -- Bruiseweed
  [13464] = { { "Alchemy", 7, 255, 320, 325 }, { "First Aid", 1, 290, 290, 310 } },  -- Golden Sansam

  -- Alchemy, Leatherworking
  [13423] = { { "Alchemy", 4, 280, 315, 322 }, { "Leatherworking", 1, 275, 275, 285 } },  -- Stonescale Oil
  [15410] = { { "Alchemy", 1, 315, 315, 322 }, { "Leatherworking", 2, 320, 320, 330 } },  -- Scale of Onyxia

  -- Alchemy, Mining
  [3858] = { { "Alchemy", 1, 230, 230, 250 }, { "Mining", 1, 175, 175, 0 } },  -- Mithril Ore
  [10620] = { { "Alchemy", 1, 295, 295, 315 }, { "Mining", 1, 250, 250, 0 } },  -- Thorium Ore

  -- Alchemy, Tailoring
  [4342] = { { "Alchemy", 1, 260, 260, 280 }, { "Tailoring", 2, 160, 195, 200 } },  -- Purple Dye

  -- Blacksmithing
  [2863] = { { "Blacksmithing", 1, 100, 100, 110 } },  -- Coarse Sharpening Stone
  [2870] = { { "Blacksmithing", 1, 175, 175, 190 } },  -- Shining Silver Breastplate
  [3466] = { { "Blacksmithing", 22, 115, 205, 217 } },  -- Strong Flux
  [3470] = { { "Blacksmithing", 31, 65, 115, 135 } },  -- Rough Grinding Stone
  [3478] = { { "Blacksmithing", 54, 100, 165, 177 } },  -- Coarse Grinding Stone
  [3486] = { { "Blacksmithing", 70, 125, 240, 250 } },  -- Heavy Grinding Stone
  [3823] = { { "Blacksmithing", 1, 245, 245, 257 } },  -- Lesser Invisibility Potion
  [4255] = { { "Blacksmithing", 1, 180, 180, 192 } },  -- Green Leather Armor
  [5966] = { { "Blacksmithing", 1, 220, 220, 230 } },  -- Guardian Gloves
  [7966] = { { "Blacksmithing", 52, 175, 270, 280 } },  -- Solid Grinding Stone
  [11184] = { { "Blacksmithing", 1, 250, 250, 260 } },  -- Blue Power Crystal
  [11185] = { { "Blacksmithing", 1, 275, 275, 285 } },  -- Green Power Crystal
  [11186] = { { "Blacksmithing", 2, 245, 295, 305 } },  -- Red Power Crystal
  [11188] = { { "Blacksmithing", 2, 245, 275, 285 } },  -- Yellow Power Crystal
  [12644] = { { "Blacksmithing", 23, 250, 325, 337 } },  -- Dense Grinding Stone
  [12784] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Arcanite Reaper
  [12790] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Arcanite Champion
  [12794] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Masterwork Stormhammer
  [12796] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Hammer of the Titans
  [12797] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Frostguard
  [17203] = { { "Blacksmithing", 2, 325, 325, 337 } },  -- Sulfuron Ingot
  [18262] = { { "Blacksmithing", 5, 320, 320, 330 } },  -- Elemental Sharpening Stone
  [20867] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Onyx Idol
  [20871] = { { "Blacksmithing", 4, 320, 320, 330 } },  -- Obsidian Idol
  [20872] = { { "Blacksmithing", 3, 320, 320, 330 } },  -- Vermillion Idol
  [20873] = { { "Blacksmithing", 2, 320, 320, 330 } },  -- Alabaster Idol
  [20874] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of the Sun
  [20875] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of Night
  [20876] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of Death
  [20877] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of the Sage
  [20878] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of Rebirth
  [20879] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of Life
  [20882] = { { "Blacksmithing", 1, 320, 320, 330 } },  -- Idol of War
  [213373] = { { "Blacksmithing", 1, 200, 200, 210 } },  -- Reflective Scrapmetal
  [273127] = { { "Blacksmithing", 1, 300, 300, 0 } },  -- Golem Heart

  -- Blacksmithing, Cooking, Leatherworking
  [8146] = { { "Blacksmithing", 5, 320, 320, 330 }, { "Cooking", 1, 255, 255, 262 }, { "Leatherworking", 1, 220, 220, 230 } },  -- Wicked Claw

  -- Blacksmithing, Enchanting
  [7081] = { { "Blacksmithing", 2, 245, 260, 272 }, { "Enchanting", 1, 285, 285, 305 } },  -- Breath of Wind
  [10938] = { { "Blacksmithing", 11, 40, 155, 170 }, { "Enchanting", 15, 75, 130, 150 } },  -- Lesser Magic Essence
  [11139] = { { "Blacksmithing", 10, 230, 250, 262 }, { "Enchanting", 7, 210, 240, 260 } },  -- Large Glowing Shard
  [11382] = { { "Blacksmithing", 6, 320, 325, 337 }, { "Enchanting", 4, 285, 285, 305 } },  -- Blood of the Mountain
  [234004] = { { "Blacksmithing", 7, 320, 320, 330 }, { "Enchanting", 1, 320, 320, 340 } },

  -- Blacksmithing, Enchanting, Engineering
  [7909] = { { "Blacksmithing", 12, 185, 290, 300 }, { "Enchanting", 1, 245, 245, 265 }, { "Engineering", 5, 230, 285, 295 } },  -- Aquamarine
  [20725] = { { "Blacksmithing", 3, 320, 320, 330 }, { "Enchanting", 48, 305, 320, 340 }, { "Engineering", 2, 315, 320, 330 } },  -- Nexus Crystal
  [234003] = { { "Blacksmithing", 10, 320, 320, 330 }, { "Enchanting", 12, 320, 320, 340 }, { "Engineering", 3, 315, 320, 330 } },
  [248820] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Enchanting", 2, 320, 320, 340 }, { "Engineering", 1, 320, 320, 330 } },  -- Torbernite
  [249432] = { { "Blacksmithing", 25, 200, 270, 280 }, { "Enchanting", 1, 225, 225, 245 }, { "Engineering", 1, 175, 175, 177 } },  -- Sandpaper
  [249726] = { { "Blacksmithing", 10, 270, 320, 330 }, { "Enchanting", 1, 320, 320, 340 }, { "Engineering", 3, 275, 320, 330 } },  -- Azerothium Bar

  -- Blacksmithing, Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [8170] = { { "Blacksmithing", 21, 260, 315, 327 }, { "Enchanting", 1, 250, 250, 255 }, { "Engineering", 14, 275, 320, 330 }, { "First Aid", 1, 280, 280, 310 }, { "Leatherworking", 163, 1, 320, 330 }, { "Tailoring", 12, 230, 315, 330 } },  -- Rugged Leather

  -- Blacksmithing, Enchanting, Engineering, Leatherworking
  [7075] = { { "Blacksmithing", 4, 235, 245, 257 }, { "Enchanting", 1, 285, 285, 305 }, { "Engineering", 3, 205, 320, 330 }, { "Leatherworking", 4, 225, 290, 300 } },  -- Core of Earth
  [12361] = { { "Blacksmithing", 25, 245, 320, 330 }, { "Enchanting", 1, 280, 280, 290 }, { "Engineering", 2, 280, 295, 305 }, { "Leatherworking", 1, 290, 290, 300 } },  -- Blue Sapphire
  [249410] = { { "Blacksmithing", 30, 110, 270, 280 }, { "Enchanting", 4, 140, 225, 245 }, { "Engineering", 2, 100, 320, 330 }, { "Leatherworking", 9, 80, 150, 160 } },  -- Sulfuric Acid

  -- Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring
  [1210] = { { "Blacksmithing", 18, 85, 230, 242 }, { "Enchanting", 2, 130, 140, 160 }, { "Engineering", 3, 145, 205, 210 }, { "Leatherworking", 10, 80, 185, 195 }, { "Tailoring", 10, 80, 170, 185 } },  -- Shadowgem
  [7079] = { { "Blacksmithing", 8, 155, 270, 280 }, { "Enchanting", 1, 285, 285, 305 }, { "Engineering", 2, 285, 320, 330 }, { "Leatherworking", 1, 225, 225, 235 }, { "Tailoring", 16, 145, 250, 265 } },  -- Globe of Water
  [12810] = { { "Blacksmithing", 27, 295, 320, 330 }, { "Enchanting", 12, 320, 320, 340 }, { "Engineering", 6, 290, 320, 330 }, { "Leatherworking", 55, 265, 320, 330 }, { "Tailoring", 19, 260, 320, 335 } },  -- Enchanted Leather
  [12811] = { { "Blacksmithing", 10, 260, 320, 330 }, { "Enchanting", 8, 305, 320, 340 }, { "Engineering", 1, 305, 305, 0 }, { "Leatherworking", 16, 260, 285, 295 }, { "Tailoring", 10, 260, 310, 325 } },  -- Righteous Orb
  [274030] = { { "Blacksmithing", 27, 310, 320, 325 }, { "Enchanting", 6, 310, 310, 317 }, { "Engineering", 1, 310, 310, 317 }, { "Leatherworking", 42, 310, 320, 325 }, { "Tailoring", 21, 310, 320, 325 } },  -- Malleable Essence of Nature

  -- Blacksmithing, Enchanting, Engineering, Mining, Tailoring
  [6037] = { { "Blacksmithing", 33, 175, 320, 330 }, { "Enchanting", 2, 225, 235, 255 }, { "Engineering", 13, 200, 295, 305 }, { "Mining", 1, 300, 300, 0 }, { "Tailoring", 1, 220, 220, 235 } },  -- Truesilver Bar

  -- Blacksmithing, Enchanting, Engineering, Tailoring
  [3829] = { { "Blacksmithing", 2, 190, 200, 212 }, { "Enchanting", 1, 255, 255, 275 }, { "Engineering", 3, 175, 280, 290 }, { "Tailoring", 1, 185, 185, 200 } },  -- Frost Oil

  -- Blacksmithing, Enchanting, Leatherworking
  [2459] = { { "Blacksmithing", 1, 130, 130, 145 }, { "Enchanting", 1, 320, 320, 340 }, { "Leatherworking", 1, 195, 195, 205 } },  -- Swiftness Potion
  [10940] = { { "Blacksmithing", 10, 40, 155, 170 }, { "Enchanting", 31, 10, 165, 185 }, { "Leatherworking", 2, 95, 95, 102 } },  -- Strange Dust
  [11754] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Enchanting", 1, 320, 320, 340 }, { "Leatherworking", 1, 310, 310, 320 } },  -- Black Diamond
  [12753] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Enchanting", 1, 320, 320, 340 }, { "Leatherworking", 2, 320, 320, 330 } },  -- Skin of Shadow

  -- Blacksmithing, Enchanting, Leatherworking, Tailoring
  [5500] = { { "Blacksmithing", 3, 140, 150, 165 }, { "Enchanting", 1, 175, 175, 195 }, { "Leatherworking", 15, 155, 270, 280 }, { "Tailoring", 3, 125, 125, 142 } },  -- Iridescent Pearl
  [7971] = { { "Blacksmithing", 13, 155, 320, 330 }, { "Enchanting", 1, 220, 220, 240 }, { "Leatherworking", 3, 185, 270, 280 }, { "Tailoring", 9, 145, 285, 300 } },  -- Black Pearl
  [12809] = { { "Blacksmithing", 4, 295, 320, 330 }, { "Enchanting", 1, 320, 320, 340 }, { "Leatherworking", 5, 285, 320, 330 }, { "Tailoring", 3, 270, 305, 320 } },  -- Guardian Stone

  -- Blacksmithing, Enchanting, Tailoring
  [13926] = { { "Blacksmithing", 8, 155, 270, 280 }, { "Enchanting", 2, 310, 320, 340 }, { "Tailoring", 14, 145, 315, 330 } },  -- Golden Pearl

  -- Blacksmithing, Engineering
  [774] = { { "Blacksmithing", 5, 40, 80, 100 }, { "Engineering", 4, 90, 250, 260 } },  -- Malachite
  [818] = { { "Blacksmithing", 16, 40, 180, 192 }, { "Engineering", 3, 130, 250, 260 } },  -- Tigerseye
  [1705] = { { "Blacksmithing", 14, 135, 240, 252 }, { "Engineering", 2, 170, 220, 230 } },  -- Lesser Moonstone
  [2836] = { { "Blacksmithing", 3, 40, 50, 70 }, { "Engineering", 1, 85, 85, 90 } },  -- Coarse Stone
  [2841] = { { "Blacksmithing", 69, 85, 155, 170 }, { "Engineering", 12, 105, 175, 177 } },  -- Bronze Bar
  [2880] = { { "Blacksmithing", 19, 55, 125, 140 }, { "Engineering", 3, 80, 115, 130 } },  -- Weak Flux
  [3859] = { { "Blacksmithing", 40, 170, 225, 237 }, { "Engineering", 1, 175, 175, 195 } },  -- Steel Bar
  [7912] = { { "Blacksmithing", 3, 175, 175, 180 }, { "Engineering", 1, 175, 175, 185 } },  -- Solid Stone
  [11371] = { { "Blacksmithing", 24, 260, 325, 337 }, { "Engineering", 6, 295, 320, 330 } },  -- Dark Iron Bar
  [19774] = { { "Blacksmithing", 6, 320, 320, 330 }, { "Engineering", 2, 320, 320, 330 } },  -- Souldarite
  [22202] = { { "Blacksmithing", 13, 315, 320, 330 }, { "Engineering", 1, 315, 315, 322 } },  -- Small Obsidian Shard
  [213383] = { { "Blacksmithing", 1, 225, 225, 230 }, { "Engineering", 2, 225, 225, 232 } },  -- Polished Truesilver Gears
  [251290] = { { "Blacksmithing", 17, 310, 320, 330 }, { "Engineering", 5, 310, 320, 330 } },  -- Legionite Bar

  -- Blacksmithing, Engineering, First Aid, Leatherworking, Tailoring
  [4304] = { { "Blacksmithing", 15, 215, 260, 272 }, { "Engineering", 12, 225, 265, 275 }, { "First Aid", 1, 220, 220, 250 }, { "Leatherworking", 79, 185, 255, 265 }, { "Tailoring", 5, 190, 220, 235 } },  -- Thick Leather
  [4338] = { { "Blacksmithing", 5, 200, 240, 252 }, { "Engineering", 4, 200, 255, 265 }, { "First Aid", 2, 210, 240, 270 }, { "Leatherworking", 1, 205, 205, 215 }, { "Tailoring", 1, 145, 145, 147 } },  -- Mageweave Cloth

  -- Blacksmithing, Engineering, First Aid, Tailoring
  [2589] = { { "Blacksmithing", 3, 55, 65, 85 }, { "Engineering", 6, 25, 115, 122 }, { "First Aid", 2, 30, 50, 75 }, { "Tailoring", 1, 25, 25, 37 } },  -- Linen Cloth

  -- Blacksmithing, Engineering, Leatherworking
  [1206] = { { "Blacksmithing", 6, 135, 240, 252 }, { "Engineering", 5, 135, 175, 187 }, { "Leatherworking", 1, 165, 165, 175 } },  -- Moss Agate
  [12799] = { { "Blacksmithing", 16, 270, 320, 330 }, { "Engineering", 3, 295, 320, 330 }, { "Leatherworking", 1, 290, 290, 300 } },  -- Large Opal
  [213376] = { { "Blacksmithing", 2, 225, 225, 230 }, { "Engineering", 1, 225, 225, 232 }, { "Leatherworking", 2, 225, 225, 230 } },  -- Low-Background Truesilver Plates

  -- Blacksmithing, Engineering, Leatherworking, Mining
  [2840] = { { "Blacksmithing", 51, 10, 155, 170 }, { "Engineering", 11, 30, 130, 155 }, { "Leatherworking", 1, 1, 1, 0 }, { "Mining", 2, 20, 65, 90 } },  -- Copper Bar

  -- Blacksmithing, Engineering, Leatherworking, Mining, Tailoring
  [17010] = { { "Blacksmithing", 15, 290, 325, 337 }, { "Engineering", 2, 320, 320, 330 }, { "Leatherworking", 6, 315, 320, 330 }, { "Mining", 1, 310, 310, 315 }, { "Tailoring", 5, 315, 320, 335 } },  -- Fiery Core

  -- Blacksmithing, Engineering, Leatherworking, Tailoring
  [1529] = { { "Blacksmithing", 15, 155, 270, 280 }, { "Engineering", 6, 180, 265, 275 }, { "Leatherworking", 12, 155, 320, 330 }, { "Tailoring", 1, 220, 220, 235 } },  -- Jade
  [2318] = { { "Blacksmithing", 8, 40, 85, 105 }, { "Engineering", 3, 90, 130, 145 }, { "Leatherworking", 82, 20, 110, 122 }, { "Tailoring", 6, 50, 95, 112 } },  -- Light Leather
  [2319] = { { "Blacksmithing", 16, 110, 155, 170 }, { "Engineering", 16, 125, 210, 220 }, { "Leatherworking", 54, 90, 150, 160 }, { "Tailoring", 3, 120, 135, 150 } },  -- Medium Leather
  [3864] = { { "Blacksmithing", 15, 170, 260, 270 }, { "Engineering", 10, 195, 260, 265 }, { "Leatherworking", 9, 155, 270, 280 }, { "Tailoring", 1, 185, 185, 200 } },  -- Citrine
  [4234] = { { "Blacksmithing", 25, 155, 235, 245 }, { "Engineering", 27, 135, 245, 255 }, { "Leatherworking", 70, 125, 215, 225 }, { "Tailoring", 10, 135, 215, 230 } },  -- Heavy Leather
  [12364] = { { "Blacksmithing", 16, 280, 325, 337 }, { "Engineering", 1, 310, 310, 320 }, { "Leatherworking", 3, 265, 295, 302 }, { "Tailoring", 1, 310, 310, 325 } },  -- Huge Emerald
  [12800] = { { "Blacksmithing", 16, 280, 325, 337 }, { "Engineering", 5, 275, 320, 330 }, { "Leatherworking", 1, 295, 295, 302 }, { "Tailoring", 2, 295, 315, 330 } },  -- Azerothian Diamond
  [17011] = { { "Blacksmithing", 15, 290, 325, 337 }, { "Engineering", 3, 320, 320, 330 }, { "Leatherworking", 6, 315, 320, 330 }, { "Tailoring", 3, 315, 315, 330 } },  -- Lava Core
  [19726] = { { "Blacksmithing", 10, 320, 320, 330 }, { "Engineering", 2, 320, 320, 330 }, { "Leatherworking", 12, 320, 320, 330 }, { "Tailoring", 9, 315, 315, 330 } },  -- Bloodvine
  [213369] = { { "Blacksmithing", 1, 225, 225, 230 }, { "Engineering", 2, 225, 225, 232 }, { "Leatherworking", 4, 225, 225, 230 }, { "Tailoring", 1, 225, 225, 230 } },  -- Faintly Glowing Leather
  [213379] = { { "Blacksmithing", 2, 225, 225, 230 }, { "Engineering", 1, 225, 225, 230 }, { "Leatherworking", 2, 225, 225, 230 }, { "Tailoring", 1, 225, 225, 230 } },  -- Hyperconductive Arcano-Filament

  -- Blacksmithing, Engineering, Mining
  [2835] = { { "Blacksmithing", 4, 15, 45, 65 }, { "Engineering", 1, 20, 20, 30 }, { "Mining", 1, 20, 20, 0 } },  -- Rough Stone
  [2838] = { { "Blacksmithing", 3, 100, 100, 112 }, { "Engineering", 1, 125, 125, 135 }, { "Mining", 1, 140, 140, 0 } },  -- Heavy Stone
  [12365] = { { "Blacksmithing", 4, 230, 275, 285 }, { "Engineering", 3, 250, 315, 322 }, { "Mining", 1, 300, 300, 0 } },  -- Dense Stone
  [12655] = { { "Blacksmithing", 41, 275, 325, 337 }, { "Engineering", 2, 280, 320, 330 }, { "Mining", 1, 315, 315, 322 } },  -- Enchanted Thorium Bar

  -- Blacksmithing, Engineering, Mining, Tailoring
  [2842] = { { "Blacksmithing", 34, 75, 295, 305 }, { "Engineering", 2, 110, 155, 167 }, { "Mining", 1, 140, 140, 0 }, { "Tailoring", 18, 125, 145, 160 } },  -- Silver Bar
  [12360] = { { "Blacksmithing", 80, 250, 325, 337 }, { "Engineering", 6, 305, 320, 330 }, { "Mining", 1, 310, 310, 315 }, { "Tailoring", 1, 295, 295, 310 } },  -- Arcanite Bar

  -- Blacksmithing, Engineering, Tailoring
  [3577] = { { "Blacksmithing", 31, 125, 310, 320 }, { "Engineering", 2, 150, 225, 230 }, { "Tailoring", 12, 145, 260, 275 } },  -- Gold Bar
  [7910] = { { "Blacksmithing", 26, 200, 325, 337 }, { "Engineering", 11, 245, 310, 320 }, { "Tailoring", 2, 275, 295, 310 } },  -- Star Ruby

  -- Blacksmithing, Leatherworking
  [3391] = { { "Blacksmithing", 1, 150, 150, 165 }, { "Leatherworking", 1, 205, 205, 215 } },  -- Elixir of Ogre Strength
  [8168] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Leatherworking", 2, 245, 290, 300 } },  -- Jet Black Feather
  [15417] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Leatherworking", 4, 285, 320, 330 } },  -- Devilsaur Leather

  -- Blacksmithing, Leatherworking, Tailoring
  [2320] = { { "Blacksmithing", 1, 75, 75, 95 }, { "Leatherworking", 55, 40, 100, 112 }, { "Tailoring", 37, 20, 70, 87 } },  -- Coarse Thread
  [2605] = { { "Blacksmithing", 6, 150, 170, 182 }, { "Leatherworking", 3, 150, 175, 185 }, { "Tailoring", 10, 60, 250, 252 } },  -- Green Dye
  [5498] = { { "Blacksmithing", 13, 85, 185, 187 }, { "Leatherworking", 12, 40, 155, 165 }, { "Tailoring", 11, 80, 145, 160 } },  -- Small Lustrous Pearl
  [7071] = { { "Blacksmithing", 1, 290, 290, 300 }, { "Leatherworking", 6, 155, 195, 205 }, { "Tailoring", 7, 160, 215, 230 } },  -- Iron Buckle
  [17012] = { { "Blacksmithing", 2, 320, 320, 330 }, { "Leatherworking", 5, 315, 320, 330 }, { "Tailoring", 2, 315, 315, 330 } },  -- Core Leather
  [20381] = { { "Blacksmithing", 1, 320, 320, 330 }, { "Leatherworking", 3, 320, 320, 330 }, { "Tailoring", 2, 320, 320, 330 } },  -- Dreamscale
  [22682] = { { "Blacksmithing", 3, 320, 320, 330 }, { "Leatherworking", 6, 320, 320, 330 }, { "Tailoring", 4, 315, 315, 330 } },  -- Frozen Rune
  [211422] = { { "Blacksmithing", 1, 175, 175, 190 }, { "Leatherworking", 2, 160, 160, 172 }, { "Tailoring", 1, 150, 150, 167 } },
  [236656] = { { "Blacksmithing", 3, 320, 320, 330 }, { "Leatherworking", 6, 320, 320, 330 }, { "Tailoring", 7, 315, 315, 330 } },
  [249427] = { { "Blacksmithing", 30, 85, 260, 270 }, { "Leatherworking", 80, 90, 295, 302 }, { "Tailoring", 16, 80, 315, 330 } },  -- Pristine Leather

  -- Blacksmithing, Mining
  [18567] = { { "Blacksmithing", 26, 290, 320, 325 }, { "Mining", 1, 310, 310, 315 } },  -- Elemental Flux
  [22203] = { { "Blacksmithing", 8, 320, 320, 330 }, { "Mining", 1, 315, 315, 322 } },  -- Large Obsidian Shard

  -- Blacksmithing, Tailoring
  [12662] = { { "Blacksmithing", 5, 280, 325, 337 }, { "Tailoring", 4, 275, 310, 325 } },  -- Demonic Rune
  [20520] = { { "Blacksmithing", 4, 320, 320, 330 }, { "Tailoring", 4, 260, 300, 315 } },  -- Dark Rune

  -- Cooking
  [723] = { { "Cooking", 1, 90, 90, 110 } },  -- Goretusk Liver
  [729] = { { "Cooking", 1, 115, 115, 135 } },  -- Stringy Vulture Meat
  [731] = { { "Cooking", 1, 115, 115, 135 } },  -- Goretusk Snout
  [769] = { { "Cooking", 2, 45, 200, 215 } },  -- Chunk of Boar Meat
  [1015] = { { "Cooking", 2, 140, 165, 185 } },  -- Lean Wolf Flank
  [1080] = { { "Cooking", 1, 135, 135, 155 } },  -- Tough Condor Meat
  [1081] = { { "Cooking", 1, 135, 135, 155 } },  -- Crisp Spider Meat
  [1179] = { { "Cooking", 5, 75, 265, 285 } },  -- Ice Cold Milk
  [1205] = { { "Cooking", 2, 135, 155, 170 } },  -- Melon Juice
  [1645] = { { "Cooking", 2, 215, 220, 235 } },  -- Moonberry Juice
  [1708] = { { "Cooking", 2, 185, 195, 215 } },  -- Sweet Nectar
  [2251] = { { "Cooking", 1, 150, 150, 170 } },  -- Gooey Spider Leg
  [2672] = { { "Cooking", 2, 45, 50, 70 } },  -- Stringy Wolf Meat
  [2673] = { { "Cooking", 1, 90, 90, 110 } },  -- Coyote Meat
  [2674] = { { "Cooking", 1, 115, 115, 135 } },  -- Crawler Meat
  [2675] = { { "Cooking", 2, 40, 125, 145 } },  -- Crawler Claw
  [2677] = { { "Cooking", 2, 120, 130, 150 } },  -- Boar Ribs
  [2886] = { { "Cooking", 1, 60, 60, 80 } },  -- Crag Boar Rib
  [2894] = { { "Cooking", 1, 60, 60, 80 } },  -- Rhapsody Malt
  [2924] = { { "Cooking", 1, 120, 120, 140 } },  -- Crocolisk Meat
  [3172] = { { "Cooking", 1, 100, 100, 120 } },  -- Boar Intestines
  [3173] = { { "Cooking", 2, 80, 100, 120 } },  -- Bear Meat
  [3404] = { { "Cooking", 3, 215, 290, 300 } },  -- Buzzard Wing
  [3667] = { { "Cooking", 2, 160, 160, 180 } },  -- Tender Crocolisk Meat
  [3685] = { { "Cooking", 2, 35, 170, 190 } },  -- Raptor Egg
  [3712] = { { "Cooking", 3, 215, 290, 300 } },  -- Turtle Meat
  [3730] = { { "Cooking", 3, 150, 280, 295 } },  -- Big Bear Meat
  [3731] = { { "Cooking", 2, 175, 190, 210 } },  -- Lion Meat
  [4536] = { { "Cooking", 2, 90, 215, 235 } },  -- Shiny Red Apple
  [4603] = { { "Cooking", 2, 265, 290, 300 } },  -- Raw Spotted Yellowtail
  [4655] = { { "Cooking", 1, 215, 215, 235 } },  -- Giant Clam Meat
  [5051] = { { "Cooking", 1, 130, 130, 150 } },  -- Dig Rat
  [5465] = { { "Cooking", 1, 50, 50, 70 } },  -- Small Spider Leg
  [5466] = { { "Cooking", 1, 60, 60, 80 } },  -- Scorpid Stinger
  [5467] = { { "Cooking", 1, 75, 75, 95 } },  -- Kodo Meat
  [5468] = { { "Cooking", 1, 90, 90, 110 } },  -- Soft Frenzy Flesh
  [5469] = { { "Cooking", 1, 90, 90, 110 } },  -- Strider Meat
  [5470] = { { "Cooking", 1, 140, 140, 160 } },  -- Thunder Lizard Tail
  [5471] = { { "Cooking", 4, 1, 280, 295 } },  -- Stag Meat
  [5503] = { { "Cooking", 2, 90, 130, 150 } },  -- Clam Meat
  [5504] = { { "Cooking", 1, 165, 165, 185 } },  -- Tangy Clam Meat
  [6289] = { { "Cooking", 1, 90, 90, 110 } },  -- Raw Longjaw Mud Snapper
  [6291] = { { "Cooking", 1, 45, 45, 65 } },  -- Raw Brilliant Smallfish
  [6303] = { { "Cooking", 1, 45, 45, 65 } },  -- Raw Slitherskin Mackerel
  [6308] = { { "Cooking", 1, 140, 140, 160 } },  -- Raw Bristle Whisker Catfish
  [6317] = { { "Cooking", 1, 90, 90, 110 } },  -- Raw Loch Frenzy
  [6361] = { { "Cooking", 1, 90, 90, 110 } },  -- Raw Rainbow Fin Albacore
  [6362] = { { "Cooking", 2, 190, 290, 300 } },  -- Raw Rockscale Cod
  [6889] = { { "Cooking", 5, 30, 80, 95 } },  -- Small Egg
  [7974] = { { "Cooking", 2, 265, 280, 295 } },  -- Zesty Clam Meat
  [8365] = { { "Cooking", 1, 215, 215, 235 } },  -- Raw Mithril Head Trout
  [8766] = { { "Cooking", 2, 255, 260, 275 } },  -- Morning Glory Dew
  [8959] = { { "Cooking", 1, 210, 210, 215 } },  -- Raw Spinefin Halibut
  [10284] = { { "Cooking", 4, 30, 300, 0 } },  -- Simple Flour
  [12037] = { { "Cooking", 4, 145, 240, 260 } },  -- Mystery Meat
  [12184] = { { "Cooking", 6, 115, 290, 300 } },  -- Raptor Flesh
  [12202] = { { "Cooking", 3, 215, 280, 295 } },  -- Tiger Meat
  [12203] = { { "Cooking", 3, 215, 285, 300 } },  -- Red Wolf Meat
  [12204] = { { "Cooking", 2, 145, 240, 260 } },  -- Heavy Kodo Meat
  [12205] = { { "Cooking", 1, 240, 240, 260 } },  -- White Spider Meat
  [12206] = { { "Cooking", 2, 220, 265, 285 } },  -- Tender Crab Meat
  [12207] = { { "Cooking", 4, 1, 265, 285 } },  -- Giant Egg
  [12208] = { { "Cooking", 1, 265, 265, 285 } },  -- Tender Wolf Meat
  [12223] = { { "Cooking", 2, 45, 280, 295 } },  -- Meaty Bat Wing
  [13754] = { { "Cooking", 1, 265, 265, 285 } },  -- Raw Glossy Mightfish
  [13755] = { { "Cooking", 1, 280, 280, 300 } },  -- Raw Winter Squid
  [13756] = { { "Cooking", 1, 280, 280, 300 } },  -- Raw Summer Bass
  [13758] = { { "Cooking", 2, 265, 325, 345 } },  -- Raw Redgill
  [13759] = { { "Cooking", 1, 290, 290, 310 } },  -- Raw Nightfin Snapper
  [13760] = { { "Cooking", 1, 290, 290, 310 } },  -- Raw Sunscale Salmon
  [13888] = { { "Cooking", 3, 290, 325, 345 } },  -- Darkclaw Lobster
  [13889] = { { "Cooking", 1, 315, 315, 335 } },  -- Raw Whitescale Salmon
  [13890] = { { "Cooking", 1, 245, 245, 250 } },  -- Raw Plated Armorfish
  [13893] = { { "Cooking", 1, 315, 315, 335 } },  -- Large Raw Mightfish
  [17194] = { { "Cooking", 2, 45, 75, 95 } },  -- Holiday Spices
  [17196] = { { "Cooking", 1, 75, 75, 95 } },  -- Holiday Spirits
  [18255] = { { "Cooking", 1, 315, 315, 335 } },  -- Runn Tum Tuber
  [20424] = { { "Cooking", 1, 325, 325, 345 } },  -- Sandworm Meat
  [21024] = { { "Cooking", 1, 325, 325, 345 } },  -- Chimaerok Tenderloin
  [21071] = { { "Cooking", 1, 120, 120, 140 } },  -- Raw Sagefish
  [21153] = { { "Cooking", 1, 215, 215, 235 } },  -- Raw Greater Sagefish
  [227813] = { { "Cooking", 1, 325, 325, 345 } },
  [239016] = { { "Cooking", 3, 260, 260, 270 } },  -- Holy Salts
  [239017] = { { "Cooking", 2, 290, 290, 300 } },  -- Exquisite Spices
  [249796] = { { "Cooking", 1, 280, 280, 282 } },  -- Hyjal Berries
  [251524] = { { "Cooking", 1, 125, 125, 145 } },  -- Whimsyfin
  [252948] = { { "Cooking", 1, 1, 1, 0 } },
  [272941] = { { "Cooking", 1, 205, 205, 0 } },  -- Thick Logs

  -- Cooking, Enchanting
  [11291] = { { "Cooking", 1, 95, 95, 0 }, { "Enchanting", 17, 140, 320, 340 } },  -- Star Wood

  -- Cooking, Enchanting, First Aid, Leatherworking, Tailoring
  [4470] = { { "Cooking", 2, 1, 25, 50 }, { "Enchanting", 6, 10, 140, 160 }, { "First Aid", 2, 140, 300, 0 }, { "Leatherworking", 1, 125, 125, 0 }, { "Tailoring", 2, 140, 300, 0 } },  -- Simple Wood

  -- Cooking, Engineering
  [9061] = { { "Cooking", 1, 325, 325, 345 }, { "Engineering", 7, 235, 295, 305 } },  -- Goblin Rocket Fuel

  -- Cooking, Engineering, First Aid
  [159] = { { "Cooking", 10, 30, 315, 335 }, { "Engineering", 3, 130, 275, 285 }, { "First Aid", 1, 20, 20, 0 } },  -- Refreshing Spring Water

  -- Cooking, Engineering, Leatherworking
  [8150] = { { "Cooking", 1, 325, 325, 345 }, { "Engineering", 1, 250, 250, 260 }, { "Leatherworking", 1, 175, 175, 0 } },  -- Deeprock Salt

  -- Cooking, First Aid
  [1468] = { { "Cooking", 2, 130, 135, 150 }, { "First Aid", 1, 160, 160, 190 } },  -- Murloc Fin
  [1475] = { { "Cooking", 1, 30, 30, 37 }, { "First Aid", 1, 80, 80, 115 } },  -- Small Venom Sac
  [2596] = { { "Cooking", 1, 215, 215, 235 }, { "First Aid", 1, 225, 225, 255 } },  -- Skin of Dwarven Stout
  [2678] = { { "Cooking", 24, 30, 200, 215 }, { "First Aid", 3, 55, 90, 125 } },  -- Mild Spices
  [2692] = { { "Cooking", 29, 130, 325, 345 }, { "First Aid", 4, 135, 295, 325 } },  -- Hot Spices
  [3174] = { { "Cooking", 2, 100, 105, 120 }, { "First Aid", 1, 90, 90, 125 } },  -- Spider Ichor
  [3713] = { { "Cooking", 27, 145, 325, 345 }, { "First Aid", 3, 160, 290, 310 } },  -- Soothing Spices

  -- Enchanting
  [2289] = { { "Enchanting", 1, 225, 225, 245 } },  -- Scroll of Strength II
  [3013] = { { "Enchanting", 1, 140, 140, 160 } },  -- Scroll of Protection
  [4605] = { { "Enchanting", 1, 140, 140, 160 } },  -- Red-speckled Mushroom
  [6217] = { { "Enchanting", 1, 5, 5, 7 } },  -- Copper Rod
  [6338] = { { "Enchanting", 1, 130, 130, 150 } },  -- Silver Rod
  [9224] = { { "Enchanting", 1, 250, 250, 270 } },  -- Potion of Demon Slaying
  [10308] = { { "Enchanting", 1, 320, 320, 340 } },  -- Scroll of Intellect IV
  [10939] = { { "Enchanting", 5, 100, 140, 160 } },  -- Greater Magic Essence
  [10978] = { { "Enchanting", 9, 120, 140, 160 } },  -- Small Glimmering Shard
  [10998] = { { "Enchanting", 11, 130, 175, 195 } },  -- Lesser Astral Essence
  [11084] = { { "Enchanting", 11, 140, 175, 195 } },  -- Large Glimmering Shard
  [11128] = { { "Enchanting", 1, 175, 175, 195 } },  -- Golden Rod
  [11135] = { { "Enchanting", 7, 195, 225, 245 } },  -- Greater Mystic Essence
  [11138] = { { "Enchanting", 3, 175, 195, 215 } },  -- Small Glowing Shard
  [11144] = { { "Enchanting", 1, 220, 220, 240 } },  -- Truesilver Rod
  [11174] = { { "Enchanting", 16, 140, 260, 280 } },  -- Lesser Nether Essence
  [11177] = { { "Enchanting", 8, 200, 285, 305 } },  -- Small Radiant Shard
  [12735] = { { "Enchanting", 1, 320, 320, 340 } },  -- Frayed Abomination Stitching
  [13180] = { { "Enchanting", 1, 320, 320, 340 } },  -- Stratholme Holy Water
  [13458] = { { "Enchanting", 1, 320, 320, 340 } },  -- Greater Nature Protection Potion
  [16202] = { { "Enchanting", 9, 250, 310, 317 } },  -- Lesser Eternal Essence
  [16206] = { { "Enchanting", 1, 310, 310, 330 } },  -- Arcanite Rod
  [17034] = { { "Enchanting", 2, 30, 160, 170 } },  -- Maple Seed
  [17035] = { { "Enchanting", 1, 210, 210, 220 } },  -- Stranglethorn Seed
  [247786] = { { "Enchanting", 3, 5, 20, 22 } },  -- Mote of Magic
  [273128] = { { "Enchanting", 1, 300, 300, 0 } },  -- Maker's Spark

  -- Enchanting, Engineering
  [16204] = { { "Enchanting", 45, 285, 320, 340 }, { "Engineering", 2, 320, 320, 330 } },  -- Illusion Dust
  [234005] = { { "Enchanting", 1, 320, 320, 340 }, { "Engineering", 4, 315, 315, 322 } },
  [249425] = { { "Enchanting", 1, 225, 225, 245 }, { "Engineering", 1, 130, 130, 142 } },  -- Bauxite

  -- Enchanting, Engineering, First Aid, Leatherworking, Tailoring
  [14047] = { { "Enchanting", 1, 320, 320, 340 }, { "Engineering", 16, 250, 320, 330 }, { "First Aid", 4, 260, 300, 330 }, { "Leatherworking", 7, 265, 305, 315 }, { "Tailoring", 1, 210, 210, 212 } },  -- Runecloth

  -- Enchanting, Engineering, Leatherworking
  [8151] = { { "Enchanting", 1, 310, 310, 320 }, { "Engineering", 2, 225, 230, 240 }, { "Leatherworking", 4, 210, 240, 250 } },  -- Flask of Mojo

  -- Enchanting, Engineering, Leatherworking, Tailoring
  [15407] = { { "Enchanting", 1, 270, 270, 290 }, { "Engineering", 1, 320, 320, 330 }, { "Leatherworking", 137, 250, 320, 330 }, { "Tailoring", 5, 315, 320, 330 } },  -- Cured Rugged Hide
  [234007] = { { "Enchanting", 2, 320, 320, 340 }, { "Engineering", 3, 315, 315, 322 }, { "Leatherworking", 5, 320, 320, 330 }, { "Tailoring", 4, 320, 320, 330 } },
  [249409] = { { "Enchanting", 12, 140, 320, 340 }, { "Engineering", 2, 25, 125, 135 }, { "Leatherworking", 9, 80, 150, 160 }, { "Tailoring", 108, 75, 270, 285 } },  -- Cerulean Dye

  -- Enchanting, Engineering, Tailoring
  [11175] = { { "Enchanting", 18, 225, 280, 290 }, { "Engineering", 1, 230, 230, 232 }, { "Tailoring", 12, 210, 220, 235 } },  -- Greater Nether Essence
  [14344] = { { "Enchanting", 53, 295, 320, 340 }, { "Engineering", 1, 320, 320, 330 }, { "Tailoring", 6, 270, 315, 330 } },  -- Large Brilliant Shard
  [234008] = { { "Enchanting", 4, 320, 320, 340 }, { "Engineering", 1, 315, 315, 322 }, { "Tailoring", 1, 315, 315, 322 } },
  [249430] = { { "Enchanting", 12, 225, 320, 340 }, { "Engineering", 1, 145, 145, 147 }, { "Tailoring", 52, 145, 270, 285 } },  -- Magenta Dye
  [249431] = { { "Enchanting", 3, 320, 320, 340 }, { "Engineering", 3, 240, 320, 330 }, { "Tailoring", 9, 230, 315, 330 } },  -- Viridian Dye

  -- Enchanting, Leatherworking
  [7392] = { { "Enchanting", 1, 220, 220, 240 }, { "Leatherworking", 2, 170, 185, 195 } },  -- Green Whelp Scale
  [8152] = { { "Enchanting", 1, 310, 310, 320 }, { "Leatherworking", 2, 230, 235, 245 } },  -- Flask of Big Mojo
  [18512] = { { "Enchanting", 1, 320, 320, 340 }, { "Leatherworking", 11, 310, 320, 330 } },  -- Larval Acid

  -- Enchanting, Leatherworking, Tailoring
  [11137] = { { "Enchanting", 26, 140, 245, 265 }, { "Leatherworking", 2, 205, 205, 215 }, { "Tailoring", 2, 205, 225, 230 } },  -- Vision Dust

  -- Enchanting, Mining
  [2772] = { { "Enchanting", 1, 170, 170, 190 }, { "Mining", 2, 130, 140, 0 } },  -- Iron Ore
  [2775] = { { "Enchanting", 1, 140, 140, 160 }, { "Mining", 1, 100, 100, 112 } },  -- Silver Ore

  -- Enchanting, Tailoring
  [6048] = { { "Enchanting", 1, 160, 160, 180 }, { "Tailoring", 2, 135, 140, 155 } },  -- Shadow Protection Potion
  [11082] = { { "Enchanting", 10, 140, 175, 195 }, { "Tailoring", 18, 125, 145, 160 } },  -- Greater Astral Essence
  [11134] = { { "Enchanting", 11, 165, 225, 245 }, { "Tailoring", 4, 185, 185, 187 } },  -- Lesser Mystic Essence
  [11178] = { { "Enchanting", 19, 225, 280, 290 }, { "Tailoring", 8, 145, 250, 265 } },  -- Large Radiant Shard
  [14343] = { { "Enchanting", 9, 285, 310, 330 }, { "Tailoring", 6, 290, 295, 297 } },  -- Small Brilliant Shard

  -- Engineering
  [2570] = { { "Engineering", 2, 25, 55, 60 } },  -- Linen Cloak
  [3030] = { { "Engineering", 1, 210, 210, 230 } },  -- Razor Arrow
  [4357] = { { "Engineering", 5, 25, 60, 75 } },  -- Rough Blasting Powder
  [4359] = { { "Engineering", 12, 20, 145, 157 } },  -- Handful of Copper Bolts
  [4360] = { { "Engineering", 1, 90, 90, 92 } },  -- Rough Copper Bomb
  [4361] = { { "Engineering", 4, 20, 130, 142 } },  -- Copper Tube
  [4363] = { { "Engineering", 7, 65, 180, 182 } },  -- Copper Modulator
  [4364] = { { "Engineering", 15, 85, 150, 170 } },  -- Coarse Blasting Powder
  [4368] = { { "Engineering", 1, 175, 175, 187 } },  -- Flying Tiger Goggles
  [4371] = { { "Engineering", 13, 135, 210, 220 } },  -- Bronze Tube
  [4375] = { { "Engineering", 16, 125, 200, 212 } },  -- Whirring Bronze Gizmo
  [4377] = { { "Engineering", 23, 125, 215, 230 } },  -- Heavy Blasting Powder
  [4380] = { { "Engineering", 1, 170, 170, 172 } },  -- Big Bronze Bomb
  [4382] = { { "Engineering", 10, 135, 255, 257 } },  -- Bronze Framework
  [4385] = { { "Engineering", 1, 225, 225, 235 } },  -- Green Tinted Goggles
  [4387] = { { "Engineering", 9, 150, 280, 282 } },  -- Iron Strut
  [4389] = { { "Engineering", 18, 150, 245, 255 } },  -- Gyrochronatom
  [4394] = { { "Engineering", 2, 205, 235, 237 } },  -- Big Iron Bomb
  [4397] = { { "Engineering", 1, 245, 245, 255 } },  -- Gnomish Cloaking Device
  [4399] = { { "Engineering", 2, 80, 130, 142 } },  -- Wooden Stock
  [4400] = { { "Engineering", 5, 145, 240, 250 } },  -- Heavy Stock
  [4404] = { { "Engineering", 8, 105, 215, 230 } },  -- Silver Contact
  [4405] = { { "Engineering", 1, 65, 65, 72 } },  -- Crude Scope
  [4407] = { { "Engineering", 1, 230, 230, 250 } },  -- Accurate Scope
  [4611] = { { "Engineering", 1, 185, 185, 205 } },  -- Blue Pearl
  [5507] = { { "Engineering", 4, 205, 205, 207 } },  -- Ornate Spyglass
  [6530] = { { "Engineering", 1, 150, 150, 160 } },  -- Nightcrawlers
  [7191] = { { "Engineering", 8, 160, 320, 330 } },  -- Fused Wiring
  [7387] = { { "Engineering", 1, 235, 235, 245 } },  -- Dusky Belt
  [9060] = { { "Engineering", 6, 245, 295, 305 } },  -- Inlaid Mithril Cylinder
  [10026] = { { "Engineering", 2, 245, 245, 255 } },  -- Black Mageweave Boots
  [10500] = { { "Engineering", 2, 230, 310, 320 } },  -- Fire Goggles
  [10502] = { { "Engineering", 1, 290, 290, 300 } },  -- Spellpower Goggles Xtreme
  [10505] = { { "Engineering", 27, 1, 245, 265 } },  -- Solid Blasting Powder
  [10507] = { { "Engineering", 1, 235, 235, 255 } },  -- Solid Dynamite
  [10518] = { { "Engineering", 1, 270, 270, 280 } },  -- Parachute Cloak
  [10543] = { { "Engineering", 1, 265, 265, 275 } },  -- Goblin Construction Helmet
  [10546] = { { "Engineering", 2, 280, 295, 305 } },  -- Deadly Scope
  [10558] = { { "Engineering", 20, 150, 320, 330 } },  -- Gold Power Core
  [10559] = { { "Engineering", 15, 205, 280, 290 } },  -- Mithril Tube
  [10560] = { { "Engineering", 27, 205, 305, 0 } },  -- Unstable Trigger
  [10561] = { { "Engineering", 22, 215, 305, 305 } },  -- Mithril Casing
  [10576] = { { "Engineering", 1, 320, 320, 330 } },  -- Mithril Mechanical Dragonling
  [10577] = { { "Engineering", 1, 1, 1, 0 } },  -- Goblin Mortar
  [10586] = { { "Engineering", 1, 285, 285, 295 } },  -- The Big One
  [10588] = { { "Engineering", 1, 305, 305, 0 } },  -- Goblin Rocket Helmet
  [10592] = { { "Engineering", 1, 240, 240, 250 } },  -- Catseye Draught
  [10647] = { { "Engineering", 2, 205, 205, 0 } },  -- Engineer's Ink
  [10648] = { { "Engineering", 2, 205, 205, 0 } },  -- Blank Parchment
  [15992] = { { "Engineering", 17, 250, 320, 330 } },  -- Dense Blasting Powder
  [15994] = { { "Engineering", 22, 250, 320, 330 } },  -- Thorium Widget
  [16000] = { { "Engineering", 11, 250, 320, 330 } },  -- Thorium Tube
  [16005] = { { "Engineering", 1, 290, 290, 292 } },  -- Dark Iron Bomb
  [16006] = { { "Engineering", 15, 280, 320, 330 } },  -- Delicate Arcanite Converter
  [16583] = { { "Engineering", 1, 205, 205, 210 } },  -- Demonic Figurine
  [17056] = { { "Engineering", 1, 310, 310, 315 } },  -- Light Feather
  [17202] = { { "Engineering", 1, 190, 190, 210 } },  -- Snowball
  [18168] = { { "Engineering", 1, 315, 315, 322 } },  -- Force Reactive Disk
  [18631] = { { "Engineering", 12, 280, 320, 330 } },  -- Truesilver Transformer
  [18984] = { { "Engineering", 1, 320, 320, 330 } },  -- Dimensional Ripper - Everlook
  [18986] = { { "Engineering", 1, 320, 320, 330 } },  -- Ultrasafe Transporter: Gadgetzan
  [20868] = { { "Engineering", 1, 320, 320, 330 } },  -- Lambent Idol
  [20870] = { { "Engineering", 1, 320, 320, 330 } },  -- Jasper Idol
  [20881] = { { "Engineering", 1, 320, 320, 330 } },  -- Idol of Strife
  [213381] = { { "Engineering", 1, 200, 200, 210 } },  -- Pile of Tarnished Gears
  [220689] = { { "Engineering", 3, 250, 250, 255 } },
  [238737] = { { "Engineering", 6, 270, 280, 282 } },
  [238786] = { { "Engineering", 1, 320, 320, 330 } },
  [238787] = { { "Engineering", 1, 320, 320, 330 } },
  [238788] = { { "Engineering", 1, 320, 320, 330 } },
  [255007] = { { "Engineering", 1, 65, 65, 72 } },  -- Golem Isospring
  [260784] = { { "Engineering", 1, 55, 55, 60 } },  -- SAF-T Tabs
  [260794] = { { "Engineering", 2, 115, 130, 155 } },  -- EZ-Thro Wrap
  [260796] = { { "Engineering", 2, 145, 150, 170 } },  -- No Slip SAF-T Padding
  [260799] = { { "Engineering", 1, 200, 200, 212 } },  -- SAF-T Bell
  [260801] = { { "Engineering", 3, 200, 210, 220 } },  -- EZ-Thro Fireproof Fuse
  [260804] = { { "Engineering", 3, 215, 270, 280 } },  -- SAF-T Casing
  [260808] = { { "Engineering", 1, 240, 240, 260 } },  -- EZ-Thro Tru-Trigger
  [260813] = { { "Engineering", 5, 275, 320, 330 } },  -- SAF-T Tube
  [260815] = { { "Engineering", 6, 285, 320, 330 } },  -- EZ-Thro Shell
  [260823] = { { "Engineering", 1, 320, 320, 330 } },  -- Dimensional Transporter - Mt. Hyjal
  [273129] = { { "Engineering", 1, 300, 300, 0 } },  -- Essence of Anarchy

  -- Engineering, First Aid, Tailoring
  [2592] = { { "Engineering", 10, 100, 200, 212 }, { "First Aid", 3, 80, 120, 155 }, { "Tailoring", 1, 70, 70, 77 } },  -- Wool Cloth
  [4306] = { { "Engineering", 7, 160, 200, 220 }, { "First Aid", 2, 150, 180, 210 }, { "Tailoring", 1, 110, 110, 115 } },  -- Silk Cloth

  -- Engineering, Leatherworking, Tailoring
  [4305] = { { "Engineering", 1, 180, 180, 182 }, { "Leatherworking", 4, 155, 190, 200 }, { "Tailoring", 100, 105, 220, 235 } },  -- Bolt of Silk Cloth
  [4337] = { { "Engineering", 1, 230, 230, 240 }, { "Leatherworking", 1, 195, 195, 205 }, { "Tailoring", 6, 150, 195, 210 } },  -- Thick Spider's Silk
  [14227] = { { "Engineering", 2, 285, 305, 315 }, { "Leatherworking", 21, 310, 320, 330 }, { "Tailoring", 53, 230, 320, 330 } },  -- Ironweb Spider Silk
  [234009] = { { "Engineering", 1, 315, 315, 322 }, { "Leatherworking", 3, 320, 320, 330 }, { "Tailoring", 7, 315, 320, 330 } },
  [249428] = { { "Engineering", 1, 190, 190, 192 }, { "Leatherworking", 43, 195, 270, 280 }, { "Tailoring", 2, 315, 315, 330 } },  -- Pristine Hide
  [249429] = { { "Engineering", 2, 285, 320, 330 }, { "Leatherworking", 12, 235, 320, 330 }, { "Tailoring", 2, 315, 315, 330 } },  -- Pristine Scale

  -- Engineering, Mining
  [249426] = { { "Engineering", 1, 320, 320, 330 }, { "Mining", 1, 275, 275, 0 } },  -- Pitchblende

  -- Engineering, Tailoring
  [814] = { { "Engineering", 2, 150, 160, 180 }, { "Tailoring", 1, 125, 125, 137 } },  -- Flask of Oil
  [2996] = { { "Engineering", 1, 130, 130, 142 }, { "Tailoring", 45, 20, 80, 97 } },  -- Bolt of Linen Cloth
  [4339] = { { "Engineering", 2, 205, 245, 255 }, { "Tailoring", 81, 145, 225, 235 } },  -- Bolt of Mageweave
  [10285] = { { "Engineering", 2, 230, 245, 255 }, { "Tailoring", 6, 190, 215, 230 } },  -- Shadow Silk

  -- First Aid
  [1251] = { { "First Aid", 1, 20, 20, 0 } },  -- Linen Bandage
  [2594] = { { "First Aid", 1, 295, 295, 325 } },  -- Flagon of Dwarven Honeymead
  [2686] = { { "First Aid", 1, 160, 160, 190 } },  -- Thunder Ale
  [2723] = { { "First Aid", 1, 90, 90, 125 } },  -- Bottle of Dalaran Noir
  [6452] = { { "First Aid", 1, 140, 140, 0 } },  -- Anti-Venom
  [6453] = { { "First Aid", 1, 300, 300, 0 } },  -- Strong Anti-Venom
  [8544] = { { "First Aid", 1, 140, 140, 0 } },  -- Mageweave Bandage
  [14530] = { { "First Aid", 2, 300, 315, 327 } },  -- Heavy Runecloth Bandage
  [19441] = { { "First Aid", 1, 300, 300, 330 } },  -- Huge Venom Sac
  [23567] = { { "First Aid", 1, 300, 300, 330 } },  -- DEPRECATED ITEM
  [255645] = { { "First Aid", 1, 230, 230, 260 } },  -- Swollen Venom Sac

  -- First Aid, Leatherworking, Tailoring
  [2321] = { { "First Aid", 1, 120, 120, 155 }, { "Leatherworking", 86, 70, 190, 200 }, { "Tailoring", 108, 55, 190, 205 } },  -- Fine Thread
  [4291] = { { "First Aid", 1, 220, 220, 250 }, { "Leatherworking", 41, 180, 230, 240 }, { "Tailoring", 47, 125, 220, 235 } },  -- Silken Thread
  [8343] = { { "First Aid", 1, 280, 280, 310 }, { "Leatherworking", 59, 185, 270, 280 }, { "Tailoring", 94, 145, 250, 265 } },  -- Heavy Silken Thread

  -- Leatherworking
  [783] = { { "Leatherworking", 1, 50, 50, 60 } },  -- Light Hide
  [2312] = { { "Leatherworking", 1, 140, 140, 152 } },  -- Fine Leather Gloves
  [2313] = { { "Leatherworking", 2, 95, 95, 102 } },  -- Medium Armor Kit
  [2454] = { { "Leatherworking", 1, 95, 95, 102 } },  -- Elixir of Minor Strength
  [2457] = { { "Leatherworking", 1, 120, 120, 132 } },  -- Elixir of Minor Agility
  [2458] = { { "Leatherworking", 9, 80, 150, 160 } },  -- Elixir of Minor Fortitude
  [2934] = { { "Leatherworking", 1, 20, 20, 30 } },  -- Ruined Leather Scraps
  [3385] = { { "Leatherworking", 1, 155, 155, 165 } },  -- Lesser Mana Potion
  [3389] = { { "Leatherworking", 1, 135, 135, 147 } },  -- Elixir of Lesser Defense
  [3390] = { { "Leatherworking", 1, 140, 140, 152 } },  -- Elixir of Lesser Agility
  [4096] = { { "Leatherworking", 1, 195, 195, 205 } },  -- Coarse Gorilla Hair
  [4231] = { { "Leatherworking", 49, 40, 120, 132 } },  -- Cured Light Hide
  [4232] = { { "Leatherworking", 1, 90, 90, 97 } },  -- Medium Hide
  [4233] = { { "Leatherworking", 45, 125, 205, 0 } },  -- Cured Medium Hide
  [4235] = { { "Leatherworking", 1, 135, 135, 140 } },  -- Heavy Hide
  [4236] = { { "Leatherworking", 49, 155, 245, 255 } },  -- Cured Heavy Hide
  [4243] = { { "Leatherworking", 1, 100, 100, 112 } },  -- Fine Leather Tunic
  [4246] = { { "Leatherworking", 1, 125, 125, 137 } },  -- Fine Leather Belt
  [4253] = { { "Leatherworking", 2, 160, 160, 172 } },  -- Toughened Leather Gloves
  [4265] = { { "Leatherworking", 2, 155, 155, 165 } },  -- Heavy Armor Kit
  [4289] = { { "Leatherworking", 3, 50, 135, 140 } },  -- Salt
  [4461] = { { "Leatherworking", 3, 155, 160, 170 } },  -- Raptor Hide
  [5082] = { { "Leatherworking", 1, 65, 65, 80 } },  -- Thin Kodo Leather
  [5116] = { { "Leatherworking", 1, 125, 125, 137 } },  -- Long Tail Feather
  [5373] = { { "Leatherworking", 1, 140, 140, 152 } },  -- Lucky Charm
  [5633] = { { "Leatherworking", 1, 195, 195, 205 } },  -- Great Rage Potion
  [5784] = { { "Leatherworking", 3, 40, 100, 115 } },  -- Slimy Murloc Scale
  [5785] = { { "Leatherworking", 3, 165, 225, 230 } },  -- Thick Murloc Scale
  [6470] = { { "Leatherworking", 12, 80, 150, 160 } },  -- Deviate Scale
  [6471] = { { "Leatherworking", 2, 105, 115, 127 } },  -- Perfect Deviate Scale
  [6662] = { { "Leatherworking", 1, 155, 155, 165 } },  -- Elixir of Giant Growth
  [7286] = { { "Leatherworking", 3, 40, 100, 112 } },  -- Black Whelp Scale
  [7287] = { { "Leatherworking", 1, 120, 120, 132 } },  -- Red Whelp Scale
  [7428] = { { "Leatherworking", 2, 185, 195, 205 } },  -- Shadowcat Hide
  [8154] = { { "Leatherworking", 7, 215, 245, 255 } },  -- Scorpid Scale
  [8165] = { { "Leatherworking", 2, 220, 250, 260 } },  -- Worn Dragonscale
  [8167] = { { "Leatherworking", 7, 200, 230, 240 } },  -- Turtle Scale
  [8169] = { { "Leatherworking", 1, 175, 175, 0 } },  -- Thick Hide
  [8171] = { { "Leatherworking", 1, 225, 225, 230 } },  -- Rugged Hide
  [8172] = { { "Leatherworking", 45, 200, 270, 280 } },  -- Cured Thick Hide
  [8173] = { { "Leatherworking", 2, 205, 205, 215 } },  -- Thick Armor Kit
  [8368] = { { "Leatherworking", 1, 220, 220, 230 } },  -- Thick Wolfhide
  [8949] = { { "Leatherworking", 1, 220, 220, 230 } },  -- Elixir of Agility
  [8951] = { { "Leatherworking", 1, 220, 220, 230 } },  -- Elixir of Defense
  [9206] = { { "Leatherworking", 1, 235, 235, 245 } },  -- Elixir of Greater Strength
  [12607] = { { "Leatherworking", 3, 320, 320, 330 } },  -- Brilliant Chromatic Scale
  [13444] = { { "Leatherworking", 1, 235, 235, 245 } },  -- Major Mana Potion
  [14044] = { { "Leatherworking", 1, 320, 320, 330 } },  -- Cindercloth Cloak
  [15408] = { { "Leatherworking", 46, 250, 320, 330 } },  -- Heavy Scorpid Scale
  [15409] = { { "Leatherworking", 1, 225, 225, 230 } },  -- Refined Deeprock Salt
  [15412] = { { "Leatherworking", 8, 250, 300, 310 } },  -- Green Dragonscale
  [15414] = { { "Leatherworking", 4, 310, 320, 330 } },  -- Red Dragonscale
  [15415] = { { "Leatherworking", 8, 280, 320, 330 } },  -- Blue Dragonscale
  [15416] = { { "Leatherworking", 13, 250, 320, 330 } },  -- Black Dragonscale
  [15419] = { { "Leatherworking", 3, 270, 320, 330 } },  -- Warbear Leather
  [15420] = { { "Leatherworking", 5, 265, 320, 330 } },  -- Ironfeather
  [15422] = { { "Leatherworking", 4, 270, 310, 320 } },  -- Frostsaber Leather
  [15423] = { { "Leatherworking", 5, 250, 285, 295 } },  -- Chimera Leather
  [15564] = { { "Leatherworking", 2, 235, 235, 245 } },  -- Rugged Armor Kit
  [18251] = { { "Leatherworking", 2, 320, 320, 330 } },  -- Core Armor Kit
  [19767] = { { "Leatherworking", 3, 320, 320, 330 } },  -- Primal Bat Leather
  [19768] = { { "Leatherworking", 2, 320, 320, 330 } },  -- Primal Tiger Leather
  [20498] = { { "Leatherworking", 12, 305, 320, 330 } },  -- Silithid Chitin
  [20500] = { { "Leatherworking", 6, 305, 320, 330 } },  -- Light Silithid Carapace
  [20501] = { { "Leatherworking", 6, 310, 320, 330 } },  -- Heavy Silithid Carapace
  [213370] = { { "Leatherworking", 1, 200, 200, 210 } },  -- Irradiated Leather Scraps
  [248824] = { { "Leatherworking", 8, 235, 310, 317 } },  -- Fel Hide
  [248825] = { { "Leatherworking", 52, 310, 320, 330 } },  -- Fel Leather
  [273130] = { { "Leatherworking", 1, 300, 300, 0 } },  -- Undeath Engine

  -- Leatherworking, Tailoring
  [2324] = { { "Leatherworking", 5, 70, 185, 187 }, { "Tailoring", 12, 35, 200, 205 } },  -- Bleach
  [2325] = { { "Leatherworking", 11, 160, 300, 310 }, { "Tailoring", 3, 170, 200, 205 } },  -- Black Dye
  [2455] = { { "Leatherworking", 1, 95, 95, 102 }, { "Tailoring", 1, 55, 55, 0 } },  -- Minor Mana Potion
  [2997] = { { "Leatherworking", 3, 1, 145, 157 }, { "Tailoring", 48, 75, 250, 252 } },  -- Bolt of Woolen Cloth
  [3182] = { { "Leatherworking", 9, 135, 270, 280 }, { "Tailoring", 13, 80, 145, 160 } },  -- Spider's Silk
  [3383] = { { "Leatherworking", 1, 125, 125, 137 }, { "Tailoring", 1, 125, 125, 140 } },  -- Elixir of Wisdom
  [3827] = { { "Leatherworking", 1, 205, 205, 215 }, { "Tailoring", 4, 170, 220, 235 } },  -- Mana Potion
  [4340] = { { "Leatherworking", 8, 40, 140, 152 }, { "Tailoring", 7, 90, 170, 185 } },  -- Gray Dye
  [6260] = { { "Leatherworking", 12, 185, 300, 310 }, { "Tailoring", 16, 50, 185, 190 } },  -- Blue Dye
  [6261] = { { "Leatherworking", 8, 255, 300, 310 }, { "Tailoring", 2, 185, 190, 195 } },  -- Orange Dye
  [14048] = { { "Leatherworking", 2, 285, 285, 290 }, { "Tailoring", 175, 220, 320, 330 } },  -- Bolt of Runecloth
  [14256] = { { "Leatherworking", 1, 300, 300, 310 }, { "Tailoring", 17, 245, 315, 330 } },  -- Felcloth
  [14341] = { { "Leatherworking", 194, 1, 320, 330 }, { "Tailoring", 116, 220, 320, 335 } },  -- Rune Thread
  [14342] = { { "Leatherworking", 2, 310, 320, 330 }, { "Tailoring", 59, 270, 320, 335 } },  -- Mooncloth
  [18240] = { { "Leatherworking", 2, 285, 285, 290 }, { "Tailoring", 1, 285, 285, 290 } },  -- Ogre Tannin
  [213372] = { { "Leatherworking", 3, 225, 225, 230 }, { "Tailoring", 1, 225, 225, 230 } },

  -- Mining
  [2770] = { { "Mining", 1, 25, 25, 47 } },  -- Copper Ore
  [2771] = { { "Mining", 1, 50, 50, 62 } },  -- Tin Ore
  [2776] = { { "Mining", 1, 170, 170, 177 } },  -- Gold Ore
  [3576] = { { "Mining", 1, 65, 65, 90 } },  -- Tin Bar
  [3857] = { { "Mining", 2, 165, 275, 0 } },  -- Coal
  [7911] = { { "Mining", 1, 230, 230, 0 } },  -- Truesilver Ore
  [11370] = { { "Mining", 1, 230, 230, 0 } },  -- Dark Iron Ore
  [18562] = { { "Mining", 1, 310, 310, 315 } },  -- Elementium Ore
  [248815] = { { "Mining", 1, 300, 300, 307 } },  -- Heavy Thorium Ore

  -- Tailoring
  [118] = { { "Tailoring", 1, 55, 55, 0 } },  -- Minor Healing Potion
  [929] = { { "Tailoring", 1, 145, 145, 160 } },  -- Healing Potion
  [2604] = { { "Tailoring", 31, 50, 300, 302 } },  -- Red Dye
  [4320] = { { "Tailoring", 1, 150, 150, 167 } },  -- Spidersilk Boots
  [4341] = { { "Tailoring", 1, 120, 120, 125 } },  -- Yellow Dye
  [4589] = { { "Tailoring", 1, 215, 215, 230 } },  -- Long Elegant Feather
  [7072] = { { "Tailoring", 1, 175, 175, 190 } },  -- Naga Scale
  [9210] = { { "Tailoring", 12, 230, 315, 330 } },  -- Ghost Dye
  [10290] = { { "Tailoring", 1, 200, 200, 205 } },  -- Pink Dye
  [11040] = { { "Tailoring", 1, 245, 245, 260 } },  -- Morrowgrain
  [213378] = { { "Tailoring", 1, 200, 200, 210 } },  -- Unstable Microfilament
  [273131] = { { "Tailoring", 1, 300, 300, 0 } },  -- Bottled Screams
}
