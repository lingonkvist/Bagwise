-- Bagwise: entry point
-- Registers events, initialises saved variables, hooks bag frames.

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local function rescanAll()
  Bagwise.Scanner.ScanAll()
  Bagwise.Overlay.UpdateAll()
end

local function invalidateAndRescan()
  Bagwise.Scanner.ClearCache()
  rescanAll()
end

-- Loot window: read what is in it, work out what is worth a slot, repaint.
local function onLootChanged()
  Bagwise.Scanner.RefreshLoot()
  rescanAll()
  Bagwise.Overlay.UpdateLoot()
end

local function onLootClosed()
  Bagwise.Scanner.ClearLoot()
  rescanAll()
  Bagwise.Overlay.UpdateLoot()
end

local function onAddonLoaded(self, addonName)
  if addonName ~= "Bagwise" then return end

  if not BagwiseDB then
    BagwiseDB = {
      keepList = {},
      flagList = {},
      version  = 1,
    }
  end

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
  BAG_UPDATE_DELAYED     = rescanAll,
  GET_ITEM_INFO_RECEIVED = rescanAll,
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
