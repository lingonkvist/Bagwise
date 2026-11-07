-- Bagwise: make room for loot
-- When the bags are full and the loot window is open, work out which loot is
-- worth a slot and which junk to delete to make room. Pure: the scanner reads
-- the game and hands plain tables in.
--
-- Loot and junk are ranked by vendor price times stack size. Loot that beats
-- the cheapest junk is worth taking; loot that does not is better left.

Bagwise = Bagwise or {}
Bagwise.MakeRoom = {}

local POOR_QUALITY = 0
local COMMON_QUALITY = 1

-- Never offered as junk: used up, holds things, crafts, or matters to a quest.
local NEVER_JUNK_CLASSES = {
  [0] = true,  -- consumables
  [1] = true,  -- containers
  [3] = true,  -- gems
  [5] = true,  -- reagents
  [6] = true,  -- projectiles
  [7] = true,  -- trade goods
  [9] = true,  -- recipes
  [12] = true, -- quest items
  [13] = true, -- keys
}

-- Specific items that are not otherwise recognisable: hearthstone, soul
-- shard, spell reagents and profession tools.
local NEVER_JUNK_ITEMS = {
  [6948] = true,  -- Hearthstone
  [6265] = true,  -- Soul Shard
  [17030] = true, -- Ankh
  [17031] = true, -- Rune of Teleportation
  [17032] = true, -- Rune of Portals
  [17033] = true, -- Symbol of Divinity
  [21177] = true, -- Symbol of Kings
  [17056] = true, -- Light Feather
  [17020] = true, -- Arcane Powder
  [2901] = true,  -- Mining Pick
  [5956] = true,  -- Blacksmith Hammer
  [7005] = true,  -- Skinning Knife
  [6219] = true,  -- Arclight Spanner
  [6256] = true,  -- Fishing Pole
  [4471] = true,  -- Flint and Tinder
}

--- Could this bag item be suggested for deletion?
-- Grays and whites that sell for something, and are not on the never list.
-- White gear only counts once Bagwise already calls it safe (a class that
-- can't wear it, or worse than what is equipped), so a possible upgrade is
-- never offered.
-- @param item table    the scanner's item fields
-- @param existing table|nil the slot's verdict result
function Bagwise.MakeRoom.IsJunkCandidate(item, existing)
  if item.isKept or item.isFlagged then return false end
  if (item.sellPrice or 0) <= 0 then return false end
  if item.questItemQuestIDs then return false end
  if NEVER_JUNK_CLASSES[item.classID] or NEVER_JUNK_ITEMS[item.id] then
    return false
  end
  local data = Bagwise.Data or {}
  if data.ReagentProfessions and data.ReagentProfessions[item.id] then return false end
  if data.VendorReagents and data.VendorReagents[item.id] then return false end
  if data.QuestItems and data.QuestItems[item.id] then return false end

  if item.quality == POOR_QUALITY then return true end
  if item.quality ~= COMMON_QUALITY then return false end
  if item.isEquippable then
    return existing ~= nil and existing.verdict == "green"
  end
  return true
end

--- What the stack sells for, in copper.
function Bagwise.MakeRoom.ValueOf(sellPrice, count)
  return (sellPrice or 0) * (count or 1)
end

--- Decide what to take and what to delete.
-- @param loot table  list of { slot, value, priority } (priority = always take:
--                    quest items, rares, things with no vendor price)
-- @param junk table  list of { key, bag, slot, value } (bag junk candidates)
-- @param freeSlots number free regular bag slots
-- @return table { take = {[lootSlot]=true}, deletes = {junk entries in order},
--                 active = boolean }
function Bagwise.MakeRoom.Plan(loot, junk, freeSlots)
  local plan = { take = {}, deletes = {}, active = false }
  if #loot <= freeSlots then return plan end
  plan.active = true

  local lootSorted = {}
  for i = 1, #loot do lootSorted[i] = loot[i] end
  table.sort(lootSorted, function(a, b)
    if (a.priority and true or false) ~= (b.priority and true or false) then
      return a.priority and true or false
    end
    if a.value ~= b.value then return a.value > b.value end
    return a.slot < b.slot
  end)

  local junkSorted = {}
  for i = 1, #junk do junkSorted[i] = junk[i] end
  table.sort(junkSorted, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
  end)

  local free = freeSlots
  for _, piece in ipairs(lootSorted) do
    if free > 0 then
      plan.take[piece.slot] = true
      free = free - 1
    else
      local victim = junkSorted[#plan.deletes + 1]
      if not victim then break end
      if piece.priority or piece.value > victim.value then
        plan.take[piece.slot] = true
        plan.deletes[#plan.deletes + 1] = victim
      else
        break
      end
    end
  end
  return plan
end

--- The result stored for a junk slot chosen for deletion. A slot that already
-- has a verdict keeps its dot and wording (green stays green). One with none
-- gets a yellow dot: it was picked by price, which is a hint, not a certainty.
-- @param existing table|nil
-- @param value number copper
function Bagwise.MakeRoom.MarkedResult(existing, value)
  local result = {}
  if existing then
    for k, v in pairs(existing) do result[k] = v end
  end
  if not result.verdict then
    result.verdict = "yellow"
    result.reason = "Cheapest junk, sells for " .. Bagwise.Verdict.FormatMoney(value)
  end
  result.detail = "Delete to make room for your loot"
  result.pulse = true -- the overlay makes the dot pulse
  return result
end

--- Everything else goes quiet while a plan is showing: the hover text stays,
-- the dot is held back, so the only dots left are the ones to act on.
function Bagwise.MakeRoom.QuietResult(existing)
  if not (existing and existing.verdict) then return existing end
  local result = {}
  for k, v in pairs(existing) do result[k] = v end
  result.quiet = true
  return result
end

--- Undo QuietResult for a slot that is about to be marked.
function Bagwise.MakeRoom.RestoreResult(result)
  if not (result and result.quiet) then return result end
  local restored = {}
  for k, v in pairs(result) do restored[k] = v end
  restored.quiet = nil
  return restored
end
