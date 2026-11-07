-- Bagwise: dot overlay
-- Blizzard bags (combined and separate), Baganator corner widgets and
-- EllesmereUI Bags.

Bagwise = Bagwise or {}
Bagwise.Overlay = {}

local COLORS = {
  green  = { 0.56, 0.87, 0.56, 1 },
  yellow = { 1.0, 0.84, 0.28, 1 },
}

local DOT_SIZE = 12
local LAST_SCANNED_BAG = 4 -- keep in step with Scanner.ScanAll

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------
local function makeDot(parent)
  local dot = parent:CreateTexture(nil, "OVERLAY")
  dot:SetSize(DOT_SIZE, DOT_SIZE)
  dot:SetTexture("Interface\\AddOns\\Bagwise\\textures\\dot")
  dot:SetVertexColor(1, 1, 1, 1)
  return dot
end

local function applyDot(dot, result)
  if result and result.verdict then
    local c = COLORS[result.verdict]
    dot:SetVertexColor(c[1], c[2], c[3], c[4])
    dot:Show()
    return true
  else
    dot:Hide()
    return false
  end
end

-- Dots we made on other addons' item buttons, kept off the buttons themselves:
-- writing custom keys onto a secure item button can taint it.
local dotsByButton = setmetatable({}, { __mode = "k" })

local function getButtonDot(button)
  local dot = dotsByButton[button]
  if dot then return dot end
  dot = makeDot(button)
  dot:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
  dotsByButton[button] = dot
  return dot
end

-- Item buttons are recycled, so every paint decides the dot from scratch.
local function paintButton(button, bagID, slotID)
  local result = nil
  if bagID and bagID >= 0 and bagID <= LAST_SCANNED_BAG then
    result = Bagwise.Scanner.GetResult(bagID, slotID)
  end
  -- Never create a dot just to hide it; a recycled button may still hold one.
  if result or dotsByButton[button] then
    applyDot(getButtonDot(button), result)
  end
end

-- Blizzard's item template reads the bag from the button's parent frame.
local function bagIDOf(button)
  if button.GetBagID then return button:GetBagID() end
  local parent = button:GetParent()
  return parent and parent:GetID()
end

-- ---------------------------------------------------------------------------
-- Adapter 1: Blizzard bags
-- ---------------------------------------------------------------------------
-- Two generations of Blizzard bag code are in play:
--   Forever (Mainline code): bags can be combined into one frame,
--     ContainerFrameCombinedBags. Item buttons have no global names, and each
--     one knows its own bag and slot (GetBagID, GetID). Slots are not reversed.
--   Classic Era: one ContainerFrameN per bag, with buttons named
--     ContainerFrameNItemM, where M counts from the end (slot = size - M + 1).
local MAX_FRAMES = NUM_CONTAINER_FRAMES or 13

local function paintEnumerated(frame)
  for _, button in frame:EnumerateValidItems() do
    paintButton(button, bagIDOf(button), button:GetID())
  end
end

local function paintNamed(frame)
  local bagID = frame:GetID()
  local frameName = frame:GetName()
  if not (bagID and frameName) then return end

  local numSlots = C_Container.GetContainerNumSlots(bagID)
  for buttonIndex = 1, numSlots do
    local button = _G[frameName .. "Item" .. buttonIndex]
    if button then
      paintButton(button, bagID, numSlots - buttonIndex + 1)
    end
  end
end

-- IsVisible, not IsShown: a bag frame parked under a hidden parent (as when a
-- bag replacement takes over) can still report shown.
local function paintFrame(frame)
  if not (frame and frame:IsVisible()) then return end
  if frame.EnumerateValidItems then
    paintEnumerated(frame)
  else
    paintNamed(frame)
  end
end

local function blizzardFrames()
  local frames = {}
  if ContainerFrameCombinedBags then
    frames[#frames + 1] = ContainerFrameCombinedBags
  end
  for frameIndex = 1, MAX_FRAMES do
    local frame = _G["ContainerFrame" .. frameIndex]
    if frame then frames[#frames + 1] = frame end
  end
  return frames
end

local function updateBlizzard()
  for _, frame in ipairs(blizzardFrames()) do
    paintFrame(frame)
  end
end

-- Blizzard refreshes its buttons through UpdateItems (item moved, split,
-- sorted). Repaint straight after so a dot never lingers on a moved item.
local function hookBlizzardUpdates()
  for _, frame in ipairs(blizzardFrames()) do
    if frame.UpdateItems then
      hooksecurefunc(frame, "UpdateItems", paintFrame)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Adapter 2: Baganator
-- ---------------------------------------------------------------------------
local function initBaganator()
  if not Baganator or not Baganator.API or not Baganator.API.RegisterCornerWidget then
    return false
  end

  -- onUpdate: called by Baganator whenever an item button is refreshed.
  -- details.itemLocation contains the bagID and slotIndex.
  local function onUpdate(dot, details)
    if not details.itemLocation then return false end

    local bagID = details.itemLocation.bagID
    local slotID = details.itemLocation.slotIndex

    if not bagID or not slotID then return false end

    local result = Bagwise.Scanner.GetResult(bagID, slotID)
    return applyDot(dot, result)
  end

  -- onInit: called once per item button to create the widget.
  -- Baganator will parent and position the returned frame.
  local function onInit(itemButton)
    local dot = makeDot(itemButton)
    -- Baganator handles the anchoring, so no SetPoint is needed here.
    return dot
  end

  -- RegisterCornerWidget(label, id, onUpdate, onInit, defaultPosition, isFast)
  local ok, err = pcall(
    Baganator.API.RegisterCornerWidget,
    "Bagwise", "bagwise", onUpdate, onInit,
    { corner = "top_right", priority = 1 }, true
  )

  if not ok then
    print("|cff66bb6a[Bagwise]|r Baganator corner widget registration failed: " .. tostring(err))
  end

  return ok
end

-- ---------------------------------------------------------------------------
-- Adapter 3: EllesmereUI Bags
-- ---------------------------------------------------------------------------
-- A bag replacement with no plugin API. Its slots are item-template buttons
-- kept in a pool, and each button's parent frame carries the bag ID, the same
-- as Blizzard's. The pool is read from the module's internals, which are
-- underscore-private: if the author renames them the dots stop and nothing
-- else breaks. RefreshInventory is the window's own repaint, so hook it.
local function ellesmereSlotPool()
  local modules = EllesmereUI and EllesmereUI._ModuleNS
  local bags = modules and modules["EllesmereUIBags"]
  local internals = bags and bags._bagsInternals
  return internals and internals.itemSlots
end

local function paintEllesmere()
  local pool = ellesmereSlotPool()
  if not pool then return end

  for _, button in pairs(pool) do
    if type(button) == "table" and button.IsVisible and button:IsVisible() then
      paintButton(button, bagIDOf(button), button:GetID())
    end
  end
end

local function hookEllesmereUpdates()
  if EUI_Bags and EUI_Bags.RefreshInventory then
    hooksecurefunc(EUI_Bags, "RefreshInventory", paintEllesmere)
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Every window that shows scanned bags and should trigger a rescan on open.
-- The entry point hooks OnShow on these.
function Bagwise.Overlay.BagWindows()
  local windows = blizzardFrames()
  if EUI_Bags then windows[#windows + 1] = EUI_Bags end
  return windows
end

--- Which bag UIs Bagwise can currently paint (for /bagwise status).
-- @return table  list of names
function Bagwise.Overlay.DetectedBagAddons()
  local found = {}
  if ContainerFrameCombinedBags then found[#found + 1] = "Blizzard combined bags" end
  if ContainerFrame1 then found[#found + 1] = "Blizzard separate bags" end
  if Baganator and Baganator.API and Baganator.API.RegisterCornerWidget then
    found[#found + 1] = "Baganator"
  end
  if ellesmereSlotPool() then found[#found + 1] = "EllesmereUI Bags" end
  return found
end

function Bagwise.Overlay.Init()
  if not initBaganator() then
    -- If Baganator isn't loaded yet, wait for its ADDON_LOADED event.
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
      if addonName == "Baganator" then
        initBaganator()
        self:UnregisterEvent("ADDON_LOADED")
      end
    end)
  end

  hookBlizzardUpdates()
  hookEllesmereUpdates()
end

function Bagwise.Overlay.UpdateAll()
  updateBlizzard()
  paintEllesmere()
  -- Baganator handles its own updates natively.
end
