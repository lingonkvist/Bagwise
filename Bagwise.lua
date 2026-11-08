-- Bagwise: entry point
-- Registers events, initialises saved variables, hooks bag frames.

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local function rescanAll()
  Bagwise.Scanner.ScanAll()
  Bagwise.Overlay.UpdateAll()
end

-- Bursts of events (item info arriving for a whole bag, several bag updates
-- in a row) become a single rescan a moment later.
local RESCAN_DELAY_SECONDS = 0.15
local rescanPending = false

local function rescanSoon()
  if not (C_Timer and C_Timer.After) then
    rescanAll()
    return
  end
  if rescanPending then return end
  rescanPending = true
  C_Timer.After(RESCAN_DELAY_SECONDS, function()
    rescanPending = false
    rescanAll()
  end)
end

local function invalidateAndRescan()
  Bagwise.Scanner.ClearCache()
  rescanAll()
end

-- Loot window: read what is in it, work out what is worth a slot, repaint.
-- LOOT_SLOT_CLEARED carries the slot that was just taken. The client can still
-- report the item for that slot, and Blizzard re-lays the rows after the event,
-- so the loot dots are repainted once now and once on the next frame.
local function onLootChanged(self, clearedSlot)
  Bagwise.Scanner.RefreshLoot(clearedSlot)
  rescanAll()
  Bagwise.Overlay.UpdateLoot()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function() Bagwise.Overlay.UpdateLoot() end)
  end
end

local function onLootClosed()
  Bagwise.Scanner.ClearLoot()
  rescanAll()
  Bagwise.Overlay.UpdateLoot()
end

local function onAddonLoaded(self, addonName)
  if addonName ~= "Bagwise" then return end

  -- Fill in anything missing, so a saved file from an older version (or one
  -- edited by hand) never leaves a nil list for the rest of the addon to trip on.
  BagwiseDB = BagwiseDB or {}
  BagwiseDB.keepList = BagwiseDB.keepList or {}
  BagwiseDB.flagList = BagwiseDB.flagList or {}
  BagwiseDB.version = BagwiseDB.version or 1

  self:UnregisterEvent("ADDON_LOADED")
end

local function onPlayerLogin(self)
  self:RegisterEvent("BAG_UPDATE_DELAYED")
  self:RegisterEvent("PLAYER_LEVEL_UP")
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  self:RegisterEvent("QUEST_TURNED_IN")
  self:RegisterEvent("SKILL_LINES_CHANGED")
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  self:RegisterEvent("LOOT_OPENED")
  self:RegisterEvent("LOOT_SLOT_CLEARED")
  self:RegisterEvent("LOOT_CLOSED")

  -- Hook bag frame Show so dots appear when bags open.
  -- Frame pool is shared (NUM_CONTAINER_FRAMES = 13), and any
  -- frame can hold any bag, so hook them all.
  -- Includes the combined-bags frame on Forever and EllesmereUI Bags.
  for _, bagFrame in ipairs(Bagwise.Overlay.BagWindows()) do
    bagFrame:HookScript("OnShow", rescanAll)
  end

  Bagwise.Tooltip.Init()
  Bagwise.Commands.Init()
  Bagwise.Overlay.Init() -- <-- Registers the Baganator corner widget

  print("|cff54de7d[Bagwise]|r v" .. Bagwise.Commands.Version()
    .. " loaded. Type /bagwise help for commands.")
end

local EVENT_HANDLERS = {
  ADDON_LOADED           = onAddonLoaded,
  PLAYER_LOGIN           = onPlayerLogin,
  BAG_UPDATE_DELAYED     = rescanSoon,
  GET_ITEM_INFO_RECEIVED = rescanSoon,
  PLAYER_LEVEL_UP        = invalidateAndRescan,
  QUEST_TURNED_IN        = invalidateAndRescan,
  SKILL_LINES_CHANGED    = invalidateAndRescan,
  PLAYER_EQUIPMENT_CHANGED = invalidateAndRescan,
  LOOT_OPENED            = onLootChanged,
  LOOT_SLOT_CLEARED      = onLootChanged,
  LOOT_CLOSED            = onLootClosed,
}

frame:SetScript("OnEvent", function(self, event, ...)
  local handler = EVENT_HANDLERS[event]
  if handler then handler(self, ...) end
end)
