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
      return "green", "Item level " .. compareLevel
    end
    return "green", "Well below your level"
  end

  if isItemLevel then
    return "yellow", "Item level " .. compareLevel
  end
  return "yellow", "Below your level"
end

local function evaluateCompletedQuestStarter(item)
  if not (item.startsQuestID and item.startsQuestCompleted) then return nil end
  return "green", "Quest already completed"
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

local RULES = {
  evaluateLevelGap,
  evaluateCompletedQuestStarter,
  evaluateVendorReagent,
  evaluateClassReagent,
}

--- Evaluate a single item and return a verdict.
function Bagwise.Verdict.Evaluate(item, state)
  for i = 1, #RULES do
    local verdict, reason = RULES[i](item, state)
    if verdict then return verdict, reason end
  end
  return nil, nil
end
