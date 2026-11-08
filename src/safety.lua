-- Bagwise: safety
-- One place that knows which items must never be called safe to delete.
--
-- The rules in verdict.lua only ever *propose* a green. Before a green is
-- accepted, Safety looks at the item itself. If the item is protected for a
-- reason the proposing rule is not allowed to override, the green is dropped
-- and the next rule gets a turn. A protection beats a green, the same idea as
-- the "deny-overrides" combining algorithm in access-control policies.
--
-- This is why a rule never has to remember "but not reagents": it can't
-- forget, because the check does not live in the rule.
--
-- Pure: reads item fields and the data tables, never the game.

Bagwise = Bagwise or {}
Bagwise.Safety = {}

-- Items that matter whatever else is true about them: the hearthstone and
-- the tools a profession needs to work at all.
local ESSENTIAL_ITEMS = {
  [6948] = true,  -- Hearthstone
  [6265] = true,  -- Soul Shard
  [2901] = true,  -- Mining Pick
  [5956] = true,  -- Blacksmith Hammer
  [7005] = true,  -- Skinning Knife
  [6219] = true,  -- Arclight Spanner
  [6256] = true,  -- Fishing Pole
  [4471] = true,  -- Flint and Tinder
  [5060] = true,  -- Thieves' Tools (Rogue lockpicking, also a quest objective)
  [6218] = true,  -- Runed Copper Rod (Enchanting)
  [6339] = true,  -- Runed Silver Rod
  [11130] = true, -- Runed Golden Rod
  [11145] = true, -- Runed Truesilver Rod
  [16207] = true, -- Runed Arcanite Rod
}

-- Item classes that are never called safe: they hold things, are worth
-- reading, or open doors.
local ESSENTIAL_CLASSES = {
  [1] = true,  -- containers
  [3] = true,  -- gems
  [6] = true,  -- projectiles
  [9] = true,  -- recipes
  [13] = true, -- keys
}

local REAGENT_CLASS_ID = 5
local QUEST_CLASS_ID = 12

local function data()
  return Bagwise.Data or {}
end

-- Each protection: a name (used by rules to say which they may override, and
-- shown by /bagwise why) and a test. Order is the order they are reported.
local PROTECTIONS = {
  { name = "essential_item", test = function(item)
      return ESSENTIAL_ITEMS[item.id] or ESSENTIAL_CLASSES[item.classID] or false
    end },
  -- Something you right-click to open (clams, lockboxes, loot bags): what is
  -- inside is the value, and no recipe or quest data says so.
  { name = "openable", test = function(item)
      return item.hasLoot or false
    end },
  { name = "recipe_reagent", test = function(item)
      return data().ReagentProfessions and data().ReagentProfessions[item.id] or false
    end },
  { name = "vendor_reagent", test = function(item)
      return data().VendorReagents and data().VendorReagents[item.id] or false
    end },
  { name = "spell_reagent", test = function(item)
      return (data().ClassReagents and data().ClassReagents[item.id])
          or item.classID == REAGENT_CLASS_ID or false
    end },
  -- A quest item is protected until the quests that need it are done. The
  -- quest rules override this one: finishing the quests is what lifts it.
  { name = "quest_item", test = function(item)
      return item.classID == QUEST_CLASS_ID or false
    end },
  -- An ordinary item (not in the game's quest class) that a quest also asks
  -- for: a tool, a mat, a piece of gear. Finishing the quest says nothing about
  -- its other uses, so no rule may call it safe.
  { name = "dual_use", test = function(item)
      local isQuestData = item.questItemQuestIDs ~= nil or item.startsQuestID ~= nil
      return isQuestData and item.classID ~= nil and item.classID ~= QUEST_CLASS_ID
    end },
  { name = "open_quest_item", test = function(item)
      return item.questItemQuestIDs ~= nil and not item.allQuestObjectivesCompleted
    end },
  { name = "open_quest_starter", test = function(item)
      return item.startsQuestID ~= nil and not item.startsQuestCompleted
    end },
}

--- Every protection that applies to this item, in a fixed order.
-- @return table list of protection names (empty when none)
function Bagwise.Safety.Protections(item)
  local found = {}
  for i = 1, #PROTECTIONS do
    if PROTECTIONS[i].test(item) then found[#found + 1] = PROTECTIONS[i].name end
  end
  return found
end

--- Is this item protected at all?
function Bagwise.Safety.IsProtected(item)
  for i = 1, #PROTECTIONS do
    if PROTECTIONS[i].test(item) then return true end
  end
  return false
end

--- The first protection a rule is not allowed to override, or nil.
-- @param item table
-- @param overrides table|nil set of protection names the rule may override
function Bagwise.Safety.Blocker(item, overrides)
  for i = 1, #PROTECTIONS do
    local protection = PROTECTIONS[i]
    if protection.test(item) and not (overrides and overrides[protection.name]) then
      return protection.name
    end
  end
  return nil
end

--- All protection names, for tests and documentation.
function Bagwise.Safety.Names()
  local names = {}
  for i = 1, #PROTECTIONS do names[i] = PROTECTIONS[i].name end
  return names
end
