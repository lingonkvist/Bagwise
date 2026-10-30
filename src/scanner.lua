-- Bagwise: bag scanner
-- Iterates bag slots, gathers item info via WoW API, feeds each item
-- to the verdict engine, and caches results.

Bagwise = Bagwise or {}
Bagwise.Scanner = {}

-- Verdict cache: keyed by itemID
-- Stores { verdict = "green"/"yellow"/nil, reason = "..." }
-- Survives across scans, cleared when player state changes.
local verdictCache = {}

-- Slot results: keyed by "bag:slot" string
-- Rebuilt on every scan. The overlay reads this.
local slotResults = {}

--- Gather player state once per scan.
-- @return table  State table matching what Verdict.Evaluate expects
local function getPlayerState()
  local class = UnitClass("player")
  local race = UnitRace("player")
  local level = UnitLevel("player")

  return {
    class = class,
    race = race,
    level = level,
  }
end

-- Use the namespaced version if available, fall back to the old global
---@diagnostic disable-next-line: deprecated
local ItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
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
  INVTYPE_BODY           = true,    -- shirt
  INVTYPE_CHEST          = true,
  INVTYPE_ROBE           = true,    -- also chest
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
  INVTYPE_HOLDABLE       = true,    -- off-hand frill
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
  equipSlot, _, _, _, _, bindType = ItemInfo(itemID)

  -- Item not cached by the client yet, skip for now
  if not name then return nil end

  local isEquippable = equipSlot and EQUIP_SLOTS[equipSlot] or false

  return {
    id = itemID,
    name = name,
    quality = quality,
    itemLevel = itemLevel,
    reqLevel = reqLevel,
    isBound = containerInfo.isBound,
    isEquippable = isEquippable,
    bindType = bindType,
  }
end

--- Scan all bag slots, evaluate verdicts, store results.
function Bagwise.Scanner.ScanAll()
  local state = getPlayerState()

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
        local cacheKey = item.id .. ":" .. tostring(item.isBound)
        local cached = verdictCache[cacheKey]
        if cached then
          slotResults[key] = cached
        else
          local verdict, reason = Bagwise.Verdict.Evaluate(item, state)
          local result = { verdict = verdict, reason = reason }
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
