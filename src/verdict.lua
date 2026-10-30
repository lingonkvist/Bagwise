-- Bagwise: verdict engine
-- Pure function: (item, playerState) -> verdict, reason
-- No WoW API calls in this file. Everything comes through arguments,
-- making it testable with busted outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

-- Helper: check if a value exists in a list
local function contains(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

--- Evaluate a single item and return a verdict.
-- @param item   table  Item data gathered by the scanner
-- @param state  table  Player state (class, race, level, professions, etc.)
-- @return string|nil   "green", "yellow", or nil
-- @return string|nil   Human-readable reason, or nil
function Bagwise.Verdict.Evaluate(item, state)
  -- Story 1.1: soulbound gear my class cannot use
  if item.isBound
      and item.isEquippable
      and item.classRestriction
      and not contains(item.classRestriction, state.class)
  then
    return "green", "Not usable by " .. state.class
  end

  -- Story 1.2: soulbound gear restricted to another race
  if item.isBound
      and item.isEquippable
      and item.raceRestriction
      and not contains(item.raceRestriction, state.race)
  then
    return "green", "Restricted to " .. table.concat(item.raceRestriction, ", ")
  end

  -- Story 1.3: soulbound gear far below my level
  if item.isBound
      and item.isEquippable
      and item.reqLevel
      and item.reqLevel > 0
  then
    local gap = state.level - item.reqLevel
    if gap >= 20 then
      return "green", "Required level " .. item.reqLevel .. ", you are " .. state.level
    elseif gap >= 10 then
      return "yellow", "Required level " .. item.reqLevel .. ", you are " .. state.level
    end
  end

  return nil, nil
end
