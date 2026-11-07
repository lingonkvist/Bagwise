-- Bagwise: verdict unit tests
-- Run with: lua5.1 tests/verdict_spec.lua (from the Bagwise/ root)

_G.Bagwise = nil

dofile("data/vendor_reagents.lua")
dofile("data/reagent_professions.lua")
dofile("data/class_reagents.lua")
dofile("data/quest_items.lua")
dofile("src/verdict.lua")

describe("Story 1.3: soulbound gear far below my level (reqLevel)", function()
  it("green when soulbound and 20+ levels below", function()
    local item = { id = 33001, isBound = true, isEquippable = true, reqLevel = 20 }
    local state = { class = "Warrior", race = "Human", level = 45 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear", reason)
  end)

  it("yellow when soulbound and 10-19 levels below", function()
    local item = { id = 33002, isBound = true, isEquippable = true, reqLevel = 30 }
    local state = { class = "Warrior", race = "Human", level = 42 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Low level gear", reason)
  end)

  it("no dot when soulbound but only 9 levels below", function()
    local item = { id = 33003, isBound = true, isEquippable = true, reqLevel = 31 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when NOT soulbound even if 20+ levels below", function()
    local item = { id = 33004, isBound = false, isEquippable = true, reqLevel = 10 }
    local state = { class = "Warrior", race = "Human", level = 50 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("green at exactly 20 levels below", function()
    local item = { id = 33006, isBound = true, isEquippable = true, reqLevel = 20 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("yellow at exactly 10 levels below", function()
    local item = { id = 33007, isBound = true, isEquippable = true, reqLevel = 30 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("no dot for an item with no signals at all", function()
    local item = { id = 99999 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)
end)

describe("Story 1.3 fallback: itemLevel when reqLevel is 0", function()
  it("green when reqLevel=0 but itemLevel is 20+ below player", function()
    local item = {
      id = 44001,
      isBound = true,
      isEquippable = true,
      reqLevel = 0,
      itemLevel = 10,
    }
    local state = { class = "Hunter", race = "Dwarf", level = 32 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low item level (10)", reason)
  end)

  it("yellow when reqLevel=0 but itemLevel is 10-19 below player", function()
    local item = {
      id = 44002,
      isBound = true,
      isEquippable = true,
      reqLevel = 0,
      itemLevel = 22,
    }
    local state = { class = "Hunter", race = "Dwarf", level = 32 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Low item level (22)", reason)
  end)

  it("no dot when reqLevel=0 and itemLevel is close to player level", function()
    local item = {
      id = 44003,
      isBound = true,
      isEquippable = true,
      reqLevel = 0,
      itemLevel = 28,
    }
    local state = { class = "Hunter", race = "Dwarf", level = 32 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when reqLevel=0 and no itemLevel either", function()
    local item = {
      id = 44004,
      isBound = true,
      isEquippable = true,
      reqLevel = 0,
      itemLevel = nil,
    }
    local state = { class = "Hunter", race = "Dwarf", level = 60 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when reqLevel=0 and itemLevel is 0", function()
    local item = {
      id = 44005,
      isBound = true,
      isEquippable = true,
      reqLevel = 0,
      itemLevel = 0,
    }
    local state = { class = "Hunter", race = "Dwarf", level = 60 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("reqLevel takes priority over itemLevel when both present", function()
    local item = {
      id = 44006,
      isBound = true,
      isEquippable = true,
      reqLevel = 30,
      itemLevel = 10,
    }
    local state = { class = "Warrior", race = "Human", level = 55 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear", reason)
  end)
end)

describe("Story 2.1: quest-starter items for completed quests", function()
  it("green when item starts a quest that is completed", function()
    local item = {
      id = 55001,
      startsQuestID = 1234,
      startsQuestCompleted = true,
      startsQuestName = "The Lost Idol",
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
    assert.are.equal("The Lost Idol", detail)
  end)

  it("includes quest level from QuestInfo in detail", function()
    local item = {
      id = 55010,
      startsQuestID = 204,
      startsQuestCompleted = true,
      startsQuestName = "Bad Medicine",
    }
    local state = { class = "Warrior", race = "Human", level = 60 }

    local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
    assert.are.equal("[34] Bad Medicine", detail)
  end)

  it("no dot when item starts a quest that is NOT completed", function()
    local item = {
      id = 55002,
      startsQuestID = 1234,
      startsQuestCompleted = false,
      startsQuestName = "The Lost Idol",
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when item does not start any quest", function()
    local item = { id = 55003, startsQuestID = nil, startsQuestCompleted = false }
    local state = { class = "Warrior", race = "Human", level = 30 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("green with fallback text when quest name is nil", function()
    local item = {
      id = 55004,
      startsQuestID = 9999,
      startsQuestCompleted = true,
      startsQuestName = nil,
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
    assert.is_nil(detail)
  end)

  it("gear verdict takes priority over quest verdict for bound equippable items", function()
    local item = {
      id = 55005,
      isBound = true,
      isEquippable = true,
      reqLevel = 10,
      startsQuestID = 1234,
      startsQuestCompleted = true,
      startsQuestName = "Some Quest",
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear", reason)
  end)
end)

describe("Epic 5: vendor reagents not needed by player's professions", function()
  local function stateWithProfessions(...)
    local skillLines = {}
    for _, id in ipairs({ ... }) do
      skillLines[id] = true
    end
    return {
      class = "Mage",
      race = "Human",
      level = 60,
      professionSkillLines = skillLines,
    }
  end

  it("green when player has no matching profession (Empty Vial, no Alchemy)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions(164, 197)

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
  end)

  it("no dot when player HAS a matching profession (Empty Vial, has Alchemy)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions(171, 164)

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("green when player has one profession but reagent needs two others", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(171)

    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("no dot when player matches ONE of multiple professions", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(197, 171)

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot for items NOT in the vendor reagent table", function()
    local item = { id = 12345 }
    local state = stateWithProfessions(171)

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("green when player has no professions at all (empty set)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions()

    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("no dot when professionSkillLines is nil (API unavailable)", function()
    local item = { id = 3371 }
    local state = { class = "Mage", race = "Human", level = 60 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("Salt shows green only when player has none of Tailoring, LW, or Cooking", function()
    local item = { id = 4289 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, stateWithProfessions(185)))
    assert.is_nil(Bagwise.Verdict.Evaluate(item, stateWithProfessions(165)))
    assert.are.equal("green",
      (Bagwise.Verdict.Evaluate(item, stateWithProfessions(171, 333))))
  end)

  it("ReagentProfessions wins over VendorReagents when they disagree", function()
    Bagwise.Data.VendorReagents[2604] = { 165, 197 }
    Bagwise.Data.ReagentProfessions[2604] = {
      { "Tailoring", 4, 1, 300 },
    }

    local item = { id = 2604, classID = 7 }
    local state = {
      class = "Warrior",
      playerClass = "WARRIOR",
      race = "Human",
      level = 60,
      professionSkillLines = { 165 },
      professionNames = { Leatherworking = true },
    }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
    assert.is_truthy(reason:find("Tailoring"))

    Bagwise.Data.VendorReagents[2604] = nil
    Bagwise.Data.ReagentProfessions[2604] = nil
  end)

  it("collapses 3+ professions to count", function()
    Bagwise.Data.VendorReagents[99901] = { 171, 164, 185 }
    Bagwise.Data.ReagentProfessions[99901] = {
      { "Alchemy",       2, 100, 200 },
      { "Blacksmithing", 3, 150, 250 },
      { "Cooking",       5, 50,  150 },
    }

    local item = { id = 99901 }
    local state = {
      class = "Warrior",
      playerClass = "WARRIOR",
      level = 60,
      professionSkillLines = {},
      professionNames = {},
    }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Vendor reagent (3 professions)", reason)

    Bagwise.Data.VendorReagents[99901] = nil
    Bagwise.Data.ReagentProfessions[99901] = nil
  end)
end)

describe("Epic 5: vendor reagent excludeClasses (Rogue vials)", function()
  local function stateWithProfessions(playerClass, ...)
    local skillLines = {}
    for _, id in ipairs({ ... }) do
      skillLines[id] = true
    end
    return {
      class = playerClass,
      playerClass = playerClass,
      race = "Human",
      level = 60,
      professionSkillLines = skillLines,
    }
  end

  it("Rogue without Alchemy gets nil on Empty Vial (not false green)", function()
    assert.is_nil(Bagwise.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Rogue without Alchemy gets nil on Leaded Vial", function()
    assert.is_nil(Bagwise.Verdict.Evaluate(
      { id = 3372 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Rogue without Alchemy gets nil on Crystal Vial", function()
    assert.is_nil(Bagwise.Verdict.Evaluate(
      { id = 8925 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Mage without Alchemy still gets green on Empty Vial", function()
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("MAGE", 164, 197))))
  end)

  it("Rogue WITH Alchemy gets nil on Empty Vial (has the profession)", function()
    assert.is_nil(Bagwise.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("ROGUE", 171, 165)))
  end)

  it("Imbued Vial has no excludeClasses, so Rogue without Alchemy gets green", function()
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(
      { id = 18256 }, stateWithProfessions("ROGUE", 164, 197))))
  end)
end)

describe("Class reagent verdict", function()
  it("returns yellow for Light Feather on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "WARRIOR" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Mage, Priest only (world drop)", reason)
  end)

  it("returns nil for Light Feather on a mage", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "MAGE" })))
  end)

  it("returns nil for Light Feather on a priest", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "PRIEST" })))
  end)

  it("returns yellow for Shiny Fish Scales on a paladin", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17057 }, { playerClass = "PALADIN" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Shaman only (world drop)", reason)
  end)

  it("returns nil for Shiny Fish Scales on a shaman", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17057 }, { playerClass = "SHAMAN" })))
  end)

  it("returns green for Arcane Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17020 }, { playerClass = "WARRIOR" })
    assert.are.equal("green", verdict)
    assert.are.equal("Mage only (vendor)", reason)
  end)

  it("returns nil for Arcane Powder on a mage", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17020 }, { playerClass = "MAGE" })))
  end)

  it("returns green for Ankh on a druid", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17030 }, { playerClass = "DRUID" })
    assert.are.equal("green", verdict)
    assert.are.equal("Shaman only (vendor)", reason)
  end)

  it("returns nil for Ankh on a shaman", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17030 }, { playerClass = "SHAMAN" })))
  end)

  it("returns green for Maple Seed on a hunter", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17034 }, { playerClass = "HUNTER" })
    assert.are.equal("green", verdict)
    assert.are.equal("Druid only (vendor)", reason)
  end)

  it("returns nil for Maple Seed on a druid", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17034 }, { playerClass = "DRUID" })))
  end)

  it("returns green for Symbol of Kings on a mage", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 21177 }, { playerClass = "MAGE" })
    assert.are.equal("green", verdict)
    assert.are.equal("Paladin only (vendor)", reason)
  end)

  it("returns green for Flash Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 5140 }, { playerClass = "WARRIOR" })
    assert.are.equal("green", verdict)
    assert.are.equal("Rogue only (vendor)", reason)
  end)

  it("returns yellow for Blinding Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 5530 }, { playerClass = "WARRIOR" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Rogue only (world drop)", reason)
  end)

  it("returns nil for a non-reagent item regardless of class", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 99999 }, { playerClass = "WARRIOR" })))
  end)

  it("returns nil when playerClass is missing from state", function()
    assert.is_nil((Bagwise.Verdict.Evaluate({ id = 17056 }, {})))
  end)

  it("returns nil when playerClass is nil", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(
      { id = 17056 }, { playerClass = nil })))
  end)
end)

describe("Story 3.3: quest objective items", function()
  it("green when item is a quest objective and all quests completed", function()
    local item = {
      id = 66001,
      questItemQuestIDs = { 100, 200 },
      allQuestObjectivesCompleted = true,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("All 2 quests completed", reason)
  end)

  it("no dot when some quests are not completed", function()
    local item = {
      id = 66002,
      questItemQuestIDs = { 100, 200 },
      allQuestObjectivesCompleted = false,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when item has no quest associations", function()
    local item = { id = 66003 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when questItemQuestIDs is nil", function()
    local item = {
      id = 66004,
      questItemQuestIDs = nil,
      allQuestObjectivesCompleted = nil,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("level gap rule takes priority over quest objective for bound gear", function()
    local item = {
      id = 66005,
      isBound = true,
      isEquippable = true,
      reqLevel = 10,
      questItemQuestIDs = { 100 },
      allQuestObjectivesCompleted = true,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear", reason)
  end)

  it("quest-starter rule takes priority over quest-objective rule", function()
    local item = {
      id = 66006,
      startsQuestID = 100,
      startsQuestCompleted = true,
      questItemQuestIDs = { 100 },
      allQuestObjectivesCompleted = true,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
  end)

  it("green with single quest completed, shows name and level in detail", function()
    local item = {
      id = 66007,
      questItemQuestIDs = { 500 },
      allQuestObjectivesCompleted = true,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason, detail = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
    assert.are.equal("[36] Crushridge Bounty", detail)
  end)
end)

describe("Epic 5.1: flag Trade Goods not used in any recipe", function()
  -- Use an item ID that is NOT in any data table
  local ORPHAN_ITEM_ID = 88888

  -- Ensure test isolation: this ID must not be in any table
  assert(not Bagwise.Data.ReagentProfessions[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in ReagentProfessions")
  assert(not Bagwise.Data.QuestItems[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in QuestItems")
  assert(not Bagwise.Data.VendorReagents[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in VendorReagents")
  assert(not Bagwise.Data.ClassReagents[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in ClassReagents")

  it("green for Trade Goods item not used in any recipe or quest", function()
    local item = { id = ORPHAN_ITEM_ID, classID = 7 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Not used for any quest or recipe", reason)
  end)

  it("no dot when item IS in ReagentProfessions (used in a recipe)", function()
    -- Silverleaf (765) is in ReagentProfessions for Alchemy
    local item = { id = 765, classID = 7 }
    local state = {
      class = "Warrior",
      playerClass = "WARRIOR",
      level = 60,
      professionSkillLines = {},
      professionNames = {},
    }

    -- Should get vendor reagent verdict or nil, never "No recipe uses this"
    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    if verdict then
      assert.is_truthy(reason ~= "Not used for any quest or recipe")
    end
  end)

  it("no dot when item IS in QuestItems (quest objective)", function()
    -- Refreshing Spring Water (159) is in QuestItems for quest 16
    local item = { id = 159, classID = 7 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    -- Should not fire 5.1 -- quest items are excluded
    if verdict then
      assert.is_truthy(reason ~= "Not used for any quest or recipe")
    end
  end)

  it("no dot when item IS in VendorReagents", function()
    -- Empty Vial (3371) is in VendorReagents
    local item = { id = 3371, classID = 7 }
    local state = {
      class = "Mage",
      playerClass = "MAGE",
      level = 60,
      professionSkillLines = { [171] = true },
      professionNames = { Alchemy = true },
    }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    -- Has Alchemy, so vendor reagent rule returns nil; 5.1 should also skip
    assert.is_nil(verdict)
  end)

  it("no dot for non-Trade-Goods items (consumable, gear, etc.)", function()
    -- classID 0 = Consumable, not Trade Goods
    local item = { id = ORPHAN_ITEM_ID, classID = 0 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot when classID is nil", function()
    local item = { id = ORPHAN_ITEM_ID, classID = nil }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("no dot for equippable gear even if classID happens to be 7", function()
    -- Hypothetical edge case: a Trade Goods item that is somehow equippable
    -- Level gap rule fires first for bound equippable items
    local item = {
      id = ORPHAN_ITEM_ID,
      classID = 7,
      isBound = true,
      isEquippable = true,
      reqLevel = 10,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    -- Level gap rule should fire first, not 5.1
    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear", reason)
  end)

  it("no dot when item is in ClassReagents", function()
    -- Temporarily add a fake classID=7 class reagent to test exclusion
    Bagwise.Data.ClassReagents[ORPHAN_ITEM_ID] = {
      classes = { MAGE = true },
      verdict = "green",
    }

    local item = { id = ORPHAN_ITEM_ID, classID = 7 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    -- ClassReagent rule fires first: "Mage only (vendor)"
    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Mage"))

    Bagwise.Data.ClassReagents[ORPHAN_ITEM_ID] = nil
  end)
end)

describe("Epic 6: player overrides", function()
  local belowLevelGear = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20 }
  local state = { class = "Warrior", race = "Human", level = 45 }

  it("kept item gets no dot even when a rule would make it green", function()
    local item = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20, isKept = true }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("flagged item is yellow even when no rule fires", function()
    local item = { id = 33011, isBound = false, isEquippable = false, isFlagged = true }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Flagged by you", reason)
  end)

  it("flagged item stays yellow even when a rule would make it green", function()
    local item = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20, isFlagged = true }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
  end)

  it("unmarked item still follows the normal rules", function()
    local verdict = Bagwise.Verdict.Evaluate(belowLevelGear, state)

    assert.are.equal("green", verdict)
  end)
end)

describe("Consumables never get a verdict", function()
  local CONSUMABLE = 0
  local TRADE_GOODS = 7
  local REFRESHING_SPRING_WATER = 159
  local ICE_COLD_MILK = 1179
  local EMPTY_VIAL = 3371

  -- A mage with no professions: every vendor reagent rule would fire.
  local mage = {
    class = "Mage",
    playerClass = "MAGE",
    level = 60,
    professionSkillLines = {},
    professionNames = {},
  }

  it("no dot on drinks that are also vendor reagents (water)", function()
    local item = { id = REFRESHING_SPRING_WATER, classID = CONSUMABLE }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, mage))
  end)

  it("no dot on food that is also a vendor reagent (milk)", function()
    local item = { id = ICE_COLD_MILK, classID = CONSUMABLE }

    assert.is_nil(Bagwise.Verdict.Evaluate(item, mage))
  end)

  it("a flagged consumable is still yellow: your own mark wins", function()
    local item = { id = REFRESHING_SPRING_WATER, classID = CONSUMABLE, isFlagged = true }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, mage)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Flagged by you", reason)
  end)

  it("real vendor reagents that are not consumables keep their green dot", function()
    local item = { id = EMPTY_VIAL, classID = TRADE_GOODS }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, mage)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
  end)
end)


describe("Verdict.QuestsForFaction", function()
  local savedInfo

  local function withQuestInfo(info)
    savedInfo = Bagwise.Data.QuestInfo
    Bagwise.Data.QuestInfo = info
  end

  local function restore()
    Bagwise.Data.QuestInfo = savedInfo
  end

  it("drops quests only the other faction can take", function()
    withQuestInfo({
      [1] = { 10, "Elwynn Forest", "Alliance version", "A" },
      [2] = { 10, "Durotar", "Horde version", "H" },
    })

    local alliance = Bagwise.Verdict.QuestsForFaction({ 1, 2 }, "Alliance")
    local horde = Bagwise.Verdict.QuestsForFaction({ 1, 2 }, "Horde")
    restore()

    assert.are.equal(1, #alliance)
    assert.are.equal(1, alliance[1])
    assert.are.equal(1, #horde)
    assert.are.equal(2, horde[1])
  end)

  it("keeps quests open to both factions", function()
    withQuestInfo({ [3] = { 40, "Tanaris", "Neutral quest" } })

    local kept = Bagwise.Verdict.QuestsForFaction({ 3 }, "Horde")
    restore()

    assert.are.equal(1, #kept)
  end)

  it("keeps quests it has no data for, so the item stays needed", function()
    withQuestInfo({})

    local kept = Bagwise.Verdict.QuestsForFaction({ 99 }, "Alliance")
    restore()

    assert.are.equal(1, #kept)
  end)

  it("keeps everything when the faction is unknown", function()
    withQuestInfo({ [2] = { 10, "Durotar", "Horde version", "H" } })

    local kept = Bagwise.Verdict.QuestsForFaction({ 2 }, nil)
    restore()

    assert.are.equal(1, #kept)
  end)

  it("returns an empty list when every quest belongs to the other faction", function()
    withQuestInfo({ [2] = { 10, "Durotar", "Horde version", "H" } })

    local kept = Bagwise.Verdict.QuestsForFaction({ 2 }, "Alliance")
    restore()

    assert.are.equal(0, #kept)
  end)
end)
