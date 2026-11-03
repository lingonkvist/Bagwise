-- Bagwise: bag scanner
-- Iterates bag slots, gathers item info via WoW API, feeds each item
-- to the verdict engine, and caches results.

Bagwise = Bagwise or {}
Bagwise.Scanner = {}

local verdictCache = {}
local slotResults = {}

local PROFESSION_NAME_TO_SKILL_LINE = {
  ["Alchemy"]        = 171,
  ["Blacksmithing"]  = 164,
  ["Cooking"]        = 185,
  ["Enchanting"]     = 333,
  ["Engineering"]    = 202,
  ["First Aid"]      = 129,
  ["Fishing"]        = 356,
  ["Herbalism"]      = 182,
  ["Leatherworking"] = 165,
  ["Mining"]         = 186,
  ["Skinning"]       = 393,
  ["Tailoring"]      = 197,
}

local EQUIP_SLOTS = {
  INVTYPE_HEAD           = true,
  INVTYPE_NECK           = true,
  INVTYPE_SHOULDER       = true,
  INVTYPE_BODY           = true,
  INVTYPE_CHEST          = true,
  INVTYPE_ROBE           = true,
  INVTYPE_WAIST          = true,
  INVTYPE_LEGS           = true,
  INVTYPE_FEET           = true,
  INVTYPE_WRIST          = true,
  INVTYPE_HAND           = true,
  INVTYPE_FINGER         = true,
  INVTYPE_TRINKET        = true,
  INVTYPE_CLOAK          = true,
  INVTYPE_WEAPON         = true,
  INVTYPE_SHIELD         = true,
  INVTYPE_2HWEAPON       = true,
  INVTYPE_WEAPONMAINHAND = true,
  INVTYPE_WEAPONOFFHAND  = true,
  INVTYPE_HOLDABLE       = true,
  INVTYPE_RANGED         = true,
  INVTYPE_RANGEDRIGHT    = true,
  INVTYPE_THROWN         = true,
  INVTYPE_TABARD         = true,
}

local ItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local function skillLinesFromModernApi()
  if not GetProfessions then return nil end
  local prof1, prof2, _, fishing, cooking = GetProfessions()
  if not (prof1 or prof2 or fishing or cooking) then return nil end

  local skillLines = {}
  local indices = { prof1, prof2, fishing, cooking }
  for i = 1, #indices do
    local index = indices[i]
    if index then
      local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
      if skillLine then skillLines[skillLine] = true end
    end
  end
  return skillLines
end

local function skillLinesFromSkillsTab()
  local skillLines = {}
  if not GetNumSkillLines then return skillLines end
  for i = 1, GetNumSkillLines() do
    local name, isHeader = GetSkillLineInfo(i)
    local id = not isHeader and name and PROFESSION_NAME_TO_SKILL_LINE[name]
    if id then skillLines[id] = true end
  end
  return skillLines
end

local function gatherProfessionSkillLines()
  return skillLinesFromModernApi() or skillLinesFromSkillsTab()
end

local function professionNamesFrom(skillLines)
  local names = {}
  for name, id in pairs(PROFESSION_NAME_TO_SKILL_LINE) do
    if skillLines[id] then names[name] = true end
  end
  return names
end

local function getPlayerState()
  local class, playerClass = UnitClass("player")
  local race = UnitRace("player")
  local level = UnitLevel("player")
  local skillLines = gatherProfessionSkillLines()
  local professionNames = professionNamesFrom(skillLines)

  return {
    class = class,
    playerClass = playerClass,
    race = race,
    level = level,
    professionSkillLines = skillLines,
    professionNames = professionNames,
  }
end

local function readQuestStarter(bag, slot)
  local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
  local questID = questInfo and questInfo.questID
  if not questID then return nil end
  return {
    startsQuestID = questID,
    startsQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID),
    startsQuestName = C_QuestLog.GetQuestInfo(questID),
  }
end

local function gatherItem(bag, slot)
  local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
  if not containerInfo then return nil end

  local itemID = containerInfo.itemID
  local name, _, quality, itemLevel, reqLevel, _, _, _,
  equipSlot, _, _, classID, _, bindType = ItemInfo(itemID)

  if not name then return nil end

  local quest = readQuestStarter(bag, slot) or {}

  return {
    id = itemID,
    name = name,
    quality = quality,
    itemLevel = itemLevel,
    reqLevel = reqLevel,
    isBound = containerInfo.isBound,
    isEquippable = equipSlot and EQUIP_SLOTS[equipSlot] or false,
    classID = classID,
    bindType = bindType,
    startsQuestID = quest.startsQuestID,
    startsQuestCompleted = quest.startsQuestCompleted or false,
    startsQuestName = quest.startsQuestName,
  }
end

local function professionCacheKey(state)
  local ids = {}
  for id in pairs(state.professionSkillLines) do
    ids[#ids + 1] = id
  end
  table.sort(ids)
  return table.concat(ids, ",")
end

local function cacheKeyFor(item, state, profKey)
  return item.id
      .. ":" .. tostring(item.isBound)
      .. ":" .. tostring(item.classID)
      .. ":" .. tostring(item.startsQuestCompleted)
      .. ":" .. tostring(state.level)
      .. ":" .. tostring(state.playerClass)
      .. ":" .. profKey
end

local function evaluateWithCache(item, state, profKey)
  local key = cacheKeyFor(item, state, profKey)
  local cached = verdictCache[key]
  if cached then return cached end

  local verdict, reason = Bagwise.Verdict.Evaluate(item, state)
  local result = {
    verdict = verdict,
    reason = reason,
  }
  verdictCache[key] = result
  return result
end

local function scanSlot(bag, slot, state, profKey)
  local item = gatherItem(bag, slot)
  if not item then return nil end
  return evaluateWithCache(item, state, profKey)
end

--- Scan all bag slots, evaluate verdicts, store results.
function Bagwise.Scanner.ScanAll()
  local state = getPlayerState()
  Bagwise.Scanner.professionNames = state.professionNames
  local profKey = professionCacheKey(state)
  slotResults = {}

  for bag = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      slotResults[bag .. ":" .. slot] = scanSlot(bag, slot, state, profKey)
    end
  end
end

--- Get the verdict for a specific bag slot.
function Bagwise.Scanner.GetResult(bag, slot)
  return slotResults[bag .. ":" .. slot]
end

--- Clear the verdict cache. Call when player state changes.
function Bagwise.Scanner.ClearCache()
  verdictCache = {}
end
