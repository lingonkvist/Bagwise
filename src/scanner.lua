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
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil

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
    faction = faction,
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

--- Build the item table Verdict.Evaluate expects.
-- @param itemID        number
-- @param isBound       boolean  Soulbound right now (false for loot)
-- @param questInfo     table|nil  C_Container quest info for the slot
-- @param state         table    Player state from getPlayerState()
-- @return table|nil  nil when the client hasn't cached the item yet
local function buildItem(itemID, isBound, questInfo, state)
  local name, _, quality, itemLevel, reqLevel, _, _, _,
  equipSlot, _, _, classID, _, bindType = getItemInfo(itemID)

  -- Item not cached by the client yet, skip for now
  if not name then return nil end

  local isEquippable = equipSlot and EQUIP_SLOTS[equipSlot] or false

  -- Quest data: does this item start a quest? Is that quest done?
  local startsQuestID = questInfo and questInfo.questID or nil
  local startsQuestCompleted = false
  local startsQuestName = nil

  if startsQuestID then
    startsQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(startsQuestID)
    startsQuestName = C_QuestLog.GetQuestInfo(startsQuestID)
  end

  -- Quest-objective data: does this item appear in the QuestItems table?
  -- If so, check which of those quests are completed.
  -- Only quests this player's faction can take count: the other faction's
  -- versions of a quest can never be completed from here.
  local questItemQuestIDs = Bagwise.Data.QuestItems
      and Bagwise.Data.QuestItems[itemID]
  if questItemQuestIDs then
    questItemQuestIDs = Bagwise.Verdict.QuestsForFaction(questItemQuestIDs, state.faction)
    if #questItemQuestIDs == 0 then questItemQuestIDs = nil end
  end
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
    isBound = isBound,
    isEquippable = isEquippable,
    classID = classID,
    bindType = bindType,
    startsQuestID = startsQuestID,
    startsQuestCompleted = startsQuestCompleted,
    startsQuestName = startsQuestName,
    questItemQuestIDs = questItemQuestIDs,
    allQuestObjectivesCompleted = allQuestObjectivesCompleted,
    isKept = Bagwise.Overrides.IsKept(itemID),
    isFlagged = Bagwise.Overrides.IsFlagged(itemID),
  }
end

--- Gather item data from the WoW API for one bag slot.
-- @param bag   number  Bag index
-- @param slot  number  Slot index (1-N)
-- @param state table   Player state from getPlayerState()
-- @return table|nil  Item table matching what Verdict.Evaluate expects, or nil
local function gatherItem(bag, slot, state)
  local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
  if not containerInfo then return nil end

  return buildItem(containerInfo.itemID, containerInfo.isBound,
    C_Container.GetContainerItemQuestInfo(bag, slot), state)
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

--- Evaluate one item through the verdict cache.
-- Cache key includes bound state because the same itemID can be both
-- soulbound and not (a BoE you equipped plus another you bought). Verdicts
-- depend on isBound. Profession key is included because vendor reagent
-- verdicts depend on which professions the player currently has.
local function evaluateCached(item, state, profKey)
  local cacheKey = item.id
      .. ":" .. tostring(item.isBound)
      .. ":" .. tostring(item.classID)
      .. ":" .. tostring(item.startsQuestCompleted)
      .. ":" .. tostring(item.allQuestObjectivesCompleted)
      .. ":" .. tostring(item.isKept)
      .. ":" .. tostring(item.isFlagged)
      .. ":" .. profKey
  local cached = verdictCache[cacheKey]
  if cached then return cached end

  local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)
  local result = { verdict = verdict, reason = reason, detail = detail }
  verdictCache[cacheKey] = result
  return result
end

--- Scan all bag slots, evaluate verdicts, store results.
function Bagwise.Scanner.ScanAll()
  local state = getPlayerState()
  local profKey = professionCacheKey(state)

  -- Clear slot results, we're rebuilding from scratch
  slotResults = {}

  for bag = 0, Bagwise.Bags.LastScanned() do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local key = bag .. ":" .. slot
      local item = gatherItem(bag, slot, state)

      if item then
        slotResults[key] = evaluateCached(item, state, profKey)
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

--- Count scanned slots by verdict (for /bagwise status).
-- @return table { items = n, green = n, yellow = n }
function Bagwise.Scanner.Counts()
  local counts = { items = 0, green = 0, yellow = 0 }
  for _, result in pairs(slotResults) do
    counts.items = counts.items + 1
    if result.verdict == "green" then counts.green = counts.green + 1 end
    if result.verdict == "yellow" then counts.yellow = counts.yellow + 1 end
  end
  return counts
end

local function sortedProfessionNames(state)
  local names = {}
  for name in pairs(state.professionNames) do names[#names + 1] = name end
  table.sort(names)
  return names
end

local function questProgressOf(questIDs)
  local progress = {}
  for _, questID in ipairs(questIDs or {}) do
    local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]
    progress[#progress + 1] = {
      id = questID,
      done = C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false,
      faction = info and info[4] or nil, -- "A", "H" or nil for both
    }
  end
  return progress
end

local function professionNamesFor(itemID)
  local entries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[itemID]
  local names = {}
  for _, entry in ipairs(entries or {}) do names[#names + 1] = entry[1] end
  return names
end

--- Snapshot of everything in bags 0-4 plus the player, for /bagwise dump.
-- Raw facts only; Bagwise.Dump turns it into text. Rescans first so the
-- verdict columns match what the bags show right now.
-- @return table { player = {...}, rows = { ... }, uncached = n }
function Bagwise.Scanner.CollectInventory()
  Bagwise.Scanner.ScanAll()
  local state = getPlayerState()
  local factionGroup = UnitFactionGroup and UnitFactionGroup("player") or nil

  local snapshot = {
    player = {
      class = state.playerClass,
      race = state.race,
      faction = factionGroup,
      level = state.level,
      professions = sortedProfessionNames(state),
    },
    rows = {},
    uncached = 0,
  }

  for bag = 0, Bagwise.Bags.LastScanned() do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
      if containerInfo then
        local itemID = containerInfo.itemID
        local name, _, quality, itemLevel, reqLevel, _, subClassName, maxStack,
        equipSlot, _, sellPrice, classID, subClassID, bindType = getItemInfo(itemID)
        if not name then snapshot.uncached = snapshot.uncached + 1 end

        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local startsQuestID = questInfo and questInfo.questID or nil
        local result = Bagwise.Scanner.GetResult(bag, slot)

        snapshot.rows[#snapshot.rows + 1] = {
          bag = bag, slot = slot, id = itemID, name = name,
          count = containerInfo.stackCount, maxStack = maxStack,
          quality = quality, itemLevel = itemLevel, reqLevel = reqLevel,
          classID = classID, subClassID = subClassID, equipSlot = equipSlot,
          bindType = bindType, isBound = containerInfo.isBound,
          sellPrice = sellPrice,
          startsQuestID = startsQuestID,
          startsQuestDone = startsQuestID
              and C_QuestLog.IsQuestFlaggedCompleted(startsQuestID) or nil,
          quests = questProgressOf(Bagwise.Data.QuestItems
              and Bagwise.Data.QuestItems[itemID]),
          recipeProfessions = professionNamesFor(itemID),
          isVendorReagent = Bagwise.Data.VendorReagents
              and Bagwise.Data.VendorReagents[itemID] ~= nil or false,
          isClassReagent = Bagwise.Data.ClassReagents
              and Bagwise.Data.ClassReagents[itemID] ~= nil or false,
          isKept = Bagwise.Overrides.IsKept(itemID),
          isFlagged = Bagwise.Overrides.IsFlagged(itemID),
          verdict = result and result.verdict,
          reason = result and result.reason,
        }
      end
    end
  end

  return snapshot
end

--- Verdict for an item that is not in a bag yet (the loot window).
-- Not soulbound and not a quest starter: nothing has been picked up.
-- @param itemID number
-- @return table|nil  { verdict, reason, detail }, or nil until the client has the item
function Bagwise.Scanner.EvaluateItem(itemID)
  local state = getPlayerState()
  local item = buildItem(itemID, false, nil, state)
  if not item then return nil end
  return evaluateCached(item, state, professionCacheKey(state))
end

--- Everything the verdict rules see for one item, for /bagwise why.
-- @return table|nil  { item, result, faction, quests = { {id,name,faction,done} } }
function Bagwise.Scanner.Explain(itemID)
  local state = getPlayerState()
  local item = buildItem(itemID, false, nil, state)
  if not item then return nil end

  local quests = {}
  for _, questID in ipairs(Bagwise.Data.QuestItems and Bagwise.Data.QuestItems[itemID] or {}) do
    local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]
    quests[#quests + 1] = {
      id = questID,
      name = info and info[3],
      faction = info and info[4],
      done = C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false,
    }
  end

  return {
    item = item,
    result = evaluateCached(item, state, professionCacheKey(state)),
    faction = state.faction,
    quests = quests,
    recipeProfessions = professionNamesFor(itemID),
  }
end
