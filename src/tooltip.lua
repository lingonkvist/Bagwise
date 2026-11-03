-- Bagwise: tooltip enrichment
-- Adds a single verdict line or clean profession icon rows.

Bagwise                     = Bagwise or {}
Bagwise.Tooltip             = {}

local INFO_COLOR            = { r = 0.5, g = 0.8, b = 1.0 }

-- Profession entry field indices (data/reagent_professions.lua is generated,
-- so we name the positions here instead of restructuring the dataset).
local PROF_NAME             = 1
local PROF_RECIPE_COUNT     = 2
local PROF_MIN_LEVEL        = 3
local PROF_MAX_LEVEL        = 4

local VERDICT_COLORS        = {
  green  = { r = 0.4, g = 0.9, b = 0.4 },
  yellow = { r = 1.0, g = 0.9, b = 0.3 },
}

local PROFESSION_ICONS      = {
  ["Alchemy"] = 136240,
  ["Blacksmithing"] = 136241,
  ["Cooking"] = 133971,
  ["Enchanting"] = 136244,
  ["Engineering"] = 136243,
  ["First Aid"] = 135966,
  ["Fishing"] = 136245,
  ["Herbalism"] = 136246,
  ["Leatherworking"] = 136247,
  ["Mining"] = 136248,
  ["Skinning"] = 134366,
  ["Tailoring"] = 136249,
}

local SECONDARY_PROFESSIONS = {
  Cooking = true,
  ["First Aid"] = true,
  Fishing = true,
}

local FALLBACK_LIMIT        = 2

local getBagName            = (C_Container and C_Container.GetBagName) or GetBagName

local function skillRange(entry)
  return entry[PROF_MIN_LEVEL] == entry[PROF_MAX_LEVEL]
      and tostring(entry[PROF_MIN_LEVEL])
      or (entry[PROF_MIN_LEVEL] .. "-" .. entry[PROF_MAX_LEVEL])
end

local function playerProfessionsFrom(entries, myProfs)
  local main, secondary = {}, {}
  for i = 1, #entries do
    local entry = entries[i]
    if myProfs[entry[PROF_NAME]] then
      local bucket = SECONDARY_PROFESSIONS[entry[PROF_NAME]] and secondary or main
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
    local rangeA = a[PROF_MAX_LEVEL] - a[PROF_MIN_LEVEL]
    local rangeB = b[PROF_MAX_LEVEL] - b[PROF_MIN_LEVEL]
    if rangeA ~= rangeB then return rangeA > rangeB end
    if a[PROF_MAX_LEVEL] ~= b[PROF_MAX_LEVEL] then
      return a[PROF_MAX_LEVEL] > b[PROF_MAX_LEVEL]
    end
    return a[PROF_RECIPE_COUNT] > b[PROF_RECIPE_COUNT]
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

local function renderProfessionDetails(tooltip, profEntries)
  local myProfs = Bagwise.Scanner and Bagwise.Scanner.professionNames
  local playerEntries = myProfs
      and playerProfessionsFrom(profEntries, myProfs) or {}

  local entriesToShow = {}
  local suffix = nil

  if #playerEntries > 0 then
    for i = 1, #playerEntries do
      entriesToShow[i] = playerEntries[i]
    end
  else
    local sorted = widestRangesFirst(profEntries)
    local count = math.min(#sorted, FALLBACK_LIMIT)
    for i = 1, count do
      entriesToShow[i] = sorted[i]
    end
    if #sorted > count then
      suffix = "+" .. (#sorted - count)
    end
  end

  for i = 1, #entriesToShow do
    local entry = entriesToShow[i]
    local icon = PROFESSION_ICONS[entry[PROF_NAME]]
    local iconStr = icon and ("|T" .. icon .. ":16:16|t ") or ""

    local text = iconStr .. entry[PROF_NAME] .. " (" .. skillRange(entry) .. ")"

    if i == #entriesToShow and suffix then
      text = text .. " " .. suffix
    end

    tooltip:AddLine(text, INFO_COLOR.r, INFO_COLOR.g, INFO_COLOR.b)
  end
end

local function renderVerdict(tooltip, verdict, reason)
  local color = VERDICT_COLORS[verdict]
  local action = verdict == "green" and "Safe to delete:" or "Probably sell:"

  -- If the reason contains a comma, it means there are multiple professions/classes.
  -- That makes the line long, so we break it into two lines.
  local hasMultiple = reason and string.find(reason, ",")

  if reason and not hasMultiple then
    tooltip:AddLine(action .. " " .. reason, color.r, color.g, color.b)
  else
    tooltip:AddLine(action, color.r, color.g, color.b)
    if reason then
      tooltip:AddLine(reason, color.r, color.g, color.b)
    end
  end
end

function Bagwise.Tooltip.OnTooltipSetItem(tooltip)
  local _, link = tooltip:GetItem()
  if not link then return end

  local itemID = tonumber(link:match("item:(%d+)"))
  if not itemID then return end

  local result = bagSlotVerdict(tooltip)
  if not result then
    tooltip:Show()
    return
  end

  local verdict = result.verdict
  local reason = result.reason

  local profEntries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[itemID]

  if verdict then
    renderVerdict(tooltip, verdict, reason)
  elseif profEntries then
    renderProfessionDetails(tooltip, profEntries)
  end

  tooltip:Show()
end

function Bagwise.Tooltip.Init()
  GameTooltip:HookScript("OnTooltipSetItem",
    Bagwise.Tooltip.OnTooltipSetItem)
end
