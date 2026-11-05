-- Bagwise: bag scanner
-- Iterates bag slots, gathers item info via WoW API, feeds each item
-- to the verdict engine, and caches results.
--
-- TODO (Forever migration):
--   - Adopt `local addonName, ns = ...` namespace pattern across all files
--     instead of the `Bagwise = Bagwise or {}` global.
--   - GetItemInfo() may move to C_Item.GetItemInfo() returning a table
--     (fields accessed by name, not positional destructuring).
--   - Verify GetProfessions() / GetProfessionInfo() work on Forever;
--     if so, the Skills-tab fallback path can be removed.

Bagwise = Bagwise or {}
Bagwise.Scanner = {}

-- Verdict cache: keyed by itemID
-- Stores { verdict = "green"/"yellow"/nil, reason = "..." }
-- Survives across scans, cleared when player state changes.
local verdictCache = {}

-- Slot results: keyed by "bag:slot" string
-- Rebuilt on every scan. The overlay reads this.
local slotResults = {}

-- English profession name -> skillLine ID.
-- Only needs the professions referenced by VendorReagents, but we include
-- all Classic Era professions so the detected set is complete for future
-- rules.  Gathering professions have no vendor reagents today but detecting
-- them is free and harmless.
-- TODO: add locale tables keyed by GetLocale() if non-English support is needed.
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

--- Gather the player's profession skillLine IDs.
-- Returns a set-style table { [skillLineID] = true, ... } for fast lookup.
--
-- Strategy:
--   1. Try GetProfessions() + GetProfessionInfo() first (works in some
--      Classic builds, returns locale-independent skillLine IDs).
--   2. Fall back to GetNumSkillLines() + GetSkillLineInfo() which iterates
--      the Skills tab.  This returns profession NAMES (locale-dependent),
--      so we map them via PROFESSION_NAME_TO_SKILL_LINE.
-- @return table  Set of skillLine IDs the player currently has
local function gatherProfessionSkillLines()
  local skillLines = {}

  -- Path A: Modern profession API
  local prof1, prof2, _, fishing, cooking = GetProfessions()
  if prof1 or prof2 or fishing or cooking then
    local slots = { prof1, prof2, fishing, cooking }
    for _, index in ipairs(slots) do
      if index then
        local name, texture, rank, maxRank, numSpells, spellOffset, skillLine =
            GetProfessionInfo(index)
        if skillLine then
          skillLines[skillLine] = true
        end
      end
    end
    return skillLines
  end

  -- Path B: Fallback for Classic Era OR Forever
  local getNum = GetNumSkillLines or (C_SkillInfo and C_SkillInfo.GetNumSkillLines)
  local getInfo = GetSkillLineInfo or (C_SkillInfo and C_SkillInfo.GetSkillLineInfo)

  if getNum and getInfo then
    for i = 1, getNum() do
      local name, isHeader = getInfo(i)
      if not isHeader and name then
        local id = PROFESSION_NAME_TO_SKILL_LINE[name]
        if id then
          skillLines[id] = true
        end
      end
    end
  end

  return skillLines
end

--- Gather player state once per scan.
-- @return table  State table matching what Verdict.Evaluate expects
local function getPlayerState()
  local class, playerClass = UnitClass("player")
  local race = UnitRace("player")
  local level = UnitLevel("player")

  local skillLines = gatherProfessionSkillLines()

  -- Build reverse lookup: English profession name -> true.
  -- Used by verdict rules that match against ReagentProfessions data
  -- (which is keyed by English name, not skillLine ID).
  local professionNames = {}
  for name, id in pairs(PROFESSION_NAME_TO_SKILL_LINE) do
    if skillLines[id] then
      professionNames[name] = true
    end
  end

  -- Expose for tooltip sorting (player's professions listed first)
  Bagwise.Scanner.professionNames = professionNames

  return {
    class = class,
    playerClass = playerClass,
    race = race,
    level = level,
    professionSkillLines = skillLines,
    professionNames = professionNames,
  }
end

-- Use the namespaced version if available, fall back to the old global
---@diagnostic disable-next-line: deprecated
local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
-- IsUsableItem is intentionally NOT used here. It checks right-click
-- usability (potions, scrolls), not whether your class can equip gear.
-- It returns false for ALL equipment regardless of class.

-- Allowlist of equipSlot values that represent actual wearable gear.
-- Classic Era returns INVTYPE_NON_EQUIP_IGNORE for everything else
-- (quest items, crafting mats, consumables, ammo, etc.), so a blocklist
-- approach misses too many edge cases.
local EQUIP_SLOTS = {
  INVTYPE_HEAD           = true,
  INVTYPE_NECK           = true,
  INVTYPE_SHOULDER       = true,
  INVTYPE_BODY           = true, -- shirt
  INVTYPE_CHEST          = true,
  INVTYPE_ROBE           = true, -- also chest
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
  INVTYPE_HOLDABLE       = true, -- off-hand frill
  INVTYPE_RANGED         = true,
  INVTYPE_RANGEDRIGHT    = true,
  INVTYPE_THROWN         = true,
  INVTYPE_TABARD         = true,
}

--- Gather item data from the WoW API for one bag slot.
-- @param bag   number  Bag index (0-4)
-- @param slot  number  Slot index (1-N)
-- @return table|nil  Item table matching what Verdict.Evaluate expects, or nil
local function gatherItem(bag, slot)
  local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
  if not containerInfo then return nil end

  local itemID = containerInfo.itemID

  local name, _, quality, itemLevel, reqLevel, _, _, _,
  equipSlot, _, _, classID, _, bindType = getItemInfo(itemID)

  -- Item not cached by the client yet, skip for now
  if not name then return nil end

  local isEquippable = equipSlot and EQUIP_SLOTS[equipSlot] or false

  -- Quest data: does this item start a quest? Is that quest done?
  local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
  local startsQuestID = questInfo and questInfo.questID or nil
  local startsQuestCompleted = false
  local startsQuestName = nil

  if startsQuestID then
    startsQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(startsQuestID)
    startsQuestName = C_QuestLog.GetQuestInfo(startsQuestID)
  end

  -- Quest-objective data: does this item appear in the QuestItems table?
  -- If so, check which of those quests are completed.
  local questItemQuestIDs = Bagwise.Data.QuestItems
      and Bagwise.Data.QuestItems[itemID]
  local allQuestObjectivesCompleted = nil

  if questItemQuestIDs and #questItemQuestIDs > 0 then
    allQuestObjectivesCompleted = true
    for _, qid in ipairs(questItemQuestIDs) do
      if not C_QuestLog.IsQuestFlaggedCompleted(qid) then
        allQuestObjectivesCompleted = false
        break
      end
    end
  end

  return {
    id = itemID,
    name = name,
    quality = quality,
    itemLevel = itemLevel,
    reqLevel = reqLevel,
    isBound = containerInfo.isBound,
    isEquippable = isEquippable,
    classID = classID,
    bindType = bindType,
    startsQuestID = startsQuestID,
    startsQuestCompleted = startsQuestCompleted,
    startsQuestName = startsQuestName,
    questItemQuestIDs = questItemQuestIDs,
    allQuestObjectivesCompleted = allQuestObjectivesCompleted,
  }
end

--- Build a short string key from the player's profession set.
-- Sorted so the key is stable regardless of iteration order.
-- @param state table  Player state from getPlayerState()
-- @return string      e.g. "164,171" for Blacksmithing+Alchemy
local function professionCacheKey(state)
  local ids = {}
  if state.professionSkillLines then
    for id in pairs(state.professionSkillLines) do
      ids[#ids + 1] = id
    end
    table.sort(ids)
  end
  return table.concat(ids, ",")
end

--- Scan all bag slots, evaluate verdicts, store results.
function Bagwise.Scanner.ScanAll()
  local state = getPlayerState()
  local profKey = professionCacheKey(state)

  -- Clear slot results, we're rebuilding from scratch
  slotResults = {}

  for bag = 0, 4 do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local key = bag .. ":" .. slot
      local item = gatherItem(bag, slot)

      if item then
        -- Cache key includes bound state because the same itemID
        -- can be both soulbound and not (e.g. a BoE you equipped
        -- plus another you bought). Verdicts depend on isBound.
        -- Profession key included because vendor reagent verdicts
        -- depend on which professions the player currently has.
        local cacheKey = item.id
            .. ":" .. tostring(item.isBound)
            .. ":" .. tostring(item.classID)
            .. ":" .. tostring(item.startsQuestCompleted)
            .. ":" .. tostring(item.allQuestObjectivesCompleted)
            .. ":" .. profKey
        local cached = verdictCache[cacheKey]
        if cached then
          slotResults[key] = cached
        else
          local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)
          local result = { verdict = verdict, reason = reason, detail = detail }
          verdictCache[cacheKey] = result
          slotResults[key] = result
        end
      else
        slotResults[key] = nil
      end
    end
  end
end

--- Get the verdict for a specific bag slot.
-- @param bag   number  Bag index (0-4)
-- @param slot  number  Slot index (1-N)
-- @return table|nil  { verdict = "green"/"yellow"/nil, reason = "..." }
function Bagwise.Scanner.GetResult(bag, slot)
  return slotResults[bag .. ":" .. slot]
end

--- Clear the verdict cache. Call when player state changes.
function Bagwise.Scanner.ClearCache()
  verdictCache = {}
end
