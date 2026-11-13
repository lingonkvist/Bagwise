-- Bagwise: verdict engine
-- Pure functions only: no WoW API calls, testable outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

local LEVEL_GAP_YELLOW = 10
local LEVEL_GAP_GREEN = 20
local RARE_QUALITY = 3
-- bindType values from GetItemInfo.
local BIND_ON_PICKUP = 1
local BIND_QUEST = 4
local UNCOMMON_QUALITY = 2

--- Can the player sell this instead of destroying it? Any green on something a
-- vendor will buy. The tooltip then says "Safe to vendor" rather than "Safe to
-- delete", so the two always read the same way whichever rule made the green.
function Bagwise.Verdict.Sellable(item, verdict)
  return verdict == "green" and (item.sellPrice or 0) > 0
end

-- An Enchanter can turn green and better gear into materials, so for them such
-- gear is never plain vendor trash, whatever a vendor or the auction house pays.
local function hasEnchanting(state)
  return state ~= nil and state.professionNames ~= nil and state.professionNames["Enchanting"] == true
end

local function needsAnyOf(lookupTable, keys)
  for i = 1, #keys do
    if lookupTable[keys[i]] then return true end
  end
  return false
end

local function professionNamesOf(profEntries)
  local names = {}
  for i = 1, #profEntries do
    names[#names + 1] = profEntries[i][1]
  end
  return names
end

-- Could this piece be an upgrade over something the player wears? Better in
-- rarity or in item level than any slot it fits counts, and so does an empty
-- slot. This is deliberately crude (no stats, no class): the point is only to
-- stay quiet when the answer is obviously "keep it", like a blue in the bag
-- while a white is equipped. Unknown gear (nil) is not treated as an upgrade.
local function couldBeUpgrade(item)
  local worn = item.equippedInSlots
  if not worn then return false end
  for i = 1, #worn do
    if (item.quality or 0) > worn[i].quality then return true end
    if (item.itemLevel or 0) > worn[i].itemLevel then return true end
  end
  return false
end

local note = Bagwise.Notes.Get
Bagwise.Verdict.Note = note

--- A yellow verdict for a rule to return: verdict, reason, detail, tag, heading.
local function yellow(key, ...)
  local reason, heading = note(key, ...)
  return "yellow", reason, nil, nil, heading
end

local function evaluateLevelGap(item, state)
  if not (item.isBound and item.isEquippable) then return nil end
  if couldBeUpgrade(item) then return nil end

  -- A low required level does not make gear outdated by itself: plenty of
  -- items with a modest requirement have an item level a character at this
  -- level still wears. If its item level is at or above the player's level,
  -- it is not "low level".
  if item.itemLevel and item.itemLevel >= state.level then return nil end

  -- Judge by the higher of the two. Some items require level 1 but have an item
  -- level of their own (The Stitcher: requires 1, item level 24), and the item
  -- level is the truer picture. Gear is only outdated when both say so.
  local requiredLevel = item.reqLevel or 0
  local itemLevel = item.itemLevel or 0
  local compareLevel = math.max(requiredLevel, itemLevel)
  if compareLevel <= 0 then return nil end
  local isItemLevel = itemLevel > requiredLevel

  local gap = state.level - compareLevel
  if gap < LEVEL_GAP_YELLOW then return nil end

  -- Rare and better gear can sell well or be disenchanted, so it is a hint
  -- at most, never a "safe".
  local canBeGreen = (item.quality or 0) < RARE_QUALITY
  if (item.quality or 0) >= UNCOMMON_QUALITY and hasEnchanting(state) then canBeGreen = false end

  if gap >= LEVEL_GAP_GREEN and canBeGreen then
    if isItemLevel then
      return "green", (note("very_low_item_level", compareLevel, state.level))
    end
    return "green", (note("very_low_level_gear", compareLevel, state.level))
  end
  if gap >= LEVEL_GAP_GREEN then
    if isItemLevel then
      return yellow("very_low_item_level", compareLevel, state.level)
    end
    return yellow("very_low_level_gear", compareLevel, state.level)
  end

  if isItemLevel then
    return yellow("low_item_level", compareLevel, state.level)
  end
  return yellow("low_level_gear", compareLevel, state.level)
end

-- QuestInfo field indices (data/quest_items.lua is generated).
local QUEST_INFO_LEVEL = 1
local QUEST_INFO_NAME  = 3

-- QuestInfo[questID][QUEST_INFO_FACTION] is "A" or "H" when only that
-- faction can take the quest; absent means open to both.
local QUEST_INFO_FACTION = 4
local FACTION_CODES = { Alliance = "A", Horde = "H" }

--- Drop the quests the player's faction can never take.
-- Alliance and Horde versions of the same quest have separate IDs, so an
-- item used by both would otherwise wait forever on the other side's quest.
-- Quests with no faction data are kept: when unsure, the item stays needed.
-- @param questIDs table        quest IDs from QuestItems
-- @param faction  string|nil   "Alliance" or "Horde"; anything else keeps all
-- @return table  the quests that can matter to this player (may be empty)
function Bagwise.Verdict.QuestsForFaction(questIDs, faction)
  local code = FACTION_CODES[faction]
  if not code then return questIDs end

  local info = Bagwise.Data.QuestInfo
  local kept = {}
  for i = 1, #questIDs do
    local questInfo = info and info[questIDs[i]]
    local questFaction = questInfo and questInfo[QUEST_INFO_FACTION]
    if questFaction == nil or questFaction == code then
      kept[#kept + 1] = questIDs[i]
    end
  end
  return kept
end

--- Build "[level] name" from QuestInfo, using runtimeName as override.
-- The WoW API only returns quest names for quests still in the active log,
-- so completed quests need the static name from QuestInfo.
local function questLabel(questID, runtimeName)
  local info = Bagwise.Data.QuestInfo and Bagwise.Data.QuestInfo[questID]
  local name = runtimeName
  if not name and info then
    name = info[QUEST_INFO_NAME]
  end
  if not name then return nil end
  if info and info[QUEST_INFO_LEVEL] then
    return "[" .. info[QUEST_INFO_LEVEL] .. "] " .. name
  end
  return name
end

-- Only the game's own quest items are certain to be finished with. Anything
-- else a quest happens to ask for (tools, mats, gear) may have other uses.
local QUEST_CLASS_ID = 12
local function isOrdinaryItem(item)
  return item.classID ~= nil and item.classID ~= QUEST_CLASS_ID
end

local function evaluateCompletedQuestStarter(item)
  if not (item.startsQuestID and item.startsQuestCompleted) then return nil end
  local label = questLabel(item.startsQuestID, item.startsQuestName)
  if isOrdinaryItem(item) then return nil end
  return "green", "Quest completed", label
end

local function evaluateVendorReagent(item, state)
  local vendorData = Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id]
  if not vendorData then return nil end

  -- "You have no use for this" needs the full list of your professions. When
  -- the scanner could not read it all, say nothing.
  if state.professionsKnown == false then return nil end

  if vendorData.excludeClasses
      and state.playerClass
      and vendorData.excludeClasses[state.playerClass] then
    return nil
  end

  local profEntries = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id]

  if profEntries and state.professionNames then
    local names = professionNamesOf(profEntries)
    if needsAnyOf(state.professionNames, names) then return nil end
    if #names >= 3 then
      return "green", "Vendor reagent (" .. #names .. " professions)"
    end
    return "green", "Vendor reagent (" .. table.concat(names, ", ") .. ")"
  end

  if not state.professionSkillLines then return nil end
  if needsAnyOf(state.professionSkillLines, vendorData) then return nil end
  return "green", "Vendor reagent"
end

local function evaluateClassReagent(item, state)
  local classReagent = Bagwise.Data.ClassReagents
      and Bagwise.Data.ClassReagents[item.id]
  if not classReagent or not state.playerClass then return nil end
  if classReagent.classes[state.playerClass] then return nil end

  local classList = {}
  for class in pairs(classReagent.classes) do
    classList[#classList + 1] = class:sub(1, 1) .. class:sub(2):lower()
  end
  table.sort(classList)

  local source = classReagent.verdict == "green" and "vendor" or "world drop"
  local classString = table.concat(classList, ", ")

  local whole = classString .. " only (" .. source .. ")"
  if classReagent.verdict == "yellow" then return yellow("wrong_class_reagent", whole) end
  return classReagent.verdict, whole
end

-- An open quest far below the player: its item is only held for a quest that
-- is barely worth finishing. Only a hint. Chains and rewards can still make a
-- low quest worth it, so it says "consider", never "delete".
local QUEST_TRIVIAL_GAP = 10

local function evaluateTrivialQuestItem(item, state)
  if not item.questItemQuestIDs or item.allQuestObjectivesCompleted then return nil end
  if isOrdinaryItem(item) then return nil end
  local open = item.openQuestIDs or item.questItemQuestIDs
  if #open == 0 then return nil end
  local info = Bagwise.Data.QuestInfo
  local repeatable = Bagwise.Data.RepeatableQuests
  for i = 1, #open do
    -- A repeatable quest keeps wanting the item at any level (Blood Shards).
    if repeatable and repeatable[open[i]] then return nil end
    local entry = info and info[open[i]]
    local level = entry and entry[QUEST_INFO_LEVEL]
    if not level or level <= 0 or level + QUEST_TRIVIAL_GAP > (state.level or 1) then return nil end
  end
  local label = #open == 1 and questLabel(open[1], nil) or nil
  local verdict, reason, _, _, heading = yellow(item.onOpenQuest and "quest_abandon" or "quest_not_worth")
  return verdict, reason, label, nil, heading
end

-- An item only wanted by quests the player cannot do for a long while, so it
-- can wait in the bank. Two kinds of quest qualify:
--   far off: nobody is on a level 60 quest at level 30. This goes by the level
--     you must be to ACCEPT the quest (data/quest_availability.lua), never the
--     quest's own level: a level 60 war effort quest opens at level 1.
--   event: a Darkmoon Faire or holiday quest can only be done while the event
--     runs, whatever your level. Bagwise cannot tell if the event is on, so it
--     only names the event.
-- Every open quest must be one of the two; a quest in your log, one within
-- reach or one with no data keeps the item in your bags. A plain material is
-- left alone when a recipe uses it, since it may be wanted sooner.
local QUEST_DISTANT_GAP = 10

local function evaluateDistantQuestItem(item, state)
  if item.onOpenQuest then return nil end
  local required = Bagwise.Data.QuestRequiredLevels
  local events = Bagwise.Data.QuestEvents
  if not (required or events) then return nil end
  local quests = item.openQuestIDs
  if not (quests and #quests > 0) then
    if not item.startsQuestID or item.startsQuestCompleted then return nil end
    quests = { item.startsQuestID }
  end
  if isOrdinaryItem(item) then
    if item.isEquippable then return nil end
    local data = Bagwise.Data
    if data.ReagentProfessions and data.ReagentProfessions[item.id] then return nil end
    if data.VendorReagents and data.VendorReagents[item.id] then return nil end
  end

  local nearestLevel, nearestQuest, eventName, eventQuest
  for i = 1, #quests do
    local quest = quests[i]
    local event = events and events[quest]
    if event then
      if not eventName then eventName, eventQuest = event, quest end
    else
      local level = required and required[quest]
      if not level or level <= (state.level or 1) + QUEST_DISTANT_GAP then return nil end
      if not nearestLevel or level < nearestLevel then nearestLevel, nearestQuest = level, quest end
    end
  end
  if nearestLevel then
    return yellow("bank_quest", nearestLevel, questLabel(nearestQuest, nil))
  end
  return yellow("bank_event", eventName, questLabel(eventQuest, nil))
end

-- Items worth a word that no quest or recipe rule can say. Library books are
-- handed in one by one for rewards, and the game will not give a deleted one
-- back. Blood Shards are a currency for repeatable buffs. Both are only a hint.
local BLOOD_SHARD_ID = 5075

local function evaluateItemHint(item, state)
  local books = Bagwise.Data.LibraryBooks
  if books and books[item.id] then
    -- A book whose quest is done can no longer be handed in.
    if item.startsQuestCompleted or item.allQuestObjectivesCompleted then return nil end
    return yellow("library_book", state.faction)
  end
  -- Mangletooth is a Horde NPC, so an Alliance character has no use for it.
  if item.id == BLOOD_SHARD_ID and state.faction ~= "Alliance" then
    return yellow("shard_buff")
  end
  return nil
end

local function evaluateQuestObjective(item)
  if not item.questItemQuestIDs then return nil end
  if not item.allQuestObjectivesCompleted then return nil end
  if isOrdinaryItem(item) then return nil end
  local count = #item.questItemQuestIDs
  if count > 1 then
    return "green", "All " .. count .. " quests completed"
  end
  local label = questLabel(item.questItemQuestIDs[1], nil)
  return "green", "Quest completed", label
end

local TRADE_GOODS_CLASS_ID = 7

-- Vendor value that counts as "worth a trip to the vendor", in copper. It
-- grows with the player's level because the same coins mean less later on:
-- 30c at level 1, about 1s25c at 20, 3s25c at 60. Nothing here is set by
-- the player.
local WORTH_KEEPING_BASE_COPPER = 25
local WORTH_KEEPING_PER_LEVEL = 5
local POOR_QUALITY = 0

-- Where a gray stops being plainly safe to delete and starts being worth some
-- silver, in copper, by player level. A little higher than the general
-- threshold above: 50c at level 2, about 1s75c at 20, 4s55c at 60.
local GRAY_WORTH_BASE_COPPER = 35
local GRAY_WORTH_PER_LEVEL = 7

local function grayThreshold(state)
  return GRAY_WORTH_BASE_COPPER + GRAY_WORTH_PER_LEVEL * (state.level or 1)
end

-- Marks a verdict as "gray item" so the scanner can thin them out.
Bagwise.Verdict.POOR_QUALITY_TAG = "poorQuality"
local POOR_QUALITY_TAG = Bagwise.Verdict.POOR_QUALITY_TAG

local function valueThreshold(state)
  return WORTH_KEEPING_BASE_COPPER + WORTH_KEEPING_PER_LEVEL * (state.level or 1)
end

--- What the whole stack sells for to a vendor, in copper.
local function stackValue(item)
  return (item.sellPrice or 0) * (item.count or 1)
end

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000

--- "1g 20s 5c" for an amount in copper (zero parts left out).
function Bagwise.Verdict.FormatMoney(copper)
  copper = math.floor(copper or 0)
  local gold = math.floor(copper / COPPER_PER_GOLD)
  local silver = math.floor((copper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
  local rest = copper % COPPER_PER_SILVER
  local parts = {}
  if gold > 0 then parts[#parts + 1] = gold .. "g" end
  if silver > 0 then parts[#parts + 1] = silver .. "s" end
  if rest > 0 or #parts == 0 then parts[#parts + 1] = rest .. "c" end
  return table.concat(parts, " ")
end

-- Colour code for item rarity names in tooltips.
local QUALITY_HEX = {
  [0] = "|cff9d9d9d", [1] = "|cffffffff", [2] = "|cff1eff00",
  [3] = "|cff0070dd", [4] = "|cffa335ee", [5] = "|cffff8000",
}

--- Item name in its rarity colour.
function Bagwise.Verdict.ColoredName(name, quality)
  local colors = _G and _G.ITEM_QUALITY_COLORS
  local hex = colors and colors[quality or 1] and colors[quality or 1].hex or QUALITY_HEX[quality or 1] or QUALITY_HEX[1]
  return hex .. name .. "|r"
end

--- The reason line for a gray. When other grays were silenced, the one that
-- keeps its dot says it is the cheapest, so the single dot makes sense.
-- @param value     number   what the stack sells for, in copper
-- @param isCheapestOfSeveral boolean
-- @param isWorthSilver boolean  true for a gray above the safe-to-delete value:
--        the dot is yellow and the reason warns that it is worth something
function Bagwise.Verdict.PoorQualityReason(value, isCheapestOfSeveral, isWorthSilver)
  if isWorthSilver then
    return note("gray_worth", Bagwise.Verdict.FormatMoney(value), isCheapestOfSeveral)
  end
  local label = isCheapestOfSeveral and "Cheapest gray" or "Poor quality"
  if value == 0 then return label .. ", no vendor value" end
  return label .. ", sells for " .. Bagwise.Verdict.FormatMoney(value)
end

-- Gray items. Cheap ones are safe to delete. One that sells for real money gets
-- a yellow warning instead, and the scanner keeps only the cheapest gray's dot,
-- so that warning only shows when no cheaper gray is green. Anything a quest or
-- recipe still lists is left alone.
local function evaluatePoorQuality(item, state)
  if item.quality ~= POOR_QUALITY then return nil end
  if item.questItemQuestIDs then return nil end
  if Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id] then
    return nil
  end

  local value = stackValue(item)
  if value >= grayThreshold(state) then
    local reason, heading = Bagwise.Verdict.PoorQualityReason(value, false, true)
    return "yellow", reason, nil, POOR_QUALITY_TAG, heading
  end
  return "green", Bagwise.Verdict.PoorQualityReason(value, false), nil, POOR_QUALITY_TAG
end

--- Keep only the cheapest few poor-quality greens, so a bag full of grays
-- doesn't turn into a wall of dots. Deleting one lights up the next.
-- @param entries table  list of { key, bag, slot, value } for every gray with a dot
-- @param maxDots number how many may stay green
-- @return table  set of keys that should go silent
function Bagwise.Verdict.SilenceAllButCheapest(entries, maxDots)
  local sorted = {}
  for i = 1, #entries do sorted[i] = entries[i] end
  table.sort(sorted, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
  end)

  local silenced = {}
  for i = maxDots + 1, #sorted do silenced[sorted[i].key] = true end
  return silenced
end

-- Only plain crafting materials can be called unused. The other Trade Goods
-- subclasses (generic, parts, explosives, devices, other, enchanting rods and
-- oils) hold things
-- you use directly, tokens, and every new item the data has not seen yet.
local MATERIAL_SUBCLASSES = {
  [4] = true,  -- Jewelcrafting
  [5] = true,  -- Cloth
  [6] = true,  -- Leather
  [7] = true,  -- Metal and Stone
  [8] = true,  -- Meat
  [9] = true,  -- Herb
  [10] = true, -- Elemental
  [13] = true, -- Materials
}

local function evaluateNoRecipeUse(item, state)
  -- Epic 5.1: crafting materials that no recipe uses for any profession.
  -- Gear, consumables, and quest items are excluded by the classID gate.
  if item.classID ~= TRADE_GOODS_CLASS_ID then return nil end
  if not MATERIAL_SUBCLASSES[item.subClassID] then return nil end
  -- Nothing to sell usually means a token or currency, not a leftover.
  if (item.sellPrice or 0) <= 0 then return nil end

  -- Already used in at least one recipe -- nothing to flag
  if Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id] then
    return nil
  end

  -- Quest objective or starter -- leave for quest rules / tooltip context
  if Bagwise.Data.QuestItems
      and Bagwise.Data.QuestItems[item.id] then
    return nil
  end

  -- Vendor reagent -- already handled by evaluateVendorReagent
  if Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id] then
    return nil
  end

  -- Class reagent -- already handled by evaluateClassReagent
  if Bagwise.Data.ClassReagents
      and Bagwise.Data.ClassReagents[item.id] then
    return nil
  end

  -- Unused is not the same as worthless: something that sells well might be
  -- worth the vendor trip, so it only gets a yellow.
  local value = stackValue(item)
  if value >= valueThreshold(state) then
    return yellow("no_known_use", Bagwise.Verdict.FormatMoney(value))
  end

  return "green", "Not used for any quest or recipe"
end

-- Recipes and the reagents behind them. A recipe's item subclass says which
-- profession it teaches. Nothing here says "delete": a recipe for a profession
-- you do not have may sell, and one you cannot use yet is only taking up room,
-- so the advice is to bank it or sell it, and the player decides.
local RECIPE_CLASS_ID = 9
local RECIPE_PROFESSIONS = {
  [1] = "Leatherworking", [2] = "Tailoring", [3] = "Engineering",
  [4] = "Blacksmithing", [5] = "Cooking", [6] = "Alchemy",
  [7] = "First Aid", [8] = "Enchanting", [9] = "Fishing",
}
-- A reagent is "outleveled" as soon as you are past the best recipe that needs
-- it, counting what it is turned into: past that skill every one of them is
-- gray, so nothing you make from it is still a skill-up.
local OUTLEVELED_SKILL_GAP = 0
-- A recipe you cannot learn yet gets the bank hint once it is this far out of
-- reach. A profession you have stopped leveling has nothing "close", so for
-- it any shortfall counts (see Bagwise.Progress).
local RECIPE_SKILL_GAP = 25
local RECIPE_IDLE_SKILL_GAP = 0
local RECIPE_LEVEL_GAP = 3
-- A reagent counts as "a while away" when it is out of reach by this much. It
-- is wider than a recipe's gap because one reagent feeds many recipes. The gap
-- closes to the recipe gap once the profession has gone quiet (half the idle
-- time) and stays there when it is idle: a reagent is never banked on any
-- shortfall, because the tooltip already says what it is for.
local BANK_SKILL_GAP = 50
local BANK_QUIET_SKILL_GAP = RECIPE_SKILL_GAP

local function evaluateRecipe(item, state)
  if item.classID ~= RECIPE_CLASS_ID then return nil end
  local profession = RECIPE_PROFESSIONS[item.subClassID]
  if not profession then return nil end
  if state.professionsKnown == false or not state.professionNames then return nil end

  if not state.professionNames[profession] then
    -- A bound recipe cannot be sold, so there is nothing to suggest.
    if item.isBound then return nil end
    return yellow("not_your_profession")
  end

  local rank = state.professionRanks and state.professionRanks[profession]
  local idle = state.professionIdle and state.professionIdle[profession]
  local skillGap = idle and RECIPE_IDLE_SKILL_GAP or RECIPE_SKILL_GAP
  if rank and item.requiredSkill and item.requiredSkill > rank + skillGap then
    return yellow("bank_skill", profession, item.requiredSkill)
  end
  if item.reqLevel and item.reqLevel > (state.level or 1) + RECIPE_LEVEL_GAP then
    return yellow("bank_level", item.reqLevel)
  end
  return nil
end

-- Where a reagent is used, direct and through what it is turned into: copper
-- bars go into bronze bars, which smithing and engineering use far higher up.
-- ReagentChains (generated) holds the downstream uses; entries are merged per
-- profession into { name, minSkill, maxSkill }.
-- Both reagent rules ask for the same merge, so it is kept per data table. A
-- different table (new data, or a test swapping it) misses and is rebuilt.
local reagentUseMemo = setmetatable({}, { __mode = "k" })

local function reagentUses(itemID)
  local direct = Bagwise.Data.ReagentProfessions and Bagwise.Data.ReagentProfessions[itemID]
  if not direct then return nil end
  local chains = Bagwise.Data.ReagentChains and Bagwise.Data.ReagentChains[itemID]
  local memo = reagentUseMemo[direct]
  if memo and memo.chains == chains then return memo.order end
  local merged, order = {}, {}
  local function add(name, minSkill, maxSkill)
    local use = merged[name]
    if not use then
      use = { name = name, minSkill = minSkill, maxSkill = maxSkill }
      merged[name] = use
      order[#order + 1] = use
      return
    end
    if minSkill and (not use.minSkill or minSkill < use.minSkill) then use.minSkill = minSkill end
    if maxSkill and (not use.maxSkill or maxSkill > use.maxSkill) then use.maxSkill = maxSkill end
  end
  for i = 1, #direct do add(direct[i][1], direct[i][3], direct[i][4]) end
  if chains then
    for i = 1, #chains do add(chains[i][1], chains[i][2], chains[i][3]) end
  end
  reagentUseMemo[direct] = { chains = chains, order = order }
  return order
end

-- A reagent the player's own professions will not use for a good while: every
-- profession of theirs that uses it starts needing it far above their skill.
local function evaluateDistantReagent(item, state)
  local entries = reagentUses(item.id)
  if not entries or state.professionsKnown == false then return nil end
  if not (state.professionNames and state.professionRanks) then return nil end

  local nearest -- the smallest gap to a profession of theirs
  for i = 1, #entries do
    local name, minSkill = entries[i].name, entries[i].minSkill
    if state.professionNames[name] then
      local rank = state.professionRanks[name]
      if not rank or not minSkill then return nil end
      local quiet = (state.professionIdle and state.professionIdle[name])
          or (state.professionSettling and state.professionSettling[name])
      local gap = quiet and BANK_QUIET_SKILL_GAP or BANK_SKILL_GAP
      if minSkill <= rank + gap then return nil end
      if not nearest or minSkill - rank < nearest.gap then
        nearest = { gap = minSkill - rank, name = name, minSkill = minSkill, rank = rank }
      end
    end
  end
  if not nearest then return nil end
  return yellow("bank_used_from", nearest.name, nearest.minSkill)
end

-- A reagent every one of your professions that uses it has left behind: the
-- best recipe that needs it is far below your skill. Only a hint, since an
-- alt or a low recipe may still want it.
local function evaluateOutleveledReagent(item, state)
  -- Without the downstream uses we cannot tell a finished material from an
  -- ingredient of something still in demand, so the rule stays silent.
  if not Bagwise.Data.ReagentChains then return nil end
  -- A quest that still wants it (a profession quest, say) is a use the recipe
  -- data knows nothing about, whatever your skill is.
  if item.openQuestIDs and #item.openQuestIDs > 0 then return nil end
  local entries = reagentUses(item.id)
  if not entries or state.professionsKnown == false then return nil end
  if not (state.professionNames and state.professionRanks) then return nil end

  local newest -- the profession whose recipes are closest behind you
  for i = 1, #entries do
    local name, maxSkill = entries[i].name, entries[i].maxSkill
    if state.professionNames[name] then
      local rank = state.professionRanks[name]
      if not rank or not maxSkill then return nil end
      if rank <= maxSkill + OUTLEVELED_SKILL_GAP then return nil end
      if not newest or maxSkill > newest.maxSkill then
        newest = { name = name, maxSkill = maxSkill }
      end
    end
  end
  if not newest then return nil end
  return yellow("outleveled_reagent", newest.name, newest.maxSkill)
end

-- Can this be listed at the auction house? Not once it is soulbound or bound to
-- a quest.
local function isTradeable(item)
  return not (item.isBound or item.bindType == BIND_ON_PICKUP or item.bindType == BIND_QUEST)
end

-- The primary professions: a character holds two, so with both taken a
-- reagent for any other profession is not coming into use.
local PRIMARY_PROFESSIONS = {
  Alchemy = true, Blacksmithing = true, Enchanting = true, Engineering = true,
  Herbalism = true, Leatherworking = true, Mining = true, Skinning = true,
  Tailoring = true,
}
local GATHERING_PROFESSIONS = { Herbalism = true, Mining = true, Skinning = true }
local PRIMARY_PROFESSION_SLOTS = 2

--- How many primary professions the player has, and how many of them craft.
local function primaryProfessions(state)
  local total, crafting = 0, 0
  for name in pairs(state.professionNames) do
    if PRIMARY_PROFESSIONS[name] then
      total = total + 1
      if not GATHERING_PROFESSIONS[name] then crafting = crafting + 1 end
    end
  end
  return total, crafting
end

-- A crafting material that drops (no vendor sells it) and that none of your
-- professions use, directly or through what it becomes. It may still sell, so
-- the hint comes with the vendor and auction prices. Three things keep it quiet:
-- a free primary slot (you may still pick a profession that uses it), a use by
-- Cooking, First Aid or Fishing (anyone can learn those any time), and a bag of
-- only gathering professions (everything gathered is meant to be sold).
local function evaluateOtherProfessionReagent(item, state)
  if item.classID ~= TRADE_GOODS_CLASS_ID then return nil end
  local entries = reagentUses(item.id)
  if not entries or state.professionsKnown == false or not state.professionNames then return nil end
  if not isTradeable(item) then return nil end
  if item.questItemQuestIDs and not item.allQuestObjectivesCompleted then return nil end
  local data = Bagwise.Data
  if data.VendorReagents and data.VendorReagents[item.id] then return nil end
  if data.ClassReagents and data.ClassReagents[item.id] then return nil end
  local total, crafting = primaryProfessions(state)
  if total < PRIMARY_PROFESSION_SLOTS or crafting == 0 then return nil end

  local professions = {}
  for i = 1, #entries do
    local name = entries[i].name
    if state.professionNames[name] or not PRIMARY_PROFESSIONS[name] then return nil end
    professions[#professions + 1] = name
  end
  return yellow("other_profession_reagent", professions)
end

-- Something you right-click to open (clams, bags of loot). It takes a slot now
-- and what is inside often stacks, so opening it usually frees room.
local function evaluateOpenable(item)
  if not item.hasLoot then return nil end
  return yellow("open_it")
end

-- Food, drink, potions and bandages made for a much lower level than yours
-- restore little now. Only a hint: you may want the stack for an alt.
local CONSUMABLE_CLASS = 0
local OUTLEVELED_SUBCLASSES = { [1] = true, [5] = true, [7] = true } -- potion, food and drink, bandage
local OUTLEVELED_GAP = 20
local CONSUMABLE_NOUNS = { [1] = "potion", [5] = "food", [7] = "bandage" }
local FOOD_SUBCLASS = 5
local POTION_SUBCLASS = 1

local CLASS_PLURALS_FOR_POTIONS = { WARRIOR = "Warriors", ROGUE = "Rogues" }

-- Mana potions and drinks are no use to a class with no mana. The IDs are listed instead
-- of matched by name, so it works in every language.
local MANA_POTIONS = {
  [2455] = true,  -- Minor Mana Potion
  [3385] = true,  -- Lesser Mana Potion
  [3827] = true,  -- Mana Potion
  [6149] = true,  -- Greater Mana Potion
  [13443] = true, -- Superior Mana Potion
  [13444] = true, -- Major Mana Potion
}
local CLASSES_WITHOUT_MANA = { WARRIOR = true, ROGUE = true }

-- data/mana_consumables.lua is generated from game data and covers every
-- mana-only consumable. The short list above is the fallback when it is empty.
local function isManaOnly(itemID)
  local generated = Bagwise.Data and Bagwise.Data.ManaOnlyConsumables
  return MANA_POTIONS[itemID] or (generated and generated[itemID]) or false
end

-- Drinks work through an aura, so the generated list misses them. The scanner
-- reads the tooltip instead and says when an item restores mana and nothing else.
local function evaluateManaConsumable(item, state)
  if not (isManaOnly(item.id) or item.restoresManaOnly == true) then return nil end
  if not CLASSES_WITHOUT_MANA[state.playerClass or ""] then return nil end
  return yellow("no_mana", CLASS_PLURALS_FOR_POTIONS[state.playerClass])
end

local function evaluateOutleveledConsumable(item, state)
  if item.classID ~= CONSUMABLE_CLASS or not OUTLEVELED_SUBCLASSES[item.subClassID] then return nil end
  if item.questItemQuestIDs or item.startsQuestID then return nil end
  -- Utility potions (swimming speed, water walking, free action) stay useful
  -- at any level. Only a potion known to restore health or mana can be outleveled.
  if item.subClassID == POTION_SUBCLASS and item.restoresHealthOrMana ~= true then return nil end
  -- Food that gives a buff (Well Fed) or whose tooltip we could not read as plain
  -- healing is not flagged: its effect can still beat what you carry.
  if item.subClassID == FOOD_SUBCLASS
      and (item.restoresHealthOrMana ~= true or item.givesBuff == true) then return nil end
  local reqLevel = item.reqLevel
  if not reqLevel or reqLevel <= 0 then return nil end
  if reqLevel + OUTLEVELED_GAP > (state.level or 1) then return nil end
  return yellow("low_level_consumable", CONSUMABLE_NOUNS[item.subClassID], reqLevel, state.level or 1)
end

local COMMON_QUALITY = 1
local ARMOR_CLASS_ID = 4

-- Armor and shield types by class. A number is the player level at which the
-- class learns to wear that type (warriors and paladins get plate at 40,
-- hunters and shamans get mail at 40); true means from the start; absent
-- means never.
local ARMOR_SUBCLASS_NAMES = {
  [2] = "leather", [3] = "mail", [4] = "plate",
}
local OTHER_SUBCLASS_PHRASES = {
  [6] = "shields", [7] = "librams", [8] = "idols", [9] = "totems",
}
local CAN_USE_SUBCLASSES = {
  WARRIOR = { [1] = true, [2] = true, [3] = true, [4] = 40, [6] = true },
  PALADIN = { [1] = true, [2] = true, [3] = true, [4] = 40, [6] = true, [7] = true },
  HUNTER  = { [1] = true, [2] = true, [3] = 40 },
  ROGUE   = { [1] = true, [2] = true },
  PRIEST  = { [1] = true },
  MAGE    = { [1] = true },
  WARLOCK = { [1] = true },
  SHAMAN  = { [1] = true, [2] = true, [3] = 40, [6] = true, [9] = true },
  DRUID   = { [1] = true, [2] = true, [8] = true },
}

local CLASS_PLURALS = {
  WARRIOR = "Warriors", PALADIN = "Paladins", HUNTER = "Hunters",
  ROGUE = "Rogues", PRIEST = "Priests", MAGE = "Mages",
  WARLOCK = "Warlocks", SHAMAN = "Shamans", DRUID = "Druids",
}

local function unwearableWording(subClassID)
  if ARMOR_SUBCLASS_NAMES[subClassID] then
    return "wear " .. ARMOR_SUBCLASS_NAMES[subClassID]
  end
  if OTHER_SUBCLASS_PHRASES[subClassID] then
    return "use " .. OTHER_SUBCLASS_PHRASES[subClassID]
  end
  return nil
end

-- White armor the player can't wear right now: the class never can, or
-- can't until a later level. Unknown classes (anything not listed above)
-- get no verdict rather than a guess. The reason stays short; the game's own
-- tooltip already shows the sell price for anyone who would rather vendor it.
local function evaluateUnwearableWhite(item, state)
  if item.quality ~= COMMON_QUALITY then return nil end
  if not item.isEquippable or item.classID ~= ARMOR_CLASS_ID then return nil end

  local usable = CAN_USE_SUBCLASSES[state.playerClass]
  if not usable or not item.subClassID then return nil end

  local wording = unwearableWording(item.subClassID)
  if not wording then return nil end

  local rule = usable[item.subClassID]
  if rule == true then return nil end

  local reason = CLASS_PLURALS[state.playerClass] .. " can't " .. wording
  if rule ~= nil then
    if (state.level or 1) >= rule then return nil end
    reason = reason .. " until " .. rule
  end
  return "green", reason
end

-- A white piece of armor you have already out-geared. Every slot it could go
-- in must hold something better than white and at least as high in item
-- level, so the white can never be the upgrade. An empty slot, or an item the
-- game hasn't loaded yet, means no verdict (the scanner leaves
-- equippedInSlots nil then). Weapons are left out: which weapon you want
-- depends on proficiencies and class, not just level.
local function evaluateOutgearedWhite(item, state)
  if item.quality ~= COMMON_QUALITY then return nil end
  if not item.isEquippable or item.classID ~= ARMOR_CLASS_ID then return nil end

  local equipped = item.equippedInSlots
  if not equipped or #equipped == 0 then return nil end

  -- A white has no stats, only armor, so any green or better in the same slot
  -- beats it whatever the item levels. The exception is gear you cannot wear
  -- yet: that is something to grow into, not something you have outgrown.
  if item.reqLevel and state and state.level and item.reqLevel > state.level then
    return nil
  end

  for i = 1, #equipped do
    if equipped[i].quality < UNCOMMON_QUALITY then return nil end
  end

  return "green", "Worse than your equipped gear"
end

-- Every rule, in priority order (first one with a verdict wins). A rule only
-- proposes; Safety can drop a green. `overrides` names the protections a rule
-- is allowed to override, and each one is a decision, not a convenience:
--   quest rules may override "quest_item": finishing the quests lifts it
--   the reagent rules decide by profession or class themselves
-- Anything not listed is protected from that rule.
-- Tradeable green gear that the auction house pays about the vendor price for:
-- selling it to a vendor loses nothing. The price data (data/auction_prices.lua)
-- is a ceiling per item, so the call is only made when even that is close to the
-- vendor price. After the auction house's 5% cut, a higher price is worth a look.
-- Every check above this rule still runs first, and the upgrade check holds.
local EQUIPMENT_CLASSES = { [2] = true, [4] = true }
-- How far above the vendor price the AH ceiling may sit and still read as "about
-- the same". The margin shrinks as the price grows: a few copper does not
-- justify a repost, but a quarter of a gold does. Each step: below `below`
-- copper of vendor price, the ceiling may be `factor` times it.
local AH_VENDOR_STEPS = {
  { below = 500,  factor = 2.0 },
  { below = 2000, factor = 1.35 },
  { below = 5000, factor = 1.2 },
}
local AH_VENDOR_LAST_FACTOR = 1.1
local AH_VENDOR_SLACK = 400 -- or this many copper above it: two lost deposits, the cut and some time

-- A few copper never decide between a vendor and the auction house, so both
-- prices are rounded before they are compared, always towards "just vendor it":
-- the vendor price up to the next half silver (3s 24c counts as 3s 50c, 3s 70c
-- as 4s) and the auction price down to whole silver (7s 78c counts as 7s). Under
-- a silver the auction price is left alone, or it would round down to nothing.
local VENDOR_ROUND_UP_COPPER = 50
local AUCTION_ROUND_DOWN_COPPER = 100

local function roundedVendor(vendorPrice)
  return math.ceil(vendorPrice / VENDOR_ROUND_UP_COPPER) * VENDOR_ROUND_UP_COPPER
end

local function roundedAuction(auctionPrice)
  if auctionPrice < AUCTION_ROUND_DOWN_COPPER then return auctionPrice end
  return math.floor(auctionPrice / AUCTION_ROUND_DOWN_COPPER) * AUCTION_ROUND_DOWN_COPPER
end

-- Stackables are sold by the stack, so a few copper per unit add up and the
-- gear allowances do not apply: no rounding up of the vendor price, no flat
-- slack. A 4c reagent that auctions for 1s 75c is worth listing by the stack.
local function isStackable(item)
  return (item.maxStack or 1) > 1
end

local function sellLimit(vendorPrice, stackable)
  if stackable then
    local factor = AH_VENDOR_LAST_FACTOR
    for i = 1, #AH_VENDOR_STEPS do
      if vendorPrice < AH_VENDOR_STEPS[i].below then
        factor = AH_VENDOR_STEPS[i].factor
        break
      end
    end
    return math.ceil(vendorPrice * factor)
  end
  local vendor = roundedVendor(vendorPrice)
  local factor = AH_VENDOR_LAST_FACTOR
  for i = 1, #AH_VENDOR_STEPS do
    if vendor < AH_VENDOR_STEPS[i].below then
      factor = AH_VENDOR_STEPS[i].factor
      break
    end
  end
  return math.max(vendor * factor, vendor + AH_VENDOR_SLACK)
end

--- The bonus ids of an item link as "12744" or "12727-12800" (sorted), or nil
-- when it has none or the link is not in the shape we expect. Links read
-- itemID:enchant:gem1..gem4:suffix:unique:linkLevel:spec:modifiersMask:context:
-- numBonusIDs:bonus1... so the count is the 13th field.
local BONUS_COUNT_FIELD = 13
function Bagwise.Verdict.BonusKey(link)
  if type(link) ~= "string" then return nil end
  local body = link:match("item:([^|]*)")
  if not body then return nil end
  local fields, position = {}, 1
  while true do
    local colon = body:find(":", position, true)
    fields[#fields + 1] = body:sub(position, colon and colon - 1 or #body)
    if not colon then break end
    position = colon + 1
  end
  local count = tonumber(fields[BONUS_COUNT_FIELD])
  if not count or count < 1 then return nil end
  local ids = {}
  for i = 1, count do
    local id = tonumber(fields[BONUS_COUNT_FIELD + i])
    if not id then return nil end
    ids[#ids + 1] = id
  end
  table.sort(ids)
  return table.concat(ids, "-")
end

--- The auction ceiling for this very item. Random-suffix gear is one item id
-- with very different prices, so when the data lists versions of the item,
-- only the player's own version counts: a version the data has no price for
-- gives nothing (it may be the rare, expensive one), never the item's price.
-- @return number|nil ceiling, string source ("version", "item" or "unknown")
local function snapshotCeilingFor(item)
  local data = Bagwise.Data or {}
  local versions = data.AuctionVariantCeiling and data.AuctionVariantCeiling[item.id]
  if versions then
    local own = item.bonusKey and versions[item.bonusKey]
    if own then return own, "version" end
    return nil, "unknown"
  end
  local prices = data.AuctionPriceCeiling
  return prices and prices[item.id], "item"
end

-- A fresh price from the player's own auction house (item.livePrice, set by the
-- scanner only when Auctionator saw the item in the last few days). It is the
-- lowest listing, so one cheap listing can make an item look worth less than it
-- is. The snapshot is the check: a live price far below the snapshot's cheap end
-- is not trusted, and the careful snapshot rules decide instead.
local LIVE_LOWBALL_FRACTION = 0.5
-- Days: a live price with no snapshot price next to it must be this fresh.
local LIVE_UNBACKED_MAX_AGE_DAYS = 1

--- The live price to use for this item, or nil.
-- @return number|nil price, string|nil why it was not used (for /bagwise why)
local function liveCeiling(item)
  local live = item.livePrice
  if type(live) ~= "number" or live <= 0 then return nil end
  local snapshot, source = snapshotCeilingFor(item)
  local backed = snapshot and source ~= "unknown"
  -- Without a snapshot price to compare against, only a very fresh price counts.
  if not backed and (type(item.liveAge) ~= "number"
      or item.liveAge > LIVE_UNBACKED_MAX_AGE_DAYS) then
    return nil, "live price " .. Bagwise.Verdict.FormatMoney(live)
        .. " is not confirmed by the snapshot and is over a day old, so it is ignored"
  end
  -- (a versioned item is not ignored here: its live price is floored in ceilingFor)
  -- A price that several recent days agree on (item.liveSteady) is the market's
  -- own, not a one-off lowball, even when it differs from the snapshot.
  if backed and not item.bonusKey and not item.liveSteady and live < snapshot * LIVE_LOWBALL_FRACTION then
    return nil, "live price " .. Bagwise.Verdict.FormatMoney(live)
        .. " is far below the snapshot (" .. Bagwise.Verdict.FormatMoney(snapshot)
        .. "), so it may be a lowball and is ignored"
  end
  return live
end

-- A version's snapshot price is the pricey end of that version (the 75th
-- percentile of its listings, build_auction_prices.py), a margin kept on purpose
-- to be careful. Its cheap end, about what a seller gets, is roughly this
-- fraction of it. A live price can bring the ceiling of a versioned item down to
-- this floor and no further, since Auctionator's price is the cheapest version's.
local VERSION_FLOOR_FRACTION = 0.6

-- Versions the data must list before the dearest of them stands in for a
-- version it has no price for. A handful of listed versions means the market
-- was seen well; a single one proves nothing about the rest.
local MIN_LISTED_VERSIONS = 3

--- The dearest listed version of a random-suffix item, for the player's version
-- when the data has no price for it. Most such items cost about the same in
-- every version or are all worth selling, and the dearest version can only keep
-- a green away, never give one that the dearest version would not.
-- @return number|nil
local function dearestVersionCeiling(item)
  local data = Bagwise.Data or {}
  local versions = data.AuctionVariantCeiling and data.AuctionVariantCeiling[item.id]
  if not versions then return nil end
  local count, dearest = 0, 0
  for _, price in pairs(versions) do
    count = count + 1
    if price > dearest then dearest = price end
  end
  if count < MIN_LISTED_VERSIONS or dearest <= 0 then return nil end
  return dearest
end

-- @return number|nil ceiling, string source ("live", "version", "versions", "item" or "unknown")
local function ceilingFor(item)
  local live = liveCeiling(item)
  local snapshot, source = snapshotCeilingFor(item)
  if source == "unknown" then
    local dearest = dearestVersionCeiling(item)
    if dearest then snapshot, source = dearest, "versions" end
  end
  if not live then return snapshot, source end
  -- Auctionator files every version of a random-suffix item under one key, so
  -- its price is the cheapest version's. For a versioned item (the link carries
  -- bonus ids) it may lower the snapshot's price only down to a floor: the
  -- snapshot is the pricey end of this version (see VERSION_FLOOR_FRACTION), and
  -- the floor is roughly its cheap end. With no snapshot price it decides nothing.
  if item.bonusKey then
    if not snapshot or source == "unknown" then return snapshot, source end
    local fraction = source == "item" and LIVE_LOWBALL_FRACTION or VERSION_FLOOR_FRACTION
    return math.max(live, snapshot * fraction), source
  end
  return live, "live"
end

-- What an auction price is worth to someone selling: the live price less the 5%
-- cut, or the snapshot's pricey end scaled down to its cheap end.
local LIVE_AFTER_CUT = 0.95

--- What one of this item fetches when sold the better way, careful about the
-- auction side so that a loot decision never leans on a price that is too high.
-- Used to weigh loot against the junk it would replace.
-- @return number copper per item (the vendor price at least)
function Bagwise.Verdict.SaleValue(item)
  local vendor = item.sellPrice or 0
  if not isTradeable(item) then return vendor end
  local ceiling, source = ceilingFor(item)
  if not ceiling or source == "unknown" then return vendor end
  local auction
  if source == "live" then
    auction = ceiling * LIVE_AFTER_CUT
  else
    auction = ceiling * VERSION_FLOOR_FRACTION
  end
  return math.max(vendor, math.floor(auction))
end

--- Everything the sell-at-vendor rule looks at, in one place: the rule and
-- /bagwise why both read this, so they cannot disagree.
-- @return table|nil nil for items the rule never considers (not gear);
--   otherwise { passes = boolean, ceiling, limit, notes = { lines } }
local function checkSellAtVendor(item, state)
  if not EQUIPMENT_CLASSES[item.classID] then return nil end
  local money = Bagwise.Verdict.FormatMoney
  local check = { passes = false, notes = {} }
  local function note_(text) check.notes[#check.notes + 1] = "sell check: " .. text end

  local ceiling, source = ceilingFor(item)
  local _, ignored = liveCeiling(item)
  if ignored then note_(ignored) end
  if source == "live" and item.liveSteady then
    local snapshot, snapshotSource = snapshotCeilingFor(item)
    if snapshot and snapshotSource ~= "unknown" and ceiling < snapshot * LIVE_LOWBALL_FRACTION then
      note_("live price " .. money(ceiling) .. " is far below the snapshot (" .. money(snapshot)
          .. ") but steady over the last days, so it is trusted")
    end
  end
  if ceiling and item.bonusKey and type(item.livePrice) == "number" and source ~= "live" and not ignored then
    note_("Auctionator's " .. money(item.livePrice) .. " is the cheapest version's price; it can lower the"
        .. " snapshot price of this version to " .. math.floor(VERSION_FLOOR_FRACTION * 100) .. "% of it at most")
  end

  -- Green gear is judged on the snapshot. With a fresh live price the price is
  -- known, so blue gear can be judged too (epics never are).
  local quality = item.quality
  local considered = quality == UNCOMMON_QUALITY
      or (source == "live" and quality == RARE_QUALITY)
  if not considered then
    note_("only green gear is considered without a live price (this is quality " .. tostring(quality) .. ")")
    return check
  end
  if item.isBound then
    note_("soulbound, so it is not sold at auction")
    return check
  end
  if quality >= UNCOMMON_QUALITY and hasEnchanting(state) then
    note_("you have Enchanting, so this gear may be worth disenchanting")
    return check
  end
  if not item.sellPrice or item.sellPrice <= 0 then
    note_("no vendor price")
    return check
  end

  if not ceiling then
    if source == "unknown" then
      note_("this version has no auction price on file (bonus "
          .. tostring(item.bonusKey) .. "), so no verdict")
    else
      note_("no auction price on file (vendor " .. money(item.sellPrice) .. ")")
    end
    return check
  end

  local limit = sellLimit(item.sellPrice)
  check.ceiling, check.limit, check.source = ceiling, limit, source
  local compared = roundedAuction(ceiling)
  local within = compared <= limit
  note_("vendor " .. money(item.sellPrice) .. ", auction ceiling " .. money(ceiling)
      .. (source == "live" and " (live price from Auctionator)"
          or source == "version" and " (this version, bonus " .. tostring(item.bonusKey) .. ")"
          or source == "versions" and " (this version has no price on file, so the dearest listed version)"
          or " (whole item)")
      .. ", limit " .. money(limit) .. " (vendor counted as " .. money(roundedVendor(item.sellPrice))
      .. ", auction as " .. money(compared) .. ")"
      .. (within and " (within)" or " (auction pays too much)"))

  if not item.equippedInSlots then
    note_("worn gear in this slot could not be read, so no verdict")
    return check
  end
  if couldBeUpgrade(item) then
    local worn = {}
    for i = 1, #item.equippedInSlots do
      worn[#worn + 1] = "quality " .. item.equippedInSlots[i].quality .. " ilvl " .. item.equippedInSlots[i].itemLevel
    end
    note_("could be an upgrade (this: quality " .. tostring(item.quality)
        .. " ilvl " .. tostring(item.itemLevel) .. "; worn: " .. table.concat(worn, ", ") .. ")")
    return check
  end
  check.passes = within
  return check
end

local function evaluateSellAtVendor(item, state)
  local check = checkSellAtVendor(item, state)
  if not (check and check.passes) then return nil end
  local money = Bagwise.Verdict.FormatMoney
  return "green", "Vendor " .. money(item.sellPrice) .. ", auction "
      .. (check.source == "live" and "about " or "up to ") .. money(check.ceiling)
end

--- The facts behind the sell-at-vendor rule for one item, as short lines for
-- /bagwise why. Empty for non-gear.
function Bagwise.Verdict.SellAtVendorFacts(item, state)
  local check = checkSellAtVendor(item, state)
  return check and check.notes or {}
end

local RULES = {
  { name = "unwearable_white",   evaluate = evaluateUnwearableWhite, checksAuction = true },
  { name = "level_gap",          evaluate = evaluateLevelGap },
  { name = "outgeared_white",    evaluate = evaluateOutgearedWhite, checksAuction = true },
  { name = "quest_starter_done", evaluate = evaluateCompletedQuestStarter, checksAuction = true,
    overrides = { quest_item = true } },
  { name = "quest_objective_done", evaluate = evaluateQuestObjective, checksAuction = true,
    overrides = { quest_item = true } },
  { name = "item_hint",          evaluate = evaluateItemHint },
  { name = "trivial_quest_item", evaluate = evaluateTrivialQuestItem },
  { name = "distant_quest_item", evaluate = evaluateDistantQuestItem },
  { name = "vendor_reagent",     evaluate = evaluateVendorReagent, checksAuction = true,
    overrides = { vendor_reagent = true, recipe_reagent = true } },
  { name = "class_reagent",      evaluate = evaluateClassReagent, checksAuction = true,
    overrides = { spell_reagent = true, recipe_reagent = true } },
  { name = "openable",           evaluate = evaluateOpenable },
  { name = "recipe",             evaluate = evaluateRecipe },
  { name = "distant_reagent",    evaluate = evaluateDistantReagent },
  { name = "outleveled_reagent", evaluate = evaluateOutleveledReagent, showsAuctionPrice = true },
  { name = "other_profession_reagent", evaluate = evaluateOtherProfessionReagent, showsAuctionPrice = true },
  { name = "poor_quality",      evaluate = evaluatePoorQuality },
  { name = "no_recipe_use",      evaluate = evaluateNoRecipeUse, checksAuction = true },
  { name = "sell_at_vendor",     evaluate = evaluateSellAtVendor },
}

--- Why a green must not stand because the auction house may pay more than a
-- vendor. Only for items that can be traded at all: a soulbound or quest-bound
-- item cannot be listed. Where the data has no price for an item, nobody lists
-- it often enough to matter, so the green stands. A version the data does not
-- know (it may be the pricey one) is silenced, as in the sell rule.
-- @return string|nil the reason it is blocked, for /bagwise why
-- @return string|nil a short "Vendor 5c, auction about 8s" for the tooltip, only
--   when the block is about the price (not an unknown version or market)
--- "Vendor 5c, auction about 8s": the real prices, not the rounded ones.
local function priceNote(item, ceiling, source)
  local money = Bagwise.Verdict.FormatMoney
  -- A live price is the real price now ("about"); the snapshot is a cheap-end
  -- ceiling ("up to").
  local approx = source == "live" and "about " or "up to "
  local vendor = item.sellPrice or 0
  local vendorText = vendor > 0 and ("vendor " .. money(vendor)) or "no vendor price"
  return vendorText:sub(1, 1):upper() .. vendorText:sub(2) .. ", auction " .. approx .. money(ceiling)
end

local function auctionBlocker(item)
  if not isTradeable(item) then return nil end
  local ceiling, source = ceilingFor(item)
  if source ~= "live" and Bagwise.Data and Bagwise.Data.AuctionMarketMissing then
    return "no auction prices for your region and faction"
  end
  if source == "unknown" then
    return "this version may sell for more at auction"
  end
  local vendor = item.sellPrice or 0
  local stackable = isStackable(item)
  local compared = stackable and ceiling or (ceiling and roundedAuction(ceiling))
  if not ceiling or compared <= sellLimit(vendor, stackable) then return nil end
  -- The same facts for the tooltip, which tells the player why there is no dot.
  local note = priceNote(item, ceiling, source)
  return "it may be worth more at auction (" .. note:sub(1, 1):lower() .. note:sub(2) .. ")", note
end

--- The price line for a hint that suggests selling at the auction house, when
-- the data has a price for the item. Never blocks anything.
local function auctionPriceLine(item)
  if not isTradeable(item) then return nil end
  local ceiling, source = ceilingFor(item)
  if source ~= "live" and Bagwise.Data and Bagwise.Data.AuctionMarketMissing then return nil end
  if not ceiling or source == "unknown" then return nil end
  return priceNote(item, ceiling, source)
end

--- Run one rule and apply the safety check to a green.
-- @return verdict, reason, detail, tag, blockedBy, heading, auctionNote
local function runRule(rule, item, state)
  local verdict, reason, detail, tag, heading = rule.evaluate(item, state)
  if verdict == "yellow" and rule.showsAuctionPrice then
    return verdict, reason, detail, tag, nil, heading, auctionPriceLine(item)
  end
  if verdict == "green" then
    local blocker = Bagwise.Safety.Blocker(item, rule.overrides)
    if blocker then return verdict, reason, detail, tag, blocker, heading end
    if rule.checksAuction then
      local pricey, note = auctionBlocker(item)
      if pricey then return verdict, reason, detail, tag, pricey, heading, note end
    end
  end
  return verdict, reason, detail, tag, nil, heading
end

local CONSUMABLE_CLASS_ID = 0

--- Evaluate a single item and return a verdict.
-- Player overrides win over every rule: a kept item is always silent,
-- a flagged item is always yellow.
-- Consumables (food, drink, potions, bandages) never get a rule verdict: they
-- are used up in play, so "you don't need this" is never safe to say. Some
-- are also vendor reagents (water, milk) and would otherwise read as green.
-- Scrolls may earn their own rules later.
-- The seventh value is a "Vendor 5c, auction about 8s" note, set when a green was
-- dropped because the auction pays clearly more: the player sees no green dot,
-- and the tooltip uses the note to say why there is none.
function Bagwise.Verdict.Evaluate(item, state)
  if item.isKept then return nil, nil, nil end
  if item.isFlagged then
    local verdict, reason, _, _, heading = yellow("flagged")
    return verdict, reason, nil, nil, nil, heading
  end
  if item.classID == CONSUMABLE_CLASS_ID then
    local verdict, reason, _, _, heading = evaluateItemHint(item, state)
    if verdict then return verdict, reason, nil, nil, "item_hint", heading end
    verdict, reason, _, _, heading = evaluateOpenable(item)
    if verdict then return verdict, reason, nil, nil, "openable", heading end
    verdict, reason, _, _, heading = evaluateManaConsumable(item, state)
    if verdict then return verdict, reason, nil, nil, "mana_consumable", heading end
    verdict, reason, _, _, heading = evaluateOutleveledConsumable(item, state)
    return verdict, reason, nil, nil, verdict and "outleveled_consumable" or nil, heading
  end

  -- A blocked green is dropped and the next rule gets its turn. A yellow is
  -- only a hint, so it waits: a later rule's green (already vetted by Safety)
  -- beats it. Otherwise the first yellow stands.
  local hint, auctionNote
  for i = 1, #RULES do
    local verdict, reason, detail, tag, blockedBy, heading, note = runRule(RULES[i], item, state)
    if verdict == "green" and not blockedBy then
      return verdict, reason, detail, tag, RULES[i].name
    end
    if note and not auctionNote then auctionNote = note end
    if verdict == "yellow" and not hint then
      hint = { verdict, reason, detail, tag, RULES[i].name, heading }
    end
  end
  if hint then return hint[1], hint[2], hint[3], hint[4], hint[5], hint[6], auctionNote end
  return nil, nil, nil, nil, nil, nil, auctionNote
end

--- Every rule that had something to say about an item, including greens that
-- Safety dropped. For /bagwise why and for tests.
-- @return table list of { rule, verdict, reason, blockedBy }
function Bagwise.Verdict.Trace(item, state)
  local trace = {}
  for i = 1, #RULES do
    local verdict, reason, _, _, blockedBy = runRule(RULES[i], item, state)
    if verdict then
      trace[#trace + 1] = { rule = RULES[i].name, verdict = verdict,
                            reason = reason, blockedBy = blockedBy }
    end
  end
  return trace
end
