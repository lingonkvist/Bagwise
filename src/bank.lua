-- Bagwise: what a verdict means once the item is in the bank.

Bagwise = Bagwise or {}

-- What a verdict means once the item is in the bank. People bank things on
-- purpose, often for another character, so a verdict only stays as it is
-- when it holds for any character; one that depends on this character's
-- professions, class or quests is capped at a yellow reminder; and one that
-- only says what to do with an item that is not banked yet is dropped. An
-- unknown rule gets the cautious treatment.
local BANK_KEEPS = {
  level_gap = true,     -- soulbound, so it cannot go to an alt
  poor_quality = true,
  no_recipe_use = true, -- nothing uses it, whoever you play
  openable = true,
}
local BANK_DROPS = {
  sell_at_vendor = true,     -- a vendor suggestion is not needed in the bank
  trivial_quest_item = true, -- you cannot abandon a quest from the bank
}

--- Turn a verdict result into what the bank should show.
-- The warband bank exists to share items between your characters, so there
-- even soulbound-looking gear may be meant for an alt: nothing is kept there
-- that depends on the item being bound.
-- @param result table|nil  { verdict, reason, detail, tag, rule }
-- @param isWarband boolean|nil  the slot is in the warband bank
-- @return table|nil  a fresh table (results are shared between slots), or
--   the same nil/empty result when there is nothing to show
function Bagwise.Verdict.ForBank(result, isWarband)
  if not result or not result.verdict then return result end
  if result.heading and result.heading.title == Bagwise.Notes.BANK_IT_TITLE then return {} end
  if BANK_DROPS[result.rule] then return {} end
  -- Nobody needs a vendor suggestion for something already banked.
  if BANK_KEEPS[result.rule] and not (isWarband and result.rule == "level_gap") then
    return { verdict = result.verdict, reason = result.reason, detail = result.detail,
             tag = result.tag, rule = result.rule, heading = result.heading, sellable = false }
  end
  return { verdict = "yellow", reason = result.reason, detail = result.detail,
           tag = result.tag, rule = result.rule, heading = result.heading }
end

