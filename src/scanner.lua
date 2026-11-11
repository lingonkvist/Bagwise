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
  local ranks = {} -- [skillLineID] = current skill rank, when the client says
  local sources = {}

  -- Path A: Modern profession API. Take every index it returns instead of
  -- trusting a fixed order: clients differ on where fishing, cooking and first
  -- aid sit, and some leave first aid out.
  local foundByModernApi = false
  if GetProfessions and GetProfessionInfo then
    local packed = { GetProfessions() }
    for position = 1, 8 do
      local index = packed[position]
      if index then
        local _, _, rank, _, _, _, skillLine = GetProfessionInfo(index)
        if skillLine then
          skillLines[skillLine] = true
          ranks[skillLine] = rank
          foundByModernApi = true
        end
      end
    end
  end
  if foundByModernApi then sources[#sources + 1] = "GetProfessions" end

  -- Path B: the Skills tab, always read as well. It lists the secondary skills
  -- (cooking, first aid, fishing) too, so it fills in whatever path A missed.
  local getNum = GetNumSkillLines or (C_SkillInfo and C_SkillInfo.GetNumSkillLines)
  local getInfo = GetSkillLineInfo or (C_SkillInfo and C_SkillInfo.GetSkillLineInfo)

  -- Whether the list is complete matters as much as what is in it: a
  -- profession we cannot see looks exactly like one the player does not have,
  -- and "you have no use for this" is a green. The Skills tab hides what sits
  -- under a collapsed header, and is empty until the client has loaded it.
  local complete = false
  if getNum and getInfo then
    local lines = getNum()
    complete = lines > 0
    for i = 1, lines do
      local name, isHeader, isExpanded, rank = getInfo(i)
      if isHeader and isExpanded == false then complete = false end
      if not isHeader and name then
        local id = PROFESSION_NAME_TO_SKILL_LINE[name]
        if id then
          skillLines[id] = true
          if ranks[id] == nil then ranks[id] = rank end
          if not sources.skills then sources.skills = true; sources[#sources + 1] = "Skills tab" end
        end
      end
    end
  end

  return skillLines, complete or foundByModernApi, ranks, table.concat(sources, " + ")
end

-- Per-character skill history, kept in the saved variables when they exist.
local fallbackProgress = {}
local function progressStore()
  if not BagwiseDB then return fallbackProgress end
  BagwiseDB.skillProgress = BagwiseDB.skillProgress or {}
  local who = (UnitName and UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
  BagwiseDB.skillProgress[who] = BagwiseDB.skillProgress[who] or {}
  return BagwiseDB.skillProgress[who]
end
local function now()
  return (GetServerTime and GetServerTime()) or (time and time()) or (os and os.time and os.time()) or 0
end

--- Gather player state once per scan.
-- @return table  State table matching what Verdict.Evaluate expects
local function getPlayerState()
  local class, playerClass = UnitClass("player")
  local race = UnitRace("player")
  local level = UnitLevel("player")
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil

  local skillLines, professionsKnown, ranksByID, professionSource = gatherProfessionSkillLines()

  -- Build reverse lookup: English profession name -> true.
  -- Used by verdict rules that match against ReagentProfessions data
  -- (which is keyed by English name, not skillLine ID).
  local professionNames = {}
  local professionRanks = {}
  for name, id in pairs(PROFESSION_NAME_TO_SKILL_LINE) do
    if skillLines[id] then
      professionNames[name] = true
      professionRanks[name] = ranksByID and ranksByID[id] or nil
    end
  end

  -- Professions you have stopped leveling (no gain for a day): nothing is
  -- close for them, so out-of-reach recipes get the bank hint at once.
  local professionIdle = {}
  if Bagwise.Progress and next(professionRanks) then
    local store = progressStore()
    Bagwise.Progress.Observe(store, professionRanks, now())
    if professionsKnown then -- forget professions you no longer have
      for name in pairs(store) do
        if not professionRanks[name] then store[name] = nil end
      end
    end
    professionIdle = Bagwise.Progress.IdleSet(store, professionRanks, now())
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
    professionRanks = professionRanks,
    professionIdle = professionIdle,
    professionsKnown = professionsKnown,
    professionSource = professionSource,
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

-- equipSlot -> the character inventory slots an item of that type can occupy.
-- Shirts and tabards are cosmetic and left out. Rings and trinkets have two
-- slots. A one-hand weapon is compared with the main hand only: the off hand
-- is empty for anyone with a two-hander or a shield, and an empty slot would
-- make every one-hander look like an upgrade.
local INVENTORY_SLOTS = {
  INVTYPE_HEAD     = { 1 },
  INVTYPE_NECK     = { 2 },
  INVTYPE_SHOULDER = { 3 },
  INVTYPE_CHEST    = { 5 },
  INVTYPE_ROBE     = { 5 },
  INVTYPE_WAIST    = { 6 },
  INVTYPE_LEGS     = { 7 },
  INVTYPE_FEET     = { 8 },
  INVTYPE_WRIST    = { 9 },
  INVTYPE_HAND     = { 10 },
  INVTYPE_FINGER   = { 11, 12 },
  INVTYPE_TRINKET  = { 13, 14 },
  INVTYPE_CLOAK    = { 15 },

  INVTYPE_WEAPON         = { 16 },
  INVTYPE_2HWEAPON       = { 16 },
  INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPONOFFHAND  = { 17 },
  INVTYPE_SHIELD         = { 17 },
  INVTYPE_HOLDABLE       = { 17 },
  INVTYPE_RANGED         = { 18 },
  INVTYPE_RANGEDRIGHT    = { 18 },
  INVTYPE_THROWN         = { 18 },
}

--- What the player wears in every slot this item could go in.
-- An empty slot is listed as quality 0, item level 0, so anything beats it.
-- @return table|nil  { {quality, itemLevel}, ... }, or nil when the item has
--   no comparable slot or something isn't loaded yet
local function equippedInSlotsFor(equipSlot)
  local slots = INVENTORY_SLOTS[equipSlot]
  if not slots then return nil end

  local worn = {}
  for _, inventorySlot in ipairs(slots) do
    local link = GetInventoryItemLink("player", inventorySlot)
    if not link then
      worn[#worn + 1] = { quality = 0, itemLevel = 0 }
    else
      local _, _, quality, itemLevel = getItemInfo(link)
      if not (quality and itemLevel) then return nil end
      worn[#worn + 1] = { quality = quality, itemLevel = itemLevel }
    end
  end
  return worn
end

--- Build the item table Verdict.Evaluate expects.
-- @param itemID        number
-- @param isBound       boolean  Soulbound right now (false for loot)
-- @param questInfo     table|nil  C_Container quest info for the slot
-- @param state         table    Player state from getPlayerState()
-- @param count         number|nil  Stack size (nil counts as 1)
-- @return table|nil  nil when the client hasn't cached the item yet
-- Classic Era calls it GetQuestInfo, newer clients GetTitleForQuestID, and a
-- client may have neither. A missing name must never stop a scan.
local function questTitle(questID)
  local lookup = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)
  if not lookup then return nil end
  local ok, title = pcall(lookup, questID)
  if ok and type(title) == "string" then return title end
  return nil
end

-- Has this quest been handed in for good? A repeatable quest (daily, weekly,
-- or turn-in-again) never counts: its items will be wanted again.
local function questFinished(questID)
  local repeatable = Bagwise.Data.RepeatableQuests
  if repeatable and repeatable[questID] then return false end
  return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

local function buildItem(itemID, isBound, questInfo, state, count, hasLoot)
  local name, _, quality, itemLevel, reqLevel, _, _, maxStack,
  equipSlot, _, sellPrice, classID, subClassID, bindType = getItemInfo(itemID)

  -- Item not cached by the client yet, skip for now
  if not name then return nil end

  local isEquippable = equipSlot and EQUIP_SLOTS[equipSlot] or false

  -- Quest data: does this item start a quest? Is that quest done?
  local startsQuestID = questInfo and questInfo.questID or nil
  local startsQuestCompleted = false
  local startsQuestName = nil

  if startsQuestID then
    startsQuestCompleted = questFinished(startsQuestID)
    startsQuestName = questTitle(startsQuestID)
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
  local openQuestIDs = nil
  local onOpenQuest = false

  if questItemQuestIDs and #questItemQuestIDs > 0 then
    allQuestObjectivesCompleted = true
    openQuestIDs = {}
    for _, qid in ipairs(questItemQuestIDs) do
      if not questFinished(qid) then
        allQuestObjectivesCompleted = false
        openQuestIDs[#openQuestIDs + 1] = qid
        if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(qid) then onOpenQuest = true end
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
    equipSlot = equipSlot,
    classID = classID,
    bindType = bindType,
    sellPrice = sellPrice,
    subClassID = subClassID,
    count = count,
    maxStack = maxStack,
    hasLoot = hasLoot and true or false, -- right-click opens it (clams, lockboxes, bags of loot)
    startsQuestID = startsQuestID,
    startsQuestCompleted = startsQuestCompleted,
    startsQuestName = startsQuestName,
    questItemQuestIDs = questItemQuestIDs,
    allQuestObjectivesCompleted = allQuestObjectivesCompleted,
    openQuestIDs = openQuestIDs,
    onOpenQuest = onOpenQuest,
    equippedInSlots = isEquippable and equippedInSlotsFor(equipSlot) or nil,
    isKept = Bagwise.Overrides.IsKept(itemID),
    isFlagged = Bagwise.Overrides.IsFlagged(itemID),
  }
end

-- A recipe's tooltip says "Requires Alchemy (150)". The skill needed is in no
-- item field, so read it from the item's own tooltip. Only recipes ask for it.
local skillTip
local skillPattern

local function requiredSkillPattern()
  if skillPattern ~= nil then return skillPattern or nil end
  local format = _G.ITEM_MIN_SKILL
  if not format then skillPattern = false; return nil end
  local escaped = format:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
  escaped = escaped:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
  skillPattern = "^" .. escaped .. "$"
  return skillPattern
end

local function readRequiredSkill(bag, slot)
  local pattern = requiredSkillPattern()
  if not (pattern and CreateFrame and UIParent) then return nil end
  if not skillTip then
    skillTip = CreateFrame("GameTooltip", "BagwiseSkillTip", nil, "GameTooltipTemplate")
  end
  skillTip:SetOwner(UIParent, "ANCHOR_NONE")
  skillTip:ClearLines()
  skillTip:SetBagItem(bag, slot)
  for line = 2, skillTip:NumLines() do
    local text = _G["BagwiseSkillTipTextLeft" .. line]
    local content = text and text:GetText()
    if content then
      local _, number = content:match(pattern)
      if number then return tonumber(number) end
    end
  end
  return nil
end

local RECIPE_CLASS_ID = 9
local CONSUMABLE_CLASS_ID = 0
local POTION_SUBCLASS_ID = 1
local FOOD_SUBCLASS_ID = 5

-- Does this potion restore health or mana? Utility potions (swim speed, free
-- action) are never outleveled, so the potion rule needs a yes. The wording is
-- English only: on other clients the answer stays "no" and nothing is flagged.
local function readRestores(bag, slot)
  -- returns restores (plain healing or mana text), givesBuff (a Well Fed style effect)
  if not (CreateFrame and UIParent) then return false, false end
  if not skillTip then
    skillTip = CreateFrame("GameTooltip", "BagwiseSkillTip", nil, "GameTooltipTemplate")
  end
  skillTip:SetOwner(UIParent, "ANCHOR_NONE")
  skillTip:ClearLines()
  skillTip:SetBagItem(bag, slot)
  local restores, givesBuff = false, false
  for line = 2, skillTip:NumLines() do
    local text = _G["BagwiseSkillTipTextLeft" .. line]
    local content = text and text:GetText()
    if content and content:find("Restores", 1, true)
        and (content:find("health", 1, true) or content:find("mana", 1, true)) then
      restores = true
    end
    if content and content:lower():find("well fed", 1, true) then
      givesBuff = true
    end
  end
  return restores, givesBuff
end

--- Gather item data from the WoW API for one bag slot.
-- @param bag   number  Bag index
-- @param slot  number  Slot index (1-N)
-- @param state table   Player state from getPlayerState()
-- @return table|nil  Item table matching what Verdict.Evaluate expects, or nil
local function gatherItem(bag, slot, state)
  local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
  if not containerInfo then return nil end

  local item = buildItem(containerInfo.itemID, containerInfo.isBound,
    C_Container.GetContainerItemQuestInfo(bag, slot), state,
    containerInfo.stackCount, containerInfo.hasLoot)
  if item then
    item.link = containerInfo.hyperlink
    item.bonusKey = Bagwise.Verdict.BonusKey(containerInfo.hyperlink)
  end
  if item and item.classID == RECIPE_CLASS_ID then
    item.requiredSkill = readRequiredSkill(bag, slot)
  elseif item and item.classID == CONSUMABLE_CLASS_ID
      and (item.subClassID == POTION_SUBCLASS_ID or item.subClassID == FOOD_SUBCLASS_ID) then
    item.restoresHealthOrMana, item.givesBuff = readRestores(bag, slot)
  end
  return item
end

--- Build a short string key from the player's profession set.
-- Sorted so the key is stable regardless of iteration order.
-- @param state table  Player state from getPlayerState()
-- @return string      e.g. "164,171" for Blacksmithing+Alchemy
local function professionCacheKey(state)
  local parts = {}
  for name in pairs(state.professionNames or {}) do
    parts[#parts + 1] = name .. "=" .. tostring(state.professionRanks and state.professionRanks[name])
      .. (state.professionIdle and state.professionIdle[name] and "!" or "")
  end
  table.sort(parts)
  local key = table.concat(parts, ",")
  if state.professionsKnown == false then key = key .. "?" end
  return key
end

--- Part of the cache key for the gear the item is compared against.
local function equippedKey(item)
  if not item.equippedInSlots then return "-" end
  local parts = {}
  for _, worn in ipairs(item.equippedInSlots) do
    parts[#parts + 1] = worn.quality .. "/" .. worn.itemLevel
  end
  return table.concat(parts, ",")
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
      .. ":" .. tostring(item.onOpenQuest)
      .. ":" .. tostring(item.isKept)
      .. ":" .. tostring(item.isFlagged)
      .. ":" .. tostring(item.count)
      .. ":" .. tostring(item.hasLoot)
      .. ":" .. tostring(item.requiredSkill) .. ":" .. tostring(item.restoresHealthOrMana) .. ":" .. tostring(item.givesBuff)
      .. ":" .. equippedKey(item)
      .. ":" .. tostring(item.bonusKey)
      .. ":" .. profKey
  local cached = verdictCache[cacheKey]
  if cached then return cached end

  local verdict, reason, detail, tag, rule, heading, auctionNote = Bagwise.Verdict.Evaluate(item, state)
  local result = { verdict = verdict, reason = reason, detail = detail, tag = tag, rule = rule,
                   heading = heading, sellable = Bagwise.Verdict.Sellable(item, verdict),
                   auctionNote = auctionNote }
  verdictCache[cacheKey] = result
  return result
end

-- How many gray items may show a green dot at once (the cheapest ones).
local MAX_POOR_QUALITY_DOTS = 1

--- Free slots in a regular bag. Quivers, ammo pouches and profession bags only
-- take their own kind of item, so their empty slots are not room for loot.
local function generalFreeSlots(bag)
  local free, bagType = C_Container.GetContainerNumFreeSlots(bag)
  if bagType and bagType ~= 0 then return 0 end
  return free or 0
end

-- The loot window's contents and what to do about them. Set by RefreshLoot
-- when the window opens and as items are taken; cleared when it closes.
local lootPieces = {}
local lootPlan = { take = {}, deletes = {}, active = false }
-- Loot slots that still hold an item. A slot that was just looted is in
-- neither list, so it must not be told to "leave".
local liveLootSlots = {}
local lastFreeSlots, lastJunkCount = 0, 0
local lastCheapestJunk = nil -- { itemID, value } of the cheapest thing that could be deleted

local lastScanError = nil

--- The last error a bag slot raised while scanning, or nil.
function Bagwise.Scanner.LastError()
  return lastScanError
end

--- Scan all bag slots, evaluate verdicts, store results.
local function scanAllSlots()
  local state = getPlayerState()
  local profKey = professionCacheKey(state)

  -- Clear slot results, we're rebuilding from scratch
  slotResults = {}
  lastScanError = nil
  local poorQuality = {}
  local junkEntries = {}
  local junkCandidates = {}
  local freeSlots = 0
  local stackRoom = {} -- itemID -> how many more fit in the stacks you carry
  local regularBags = NUM_BAG_SLOTS or 4

  local bagsToScan = {}
  for bag = 0, Bagwise.Bags.LastScanned() do bagsToScan[#bagsToScan + 1] = bag end
  for _, bag in ipairs(Bagwise.Bags.BankBags()) do bagsToScan[#bagsToScan + 1] = bag end

  for _, bag in ipairs(bagsToScan) do
    local carried = Bagwise.Bags.IsCarried(bag)
    if carried and bag <= regularBags then freeSlots = freeSlots + generalFreeSlots(bag) end

    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local key = bag .. ":" .. slot
      -- One item that fails must not take every other dot with it.
      local gathered, item = pcall(gatherItem, bag, slot, state)
      if not gathered then
        lastScanError = "bag " .. bag .. " slot " .. slot .. ": " .. tostring(item)
        item = nil
      end

      if item and not carried then
        -- Banked on purpose, maybe for an alt: see Verdict.ForBank.
        slotResults[key] = Bagwise.Verdict.ForBank(evaluateCached(item, state, profKey),
            Bagwise.Bags.IsWarbandBank(bag))
      elseif item then
        local maxStack = item.maxStack or 1
        if maxStack > 1 and (item.count or 1) < maxStack then
          stackRoom[item.id] = (stackRoom[item.id] or 0) + maxStack - (item.count or 1)
        end
        slotResults[key] = evaluateCached(item, state, profKey)
        junkCandidates[#junkCandidates + 1] = {
          key = key, bag = bag, slot = slot, item = item,
          value = Bagwise.MakeRoom.ValueOf(item.sellPrice, item.count),
        }
        if slotResults[key].tag == Bagwise.Verdict.POOR_QUALITY_TAG then
          poorQuality[#poorQuality + 1] = {
            key = key, bag = bag, slot = slot,
            value = (item.sellPrice or 0) * (item.count or 1),
            verdict = slotResults[key].verdict,
          }
        end
      else
        slotResults[key] = nil
      end
    end
  end

  -- Only the cheapest gray(s) keep their dot. The cached result is shared
  -- between slots, so silence them with a fresh table instead of editing it.
  local silenced = Bagwise.Verdict.SilenceAllButCheapest(poorQuality, MAX_POOR_QUALITY_DOTS)
  for _, entry in ipairs(poorQuality) do
    if silenced[entry.key] then
      slotResults[entry.key] = {}
    else
      local original = slotResults[entry.key]
      local reason, heading = Bagwise.Verdict.PoorQualityReason(entry.value, true, entry.verdict == "yellow")
      slotResults[entry.key] = {
        verdict = entry.verdict,
        reason = reason,
        heading = heading,
        tag = Bagwise.Verdict.POOR_QUALITY_TAG,
        detail = original.detail,
        rule = original.rule,
        sellable = original.sellable,
      }
    end
  end

  -- Making room for loot runs last, on the final results.
  lootPlan = { take = {}, deletes = {}, active = false }
  lastFreeSlots, lastJunkCount = freeSlots, 0
  lastCheapestJunk = nil
  if #lootPieces == 0 then return end

  for _, candidate in ipairs(junkCandidates) do
    if Bagwise.MakeRoom.IsJunkCandidate(candidate.item, slotResults[candidate.key]) then
      junkEntries[#junkEntries + 1] = candidate
    end
  end

  lastJunkCount = #junkEntries
  for _, entry in ipairs(junkEntries) do
    if not lastCheapestJunk or entry.value < lastCheapestJunk.value then
      lastCheapestJunk = { itemID = entry.item.id, value = entry.value }
    end
  end
  -- Loot that fits into a stack you already carry needs no free slot.
  local pieces = {}
  for i, piece in ipairs(lootPieces) do
    local copy = {}
    for k, v in pairs(piece) do copy[k] = v end
    local room = stackRoom[piece.itemID] or 0
    if room >= piece.quantity then
      copy.stacks = true
      stackRoom[piece.itemID] = room - piece.quantity
    end
    pieces[i] = copy
  end
  lootPlan = Bagwise.MakeRoom.Plan(pieces, junkEntries, freeSlots)

  -- Nothing to delete means nothing to act on, so the dots stay as they are
  -- and the banner explains why the loot is being left.
  if #lootPlan.deletes == 0 then return end

  -- Quiet every other dot, then mark the slots to delete. Fresh tables: the
  -- cached results are shared between slots.
  for key, result in pairs(slotResults) do
    slotResults[key] = Bagwise.MakeRoom.QuietResult(result)
  end
  for _, entry in ipairs(lootPlan.deletes) do
    slotResults[entry.key] = Bagwise.MakeRoom.MarkedResult(
      Bagwise.MakeRoom.RestoreResult(slotResults[entry.key]), entry.value)
  end
end

-- Bag addons only need telling when something Bagwise would draw changed, so
-- remember a one-line summary per slot and compare it on the next scan.
local lastSignature = {}
local resultsChanged = false

local function signatureOf(result)
  if not result or not result.verdict then return "" end
  return result.verdict .. (result.glow and "g" or "") .. (result.quiet and "q" or "")
end

function Bagwise.Scanner.ScanAll()
  scanAllSlots()
  local signature, changed = {}, false
  for key, result in pairs(slotResults) do
    local sig = signatureOf(result)
    signature[key] = sig
    if sig ~= (lastSignature[key] or "") then changed = true end
  end
  for key, sig in pairs(lastSignature) do
    if sig ~= "" and (signature[key] or "") ~= sig then changed = true end
  end
  lastSignature = signature
  resultsChanged = changed
end

--- What Bagwise thinks your professions are, for /bagwise report.
function Bagwise.Scanner.ProfessionSummary()
  local state = getPlayerState()
  local parts = {}
  for name in pairs(state.professionNames or {}) do
    parts[#parts + 1] = name .. " " .. tostring(state.professionRanks and state.professionRanks[name] or "?")
      .. (state.professionIdle and state.professionIdle[name] and " idle" or "")
  end
  table.sort(parts)
  local list = #parts > 0 and table.concat(parts, ", ") or "none"
  return list .. " (read from " .. ((state.professionSource or "") ~= "" and state.professionSource or "nowhere")
    .. (state.professionsKnown == false and ", incomplete" or "") .. ")"
end

--- Did the last scan change anything that is drawn?
function Bagwise.Scanner.ResultsChanged()
  return resultsChanged
end

-- Does the loot window piece count as must-take? Quest items, rares and
-- anything with no vendor price can't be compared with junk by price.
-- Do quests still want this item? true: an open quest does. false: it is
-- listed for quests and you have finished them all. nil: no quest data.
local function questStillWantsIt(itemID)
  local ids = Bagwise.Data and Bagwise.Data.QuestItems and Bagwise.Data.QuestItems[itemID]
  if not ids then return nil end
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  ids = Bagwise.Verdict.QuestsForFaction(ids, faction)
  if #ids == 0 then return nil end
  for _, questID in ipairs(ids) do
    if not questFinished(questID) then return true end
  end
  return false
end

local function isPriorityLoot(info)
  local wanted = questStillWantsIt(info.itemID)
  if wanted then return true end -- an open quest needs it, even a gray
  if info.quality and info.quality >= 3 then return true end
  -- Green gear can be an upgrade, which a vendor price cannot tell.
  if info.quality and info.quality >= 2 and (info.classID == 2 or info.classID == 4) then
    return true
  end
  -- Finished the quests it was for, or a gray: it is only worth its price.
  if wanted == false or info.quality == 0 then return false end
  if info.classID == 12 then return true end
  -- No vendor price usually means it is worth something elsewhere (AH,
  -- quests, a use we cannot see).
  if (info.sellPrice or 0) == 0 then return true end
  local data = Bagwise.Data or {}
  return (data.ReagentProfessions and data.ReagentProfessions[info.itemID]) and true or false
end

--- Read the open loot window and rescan with it in mind.
-- @param clearedSlot number|nil  a slot that was just looted, to leave out
function Bagwise.Scanner.RefreshLoot(clearedSlot)
  lootPieces = {}
  liveLootSlots = {}
  local count = GetNumLootItems and GetNumLootItems() or 0
  for slot = 1, count do
    local link = GetLootSlotLink and GetLootSlotLink(slot)
    local gone = slot == clearedSlot
        or (LootSlotHasItem and not LootSlotHasItem(slot))
    if link and not gone then
      local _, _, quantity = GetLootSlotInfo(slot)
      local itemID = tonumber(link:match("item:(%d+)"))
      local _, _, quality, _, _, _, _, _, _, _, sellPrice, classID = getItemInfo(link)
      if itemID then
        local info = { itemID = itemID, quality = quality, sellPrice = sellPrice, classID = classID }
        liveLootSlots[slot] = true
        lootPieces[#lootPieces + 1] = {
          slot = slot,
          itemID = itemID,
          quantity = quantity or 1,
          value = (sellPrice or 0) * (quantity or 1),
          priority = isPriorityLoot(info) and true or false,
        }
      end
    end
  end
end

--- What the make-room plan saw on the last scan (for /bagwise loot).
function Bagwise.Scanner.MakeRoomSummary()
  local takes, leaving, noRoom = 0, 0, 0
  for _ in pairs(lootPlan.take) do takes = takes + 1 end
  if lootPlan.active then
    for _, piece in ipairs(lootPieces) do
      if not lootPlan.take[piece.slot] then
        if piece.priority then noRoom = noRoom + 1 else leaving = leaving + 1 end
      end
    end
  end
  local cheapest = lastCheapestJunk
  local cheapestName, cheapestQuality
  if cheapest then
    local name, _, quality = getItemInfo(cheapest.itemID)
    cheapestName, cheapestQuality = name, quality
  end
  local deleteNames = {}
  for _, victim in ipairs(lootPlan.deletes) do
    local name = victim.item and victim.item.id and (getItemInfo(victim.item.id))
    if name then deleteNames[#deleteNames + 1] = name end
  end
  return {
    deleteNames = deleteNames,
    leaving = leaving,
    noRoom = noRoom,
    cheapestJunkValue = cheapest and cheapest.value or nil,
    cheapestJunkName = cheapestName,
    cheapestJunkQuality = cheapestQuality,
    lootItems = #lootPieces,
    freeSlots = lastFreeSlots,
    junkCandidates = lastJunkCount,
    active = lootPlan.active,
    takes = takes,
    deletes = #lootPlan.deletes,
  }
end

function Bagwise.Scanner.ClearLoot()
  lootPieces = {}
  liveLootSlots = {}
  lootPlan = { take = {}, deletes = {}, active = false }
end

--- What the make-room plan says about a loot slot: "take", "leave" (worth less
-- than your junk), "consider" (taken, but not by price), "noroom" (must-take, but nothing to delete) or nil when
-- there is nothing to decide (bags have room, or no loot window).
function Bagwise.Scanner.LootDecision(slot)
  if not lootPlan.active or not liveLootSlots[slot] then return nil end
  if lootPlan.take[slot] then
    -- Taken because it beats the junk by price, or because a price cannot
    -- judge it (quests, reagents, no vendor value): that one is a "consider".
    for _, piece in ipairs(lootPieces) do
      if piece.slot == slot and piece.priority then return "consider" end
    end
    return "take"
  end
  -- Must-take loot that nothing can be deleted for is not "not needed": the
  -- player has to make room by hand.
  for _, piece in ipairs(lootPieces) do
    if piece.slot == slot and piece.priority then return "noroom" end
  end
  return "leave"
end

--- Get the verdict for a specific bag slot.
-- @param bag   number  Bag index (0-4)
-- @param slot  number  Slot index (1-N)
-- @return table|nil  { verdict = "green"/"yellow"/nil, reason = "..." }
--- Mark the first occupied slot as "delete me" without any loot window, so the
-- glow can be checked on its own. The next real scan puts things back.
-- @return string|nil  "bag:slot" that was marked
function Bagwise.Scanner.ForceTestGlow()
  for bag = 0, Bagwise.Bags.LastScanned() do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local key = bag .. ":" .. slot
      if C_Container.GetContainerItemInfo(bag, slot) then
        slotResults[key] = Bagwise.MakeRoom.MarkedResult(slotResults[key], 0)
        return key
      end
    end
  end
  return nil
end

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
  for key, result in pairs(slotResults) do
    -- Count what you carry; the bank is only there while it is open.
    if Bagwise.Bags.IsCarried(tonumber(key:match("^(-?%d+):"))) then
      counts.items = counts.items + 1
      if result.verdict == "green" then counts.green = counts.green + 1 end
      if result.verdict == "yellow" then counts.yellow = counts.yellow + 1 end
    end
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
      done = questFinished(questID),
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
              and questFinished(startsQuestID) or nil,
          quests = questProgressOf(Bagwise.Data.QuestItems
              and Bagwise.Data.QuestItems[itemID]),
          recipeProfessions = professionNamesFor(itemID),
          isVendorReagent = Bagwise.Data.VendorReagents
              and Bagwise.Data.VendorReagents[itemID] ~= nil or false,
          isClassReagent = Bagwise.Data.ClassReagents
              and Bagwise.Data.ClassReagents[itemID] ~= nil or false,
          equippedInSlots = equipSlot and EQUIP_SLOTS[equipSlot] and equippedInSlotsFor(equipSlot) or nil,
          isKept = Bagwise.Overrides.IsKept(itemID),
          isFlagged = Bagwise.Overrides.IsFlagged(itemID),
          lootable = containerInfo.hasLoot and true or false,
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
function Bagwise.Scanner.EvaluateItem(itemID, opensForLoot, link)
  local state = getPlayerState()
  local item = buildItem(itemID, false, nil, state, nil, opensForLoot)
  if not item then return nil end
  item.bonusKey = Bagwise.Verdict.BonusKey(link)
  return evaluateCached(item, state, professionCacheKey(state))
end

--- Everything the verdict rules see for one item, for /bagwise why.
-- @return table|nil  { item, result, faction, quests = { {id,name,faction,done} } }
function Bagwise.Scanner.Explain(itemID)
  local state = getPlayerState()

  -- Judge the item as it sits in your bags when you carry one: soulbound,
  -- stack size, openable and quest-starter state all come from the real slot.
  local fromBag = false
  local item
  for bag = 0, Bagwise.Bags.LastScanned() do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == itemID then
        item = gatherItem(bag, slot, state)
        fromBag = item ~= nil
        break
      end
    end
    if item then break end
  end
  item = item or buildItem(itemID, false, nil, state)
  if not item then return nil end

  local quests = {}
  for _, questID in ipairs(Bagwise.Data.QuestItems and Bagwise.Data.QuestItems[itemID] or {}) do
    local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]
    quests[#quests + 1] = {
      id = questID,
      name = info and info[3],
      faction = info and info[4],
      done = questFinished(questID),
    }
  end

  return {
    item = item,
    fromBag = fromBag,
    professionsKnown = state.professionsKnown,
    result = evaluateCached(item, state, professionCacheKey(state)),
    trace = Bagwise.Verdict.Trace(item, state),
    protections = Bagwise.Safety.Protections(item),
    faction = state.faction,
    state = state,
    quests = quests,
    recipeProfessions = professionNamesFor(itemID),
  }
end
