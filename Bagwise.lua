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

  -- Hook bag frame Show so dots appear when bags open.
  -- Frame pool is shared (NUM_CONTAINER_FRAMES = 13), and any
  -- frame can hold any bag, so hook them all.
  local maxFrames = NUM_CONTAINER_FRAMES or 13
  for i = 1, maxFrames do
    local bagFrame = _G["ContainerFrame" .. i]
    if bagFrame then
      bagFrame:HookScript("OnShow", rescanAll)
    end
  end

  Bagwise.Tooltip.Init()
  Bagwise.Commands.Init()

  print("|cff66bb6a[Bagwise]|r v0.2.0 loaded. Type /bagwise help for commands.")
end

local EVENT_HANDLERS = {
  ADDON_LOADED           = onAddonLoaded,
  PLAYER_LOGIN           = onPlayerLogin,
  BAG_UPDATE_DELAYED     = rescanAll,
  GET_ITEM_INFO_RECEIVED = rescanAll,
  PLAYER_LEVEL_UP        = invalidateAndRescan,
  QUEST_TURNED_IN        = invalidateAndRescan,
  SKILL_LINES_CHANGED    = invalidateAndRescan,
}

frame:SetScript("OnEvent", function(self, event, ...)
  local handler = EVENT_HANDLERS[event]
  if handler then handler(self, ...) end
end)
