-- Bagwise: tooltip enrichment
-- Appends reagent-profession info and verdict reasons to the item
-- tooltip on hover.
--
-- Default: compact one-liner listing profession names.
-- Shift held: per-profession breakdown with skill ranges.
--
-- Listens to MODIFIER_STATE_CHANGED so pressing/releasing shift while
-- a bag tooltip is open instantly rebuilds it (no re-hover needed).

Bagwise = Bagwise or {}
Bagwise.Tooltip = {}

-- Light blue for reagent info lines
local INFO_R, INFO_G, INFO_B = 0.5, 0.8, 1.0

-- Track which bag/slot the current tooltip is showing so we can
-- rebuild it on modifier key change without re-hovering.
local currentBag, currentSlot

--- Sort entries so the player's own professions appear first.
-- Falls back to original order when scanner state is unavailable.
-- @param entries  table  Array of { profession, count, minSkill, maxSkill }
-- @return table  Sorted copy (or the same table if no reorder needed)
local function sortedByPlayerProf(entries)
  local myProfs = Bagwise.Scanner and Bagwise.Scanner.professionNames
  if not myProfs then return entries end
  local mine, other = {}, {}
  for i = 1, #entries do
    if myProfs[entries[i][1]] then
      mine[#mine + 1] = entries[i]
    else
      other[#other + 1] = entries[i]
    end
  end
  if #mine == 0 then return entries end
  for i = 1, #other do
    mine[#mine + 1] = other[i]
  end
  return mine
end

--- Build the compact reagent line.
-- Single: "Alchemy reagent (1-50)"   -- range shown
-- Multi:  "Alchemy, Tailoring reagent" -- range omitted (shift reveals per-prof)
-- Player's professions are listed first.
-- @param entries  table  Array of { profession, count, minSkill, maxSkill }
-- @return string
local function compactLine(entries)
  local sorted = sortedByPlayerProf(entries)
  local names = {}
  for i = 1, #sorted do
    names[#names + 1] = sorted[i][1]
  end
  local text = table.concat(names, ", ") .. " reagent"
  if #sorted == 1 then
    local e = sorted[1]
    local range = e[3] == e[4] and tostring(e[3]) or (e[3] .. "-" .. e[4])
    text = text .. " (" .. range .. ")"
  end
  return text
end

--- Hook handler for GameTooltip:OnTooltipSetItem.
-- Called every time a tooltip is populated for an item.
function Bagwise.Tooltip.OnTooltipSetItem(tooltip)
  local _, link = tooltip:GetItem()
  if not link then return end

  local itemID = tonumber(link:match("item:(%d+)"))
  if not itemID then return end

  local expanded = IsShiftKeyDown and IsShiftKeyDown()

  -- Detect bag tooltip and look up verdict.
  local verdict, reason
  local isBagItem = false
  local owner = tooltip:GetOwner()
  if owner and owner:GetParent() then
    local parentName = owner:GetParent():GetName()
    if parentName and parentName:match("^ContainerFrame%d+$") then
      isBagItem = true
      local bag = owner:GetParent():GetID()
      local slot = owner:GetID()
      -- Track for MODIFIER_STATE_CHANGED refresh
      currentBag = bag
      currentSlot = slot
      local result = Bagwise.Scanner.GetResult(bag, slot)
      if result then
        verdict = result.verdict
        reason = result.reason
      end
    end
  end

  -- Pick line color: verdict color when verdict fires, blue otherwise
  local lineR, lineG, lineB = INFO_R, INFO_G, INFO_B
  local isReagentVerdict = false
  if verdict == "green" and reason and reason:find("vendor") then
    lineR, lineG, lineB = 0.4, 0.9, 0.4
    isReagentVerdict = true
  elseif verdict == "yellow" and reason and reason:find("reagent") then
    lineR, lineG, lineB = 1.0, 0.9, 0.3
    isReagentVerdict = true
  end

  -- Reagent-profession enrichment
  -- The text is always the same regardless of verdict; only the color
  -- changes. For reagent verdicts the info line IS the verdict line,
  -- so we skip the separate verdict output below.
  local profEntries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[itemID]
  local showHint = false
  if profEntries then
    local isMulti = #profEntries > 1
    local isVendorReagent = Bagwise.Data.VendorReagents
        and Bagwise.Data.VendorReagents[itemID]
    -- Vendor reagents: no shift-expand (skill range irrelevant).
    -- Non-vendor multi-prof: expandable with shift.
    local canExpand = isMulti and not isVendorReagent
    if expanded and canExpand then
      -- Per-profession with individual skill ranges
      local sorted = sortedByPlayerProf(profEntries)
      for i = 1, #sorted do
        local e = sorted[i]
        local range
        if e[3] == e[4] then
          range = tostring(e[3])
        else
          range = e[3] .. "-" .. e[4]
        end
        tooltip:AddLine(
          e[1] .. " reagent (" .. range .. ")",
          lineR, lineG, lineB)
      end
    elseif isVendorReagent then
      -- Vendor format: "Prof reagent (vendor)"
      local sorted = sortedByPlayerProf(profEntries)
      local names = {}
      for i = 1, #sorted do
        names[#names + 1] = sorted[i][1]
      end
      tooltip:AddLine(
        table.concat(names, ", ") .. " reagent (vendor)",
        lineR, lineG, lineB)
    else
      -- Reagent format: range on single, names only on multi
      tooltip:AddLine(compactLine(profEntries), lineR, lineG, lineB)
    end
    -- Show hint only for expandable multi-prof items
    if canExpand and not expanded then
      showHint = true
    end
  end

  -- Verdict reason line (non-reagent verdicts only)
  if reason and not isReagentVerdict then
    local r, g, b = 0.4, 0.9, 0.4     -- green
    if verdict == "yellow" then
      r, g, b = 1.0, 0.9, 0.3
    end
    tooltip:AddLine(reason, r, g, b)
  end

  -- "Hold Shift" hint at bottom of Bagwise's tooltip section
  if showHint then
    tooltip:AddLine("Hold Shift for details", 0.5, 0.5, 0.5)
  end

  tooltip:Show()
end

--- Refresh the tooltip when shift is pressed or released.
-- Calls SetBagItem to re-trigger OnTooltipSetItem with the new
-- modifier state, so the expanded/compact view updates instantly.
local function onModifierStateChanged(key)
  if key ~= "LSHIFT" and key ~= "RSHIFT" then return end
  if not currentBag or not currentSlot then return end
  if not GameTooltip:IsShown() then
    currentBag = nil
    currentSlot = nil
    return
  end
  GameTooltip:SetBagItem(currentBag, currentSlot)
end

--- Clear tracked slot when the tooltip hides.
local function onTooltipCleared()
  currentBag = nil
  currentSlot = nil
end

--- Register hooks and events. Called once from Bagwise.lua on PLAYER_LOGIN.
function Bagwise.Tooltip.Init()
  GameTooltip:HookScript("OnTooltipSetItem",
    Bagwise.Tooltip.OnTooltipSetItem)
  GameTooltip:HookScript("OnTooltipCleared", onTooltipCleared)

  -- Frame to listen for modifier key changes
  local f = CreateFrame("Frame")
  f:RegisterEvent("MODIFIER_STATE_CHANGED")
  f:SetScript("OnEvent", function(self, event, key, state)
    onModifierStateChanged(key)
  end)
end
