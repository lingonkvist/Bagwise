-- Bagwise: vendor reagent dataset
-- Cheap vendor-bought crafting materials (vials, thread, flux, dyes, spices, etc.)
-- Maps item IDs to the professions that use them, via locale-independent skillLine IDs.
-- Hand-curated; edit freely.

Bagwise                     = Bagwise or {}
Bagwise.Data                = Bagwise.Data or {}

local SKILL_ALCHEMY         = 171
local SKILL_BLACKSMITHING   = 164
local SKILL_COOKING         = 185
local SKILL_ENCHANTING      = 333
local SKILL_ENGINEERING     = 202
local SKILL_LEATHERWORKING  = 165
local SKILL_TAILORING       = 197

Bagwise.Data.VendorReagents = {
  -- Vials (Alchemy, some shared with Enchanting)
  [3371]  = { SKILL_ALCHEMY, excludeClasses = { ROGUE = true } },                   -- Empty Vial
  [3372]  = { SKILL_ALCHEMY, SKILL_ENCHANTING, excludeClasses = { ROGUE = true } }, -- Leaded Vial
  [8925]  = { SKILL_ALCHEMY, SKILL_ENCHANTING, excludeClasses = { ROGUE = true } }, -- Crystal Vial
  [18256] = { SKILL_ALCHEMY, SKILL_ENCHANTING },                                    -- Imbued Vial

  -- Thread (Tailoring + Leatherworking)
  [2320]  = { SKILL_TAILORING, SKILL_LEATHERWORKING }, -- Coarse Thread
  [2321]  = { SKILL_TAILORING, SKILL_LEATHERWORKING }, -- Fine Thread
  [4291]  = { SKILL_TAILORING, SKILL_LEATHERWORKING }, -- Silken Thread
  [8343]  = { SKILL_TAILORING, SKILL_LEATHERWORKING }, -- Heavy Silken Thread
  [14341] = { SKILL_TAILORING, SKILL_LEATHERWORKING }, -- Rune Thread

  -- Dyes and bleach
  -- Sources: warcraft.wiki.gg per-dye recipe lists, cross-checked by profession.
  -- Pink Dye omitted: only Shadowlands recipes use it, not available in Classic Era.
  [2324]  = { SKILL_TAILORING, SKILL_LEATHERWORKING },                                         -- Bleach
  [2604]  = { SKILL_TAILORING, SKILL_LEATHERWORKING },                                         -- Red Dye
  [2325]  = { SKILL_TAILORING, SKILL_LEATHERWORKING },                                         -- Black Dye
  [4341]  = { SKILL_TAILORING },                                                               -- Yellow Dye
  [4340]  = { SKILL_TAILORING, SKILL_LEATHERWORKING },                                         -- Gray Dye
  [4342]  = { SKILL_TAILORING, SKILL_LEATHERWORKING, SKILL_ALCHEMY, SKILL_ENGINEERING },       -- Purple Dye
  [6260]  = { SKILL_TAILORING },                                                               -- Blue Dye
  [2605]  = { SKILL_TAILORING, SKILL_LEATHERWORKING, SKILL_BLACKSMITHING, SKILL_ENGINEERING }, -- Green Dye
  [6261]  = { SKILL_TAILORING },                                                               -- Orange Dye

  -- Salt (Tailoring, Leatherworking, Cooking)
  [4289]  = { SKILL_TAILORING, SKILL_LEATHERWORKING, SKILL_COOKING }, -- Salt

  -- Flux (Blacksmithing)
  [2880]  = { SKILL_BLACKSMITHING }, -- Weak Flux
  [3466]  = { SKILL_BLACKSMITHING }, -- Strong Flux
  [10505] = { SKILL_BLACKSMITHING }, -- Durable Flux

  -- Coal (Blacksmithing, Engineering)
  [3857]  = { SKILL_BLACKSMITHING, SKILL_ENGINEERING }, -- Coal

  -- Stocks (Engineering)
  [4399]  = { SKILL_ENGINEERING }, -- Wooden Stock
  [4400]  = { SKILL_ENGINEERING }, -- Heavy Stock

  -- Spices and ingredients (Cooking)
  [2678]  = { SKILL_COOKING }, -- Mild Spices
  [2692]  = { SKILL_COOKING }, -- Hot Spices
  [3713]  = { SKILL_COOKING }, -- Soothing Spices
  [1179]  = { SKILL_COOKING }, -- Ice Cold Milk
}
