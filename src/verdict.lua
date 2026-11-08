-- Bagwise: verdict engine
-- Pure functions only: no WoW API calls, testable outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

local LEVEL_GAP_YELLOW = 10
local LEVEL_GAP_GREEN = 20
local RARE_QUALITY = 3

-- Marks a green the player can sell instead of destroy (the tooltip says
-- "Safe to vendor"). Only set when the item actually has a vendor price.
Bagwise.Verdict.VENDOR_TAG = "vendor"
local VENDOR_TAG = Bagwise.Verdict.VENDOR_TAG

local function vendorTagFor(item)
  if (item.sellPrice or 0) > 0 then return VENDOR_TAG end
  return nil
end

local function needsAnyOf(lookupTable, keys)
  for i = 1, #keys do
    if lookupTable[keys[i]] then return true end
  end
  return false
end

local function professionNamesOf(profEntries)
  local names = {}
  for i = 1, #profEntries do
    names[#names + 1] = profEntries[i][1]
  end
  return names
end

local function evaluateLevelGap(item, state)
  if not (item.isBound and item.isEquippable) then return nil end

  -- A low required level does not make gear outdated by itself: plenty of
  -- items with a modest requirement have an item level a character at this
  -- level still wears. If its item level is at or above the player's level,
  -- it is not "low level".
  if item.itemLevel and item.itemLevel >= state.level then return nil end

  local compareLevel, isItemLevel
  if item.reqLevel and item.reqLevel > 0 then
    compareLevel = item.reqLevel
  elseif item.itemLevel and item.itemLevel > 0 then
    compareLevel = item.itemLevel
    isItemLevel = true
  else
    return nil
  end

  local gap = state.level - compareLevel
  if gap < LEVEL_GAP_YELLOW then return nil end

  -- Rare and better gear can sell well or be disenchanted, so it is a hint
  -- at most, never a "safe".
  local canBeGreen = (item.quality or 0) < RARE_QUALITY

  if gap >= LEVEL_GAP_GREEN and canBeGreen then
    if isItemLevel then
      return "green", "Very low item level (" .. compareLevel .. ")", nil, vendorTagFor(item)
    end
    return "green", "Very low level gear", nil, vendorTagFor(item)
  end
  if gap >= LEVEL_GAP_GREEN then
    if isItemLevel then
      return "yellow", "Very low item level (" .. compareLevel .. ")"
    end
    return "yellow", "Very low level gear"
  end

  if isItemLevel then
    return "yellow", "Low item level (" .. compareLevel .. ")"
  end
  return "yellow", "Low level gear"
end

-- QuestInfo field indices (data/quest_items.lua is generated).
local QUEST_INFO_LEVEL = 1
local QUEST_INFO_NAME  = 3

-- QuestInfo[questID][QUEST_INFO_FACTION] is "A" or "H" when only that
-- faction can take the quest; absent means open to both.
local QUEST_INFO_FACTION = 4
local FACTION_CODES = { Alliance = "A", Horde = "H" }

--- Drop the quests the player's faction can never take.
-- Alliance and Horde versions of the same quest have separate IDs, so an
-- item used by both would otherwise wait forever on the other side's quest.
-- Quests with no faction data are kept: when unsure, the item stays needed.
-- @param questIDs table        quest IDs from QuestItems
-- @param faction  string|nil   "Alliance" or "Horde"; anything else keeps all
-- @return table  the quests that can matter to this player (may be empty)
function Bagwise.Verdict.QuestsForFaction(questIDs, faction)
  local code = FACTION_CODES[faction]
  if not code then return questIDs end

  local info = Bagwise.Data.QuestInfo
  local kept = {}
  for i = 1, #questIDs do
    local questInfo = info and info[questIDs[i]]
    local questFaction = questInfo and questInfo[QUEST_INFO_FACTION]
    if questFaction == nil or questFaction == code then
      kept[#kept + 1] = questIDs[i]
    end
  end
  return kept
end

--- Build "[level] name" from QuestInfo, using runtimeName as override.
-- The WoW API only returns quest names for quests still in the active log,
-- so completed quests need the static name from QuestInfo.
local function questLabel(questID, runtimeName)
  local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]
  local name = runtimeName
  if not name and info then
    name = info[QUEST_INFO_NAME]
  end
  if not name then return nil end
  if info and info[QUEST_INFO_LEVEL] then
    return "[" .. info[QUEST_INFO_LEVEL] .. "] " .. name
  end
  return name
end

-- Only the game's own quest items are certain to be finished with. Anything
-- else a quest happens to ask for (tools, mats, gear) may have other uses.
local QUEST_CLASS_ID = 12
local function isOrdinaryItem(item)
  return item.classID ~= nil and item.classID ~= QUEST_CLASS_ID
end

local function evaluateCompletedQuestStarter(item)
  if not (item.startsQuestID and item.startsQuestCompleted) then return nil end
  local label = questLabel(item.startsQuestID, item.startsQuestName)
  if isOrdinaryItem(item) then return nil end
  return "green", "Quest completed", label
end

local function evaluateVendorReagent(item, state)
  local vendorData = Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id]
  if not vendorData then return nil end

  -- "You have no use for this" needs the full list of your professions. When
  -- the scanner could not read it all, say nothing.
  if state.professionsKnown == false then return nil end

  if vendorData.excludeClasses
      and state.playerClass
      and vendorData.excludeClasses[state.playerClass] then
    return nil
  end

  local profEntries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id]

  if profEntries and state.professionNames then
    local names = professionNamesOf(profEntries)
    if needsAnyOf(state.professionNames, names) then return nil end
    if #names >= 3 then
      return "green", "Vendor reagent (" .. #names .. " professions)"
    end
    return "green", "Vendor reagent (" .. table.concat(names, ", ") .. ")"
  end

  if not state.professionSkillLines then return nil end
  if needsAnyOf(state.professionSkillLines, vendorData) then return nil end
  return "green", "Vendor reagent"
end

local function evaluateClassReagent(item, state)
  local classReagent = Bagwise.Data.ClassReagents
      and Bagwise.Data.ClassReagents[item.id]
  if not classReagent or not state.playerClass then return nil end
  if classReagent.classes[state.playerClass] then return nil end

  local classList = {}
  for class in pairs(classReagent.classes) do
    classList[#classList + 1] = class:sub(1, 1) .. class:sub(2):lower()
  end
  table.sort(classList)

  local source = classReagent.verdict == "green" and "vendor" or "world drop"
  local classString = table.concat(classList, ", ")

  return classReagent.verdict, classString .. " only (" .. source .. ")"
end

local function evaluateQuestObjective(item)
  if not item.questItemQuestIDs then return nil end
  if not item.allQuestObjectivesCompleted then return nil end
  if isOrdinaryItem(item) then return nil end
  local count = #item.questItemQuestIDs
  if count > 1 then
    return "green", "All " .. count .. " quests completed"
  end
  local label = questLabel(item.questItemQuestIDs[1], nil)
  return "green", "Quest completed", label
end

local TRADE_GOODS_CLASS_ID = 7

-- Vendor value that counts as "worth a trip to the vendor", in copper. It
-- grows with the player's level because the same coins mean less later on:
-- 30c at level 1, about 1s25c at 20, 3s25c at 60. Nothing here is set by
-- the player.
local WORTH_KEEPING_BASE_COPPER = 25
local WORTH_KEEPING_PER_LEVEL = 5
local POOR_QUALITY = 0

-- Where a gray stops being plainly safe to delete and starts being worth some
-- silver, in copper, by player level. A little higher than the general
-- threshold above: 50c at level 2, about 1s75c at 20, 4s55c at 60.
local GRAY_WORTH_BASE_COPPER = 35
local GRAY_WORTH_PER_LEVEL = 7

local function grayThreshold(state)
  return GRAY_WORTH_BASE_COPPER + GRAY_WORTH_PER_LEVEL * (state.level or 1)
end

-- Marks a verdict as "gray item" so the scanner can thin them out.
Bagwise.Verdict.POOR_QUALITY_TAG = "poorQuality"
local POOR_QUALITY_TAG = Bagwise.Verdict.POOR_QUALITY_TAG

local function valueThreshold(state)
  return WORTH_KEEPING_BASE_COPPER + WORTH_KEEPING_PER_LEVEL * (state.level or 1)
end

--- What the whole stack sells for to a vendor, in copper.
local function stackValue(item)
  return (item.sellPrice or 0) * (item.count or 1)
end

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000

--- "1g 20s 5c" for an amount in copper (zero parts left out).
function Bagwise.Verdict.FormatMoney(copper)
  copper = math.floor(copper or 0)
  local gold = math.floor(copper / COPPER_PER_GOLD)
  local silver = math.floor((copper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
  local rest = copper % COPPER_PER_SILVER
  local parts = {}
  if gold > 0 then parts[#parts + 1] = gold .. "g" end
  if silver > 0 then parts[#parts + 1] = silver .. "s" end
  if rest > 0 or #parts == 0 then parts[#parts + 1] = rest .. "c" end
  return table.concat(parts, " ")
end

--- The reason line for a gray. When other grays were silenced, the one that
-- keeps its dot says it is the cheapest, so the single dot makes sense.
-- @param value     number   what the stack sells for, in copper
-- @param isCheapestOfSeveral boolean
-- @param isWorthSilver boolean  true for a gray above the safe-to-delete value:
--        the dot is yellow and the reason warns that it is worth something
function Bagwise.Verdict.PoorQualityReason(value, isCheapestOfSeveral, isWorthSilver)
  if isWorthSilver then
    local label = isCheapestOfSeveral and "Cheapest gray" or "Gray"
    return label .. ", but worth " .. Bagwise.Verdict.FormatMoney(value)
  end
  local label = isCheapestOfSeveral and "Cheapest gray" or "Poor quality"
  if value == 0 then return label .. ", no vendor value" end
  return label .. ", sells for " .. Bagwise.Verdict.FormatMoney(value)
end

-- Gray items. Cheap ones are safe to delete. One that sells for real money gets
-- a yellow warning instead, and the scanner keeps only the cheapest gray's dot,
-- so that warning only shows when no cheaper gray is green. Anything a quest or
-- recipe still lists is left alone.
local function evaluatePoorQuality(item, state)
  if item.quality ~= POOR_QUALITY then return nil end
  if item.questItemQuestIDs then return nil end
  if Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id] then
    return nil
  end

  local value = stackValue(item)
  if value >= grayThreshold(state) then
    return "yellow", Bagwise.Verdict.PoorQualityReason(value, false, true), nil, POOR_QUALITY_TAG
  end
  return "green", Bagwise.Verdict.PoorQualityReason(value, false), nil, POOR_QUALITY_TAG
end

--- Keep only the cheapest few poor-quality greens, so a bag full of grays
-- doesn't turn into a wall of dots. Deleting one lights up the next.
-- @param entries table  list of { key, bag, slot, value } for every gray with a dot
-- @param maxDots number how many may stay green
-- @return table  set of keys that should go silent
function Bagwise.Verdict.SilenceAllButCheapest(entries, maxDots)
  local sorted = {}
  for i = 1, #entries do sorted[i] = entries[i] end
  table.sort(sorted, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
  end)

  local silenced = {}
  for i = maxDots + 1, #sorted do silenced[sorted[i].key] = true end
  return silenced
end

local function evaluateNoRecipeUse(item, state)
  -- Epic 5.1: Trade Goods that no recipe uses for any profession.
  -- Gear, consumables, and quest items are excluded by the classID gate.
  if item.classID ~= TRADE_GOODS_CLASS_ID then return nil end

  -- Already used in at least one recipe -- nothing to flag
  if Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id] then
    return nil
  end

  -- Quest objective or starter -- leave for quest rules / tooltip context
  if Bagwise.Data.QuestItems
      and Bagwise.Data.QuestItems[item.id] then
    return nil
  end

  -- Vendor reagent -- already handled by evaluateVendorReagent
  if Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id] then
    return nil
  end

  -- Class reagent -- already handled by evaluateClassReagent
  if Bagwise.Data.ClassReagents
      and Bagwise.Data.ClassReagents[item.id] then
    return nil
  end

  -- Unused is not the same as worthless: something that sells well might be
  -- worth the vendor trip, so it only gets a yellow.
  local value = stackValue(item)
  if value >= valueThreshold(state) then
    return "yellow", "Not used for any quest or recipe, sells for "
        .. Bagwise.Verdict.FormatMoney(value)
  end

  return "green", "Not used for any quest or recipe"
end

-- Recipes and the reagents behind them. A recipe's item subclass says which
-- profession it teaches. Nothing here says "delete": a recipe for a profession
-- you do not have may sell, and one you cannot use yet is only taking up room,
-- so the advice is to bank it or sell it, and the player decides.
local RECIPE_CLASS_ID = 9
local RECIPE_PROFESSIONS = {
  [1] = "Leatherworking", [2] = "Tailoring", [3] = "Engineering",
  [4] = "Blacksmithing", [5] = "Cooking", [6] = "Alchemy",
  [7] = "First Aid", [8] = "Enchanting", [9] = "Fishing",
}
-- How many skill points short before something counts as "a while away".
local BANK_SKILL_GAP = 50

local function evaluateRecipe(item, state)
  if item.classID ~= RECIPE_CLASS_ID then return nil end
  local profession = RECIPE_PROFESSIONS[item.subClassID]
  if not profession then return nil end
  if state.professionsKnown == false or not state.professionNames then return nil end

  if not state.professionNames[profession] then
    return "yellow", "You don't have this profession. May sell on AH"
  end

  local rank = state.professionRanks and state.professionRanks[profession]
  if rank and item.requiredSkill and item.requiredSkill > rank + BANK_SKILL_GAP then
    return "yellow", "Bank it, needs " .. profession .. " " .. item.requiredSkill
  end
  return nil
end

-- A reagent the player's own professions will not use for a good while: every
-- profession of theirs that uses it starts needing it far above their skill.
local function evaluateDistantReagent(item, state)
  local entries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id]
  if not entries or state.professionsKnown == false then return nil end
  if not (state.professionNames and state.professionRanks) then return nil end

  local nearest -- the smallest gap to a profession of theirs
  for i = 1, #entries do
    local name, minSkill = entries[i][1], entries[i][3]
    if state.professionNames[name] then
      local rank = state.professionRanks[name]
      if not rank or not minSkill then return nil end
      if minSkill <= rank + BANK_SKILL_GAP then return nil end
      if not nearest or minSkill - rank < nearest.gap then
        nearest = { gap = minSkill - rank, name = name, minSkill = minSkill, rank = rank }
      end
    end
  end
  if not nearest then return nil end
  return "yellow", "Bank it, used from " .. nearest.name .. " " .. nearest.minSkill
end

-- Something you right-click to open (clams, bags of loot). It takes a slot now
-- and what is inside often stacks, so opening it usually frees room.
local function evaluateOpenable(item)
  if not item.hasLoot then return nil end
  return "yellow", "Open it, the contents may stack"
end

-- Food, drink, potions and bandages made for a much lower level than yours
-- restore little now. Only a hint: you may want the stack for an alt.
local CONSUMABLE_CLASS = 0
local OUTLEVELED_SUBCLASSES = { [1] = true, [5] = true, [7] = true } -- potion, food and drink, bandage
local OUTLEVELED_GAP = 20

local function evaluateOutleveledConsumable(item, state)
  if item.classID ~= CONSUMABLE_CLASS or not OUTLEVELED_SUBCLASSES[item.subClassID] then return nil end
  if item.questItemQuestIDs or item.startsQuestID then return nil end
  local reqLevel = item.reqLevel
  if not reqLevel or reqLevel <= 0 then return nil end
  if reqLevel + OUTLEVELED_GAP > (state.level or 1) then return nil end
  return "yellow", "Outleveled, a level " .. reqLevel .. " item"
end

local COMMON_QUALITY = 1
local UNCOMMON_QUALITY = 2
local ARMOR_CLASS_ID = 4

-- Armor and shield types by class. A number is the player level at which the
-- class learns to wear that type (warriors and paladins get plate at 40,
-- hunters and shamans get mail at 40); true means from the start; absent
-- means never.
local ARMOR_SUBCLASS_NAMES = {
  [2] = "leather", [3] = "mail", [4] = "plate",
}
local OTHER_SUBCLASS_PHRASES = {
  [6] = "shields", [7] = "librams", [8] = "idols", [9] = "totems",
}
local CAN_USE_SUBCLASSES = {
  WARRIOR = { [1] = true, [2] = true, [3] = true, [4] = 40, [6] = true },
  PALADIN = { [1] = true, [2] = true, [3] = true, [4] = 40, [6] = true, [7] = true },
  HUNTER  = { [1] = true, [2] = true, [3] = 40 },
  ROGUE   = { [1] = true, [2] = true },
  PRIEST  = { [1] = true },
  MAGE    = { [1] = true },
  WARLOCK = { [1] = true },
  SHAMAN  = { [1] = true, [2] = true, [3] = 40, [6] = true, [9] = true },
  DRUID   = { [1] = true, [2] = true, [8] = true },
}

local CLASS_PLURALS = {
  WARRIOR = "Warriors", PALADIN = "Paladins", HUNTER = "Hunters",
  ROGUE = "Rogues", PRIEST = "Priests", MAGE = "Mages",
  WARLOCK = "Warlocks", SHAMAN = "Shamans", DRUID = "Druids",
}

local function unwearableWording(subClassID)
  if ARMOR_SUBCLASS_NAMES[subClassID] then
    return "wear " .. ARMOR_SUBCLASS_NAMES[subClassID]
  end
  if OTHER_SUBCLASS_PHRASES[subClassID] then
    return "use " .. OTHER_SUBCLASS_PHRASES[subClassID]
  end
  return nil
end

-- White armor the player can't wear right now: the class never can, or
-- can't until a later level. Unknown classes (anything not listed above)
-- get no verdict rather than a guess. The reason stays short; the game's own
-- tooltip already shows the sell price for anyone who would rather vendor it.
local function evaluateUnwearableWhite(item, state)
  if item.quality ~= COMMON_QUALITY then return nil end
  if not item.isEquippable or item.classID ~= ARMOR_CLASS_ID then return nil end

  local usable = CAN_USE_SUBCLASSES[state.playerClass]
  if not usable or not item.subClassID then return nil end

  local wording = unwearableWording(item.subClassID)
  if not wording then return nil end

  local rule = usable[item.subClassID]
  if rule == true then return nil end

  local reason = CLASS_PLURALS[state.playerClass] .. " can't " .. wording
  if rule ~= nil then
    if (state.level or 1) >= rule then return nil end
    reason = reason .. " until " .. rule
  end
  return "green", reason, nil, vendorTagFor(item)
end

-- A white piece of armor you have already out-geared. Every slot it could go
-- in must hold something better than white and at least as high in item
-- level, so the white can never be the upgrade. An empty slot, or an item the
-- game hasn't loaded yet, means no verdict (the scanner leaves
-- equippedInSlots nil then). Weapons are left out: which weapon you want
-- depends on proficiencies and class, not just level.
local function evaluateOutgearedWhite(item, state)
  if item.quality ~= COMMON_QUALITY then return nil end
  if not item.isEquippable or item.classID ~= ARMOR_CLASS_ID then return nil end

  local equipped = item.equippedInSlots
  if not equipped or #equipped == 0 then return nil end

  -- A white has no stats, only armor, so any green or better in the same slot
  -- beats it whatever the item levels. The exception is gear you cannot wear
  -- yet: that is something to grow into, not something you have outgrown.
  if item.reqLevel and state and state.level and item.reqLevel > state.level then
    return nil
  end

  for i = 1, #equipped do
    if equipped[i].quality < UNCOMMON_QUALITY then return nil end
  end

  return "green", "Worse than your equipped gear", nil, vendorTagFor(item)
end

-- Every rule, in priority order (first one with a verdict wins). A rule only
-- proposes; Safety can drop a green. `overrides` names the protections a rule
-- is allowed to override, and each one is a decision, not a convenience:
--   quest rules may override "quest_item": finishing the quests lifts it
--   the reagent rules decide by profession or class themselves
-- Anything not listed is protected from that rule.
local RULES = {
  { name = "unwearable_white",   evaluate = evaluateUnwearableWhite },
  { name = "level_gap",          evaluate = evaluateLevelGap },
  { name = "outgeared_white",    evaluate = evaluateOutgearedWhite },
  { name = "quest_starter_done", evaluate = evaluateCompletedQuestStarter,
    overrides = { quest_item = true } },
  { name = "quest_objective_done", evaluate = evaluateQuestObjective,
    overrides = { quest_item = true } },
  { name = "vendor_reagent",     evaluate = evaluateVendorReagent,
    overrides = { vendor_reagent = true, recipe_reagent = true } },
  { name = "class_reagent",      evaluate = evaluateClassReagent,
    overrides = { spell_reagent = true, recipe_reagent = true } },
  { name = "openable",           evaluate = evaluateOpenable },
  { name = "recipe",             evaluate = evaluateRecipe },
  { name = "distant_reagent",    evaluate = evaluateDistantReagent },
  { name = "poor_quality",       evaluate = evaluatePoorQuality },
  { name = "no_recipe_use",      evaluate = evaluateNoRecipeUse },
}

--- Run one rule and apply the safety check to a green.
-- @return verdict, reason, detail, tag, blockedBy
local function runRule(rule, item, state)
  local verdict, reason, detail, tag = rule.evaluate(item, state)
  if verdict == "green" then
    local blocker = Bagwise.Safety.Blocker(item, rule.overrides)
    if blocker then return verdict, reason, detail, tag, blocker end
  end
  return verdict, reason, detail, tag, nil
end

local CONSUMABLE_CLASS_ID = 0

--- Evaluate a single item and return a verdict.
-- Player overrides win over every rule: a kept item is always silent,
-- a flagged item is always yellow.
-- Consumables (food, drink, potions, bandages) never get a rule verdict: they
-- are used up in play, so "you don't need this" is never safe to say. Some
-- are also vendor reagents (water, milk) and would otherwise read as green.
-- Scrolls may earn their own rules later.
function Bagwise.Verdict.Evaluate(item, state)
  if item.isKept then return nil, nil, nil end
  if item.isFlagged then return "yellow", "Flagged by you", nil end
  if item.classID == CONSUMABLE_CLASS_ID then
    local verdict, reason = evaluateOpenable(item)
    if verdict then return verdict, reason, nil end
    verdict, reason = evaluateOutleveledConsumable(item, state)
    return verdict, reason, nil
  end

  -- A blocked green is dropped and the next rule gets its turn. A yellow is
  -- only a hint, so it waits: a later rule's green (already vetted by Safety)
  -- beats it. Otherwise the first yellow stands.
  local hint
  for i = 1, #RULES do
    local verdict, reason, detail, tag, blockedBy = runRule(RULES[i], item, state)
    if verdict == "green" and not blockedBy then return verdict, reason, detail, tag end
    if verdict == "yellow" and not hint then
      hint = { verdict, reason, detail, tag }
    end
  end
  if hint then return hint[1], hint[2], hint[3], hint[4] end
  return nil, nil, nil
end

--- Every rule that had something to say about an item, including greens that
-- Safety dropped. For /bagwise why and for tests.
-- @return table list of { rule, verdict, reason, blockedBy }
function Bagwise.Verdict.Trace(item, state)
  local trace = {}
  for i = 1, #RULES do
    local verdict, reason, _, _, blockedBy = runRule(RULES[i], item, state)
    if verdict then
      trace[#trace + 1] = { rule = RULES[i].name, verdict = verdict,
                            reason = reason, blockedBy = blockedBy }
    end
  end
  return trace
end

--- Names of the rules, in priority order.
function Bagwise.Verdict.RuleNames()
  local names = {}
  for i = 1, #RULES do names[i] = RULES[i].name end
  return names
end
