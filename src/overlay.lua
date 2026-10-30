-- Bagwise: dot overlay
-- Creates small colored corner dots on bag slot frames.
-- Each dot is a Texture attached to a bag slot button.

Bagwise = Bagwise or {}
Bagwise.Overlay = {}

-- Dot colors (RGBA, 0-1)
local COLORS = {
  green  = { 0.4, 0.73, 0.42, 1 },   -- #66bb6a
  yellow = { 0.95, 0.8, 0.25, 1 },   -- #f2cc40
}

-- Dot size in pixels
local DOT_SIZE = 8

-- Where to put the dot on the icon
local DOT_CORNER = "TOPRIGHT"

-- Offset from the corner (negative = inward)
local DOT_OFFSET_X = -2
local DOT_OFFSET_Y = -2

-- ContainerFrame pool size in Classic Era.
-- Frames are shared across player bags and bank bags.
-- WoW assigns whichever frame is free, so we must check them all.
local MAX_FRAMES = NUM_CONTAINER_FRAMES or 13

--- Get or create a dot texture on a bag slot button.
-- @param button  Frame  The bag slot button frame
-- @return Texture  The dot texture (reused if already created)
local function getDot(button)
  -- If we already created a dot on this button, reuse it
  if button.BagwiseDot then
    return button.BagwiseDot
  end

  -- Create a new texture as a child of the button
  local dot = button:CreateTexture(nil, "OVERLAY")
  dot:SetSize(DOT_SIZE, DOT_SIZE)
  dot:SetPoint(DOT_CORNER, button, DOT_CORNER, DOT_OFFSET_X, DOT_OFFSET_Y)

  -- SetColorTexture creates a solid-color square with no file dependency.
  -- Guaranteed to work in every client version. We set the actual color
  -- in UpdateAll, so use white here as a base.
  dot:SetColorTexture(1, 1, 1, 1)

  -- Store it on the button so we can find it next time
  button.BagwiseDot = dot

  return dot
end

--- Update all dots on all open bag frames.
-- Called after Scanner.ScanAll() has refreshed the results.
function Bagwise.Overlay.UpdateAll()
  -- ContainerFrame numbering is dynamic: WoW assigns whichever frame
  -- is free when a bag opens. We check all frames and read bagID from
  -- each with GetID(), rather than assuming frame N = bag N.
  for frameIndex = 1, MAX_FRAMES do
    local frameName = "ContainerFrame" .. frameIndex
    local frame = _G[frameName]

    -- Frame might not exist or might not be visible (bag not open)
    if frame and frame:IsShown() then
      local bagID = frame:GetID()

      -- Only paint dots on player bags (0-4), not bank bags
      if bagID >= 0 and bagID <= 4 then
        local numSlots = C_Container.GetContainerNumSlots(bagID)

        for buttonIndex = 1, numSlots do
          local buttonName = frameName .. "Item" .. buttonIndex
          local button = _G[buttonName]

          if button then
            -- IMPORTANT: button:GetID() returns the actual
            -- container slot. Button naming is reversed:
            -- Item1 = last slot, ItemN = slot 1.
            local slotID = button:GetID()
            local result = Bagwise.Scanner.GetResult(bagID, slotID)
            local dot = getDot(button)

            if result and result.verdict then
              local color = COLORS[result.verdict]
              dot:SetColorTexture(color[1], color[2], color[3], color[4])
              dot:Show()
            else
              dot:Hide()
            end
          end
        end
      end
    end
  end
end

--- Hide all dots on every frame that has them.
function Bagwise.Overlay.HideAll()
  for frameIndex = 1, MAX_FRAMES do
    local frameName = "ContainerFrame" .. frameIndex
    local frame = _G[frameName]
    if frame then
      local numSlots = C_Container.GetContainerNumSlots(frame:GetID())
      for buttonIndex = 1, numSlots do
        local button = _G[frameName .. "Item" .. buttonIndex]
        if button and button.BagwiseDot then
          button.BagwiseDot:Hide()
        end
      end
    end
  end
end
