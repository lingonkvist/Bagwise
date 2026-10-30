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

  return nil, nil
end
