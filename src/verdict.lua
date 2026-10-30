-- Bagwise: verdict engine
-- Pure function: (item, playerState) -> verdict, reason
-- No WoW API calls in this file. Everything comes through arguments,
-- making it testable with busted outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

--- Evaluate a single item and return a verdict.
-- @param item   table  Item data gathered by the scanner
-- @param state  table  Player state (class, race, level, professions, etc.)
-- @return string|nil   "green", "yellow", or nil
-- @return string|nil   Human-readable reason, or nil
function Bagwise.Verdict.Evaluate(item, state)
  -- Stories 1.1 + 1.2: soulbound gear not usable by your character
  -- DISABLED: IsUsableItem() checks right-click usability (potions,
  -- scrolls), NOT whether your class can equip gear. It returns false
  -- for ALL equipment. Proper class restriction detection needs
  -- tooltip scanning or a proficiency lookup table -- a separate story.

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
