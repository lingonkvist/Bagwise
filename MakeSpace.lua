-- MakeSpace: entry point
-- Registers events, initialises saved variables, hooks bag frames.

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local function rescanAll()
  MakeSpace.Scanner.ScanAll()
  MakeSpace.Overlay.UpdateAll()
  -- Looting changes your bags a moment after the loot event, so the plan (and
  -- with it the marks, banner and tooltips) only becomes right on this scan.
  if MakeSpace.Scanner.HasLoot and MakeSpace.Scanner.HasLoot() then
    MakeSpace.Overlay.UpdateLoot()
  end
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

-- A bank tab the client draws that MakeSpace did not know about: scan it.
MakeSpace.Bags.onNewBankBag = function() rescanSoon() end

-- Auctionator keeps its prices in a database it fills while the auction house is
-- open (a scan, a search, listing something). Nothing tells MakeSpace, so the dots
-- would keep the old verdicts until the bags next changed. Hook the point where a
-- price is stored and rescan a moment after, once per burst.
local AUCTION_PRICES_RESCAN_DELAY_SECONDS = 2
local auctionPricesPending = false
local auctionatorHooked = false

local function auctionPricesChanged()
  if auctionPricesPending or not (C_Timer and C_Timer.After) then return end
  auctionPricesPending = true
  C_Timer.After(AUCTION_PRICES_RESCAN_DELAY_SECONDS, function()
    auctionPricesPending = false
    MakeSpace.Live.ClearCache()
    rescanAll()
  end)
end

local function hookAuctionatorPrices()
  if auctionatorHooked then return end
  local database = _G.Auctionator and _G.Auctionator.Database
  if not (database and database.SetPrice and hooksecurefunc) then return end
  if pcall(hooksecurefunc, database, "SetPrice", auctionPricesChanged) then
    auctionatorHooked = true
  end
end

local function invalidateAndRescan()
  MakeSpace.Scanner.ClearCache()
  rescanAll()
end

-- A new level changes what is outdated. The client can still report the old
-- level for a moment after the event, so the bags are scanned once more after
-- a short wait.
local LEVEL_UP_RESCAN_DELAY_SECONDS = 2
local function onPlayerLevelUp()
  invalidateAndRescan()
  if not (C_Timer and C_Timer.After) then return end
  C_Timer.After(LEVEL_UP_RESCAN_DELAY_SECONDS, invalidateAndRescan)
end

-- Loot window: read what is in it, work out what is worth a slot, repaint.
-- LOOT_SLOT_CLEARED carries the slot that was just taken. The client can still
-- report the item for that slot, and Blizzard re-lays the rows after the event,
-- so the loot dots are repainted once now and once on the next frame.
local function onLootChanged(self, clearedSlot)
  local hadLoot = MakeSpace.Scanner.HasLoot()
  MakeSpace.Scanner.RefreshLoot(clearedSlot)
  -- Gold, or a window with no items before or after: the bags did not change
  -- and there is no plan to make, so a full scan would only cost time. This is
  -- most loot windows when farming.
  if not (hadLoot or MakeSpace.Scanner.HasLoot()) then return end
  rescanAll()
  MakeSpace.Overlay.UpdateLoot()
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function() MakeSpace.Overlay.UpdateLoot() end)
  end
end

-- With full bags the dots that matter are in the bags, so open them. If they
-- were closed, close them again when the loot window goes away.
local openedBagsForLoot = false
-- OpenAllBags is a toggle: a second call closes what the first one opened. A
-- bag addon that replaces the bags is not seen by anyBagOpen, so the check
-- below cannot be trusted to stop a second call. One call per loot window.
local triedOpeningBags = false

-- Is a bag window showing? Checks the frames themselves rather than trusting
-- IsAnyBagOpen alone, which can say yes while nothing is on screen.
local function anyBagOpen()
  if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then return true end
  for i = 1, 13 do
    local frame = _G["ContainerFrame" .. i]
    if frame and frame:IsShown() then return true end
  end
  return false
end

local function openBagsForLoot()
  if MakeSpaceDB and MakeSpaceDB.autoOpenBags == false then return end
  if not MakeSpace.Scanner.MakeRoomSummary().active then return end
  if triedOpeningBags or anyBagOpen() or not OpenAllBags then return end
  triedOpeningBags = true
  if pcall(OpenAllBags) then openedBagsForLoot = true end
end

local function onLootOpened(self, ...)
  onLootChanged(self, ...)
  openBagsForLoot()
  -- The client can still be settling when the loot window opens (free slots,
  -- item info), so look once more on the next frame.
  if C_Timer and C_Timer.After then
    C_Timer.After(0.1, function()
      if MakeSpace.Scanner.HasLoot() then openBagsForLoot() end
    end)
  end
end

local function onLootClosed()
  triedOpeningBags = false
  local hadLoot = MakeSpace.Scanner.HasLoot()
  MakeSpace.Scanner.ClearLoot()
  -- Only a window that had items left has marks and a plan to take down.
  if hadLoot then
    rescanAll()
    MakeSpace.Overlay.UpdateLoot()
  end
  if openedBagsForLoot then
    openedBagsForLoot = false
    if CloseAllBags then pcall(CloseAllBags) end
  end
end

local function onAddonLoaded(self, addonName)
  if addonName ~= "MakeSpace" then return end

  -- Fill in anything missing, so a saved file from an older version (or one
  -- edited by hand) never leaves a nil list for the rest of the addon to trip on.
  MakeSpaceDB = MakeSpaceDB or {}
  MakeSpaceAccountDB = MakeSpaceAccountDB or {}
  MakeSpaceAccountDB.marks = MakeSpaceAccountDB.marks or {}
  if MakeSpaceDB.autoOpenBags == nil then MakeSpaceDB.autoOpenBags = true end
  MakeSpaceDB.version = MakeSpaceDB.version or 1

  self:UnregisterEvent("ADDON_LOADED")
end

local function onPlayerLogin(self)
  self:RegisterEvent("BAG_UPDATE_DELAYED")
  self:RegisterEvent("PLAYER_LEVEL_UP")
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  self:RegisterEvent("QUEST_TURNED_IN")
  -- Registering an event a client does not have is an error, and it would stop
  -- the rest of the setup. These two only refresh quest hints, so try them safely.
  pcall(self.RegisterEvent, self, "QUEST_ACCEPTED")
  pcall(self.RegisterEvent, self, "QUEST_REMOVED")
  self:RegisterEvent("SKILL_LINES_CHANGED")
  self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  self:RegisterEvent("LOOT_OPENED")
  self:RegisterEvent("LOOT_SLOT_CLEARED")
  self:RegisterEvent("LOOT_CLOSED")
  self:RegisterEvent("MERCHANT_SHOW")
  self:RegisterEvent("MERCHANT_CLOSED")
  -- The bank can only be read while it is open. Which of these a client has
  -- differs, and an unknown event must not stop the rest of the setup.
  for _, bankEvent in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
      "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED",
      "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED" }) do
    pcall(self.RegisterEvent, self, bankEvent)
  end

  -- Hook bag frame Show so dots appear when bags open.
  -- Frame pool is shared (NUM_CONTAINER_FRAMES = 13), and any
  -- frame can hold any bag, so hook them all.
  -- Includes the combined-bags frame on Forever and EllesmereUI Bags.
  for _, bagFrame in ipairs(MakeSpace.Overlay.BagWindows()) do
    bagFrame:HookScript("OnShow", rescanAll)
  end

  -- Auction prices are kept per region and faction. Without both, the
  -- addon cannot tell what a tradable item sells for, and says nothing.
  local function read(call, ...)
    local ok, value = pcall(call, ...)
    return ok and value or nil
  end
  MakeSpace.Market.Select(
    MakeSpace.Market.RegionOf(GetNormalizedRealmName and read(GetNormalizedRealmName),
      GetCurrentRegion and read(GetCurrentRegion)),
    UnitFactionGroup and read(UnitFactionGroup, "player"))

  hookAuctionatorPrices()
  -- Auctionator may load after MakeSpace, and its database is made at the first
  -- auction house visit on some builds: try again whenever the house opens.
  -- Closing it also settles prices a scan was still storing.
  pcall(self.RegisterEvent, self, "AUCTION_HOUSE_SHOW")
  pcall(self.RegisterEvent, self, "AUCTION_HOUSE_CLOSED")

  MakeSpace.Tooltip.Init()
  MakeSpace.Commands.Init()
  MakeSpace.Overlay.Init() -- <-- Registers the Baganator corner widget

  print("|cff54de7d[Make Space]|r v" .. MakeSpace.Commands.Version()
    .. " loaded. Type /makespace help for commands.")

  local okNow, now = pcall(time)
  local notice = okNow and MakeSpace.Curves.SnapshotNotice(
    MakeSpace.Curves.SnapshotAgeDays(MakeSpace.Data and MakeSpace.Data.AuctionPricesDate, now))
  if notice then print("|cff54de7d[Make Space]|r " .. notice) end
end

local EVENT_HANDLERS = {
  ADDON_LOADED           = onAddonLoaded,
  PLAYER_LOGIN           = onPlayerLogin,
  BAG_UPDATE_DELAYED     = rescanSoon,
  GET_ITEM_INFO_RECEIVED = rescanSoon,
  PLAYER_LEVEL_UP        = onPlayerLevelUp,
  QUEST_TURNED_IN        = invalidateAndRescan,
  QUEST_ACCEPTED         = invalidateAndRescan,
  QUEST_REMOVED          = invalidateAndRescan,
  SKILL_LINES_CHANGED    = invalidateAndRescan,
  PLAYER_EQUIPMENT_CHANGED = invalidateAndRescan,
  LOOT_OPENED            = onLootOpened,
  LOOT_SLOT_CLEARED      = onLootChanged,
  LOOT_CLOSED            = onLootClosed,
  BANKFRAME_OPENED       = function()
    rescanSoon()
    -- Blizzard fills the bank panel after the event; paint once it has.
    if C_Timer and C_Timer.After then
      C_Timer.After(0.5, function() MakeSpace.Overlay.UpdateAll() end)
    end
  end,
  AUCTION_HOUSE_SHOW     = hookAuctionatorPrices,
  AUCTION_HOUSE_CLOSED   = auctionPricesChanged,
  BANKFRAME_CLOSED       = rescanSoon,
  MERCHANT_SHOW          = function() MakeSpace.Overlay.SetVendorOpen(true) end,
  MERCHANT_CLOSED        = function() MakeSpace.Overlay.SetVendorOpen(false) end,
  PLAYERBANKSLOTS_CHANGED = rescanSoon,
  PLAYERBANKBAGSLOTS_CHANGED = rescanSoon,
  PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = rescanSoon,
}

frame:SetScript("OnEvent", function(self, event, ...)
  local handler = EVENT_HANDLERS[event]
  if handler then handler(self, ...) end
end)
