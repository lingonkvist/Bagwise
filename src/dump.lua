-- Bagwise: inventory dump
-- Turns a scanner snapshot into plain text a person can copy out of the
-- game and paste somewhere else (for testing rules against real inventories).
-- Format() is pure; Show() builds the copy window.

Bagwise = Bagwise or {}
Bagwise.Dump = {}

local COLUMNS = {
  "bag", "slot", "id", "name", "count", "maxStack", "quality", "ilvl", "reqLvl",
  "class", "subclass", "equipSlot", "bind", "bound", "sellCopper",
  "verdict", "reason", "kept", "flagged",
  "recipeProfs", "quests", "startsQuest", "vendorReagent", "classReagent",
  "wornQualityIlvl", "lootable",
}

-- The column separator. Not a pipe: the game treats "|" as the start of an
-- escape code, and a pipe-heavy text in an edit box shows up blank.
local SEPARATOR = ";"

local function cell(value)
  if value == nil then return "" end
  if value == true then return "1" end
  if value == false then return "0" end
  -- The separator can't appear inside a cell, and a stray pipe would be read
  -- as an escape code by the edit box.
  return (tostring(value):gsub("[;|]", "/"))
end

local function questCell(quests)
  local parts = {}
  for _, quest in ipairs(quests or {}) do
    parts[#parts + 1] = quest.id .. (quest.done and ":done" or ":open")
        .. (quest.faction and (":" .. quest.faction) or "")
  end
  return table.concat(parts, ",")
end

local function startsQuestCell(row)
  if not row.startsQuestID then return "" end
  return row.startsQuestID .. (row.startsQuestDone and ":done" or ":open")
end

local function wornCell(worn)
  local parts = {}
  for _, slot in ipairs(worn or {}) do
    parts[#parts + 1] = slot.quality .. "/" .. slot.itemLevel
  end
  return table.concat(parts, ",")
end

local function rowCells(row)
  return {
    cell(row.bag), cell(row.slot), cell(row.id), cell(row.name),
    cell(row.count), cell(row.maxStack), cell(row.quality),
    cell(row.itemLevel), cell(row.reqLevel),
    cell(row.classID), cell(row.subClassID), cell(row.equipSlot),
    cell(row.bindType), cell(row.isBound), cell(row.sellPrice),
    cell(row.verdict), cell(row.reason), cell(row.isKept), cell(row.isFlagged),
    cell(table.concat(row.recipeProfessions or {}, ",")),
    questCell(row.quests), startsQuestCell(row),
    cell(row.isVendorReagent), cell(row.isClassReagent),
    wornCell(row.equippedInSlots), cell(row.lootable),
  }
end

--- Render a snapshot as text: a few header lines, then one pipe-separated
-- row per item.
-- @param snapshot table  from Bagwise.Scanner.CollectInventory()
-- @param context  table  { version = "...", build = "...", extra = { "key=value", ... } }
--                         extra lines go in the header, for bug reports
-- @return string
function Bagwise.Dump.Format(snapshot, context)
  context = context or {}
  local player = snapshot.player or {}
  local lines = {
    "# Bagwise inventory dump",
    "# bagwise=" .. cell(context.version) .. " wow=" .. cell(context.build),
    "# class=" .. cell(player.class) .. " race=" .. cell(player.race)
        .. " faction=" .. cell(player.faction) .. " level=" .. cell(player.level),
    "# professions=" .. table.concat(player.professions or {}, ","),
    "# columns: " .. table.concat(COLUMNS, SEPARATOR),
  }

  -- Extra header lines (bag UI, safety checks, make-room state) go after the
  -- player lines and before the columns line.
  for i, extra in ipairs(context.extra or {}) do
    table.insert(lines, 4 + i, "# " .. cell(extra))
  end

  for _, row in ipairs(snapshot.rows) do
    lines[#lines + 1] = table.concat(rowCells(row), SEPARATOR)
  end

  lines[#lines + 1] = "# " .. #snapshot.rows .. " items"
      .. ((snapshot.uncached or 0) > 0
        and (", " .. snapshot.uncached .. " not cached yet (name and stats empty; run again)")
        or "")
  return table.concat(lines, "\n")
end

local frame
local editBox

local function buildFrame()
  frame = CreateFrame("Frame", "BagwiseDumpFrame", UIParent, "BackdropTemplate")
  frame:SetSize(640, 420)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 20, -16)
  title:SetText("Bagwise inventory dump: Ctrl+C to copy, Esc to close")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  local scroll = CreateFrame("ScrollFrame", "BagwiseDumpScroll", frame,
    "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 18, -42)
  scroll:SetPoint("BOTTOMRIGHT", -36, 16)

  editBox = CreateFrame("EditBox", nil, scroll)
  editBox:SetMultiLine(true)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetWidth(580)
  -- A multiline edit box inside a scroll frame needs a starting height or it
  -- can stay invisible, and a cap on length would cut a big inventory short.
  editBox:SetHeight(400)
  if editBox.SetMaxLetters then editBox:SetMaxLetters(0) end
  if editBox.SetMaxBytes then editBox:SetMaxBytes(0) end
  editBox:SetAutoFocus(false)
  editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
  scroll:SetScrollChild(editBox)

  -- Esc closes the window like other dialogs.
  tinsert(UISpecialFrames, "BagwiseDumpFrame")
end

--- Show text in a selectable window.
function Bagwise.Dump.Show(text)
  if not frame then buildFrame() end
  -- Belt and braces: show any remaining pipe literally.
  editBox:SetText((text:gsub("|", "||")))
  frame:Show()
  editBox:SetFocus()
  editBox:HighlightText()
end
