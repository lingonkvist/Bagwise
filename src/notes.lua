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
  bank_quest = function(level, label)
    return "Bank it, quest needs level " .. level, BANK_IT, label or ("Needs level " .. level)
  end,
  bank_event = function(event, label)
    return "Bank it, for a " .. event .. " quest", BANK_IT,
        label and (capitalize(event) .. ": " .. label) or capitalize(event)
  end,
  outleveled_reagent = function(profession, skill, green)
    -- With the green point known, say where the last recipe turns green.
    local rest = green and ("recipes turn green at " .. profession .. " " .. skill)
        or (profession .. " recipes use it up to " .. skill)
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
  weak_bandage = function(heal, percent, health)
    return "Weak bandage", "Weak bandage",
        "Heals " .. percent .. "% of your health (" .. heal .. " of " .. health .. ")"
  end,
  wrong_class_reagent = function(whole)
    return whole, "Wrong class reagent", whole
  end,
  other_profession_reagent = function(professions)
    local list
    if #professions > 3 then
      list = #professions .. " professions"
    else
      list = table.concat(professions, ", ")
    end
    return "Only used by professions you don't have. May sell at the auction house",
        "Not your profession", "Used by " .. list
  end,
  library_book = function(faction)
    local where = "the librarian in Stormwind or Undercity"
    local short = "Stormwind or Undercity"
    if faction == "Alliance" then
      where, short = "Garion Wendell in Stormwind", "Garion Wendell, Stormwind"
    elseif faction == "Horde" then
      where, short = "Owen Thadd in Undercity", "Owen Thadd, Undercity"
    end
    return "Library book, hand it in to " .. where, "Library book", "Hand in to " .. short
  end,
  shard_buff = function()
    return "Trade 4 of these to Mangletooth for a buff in the Barrens", "Trade for a buff",
        "Mangletooth, Camp Taurajo"
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
