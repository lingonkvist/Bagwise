-- Bagwise: tooltip enrichment
-- Adds a single verdict line or reagent detail rows.
-- Color carries the verdict; the reason carries the fact.

Bagwise = Bagwise or {}
Bagwise.Tooltip = {}

local INFO = { r = 0.5, g = 0.8, b = 1.0 }

local VERDICT_COLORS = {
  green  = { r = 0.4, g = 0.9, b = 0.4 },
  yellow = { r = 1.0, g = 0.9, b = 0.3 },
}

local SECONDARY_PROFESSIONS = {
  Cooking = true,
  ["First Aid"] = true,
  Fishing = true,
}

local FALLBACK_LIMIT = 2

local getBagName = (C_Container and C_Container.GetBagName) or GetBagName

local function skillRange(entry)
  return entry[3] == entry[4] and tostring(entry[3])
      or (entry[3] .. "-" .. entry[4])
end

local function playerProfessionsFrom(entries, myProfs)
  local main, secondary = {}, {}
  for i = 1, #entries do
    local entry = entries[i]
    if myProfs[entry[1]] then
      local bucket = SECONDARY_PROFESSIONS[entry[1]] and secondary or main
      bucket[#bucket + 1] = entry
    end
  end
  local result = {}
  for i = 1, #main do result[#result + 1] = main[i] end
  for i = 1, #secondary do result[#result + 1] = secondary[i] end
  return result
end

local function widestRangesFirst(entries)
  local copy = {}
  for i = 1, #entries do copy[i] = entries[i] end
  table.sort(copy, function(a, b)
    local rangeA, rangeB = a[4] - a[3], b[4] - b[3]
    if rangeA ~= rangeB then return rangeA > rangeB end
    if a[4] ~= b[4] then return a[4] > b[4] end
    return a[2] > b[2]
  end)
  return copy
end

local function bagSlotOf(tooltip)
  local owner = tooltip:GetOwner()
  if not (owner and owner.GetParent and owner.GetID) then return nil end

  local parent = owner:GetParent()
  if not (parent and parent.GetID) then return nil end

  local slotID = owner:GetID()
  local bagID = parent:GetID()
  if not slotID or not bagID then return nil end

  if parent.GetName then
    local parentName = parent:GetName()
    if parentName and parentName:match("^ContainerFrame%d+$") then
      return bagID, slotID
    end
  end

  if owner.BGR then
    return bagID, slotID
  end

  if not getBagName or not getBagName(bagID) then return nil end
  if not (C_Container and C_Container.GetContainerItemInfo) then return nil end

  local _, link = tooltip:GetItem()
  if not link then return nil end
  local tooltipItemID = tonumber(link:match("item:(%d+)"))
  if not tooltipItemID then return nil end

  local containerInfo = C_Container.GetContainerItemInfo(bagID, slotID)
  if not containerInfo or containerInfo.itemID ~= tooltipItemID then
    return nil
  end

  return bagID, slotID
end

local function bagSlotVerdict(tooltip)
  local bag, slot = bagSlotOf(tooltip)
  if not bag then return nil end
  return Bagwise.Scanner.GetResult(bag, slot)
end

-- Format: Profession (Range)  OR  Profession (Range) +N
local function addInfoLine(tooltip, left, right, suffix)
  local text = left .. " (" .. right .. ")"
  if suffix then
    text = text .. " " .. suffix
  end
  tooltip:AddLine(text, INFO.r, INFO.g, INFO.b)
end

local function renderProfessionDetails(tooltip, profEntries)
  local myProfs = Bagwise.Scanner and Bagwise.Scanner.professionNames
  local playerEntries = myProfs
      and playerProfessionsFrom(profEntries, myProfs) or {}

  if #playerEntries > 0 then
    for i = 1, #playerEntries do
      addInfoLine(tooltip, playerEntries[i][1], skillRange(playerEntries[i]))
    end
    return
  end

  local sorted = widestRangesFirst(profEntries)
  local count = math.min(#sorted, FALLBACK_LIMIT)
  for i = 1, count do
    local suffix
    if i == count and #sorted > count then
      suffix = "+" .. (#sorted - count)
    end
    addInfoLine(tooltip, sorted[i][1], skillRange(sorted[i]), suffix)
  end
end

local function renderVerdict(tooltip, verdict, reason)
  local color = VERDICT_COLORS[verdict]
  tooltip:AddLine(reason, color.r, color.g, color.b)
end

function Bagwise.Tooltip.OnTooltipSetItem(tooltip)
  local _, link = tooltip:GetItem()
  if not link then return end

  local itemID = tonumber(link:match("item:(%d+)"))
  if not itemID then return end

  local result = bagSlotVerdict(tooltip)
  local verdict = result and result.verdict
  local reason = result and result.reason

  local profEntries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[itemID]

  if not verdict and not profEntries then
    tooltip:Show()
    return
  end

  if verdict then
    renderVerdict(tooltip, verdict, reason)
  end

  if not verdict and profEntries then
    renderProfessionDetails(tooltip, profEntries)
  end

  tooltip:Show()
end

function Bagwise.Tooltip.Init()
  GameTooltip:HookScript("OnTooltipSetItem",
    Bagwise.Tooltip.OnTooltipSetItem)
end
