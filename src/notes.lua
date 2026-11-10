-- Bagwise: the words behind every yellow verdict.
--
-- Every yellow Bagwise can show is defined here once: the full reason (for the
-- report and /bagwise why), a short heading of three or four words, and the
-- detail line under it. A rule returns the heading with its verdict, so the
-- tooltip never has to guess it from the reason text.
Bagwise = Bagwise or {}
Bagwise.Notes = {
  -- Title of the hints that tell you to bank an item. Pointless once the item
  -- is in the bank, so the bank view drops anything with this title.
  BANK_IT_TITLE = "Bank it",
}
local BANK_IT = Bagwise.Notes.BANK_IT_TITLE

local function capitalize(text)
  return (text:gsub("^%l", string.upper))
end

local NOTES = {
  very_low_item_level = function(n, you)
    return "Very low item level (" .. n .. " for level " .. you .. ")", "Outleveled gear", "Item level " .. n .. ", low for level " .. you
  end,
  very_low_level_gear = function(n, you)
    return "Very low level gear (needs " .. n .. ", you are " .. you .. ")", "Outleveled gear", "Required level " .. n .. ", you are " .. you
  end,
  low_item_level = function(n, you)
    return "Low item level (" .. n .. " for level " .. you .. ")", "Outleveled gear", "Item level " .. n .. ", low for level " .. you
  end,
  low_level_gear = function(n, you)
    return "Low level gear (needs " .. n .. ", you are " .. you .. ")", "Outleveled gear", "Required level " .. n .. ", you are " .. you
  end,
  quest_abandon = function()
    return "Quest is far below you, consider abandoning it", "Low-level quest", "Consider abandoning it"
  end,
  quest_not_worth = function()
    return "Quest is far below you, probably not worth taking", "Low-level quest", "Probably not worth it"
  end,
  gray_worth = function(value, isCheapest)
    return (isCheapest and "Cheapest gray" or "Gray") .. ", but worth " .. value,
        isCheapest and "Cheapest gray" or "Gray item", "Sells for " .. value
  end,
  no_known_use = function(value)
    return "Not used for any quest or recipe, sells for " .. value, "No known use", nil
  end,
  not_your_profession = function()
    return "You don't have this profession. May sell at the auction house", "Not your profession", "Try the auction house"
  end,
  bank_skill = function(profession, skill)
    return "Bank it, needs " .. profession .. " " .. skill, BANK_IT, "Needs " .. profession .. " " .. skill
  end,
  bank_level = function(level)
    return "Bank it, needs level " .. level, BANK_IT, "Needs level " .. level
  end,
  bank_used_from = function(profession, skill)
    return "Bank it, used from " .. profession .. " " .. skill, BANK_IT, "Used from " .. profession .. " " .. skill
  end,
  outleveled_reagent = function(profession, maxSkill)
    local rest = profession .. " recipes use it up to " .. maxSkill
    return "Outleveled, " .. rest, "Outleveled reagent", capitalize(rest)
  end,
  open_it = function()
    return "Open it, the contents may stack", "Open it", "Contents may stack"
  end,
  no_mana = function(who)
    return who .. " have no mana. May sell at the auction house", "Not for your class", "No mana for " .. who
  end,
  low_level_consumable = function(noun, level, you)
    return "Low-level " .. noun .. " (level " .. level .. ", you are " .. you .. ")",
        "Low-level " .. noun, "Level " .. level .. ", you are " .. you
  end,
  wrong_class_reagent = function(whole)
    return whole, "Wrong class reagent", whole
  end,
  flagged = function()
    return "Flagged by you", "Flagged by you", nil
  end,
}


--- Look up a note: returns the full reason and a heading { title, detail }.
-- @param key string  a key of NOTES
function Bagwise.Notes.Get(key, ...)
  local reason, title, detail = NOTES[key](...)
  return reason, { title = title, detail = detail }
end
