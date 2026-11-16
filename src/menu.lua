-- MakeSpace: the item menu (alt-right-click an item in your bags)
-- One choice per item. The rows are worked out by Rows() from the dot the item
-- would get on its own and the mark it carries; the frame below only draws them.

MakeSpace = MakeSpace or {}
MakeSpace.Menu = {}

local LABELS = { green = "Safe to delete", yellow = "Worth a glance", none = "No dot" }

--- The rows of the menu: "Default" first, then the marks that would change
-- something. The mark that equals what the item gets by default is left out,
-- so "Default (safe to delete)" and "Safe to delete" never sit side by side,
-- and "No dot" only shows where there is a dot to hide. The row you have
-- chosen is always there.
-- @param defaultVerdict string|nil  "green", "yellow" or nil: the dot with no mark
-- @param mark string|nil            the item's mark: "green", "yellow", "none" or nil
-- @return table list of { label, mark, icon, checked }; mark nil means "Default"
function MakeSpace.Menu.Rows(defaultVerdict, mark)
  local rows = {
    { label = "Default (" .. (defaultVerdict and LABELS[defaultVerdict]:lower() or "no dot") .. ")",
      mark = nil, icon = defaultVerdict, checked = mark == nil },
  }
  local sameAsDefault = defaultVerdict or "none"
  for _, choice in ipairs({ "green", "yellow", "none" }) do
    local checked = mark == choice
    if choice ~= sameAsDefault or checked then
      rows[#rows + 1] = {
        label = LABELS[choice], mark = choice,
        icon = (choice ~= "none") and choice or nil, checked = checked,
      }
    end
  end
  return rows
end

-- ---------------------------------------------------------------------------
-- The frame. Plain frames and textures only, so it does not depend on which
-- menu system the client has. Not covered by the tests: confirmed in game.
-- ---------------------------------------------------------------------------
local ROW_HEIGHT = 22
local MENU_WIDTH = 210
local TITLE_HEIGHT = 21 -- the title and its divider, above the rows
-- The fonts. Frames hang off UIParent, so the menu follows the UI scale setting.
local TEXT_FONT, TITLE_FONT = "GameFontHighlight", "GameFontNormal"
-- The font sizes, between the game's small and normal. The game's fonts come
-- in fixed steps, so the size is set on the text itself.
local TEXT_SIZE, TITLE_SIZE = 11, 11

local function setSize(text, size)
  local path, _, flags = text:GetFont()
  if path then text:SetFont(path, size, flags) end
end
local PADDING = 8
local ICON_TEXTURES = {
  green  = "Interface\\AddOns\\MakeSpace\\textures\\pearl_green",
  yellow = "Interface\\AddOns\\MakeSpace\\textures\\pearl_yellow",
}
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- The look: flat near-black panel, a thin warm grey border, a gold title and
-- soft gold under the cursor, like the context menus of the current client.
-- Every color of the menu is in this table.
local COLORS = {
  background = { 0.05, 0.05, 0.06, 0.96 },
  border     = { 0.30, 0.27, 0.20, 1 },
  divider    = { 0.30, 0.27, 0.20, 0.8 },
  hover      = { 1, 0.82, 0, 0.14 },
  selected   = { 1, 0.82, 0, 0.22 },
  selectedText = { 1, 0.82, 0 },
  text       = { 1, 1, 1 },
}

local menu, catcher
local rowFrames = {}

local function close()
  if menu then menu:Hide() end
end

local function makeRow(index)
  local row = CreateFrame("Button", nil, menu)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING, -(PADDING + TITLE_HEIGHT + (index - 1) * ROW_HEIGHT))
  row:SetPoint("RIGHT", menu, "RIGHT", -PADDING, 0)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetTexture(WHITE)
  highlight:SetVertexColor(unpack(COLORS.hover))
  -- The chosen row stays tinted; no bullet.
  row.selected = row:CreateTexture(nil, "BACKGROUND")
  row.selected:SetAllPoints()
  row.selected:SetTexture(WHITE)
  row.selected:SetVertexColor(unpack(COLORS.selected))
  row.icon = row:CreateTexture(nil, "OVERLAY")
  row.icon:SetSize(15, 15)
  row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
  row.text = row:CreateFontString(nil, "OVERLAY", TEXT_FONT)
  setSize(row.text, TEXT_SIZE)
  row.text:SetPoint("LEFT", row, "LEFT", 28, 0)
  return row
end

local function build()
  catcher = CreateFrame("Frame", nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata("FULLSCREEN_DIALOG")
  catcher:EnableMouse(true)
  catcher:SetScript("OnMouseDown", close)
  catcher:Hide()

  menu = CreateFrame("Frame", "MakeSpaceItemMenu", UIParent)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetFrameLevel(10)
  menu:SetClampedToScreen(true)
  menu:EnableMouse(true)
  local background = menu:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetTexture(WHITE)
  background:SetVertexColor(unpack(COLORS.background))
  local edge = menu:CreateTexture(nil, "BACKGROUND", nil, -1)
  edge:SetPoint("TOPLEFT", -1, 1)
  edge:SetPoint("BOTTOMRIGHT", 1, -1)
  edge:SetTexture(WHITE)
  edge:SetVertexColor(unpack(COLORS.border))
  local divider = menu:CreateTexture(nil, "ARTWORK")
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING, -(PADDING + TITLE_HEIGHT - 4))
  divider:SetPoint("RIGHT", menu, "RIGHT", -PADDING, 0)
  divider:SetTexture(WHITE)
  divider:SetVertexColor(unpack(COLORS.divider))
  menu.title = menu:CreateFontString(nil, "OVERLAY", TITLE_FONT)
  setSize(menu.title, TITLE_SIZE)
  menu.title:SetPoint("TOPLEFT", menu, "TOPLEFT", PADDING, -PADDING)
  menu.title:SetPoint("RIGHT", menu, "RIGHT", -PADDING, 0)
  menu.title:SetJustifyH("LEFT")
  menu.title:SetWordWrap(false)
  menu:SetScript("OnHide", function() catcher:Hide() end)
  -- Escape closes it, like any other window.
  if UISpecialFrames then tinsert(UISpecialFrames, "MakeSpaceItemMenu") end
  menu:Hide()
end

--- Open the menu next to the cursor for the item in this bag slot.
function MakeSpace.Menu.Open(bagID, slotID)
  if InCombatLockdown and InCombatLockdown() then return end
  local itemID = C_Container.GetContainerItemID(bagID, slotID)
  if not itemID then return end
  if not menu then build() end

  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local itemName = getInfo and getInfo(itemID) or nil
  local name = itemName or ("item " .. itemID)
  local rows = MakeSpace.Menu.Rows(MakeSpace.Scanner.DefaultVerdict(bagID, slotID),
      MakeSpace.Overrides.Get(itemID))

  menu.title:SetText(name)
  for index, row in ipairs(rows) do
    local frame = rowFrames[index] or makeRow(index)
    rowFrames[index] = frame
    frame.selected:SetShown(row.checked)
    frame.text:SetTextColor(unpack(row.checked and COLORS.selectedText or COLORS.text))
    if row.icon then
      frame.icon:SetTexture(ICON_TEXTURES[row.icon])
      frame.icon:Show()
    else
      frame.icon:Hide()
    end
    frame.text:SetText(row.label)
    frame:SetScript("OnClick", function()
      MakeSpace.Overrides.Set(itemID, row.mark, itemName)
      close()
      MakeSpace.Scanner.ClearCache()
      MakeSpace.Scanner.ScanAll()
      MakeSpace.Overlay.UpdateAll()
    end)
    frame:Show()
  end
  for index = #rows + 1, #rowFrames do rowFrames[index]:Hide() end

  menu:SetSize(MENU_WIDTH, PADDING * 2 + TITLE_HEIGHT + #rows * ROW_HEIGHT)
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 4, y / scale - 4)
  catcher:Show()
  menu:Show()
end
