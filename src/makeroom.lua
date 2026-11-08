-- Bagwise: make room for loot
-- When the bags are full and the loot window is open, work out which loot is
-- worth a slot and which junk to delete to make room. Pure: the scanner reads
-- the game and hands plain tables in.
--
-- Loot and junk are ranked by vendor price times stack size. Loot that beats
-- the cheapest junk is worth taking; loot that does not is better left.

Bagwise = Bagwise or {}
Bagwise.MakeRoom = {}

local JUNK_CLASS_ID = 15    -- Miscellaneous
local JUNK_SUBCLASS_ID = 0  -- Junk

local POOR_QUALITY = 0
local COMMON_QUALITY = 1

-- Never offered as junk on top of what Safety protects: used up, or crafting
-- materials. (Safety lets the verdict rules call unused trade goods green, but
-- here a mat is never picked just because its stack is cheap.)
local NEVER_JUNK_CLASSES = {
  [0] = true, -- consumables
  [7] = true, -- trade goods
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
  if NEVER_JUNK_CLASSES[item.classID] then return false end
  if Bagwise.Safety.IsProtected(item) then return false end

  if item.quality == POOR_QUALITY then return true end
  if item.quality ~= COMMON_QUALITY then return false end
  if item.isEquippable then
    return existing ~= nil and existing.verdict == "green"
  end
  -- A plain white that is not gear is only offered when the game files it as
  -- Junk. Other whites (companion pets, tokens, odds and ends) can matter.
  return item.classID == JUNK_CLASS_ID and item.subClassID == JUNK_SUBCLASS_ID
end

--- What the stack sells for, in copper.
function Bagwise.MakeRoom.ValueOf(sellPrice, count)
  return (sellPrice or 0) * (count or 1)
end

--- Decide what to take and what to delete.
-- @param loot table  list of { slot, value, priority, stacks } (priority = always
--                    take: quest items, rares, things with no vendor price;
--                    stacks = joins a stack you already carry, needs no slot)
-- @param junk table  list of { key, bag, slot, value } (bag junk candidates)
-- @param freeSlots number free regular bag slots
-- @return table { take = {[lootSlot]=true}, deletes = {junk entries in order},
--                 active = boolean }
function Bagwise.MakeRoom.Plan(loot, junk, freeSlots)
  local plan = { take = {}, deletes = {}, active = false }

  -- Loot that joins an existing stack never needs a free slot.
  local needsSlot = {}
  for i = 1, #loot do
    if not loot[i].stacks then needsSlot[#needsSlot + 1] = loot[i] end
  end
  if #needsSlot <= freeSlots then return plan end
  plan.active = true
  for i = 1, #loot do
    if loot[i].stacks then plan.take[loot[i].slot] = true end
  end

  local lootSorted = {}
  for i = 1, #needsSlot do lootSorted[i] = needsSlot[i] end
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
  result.glow = true -- the overlay draws a green border glow
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
