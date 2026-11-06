-- Bagwise: verdict engine
-- Pure functions only: no WoW API calls, testable outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

local LEVEL_GAP_YELLOW = 10
local LEVEL_GAP_GREEN = 20

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

  if gap >= LEVEL_GAP_GREEN then
    if isItemLevel then
      return "green", "Very low item level (" .. compareLevel .. ")"
    end
    return "green", "Very low level gear"
  end

  if isItemLevel then
    return "yellow", "Low item level (" .. compareLevel .. ")"
  end
  return "yellow", "Low level gear"
end

-- QuestInfo field indices (data/quest_items.lua is generated).
local QUEST_INFO_LEVEL = 1
local QUEST_INFO_NAME  = 3

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

local function evaluateCompletedQuestStarter(item)
  if not (item.startsQuestID and item.startsQuestCompleted) then return nil end
  local label = questLabel(item.startsQuestID, item.startsQuestName)
  return "green", "Quest completed", label
end

local function evaluateVendorReagent(item, state)
  local vendorData = Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id]
  if not vendorData then return nil end

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
  local count = #item.questItemQuestIDs
  if count > 1 then
    return "green", "All " .. count .. " quests completed"
  end
  local label = questLabel(item.questItemQuestIDs[1], nil)
  return "green", "Quest completed", label
end

local TRADE_GOODS_CLASS_ID = 7

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

  return "green", "Not used for any quest or recipe"
end

local RULES = {
  evaluateLevelGap,
  evaluateCompletedQuestStarter,
  evaluateQuestObjective,
  evaluateVendorReagent,
  evaluateClassReagent,
  evaluateNoRecipeUse,
}

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
  if item.classID == CONSUMABLE_CLASS_ID then return nil, nil, nil end

  for i = 1, #RULES do
    local verdict, reason, detail = RULES[i](item, state)
    if verdict then return verdict, reason, detail end
  end
  return nil, nil, nil
end
