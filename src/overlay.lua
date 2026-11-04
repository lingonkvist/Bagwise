-- Bagwise: dot overlay
-- Blizzard ContainerFrames + Baganator corner widgets.

Bagwise = Bagwise or {}
Bagwise.Overlay = {}

local COLORS = {
  green  = { 0.56, 0.87, 0.56, 1 },
  yellow = { 1.0, 0.84, 0.28, 1 },
}

local DOT_SIZE = 12

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

-- ---------------------------------------------------------------------------
-- Adapter 1: Blizzard ContainerFrames
-- ---------------------------------------------------------------------------
local MAX_FRAMES = NUM_CONTAINER_FRAMES or 13

local function getBlizzardDot(button)
  if button.BagwiseDot then return button.BagwiseDot end
  local dot = makeDot(button)
  dot:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
  button.BagwiseDot = dot
  return dot
end

local function updateBlizzard()
  for frameIndex = 1, MAX_FRAMES do
    local frameName = "ContainerFrame" .. frameIndex
    local frame = _G[frameName]

    if frame and frame:IsShown() then
      local bagID = frame:GetID()

      if bagID and bagID >= 0 and bagID <= 4 then
        local numSlots = C_Container.GetContainerNumSlots(bagID)

        for buttonIndex = 1, numSlots do
          local button = _G[frameName .. "Item" .. buttonIndex]
          if button then
            -- Classic Era reverses button order; slot 1 is the last button.
            local slotID = numSlots - buttonIndex + 1
            local result = Bagwise.Scanner.GetResult(bagID, slotID)
            applyDot(getBlizzardDot(button), result)
          end
        end
      end
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
-- Adapter 3: Generic fallback for other bag addons
-- ---------------------------------------------------------------------------
-- If another bag addon exposes item buttons via a global frame name pattern,
-- you can hook those here. For now, EllesmereUI and others will get tooltip
-- context only until they expose a per-item widget API.
local function initGeneric()
  -- Intentionally left as a hook point for future adapters.
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
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

  initGeneric()
end

function Bagwise.Overlay.UpdateAll()
  updateBlizzard()
  -- Baganator handles its own updates natively.
end

function Bagwise.Overlay.HideAll()
  for frameIndex = 1, MAX_FRAMES do
    local frame = _G["ContainerFrame" .. frameIndex]
    if frame then
      local numSlots = C_Container.GetContainerNumSlots(frame:GetID())
      for buttonIndex = 1, numSlots do
        local button = _G["ContainerFrame" .. frameIndex .. "Item" .. buttonIndex]
        if button and button.BagwiseDot then
          button.BagwiseDot:Hide()
        end
      end
    end
  end
end
