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
local QUEST_DETAIL_LIMIT    = 2

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

-- Classic Era uses GetQuestInfo; retail renamed it to GetTitleForQuestID.
local getQuestTitle    = C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo

-- QuestInfo field indices (data/quest_items.lua is generated).
local QUEST_INFO_LEVEL = 1
local QUEST_INFO_ZONE  = 2
local QUEST_INFO_NAME  = 3

local function formatQuestLine(questID)
  local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]

  -- Try runtime API first, fall back to static data (API returns nil
  -- for completed quests no longer in the active quest log).
  local name = getQuestTitle and getQuestTitle(questID)
  if not name and info then
    name = info[QUEST_INFO_NAME]
  end
  if not name then return nil end

  if info then
    local level = info[QUEST_INFO_LEVEL]
    local zone  = info[QUEST_INFO_ZONE]
    if level and zone then
      return "[" .. level .. "] " .. name .. " (" .. zone .. ")"
    elseif level then
      return "[" .. level .. "] " .. name
    elseif zone then
      return name .. " (" .. zone .. ")"
    end
  end

  return name
end

local function renderQuestDetails(tooltip, questIDs)
  -- Build unique display lines (Alliance/Horde versions share names).
  local unique = {}
  local seen = {}
  for i = 1, #questIDs do
    local text = formatQuestLine(questIDs[i])
    if text and not seen[text] then
      seen[text] = true
      unique[#unique + 1] = text
    end
  end

  local shown = 0
  for i = 1, math.min(#unique, QUEST_DETAIL_LIMIT) do
    local text = unique[i]
    if i == QUEST_DETAIL_LIMIT and #unique > QUEST_DETAIL_LIMIT then
      text = text .. " +" .. (#unique - QUEST_DETAIL_LIMIT)
    end
    tooltip:AddLine(text, INFO_COLOR.r, INFO_COLOR.g, INFO_COLOR.b)
    shown = shown + 1
  end
  return shown
end

local VERDICT_LINE_WRAP = 45

local function renderVerdict(tooltip, verdict, reason)
  local color = VERDICT_COLORS[verdict]
  if not reason then return end

  -- Break long lines at the last comma before the wrap threshold.
  if #reason > VERDICT_LINE_WRAP then
    local breakAt = nil
    for i = VERDICT_LINE_WRAP, 1, -1 do
      if reason:sub(i, i) == "," then
        breakAt = i
        break
      end
    end
    if breakAt then
      tooltip:AddLine(reason:sub(1, breakAt), color.r, color.g, color.b)
      tooltip:AddLine(reason:sub(breakAt + 2), color.r, color.g, color.b)
      return
    end
  end

  tooltip:AddLine(reason, color.r, color.g, color.b)
end

function Bagwise.Tooltip.OnTooltipSetItem(tooltip)
  -- The TooltipDataProcessor fires for every tooltip that shows an item,
  -- including ShoppingTooltip1/2 (the Shift-hover comparison tooltips).
  -- Those don't have GetItem() and have no bag-slot owner, so skip them.
  if not tooltip.GetItem then return end

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

  local questIDs = Bagwise.Data.QuestItems
      and Bagwise.Data.QuestItems[itemID]

  if verdict then
    renderVerdict(tooltip, verdict, reason)
    -- Quest-completed verdicts: show quest detail on a second line in info-blue.
    if result.detail then
      tooltip:AddLine(result.detail, INFO_COLOR.r, INFO_COLOR.g, INFO_COLOR.b)
    end
  else
    -- No verdict: show context rows (profession and/or quest).
    -- Design doc 4.3: never more than 2 detail rows total.
    -- Skip all detail rows for vendor reagents (cheap, repurchasable).
    local isVendorReagent = Bagwise.Data.VendorReagents
        and Bagwise.Data.VendorReagents[itemID]
    if profEntries and not isVendorReagent then
      renderProfessionDetails(tooltip, profEntries)
    elseif questIDs and not isVendorReagent then
      renderQuestDetails(tooltip, questIDs)
    end
  end

  tooltip:Show()
end

function Bagwise.Tooltip.Init()
  -- Forever uses the modern TooltipDataProcessor API.
  -- Classic Era still uses the old GameTooltip:HookScript.
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
      Bagwise.Tooltip.OnTooltipSetItem(tooltip)
    end)
  elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      Bagwise.Tooltip.OnTooltipSetItem(tooltip)
    end)
  end
end
