-- Bagwise: verdict unit tests
-- Run with: lua5.1 tests/verdict_spec.lua (from the Bagwise/ root)

_G.Bagwise = nil

dofile("data/vendor_reagents.lua")
dofile("data/reagent_professions.lua")
dofile("data/class_reagents.lua")
dofile("data/quest_items.lua")
dofile("src/safety.lua")
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
    local item = { id = ORPHAN_ITEM_ID, classID = 7, subClassID = 9, sellPrice = 20 }
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

describe("Outgeared white armor", function()
  local state = { level = 30, professionNames = {}, professionSkillLines = {} }

  local function whiteArmor(overrides)
    local item = {
      id = 1001, quality = 1, isEquippable = true, classID = 4,
      itemLevel = 12, isBound = false,
      equippedInSlots = { { quality = 2, itemLevel = 20 } },
    }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  it("is green when every slot holds a better-than-white item of equal or higher level", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(whiteArmor(), state)

    assert.are.equal("green", verdict)
    assert.are.equal("Worse than your equipped gear", reason)
  end)

  it("is silent when the equipped item is also white", function()
    local item = whiteArmor({ equippedInSlots = { { quality = 1, itemLevel = 30 } } })

    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("is silent when the slot is empty or unknown", function()
    local unknown = whiteArmor()
    unknown.equippedInSlots = nil

    assert.is_nil(Bagwise.Verdict.Evaluate(unknown, state))
    assert.is_nil(Bagwise.Verdict.Evaluate(whiteArmor({ equippedInSlots = {} }), state))
  end)

  it("needs both ring or trinket slots to be better", function()
    local oneWeak = whiteArmor({
      equippedInSlots = { { quality = 2, itemLevel = 20 }, { quality = 1, itemLevel = 5 } },
    })
    local bothBetter = whiteArmor({
      equippedInSlots = { { quality = 2, itemLevel = 20 }, { quality = 3, itemLevel = 25 } },
    })

    assert.is_nil(Bagwise.Verdict.Evaluate(oneWeak, state))
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(bothBetter, state)))
  end)

  it("leaves green and better items alone", function()
    local green = whiteArmor({ quality = 2 })

    assert.is_nil(Bagwise.Verdict.Evaluate(green, state))
  end)

  it("leaves weapons alone", function()
    local weapon = whiteArmor({ classID = 2 })

    assert.is_nil(Bagwise.Verdict.Evaluate(weapon, state))
  end)

  it("never overrides a kept item", function()
    local kept = whiteArmor({ isKept = true })

    assert.is_nil(Bagwise.Verdict.Evaluate(kept, state))
  end)
end)

describe("Verdict.FormatMoney", function()
  it("writes gold, silver and copper, leaving out zero parts", function()
    assert.are.equal("1g 20s 5c", Bagwise.Verdict.FormatMoney(12005))
    assert.are.equal("2g", Bagwise.Verdict.FormatMoney(20000))
    assert.are.equal("45s", Bagwise.Verdict.FormatMoney(4500))
    assert.are.equal("7c", Bagwise.Verdict.FormatMoney(7))
    assert.are.equal("0c", Bagwise.Verdict.FormatMoney(0))
  end)
end)

describe("Gray items by vendor value", function()
  local function gray(overrides)
    local item = {
      id = 7001, quality = 0, classID = 15, isBound = false,
      sellPrice = 10, count = 1,
    }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  local function stateAtLevel(level)
    return { level = level, professionNames = {}, professionSkillLines = {} }
  end

  it("cheap grays are green and say what they sell for", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(gray(), stateAtLevel(30))

    assert.are.equal("green", verdict)
    assert.are.equal("Poor quality, sells for 10c", reason)
  end)

  it("grays with no vendor value are green", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(gray({ sellPrice = 0 }), stateAtLevel(30))

    assert.are.equal("green", verdict)
    assert.are.equal("Poor quality, no vendor value", reason)
  end)

  it("a gray that sells for real money is yellow and says so", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(gray({ sellPrice = 500 }), stateAtLevel(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Gray, but worth 5s", reason)
  end)

  it("judges the whole stack, not one item", function()
    local verdict = Bagwise.Verdict.Evaluate(gray({ sellPrice = 20, count = 20 }), stateAtLevel(30))

    assert.are.equal("yellow", verdict)
  end)

  it("the bar rises with level: 60c is worth a glance at level 1 but not at level 60", function()
    local early = Bagwise.Verdict.Evaluate(gray({ sellPrice = 60 }), stateAtLevel(1))
    local late = Bagwise.Verdict.Evaluate(gray({ sellPrice = 60 }), stateAtLevel(60))

    assert.are.equal("yellow", early)
    assert.are.equal("green", late)
  end)

  it("leaves a gray alone while a quest still lists it", function()
    local verdict = Bagwise.Verdict.Evaluate(gray({ questItemQuestIDs = { 55 } }), stateAtLevel(30))

    assert.is_nil(verdict)
  end)

  it("leaves a gray alone when a recipe uses it", function()
    Bagwise.Data.ReagentProfessions = { [7001] = { { "Cooking", 1, 1, 50 } } }

    local verdict = Bagwise.Verdict.Evaluate(gray(), stateAtLevel(30))
    Bagwise.Data.ReagentProfessions = nil

    assert.is_nil(verdict)
  end)

  it("does not touch white or better items", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(gray({ quality = 1 }), stateAtLevel(30))))
  end)

  it("keeps a kept gray silent and a flagged gray yellow", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(gray({ isKept = true }), stateAtLevel(30))))
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(gray({ isFlagged = true }), stateAtLevel(30))))
  end)
end)

describe("Unused trade goods that sell well", function()
  local function unusedTradeGood(overrides)
    local item = { id = 7002, quality = 1, classID = 7, subClassID = 9, isBound = false, sellPrice = 0, count = 1 }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  local state = { level = 30, professionNames = {}, professionSkillLines = {} }

  it("a cheap unused trade good is still green", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(unusedTradeGood({ sellPrice = 20 }), state)

    assert.are.equal("green", verdict)
    assert.are.equal("Not used for any quest or recipe", reason)
  end)

  it("one that sells for real money is yellow and says how much", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(unusedTradeGood({ sellPrice = 4000 }), state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Not used for any quest or recipe, sells for 40s", reason)
  end)

  it("a stack of cheap ones can add up to yellow", function()
    local verdict = Bagwise.Verdict.Evaluate(unusedTradeGood({ sellPrice = 50, count = 20 }), state)

    assert.are.equal("yellow", verdict)
  end)

  it("things you use directly are never called unused: parts, devices, explosives, rods, oils, generic goods", function()
    for _, subClassID in ipairs({ 0, 1, 2, 3, 11, 12, 14, 15 }) do
      assert.is_nil((Bagwise.Verdict.Evaluate(unusedTradeGood({ sellPrice = 20, subClassID = subClassID }), state)))
    end
  end)

  it("a known-use item such as a Greenhouse seed is never called unused", function()
    Bagwise.Data.ProtectedItems = { [268415] = "Herb seed, used in the Herbalism Greenhouse" }
    local seed = unusedTradeGood({ id = 268415, sellPrice = 10, subClassID = 9 })
    assert.is_nil((Bagwise.Verdict.Evaluate(seed, state)))
    Bagwise.Data.ProtectedItems = nil
  end)

  it("an item with no vendor value is a token, not a leftover, so it gets no verdict", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(unusedTradeGood({ sellPrice = 0 }), state)))
  end)
end)

describe("White armor your class can't wear", function()
  local function whiteArmor(subClassID, overrides)
    local item = {
      id = 8001, quality = 1, isEquippable = true, classID = 4,
      subClassID = subClassID, itemLevel = 12, isBound = false,
    }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  local function stateFor(class)
    return { level = 30, playerClass = class, professionNames = {}, professionSkillLines = {} }
  end

  it("mail on a rogue is green and says why", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(whiteArmor(3), stateFor("ROGUE"))

    assert.are.equal("green", verdict)
    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("plate and leather are checked per class", function()
    assert.are.equal("Hunters can't wear plate",
      select(2, Bagwise.Verdict.Evaluate(whiteArmor(4), stateFor("HUNTER"))))
    assert.are.equal("Mages can't wear leather",
      select(2, Bagwise.Verdict.Evaluate(whiteArmor(2), stateFor("MAGE"))))
  end)

  it("shields and class relics follow the same rule", function()
    assert.are.equal("Rogues can't use shields",
      select(2, Bagwise.Verdict.Evaluate(whiteArmor(6), stateFor("ROGUE"))))
    assert.are.equal("Priests can't use totems",
      select(2, Bagwise.Verdict.Evaluate(whiteArmor(9), stateFor("PRIEST"))))
  end)

  it("armor the class learns later is green until that level", function()
    local early = Bagwise.Verdict.Evaluate(whiteArmor(4), stateFor("WARRIOR"))
    local _, reason = Bagwise.Verdict.Evaluate(whiteArmor(4), stateFor("WARRIOR"))

    assert.are.equal("green", early)
    assert.are.equal("Warriors can't wear plate until 40", reason)
    local _, shamanReason = Bagwise.Verdict.Evaluate(whiteArmor(3), stateFor("SHAMAN"))
    assert.are.equal("Shamans can't wear mail until 40", shamanReason)
  end)

  it("goes silent once the class can wear it", function()
    local atForty = { level = 40, playerClass = "WARRIOR", professionNames = {}, professionSkillLines = {} }

    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(4), atForty)))
    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(1), stateFor("MAGE"))))
    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(3), stateFor("WARRIOR"))))
  end)

  it("stays silent for classes it doesn't know", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(3), stateFor("SOMETHINGNEW"))))
  end)

  it("takes priority over the outgeared-white wording", function()
    local item = whiteArmor(3, { equippedInSlots = { { quality = 2, itemLevel = 20 } } })

    local _, reason = Bagwise.Verdict.Evaluate(item, stateFor("ROGUE"))

    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("only applies to white armor", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(3, { quality = 2 }), stateFor("ROGUE"))))
    assert.is_nil((Bagwise.Verdict.Evaluate(whiteArmor(3, { classID = 2 }), stateFor("ROGUE"))))
  end)
end)

describe("Verdict.SilenceAllButCheapest", function()
  local function entry(key, bag, slot, value)
    return { key = key, bag = bag, slot = slot, value = value }
  end

  it("keeps only the cheapest entry green", function()
    local silenced = Bagwise.Verdict.SilenceAllButCheapest({
      entry("0:1", 0, 1, 50), entry("0:2", 0, 2, 5), entry("1:1", 1, 1, 20),
    }, 1)

    assert.is_nil(silenced["0:2"])
    assert.is_truthy(silenced["0:1"])
    assert.is_truthy(silenced["1:1"])
  end)

  it("breaks ties by bag and slot so the choice is stable", function()
    local silenced = Bagwise.Verdict.SilenceAllButCheapest({
      entry("2:3", 2, 3, 10), entry("1:9", 1, 9, 10), entry("1:2", 1, 2, 10),
    }, 1)

    assert.is_nil(silenced["1:2"])
    assert.is_truthy(silenced["1:9"])
    assert.is_truthy(silenced["2:3"])
  end)

  it("silences nothing when there are no more entries than allowed", function()
    local silenced = Bagwise.Verdict.SilenceAllButCheapest({ entry("0:1", 0, 1, 5) }, 1)

    assert.is_nil(next(silenced))
  end)

  it("lets more through when the limit is raised", function()
    local silenced = Bagwise.Verdict.SilenceAllButCheapest({
      entry("0:1", 0, 1, 1), entry("0:2", 0, 2, 2), entry("0:3", 0, 3, 3),
    }, 2)

    assert.is_nil(silenced["0:1"])
    assert.is_nil(silenced["0:2"])
    assert.is_truthy(silenced["0:3"])
  end)

  it("gray verdicts carry the tag the scanner uses to find them", function()
    local item = { id = 1, quality = 0, classID = 15, sellPrice = 5, count = 1 }
    local _, _, _, tag = Bagwise.Verdict.Evaluate(item, { level = 30 })

    assert.are.equal(Bagwise.Verdict.POOR_QUALITY_TAG, tag)
  end)
end)

describe("Reason wording", function()
  local state = { level = 30, playerClass = "ROGUE", professionNames = {}, professionSkillLines = {} }

  it("unwearable white armor keeps its reason short, with no price", function()
    local item = {
      id = 9001, quality = 1, isEquippable = true, classID = 4, subClassID = 3,
      itemLevel = 10, sellPrice = 120, count = 1,
    }

    local _, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("white gear that sells is tagged for vendoring, one that does not sell is not", function()
    local item = {
      id = 9001, quality = 1, isEquippable = true, classID = 4, subClassID = 3,
      itemLevel = 10, sellPrice = 120, count = 1,
    }
    local _, _, _, tag = Bagwise.Verdict.Evaluate(item, state)
    assert.are.equal(Bagwise.Verdict.VENDOR_TAG, tag)

    item.sellPrice = 0
    local verdict, _, _, noTag = Bagwise.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
    assert.is_nil(noTag)
  end)

  it("the gray that keeps its dot says it is the cheapest", function()
    assert.are.equal("Cheapest gray, sells for 5c", Bagwise.Verdict.PoorQualityReason(5, true))
    assert.are.equal("Cheapest gray, no vendor value", Bagwise.Verdict.PoorQualityReason(0, true))
    assert.are.equal("Poor quality, sells for 5c", Bagwise.Verdict.PoorQualityReason(5, false))
  end)
end)

describe("Level gap and item level", function()
  local state = { level = 18, professions = {}, class = "WARRIOR" }
  local function gear(reqLevel, itemLevel)
    return { id = 990100, isBound = true, isEquippable = true, quality = 2, classID = 4,
             reqLevel = reqLevel, itemLevel = itemLevel, count = 1 }
  end

  it("does not call gear low level when its item level is above the player's level", function()
    local verdict = Bagwise.Verdict.Evaluate(gear(8, 24), state)
    assert.is_nil(verdict)
  end)

  it("still flags gear whose requirement and item level are both well below", function()
    local verdict = Bagwise.Verdict.Evaluate(gear(5, 9), state)
    assert.are.equal("yellow", verdict)
  end)
end)

describe("Reagents are never made safe by a finished quest", function()
  local state = { level = 30, professions = {}, class = "DRUID" }

  it("leaves an Alchemy herb that finished quests also use without a verdict", function()
    Bagwise.Data.ReagentProfessions = { [2449] = { { "Alchemy", 9, 20, 175 } } }
    local verdict = Bagwise.Verdict.Evaluate({
      id = 2449, classID = 7, quality = 1, count = 1,
      questItemQuestIDs = { 6123, 6128 }, allQuestObjectivesCompleted = true,
    }, state)
    assert.is_nil(verdict)
    Bagwise.Data.ReagentProfessions = {}
  end)

  it("still marks a plain quest item green once its quests are done", function()
    Bagwise.Data.ReagentProfessions = {}
    local verdict = Bagwise.Verdict.Evaluate({
      id = 990200, classID = 12, quality = 1, count = 1,
      questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true,
    }, state)
    assert.are.equal("green", verdict)
  end)
end)

describe("Level gap: rare gear and vendor wording", function()
  local state = { level = 40, professions = {}, class = "WARRIOR" }
  local function gear(quality)
    return { id = 990400, isBound = true, isEquippable = true, quality = quality, classID = 4,
             reqLevel = 10, itemLevel = 12, sellPrice = 300, count = 1 }
  end

  it("is green and tagged for vendoring when ordinary gear is far below", function()
    local verdict, _, _, tag = Bagwise.Verdict.Evaluate(gear(2), state)
    assert.are.equal("green", verdict)
    assert.are.equal(Bagwise.Verdict.VENDOR_TAG, tag)
  end)

  it("is only yellow for rare and better gear, however far below", function()
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(gear(3), state)))
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(gear(4), state)))
  end)
end)


describe("A yellow hint does not hide a later green", function()
  it("white boots below your level are green when blue boots outclass them", function()
    local item = { id = 33900, isBound = true, isEquippable = true, classID = 4,
      quality = 1, reqLevel = 8, itemLevel = 10,
      equippedInSlots = { { quality = 3, itemLevel = 20 } } }
    local verdict, reason = Bagwise.Verdict.Evaluate(item, { class = "Warrior", race = "Tauren", level = 20 })
    assert.are.equal("green", verdict)
    assert.are.equal("Worse than your equipped gear", reason)
  end)

  it("stays yellow when nothing else is certain", function()
    local item = { id = 33901, isBound = true, isEquippable = true, classID = 4,
      quality = 1, reqLevel = 8, itemLevel = 10 }
    local verdict = Bagwise.Verdict.Evaluate(item, { class = "Warrior", race = "Tauren", level = 20 })
    assert.are.equal("yellow", verdict)
  end)
end)

describe("White armor against any green or better you wear", function()
  local state = { class = "Warrior", race = "Tauren", level = 20 }
  local function white(overrides)
    local item = { id = 33950, isBound = false, isEquippable = true, classID = 4,
      quality = 1, reqLevel = 10, itemLevel = 25,
      equippedInSlots = { { quality = 2, itemLevel = 8 } } }
    for k, v in pairs(overrides or {}) do item[k] = v end
    return item
  end

  it("is green even when the white has the higher item level", function()
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(white(), state)))
  end)

  it("is not green against a white or grey you wear", function()
    local item = white({ equippedInSlots = { { quality = 1, itemLevel = 30 } } })
    assert.is_nil((Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("is not green when you cannot wear it yet", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(white({ reqLevel = 25 }), state)))
  end)
end)

describe("Vendor reagents when the professions could not be read", function()
  local VENDOR_ID
  for id in pairs(Bagwise.Data.VendorReagents) do VENDOR_ID = id; break end

  it("stays silent instead of calling a profession you may have unneeded", function()
    local item = { id = VENDOR_ID, classID = 7, quality = 1, count = 1, sellPrice = 5 }
    local base = { class = "Warrior", playerClass = "WARRIOR", level = 20,
      professionNames = {}, professionSkillLines = {} }
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, base)))

    base.professionsKnown = false
    assert.is_nil((Bagwise.Verdict.Evaluate(item, base)))
  end)
end)

describe("Ordinary items that a finished quest also asked for", function()
  local state = { class = "Rogue", playerClass = "ROGUE", level = 30 }

  it("get no verdict, so a tool or mat the quest used is left alone", function()
    local tools = { id = 990401, classID = 15, quality = 1, sellPrice = 5, count = 1,
      questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.is_nil((Bagwise.Verdict.Evaluate(tools, state)))
  end)

  it("still go green when the game's own quest item is finished with", function()
    local scroll = { id = 990402, classID = 12, quality = 1, sellPrice = 0, count = 1,
      questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(scroll, state)))
  end)
end)

describe("Recipes and reagents you cannot use yet", function()
  local function state(professions, extra)
    local names, ranks = {}, {}
    for name, rank in pairs(professions) do names[name] = true; ranks[name] = rank end
    local s = { level = 30, professionNames = names, professionRanks = ranks,
                professionSkillLines = {}, professionsKnown = true }
    for key, value in pairs(extra or {}) do s[key] = value end
    return s
  end
  local function recipe(overrides)
    local item = { id = 9001, classID = 9, subClassID = 6, quality = 1, isBound = false }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local MITHRIL_BAR = { id = 3860, classID = 7, quality = 1, sellPrice = 400, count = 1 }
  -- Earlier specs swap the real table out, so give these tests their own.
  Bagwise.Data.ReagentProfessions = {
    [3860] = { { "Alchemy", 1, 240, 240 }, { "Blacksmithing", 54, 200, 260 },
               { "Engineering", 37, 1, 320 } },
  }

  it("recipe for a profession you do not have is yellow and says whose it is", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(recipe(), state({ Mining = 50 }))

    assert.are.equal("yellow", verdict)
    assert.is_truthy(reason:find("You don't have this profession", 1, true))
  end)

  it("recipe whose level requirement is far above yours says to bank it", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(recipe({ reqLevel = 45 }), state({ Alchemy = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, needs level 45", reason)
  end)

  it("a recipe at or below your level is left alone", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(recipe({ reqLevel = 30 }), state({ Alchemy = 100 }))))
  end)

  it("a recipe up to three levels above yours is left alone", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(recipe({ reqLevel = 33 }), state({ Alchemy = 100 }))))
  end)

  it("a recipe four levels above yours says to bank it", function()
    local _, reason = Bagwise.Verdict.Evaluate(recipe({ reqLevel = 34 }), state({ Alchemy = 100 }))
    assert.are.equal("Bank it, needs level 34", reason)
  end)

  it("recipe far above your skill says to bank it", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 200 }), state({ Alchemy = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, needs Alchemy 200", reason)
  end)

  it("recipe within 25 skill points stays silent while you level the profession", function()
    local verdict = Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 125 }), state({ Alchemy = 100 }))

    assert.is_nil(verdict)
  end)

  it("recipe 26 skill points out of reach says to bank it", function()
    local _, reason = Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 126 }), state({ Alchemy = 100 }))

    assert.are.equal("Bank it, needs Alchemy 126", reason)
  end)

  it("a profession you have stopped leveling banks any recipe out of reach", function()
    local idleState = state({ Alchemy = 100 })
    idleState.professionIdle = { Alchemy = true }

    local _, reason = Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 101 }), idleState)
    assert.are.equal("Bank it, needs Alchemy 101", reason)
    assert.is_nil((Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 100 }), idleState)))
  end)

  it("idle only counts for its own profession", function()
    local mixed = state({ Alchemy = 100, Tailoring = 100 })
    mixed.professionIdle = { Tailoring = true }

    assert.is_nil((Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 101 }), mixed)))
  end)

  it("recipe with an unknown skill requirement stays silent", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(recipe(), state({ Alchemy = 100 }))))
  end)

  it("says nothing about recipes while the profession list is incomplete", function()
    local verdict = Bagwise.Verdict.Evaluate(recipe(), state({}, { professionsKnown = false }))

    assert.is_nil(verdict)
  end)

  it("recipes are never green, whatever else is true", function()
    local verdict = Bagwise.Verdict.Evaluate(recipe({ requiredSkill = 300 }), state({ Alchemy = 1 }))

    assert.is_truthy(verdict ~= "green")
  end)

  it("reagent your profession will not use for a long while says to bank it", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, used from Blacksmithing 200", reason)
  end)

  it("reagent within reach stays silent", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 160 }))))
  end)

  it("reagent another of your professions already uses stays silent", function()
    local verdict = Bagwise.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 100, Engineering = 100 }))

    assert.is_nil(verdict)
  end)

  it("reagent for professions you do not have is not a bank-it case", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(MITHRIL_BAR, state({ Mining = 50 }))))
  end)
end)

describe("Outleveled consumables", function()
  local function consumable(overrides)
    local item = { id = 9100, classID = 0, subClassID = 5, quality = 1, reqLevel = 5, count = 10, sellPrice = 4 }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function at(level) return { level = level, professionNames = {}, professionsKnown = true } end

  it("food made for a level 5 character is yellow at level 30", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(consumable(), at(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Outleveled, a level 5 item", reason)
  end)

  it("stays silent while it is still within 20 levels", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable(), at(24))))
  end)

  it("covers potions and bandages but not elixirs or flasks", function()
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(
      consumable({ subClassID = 1, restoresHealthOrMana = true }), at(40))))
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(consumable({ subClassID = 7 }), at(40))))
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ subClassID = 2 }), at(40))))
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ subClassID = 3 }), at(40))))
  end)

  it("a utility potion (swim speed, water walking) is never outleveled", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ subClassID = 1, restoresHealthOrMana = false }), at(60))))
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ subClassID = 1 }), at(60))))
  end)

  it("says nothing when the item has no level requirement or serves a quest", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ reqLevel = 0 }), at(50))))
    assert.is_nil((Bagwise.Verdict.Evaluate(consumable({ questItemQuestIDs = { 1 } }), at(50))))
  end)
end)

describe("Outleveled reagents", function()
  local function state(ranks)
    local names = {}
    for name in pairs(ranks) do names[name] = true end
    return { level = 60, professionNames = names, professionRanks = ranks,
             professionSkillLines = {}, professionsKnown = true }
  end
  local LINEN = { id = 2589, classID = 7, subClassID = 5, quality = 1, sellPrice = 13, count = 5 }
  Bagwise.Data.ReagentProfessions = {
    [2589] = { { "Tailoring", 10, 1, 125 } },
    [2592] = { { "Tailoring", 10, 1, 125 }, { "First Aid", 3, 1, 260 } },
  }

  it("is yellow once every profession of yours that uses it is far past it", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(LINEN, state({ Tailoring = 250 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Outleveled, Tailoring recipes use it up to 125", reason)
  end)

  it("stays silent while a recipe of yours still uses it", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(LINEN, state({ Tailoring = 150 }))))
    assert.is_nil((Bagwise.Verdict.Evaluate(LINEN, state({ Tailoring = 175 }))))
  end)

  it("stays silent when one of your professions still uses it", function()
    local wool = { id = 2592, classID = 7, subClassID = 5, quality = 1, sellPrice = 20, count = 5 }
    assert.is_nil((Bagwise.Verdict.Evaluate(wool, state({ Tailoring = 250, ["First Aid"] = 200 }))))
  end)

  it("says nothing without a profession that uses it", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(LINEN, state({ Mining = 250 }))))
  end)
end)

describe("Mana potions for classes without mana", function()
  local function potion(id) return { id = id, classID = 0, subClassID = 1, quality = 1, reqLevel = 0, count = 5, sellPrice = 50 } end
  local function as(class, level) return { level = level or 30, playerClass = class, professionNames = {}, professionsKnown = true } end

  it("a warrior or rogue gets a yellow", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(potion(3827), as("WARRIOR"))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Warriors have no mana. May sell on AH", reason)
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(potion(13443), as("ROGUE"))))
  end)

  it("a class with mana, including a druid, does not", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(potion(3827), as("MAGE"))))
    assert.is_nil((Bagwise.Verdict.Evaluate(potion(3827), as("DRUID"))))
  end)

  it("other potions are not touched", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(potion(929), as("WARRIOR"))))
  end)

  it("uses the generated mana-only list, so new potions are covered", function()
    local saved = Bagwise.Data.ManaOnlyConsumables
    Bagwise.Data.ManaOnlyConsumables = { [99001] = true }
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(potion(99001), as("WARRIOR"))))
    assert.is_nil((Bagwise.Verdict.Evaluate(potion(99002), as("WARRIOR"))))
    Bagwise.Data.ManaOnlyConsumables = saved
  end)
end)

describe("Items for a quest far below you", function()
  local function questItem(overrides)
    local item = { id = 9300, classID = 12, quality = 1, questItemQuestIDs = { 5001 },
                   allQuestObjectivesCompleted = false, openQuestIDs = { 5001 }, onOpenQuest = true }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function at(level) return { level = level, professionNames = {}, professionsKnown = true } end
  Bagwise.Data.QuestInfo = Bagwise.Data.QuestInfo or {}
  Bagwise.Data.QuestInfo[5001] = { 5, "Elwynn Forest", "Wolf Problem" }
  Bagwise.Data.QuestInfo[5002] = { 28, "Duskwood", "Deep Trouble" }

  it("is yellow and suggests abandoning a quest that is in your log", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(questItem(), at(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Quest is far below you, consider abandoning it", reason)
  end)

  it("says it is probably not worth taking when the quest is not in your log", function()
    local _, reason = Bagwise.Verdict.Evaluate(questItem({ onOpenQuest = false }), at(30))

    assert.are.equal("Quest is far below you, probably not worth taking", reason)
  end)

  it("stays silent while the quest is within 10 levels", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(questItem(), at(14))))
  end)

  it("stays silent when any open quest for the item is not far below you", function()
    local item = questItem({ questItemQuestIDs = { 5001, 5002 }, openQuestIDs = { 5001, 5002 } })

    assert.is_nil((Bagwise.Verdict.Evaluate(item, at(30))))
  end)

  it("never applies to an ordinary item that a quest also asks for", function()
    assert.is_nil((Bagwise.Verdict.Evaluate(questItem({ classID = 15 }), at(30))))
  end)
end)

describe("Low level gear that could be an upgrade", function()
  local state = { class = "Warrior", race = "Human", level = 40 }

  local function gear(overrides)
    local item = { id = 34001, isBound = true, isEquippable = true, quality = 3,
                   reqLevel = 20, itemLevel = 25, equipSlot = "INVTYPE_CHEST",
                   equippedInSlots = { { quality = 1, itemLevel = 30 } } }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  it("stays silent for a blue in the bags while a white is worn", function()
    local item = gear({ quality = 3, itemLevel = 25 })
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("stays silent when the bag piece has the higher item level, even at lower rarity", function()
    local item = gear({ quality = 1, itemLevel = 33,
                        equippedInSlots = { { quality = 2, itemLevel = 30 } } })
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("stays silent when the slot is empty", function()
    local item = gear({ equippedInSlots = { { quality = 0, itemLevel = 0 } } })
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("keeps its verdict when the worn piece is better in rarity and item level", function()
    local item = gear({ quality = 2, itemLevel = 22,
                        equippedInSlots = { { quality = 3, itemLevel = 35 } } })
    local verdict = Bagwise.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
  end)

  it("keeps its verdict when worn gear ties it on rarity and item level", function()
    local item = gear({ quality = 2, itemLevel = 22,
                        equippedInSlots = { { quality = 2, itemLevel = 22 } } })
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("stays silent for a ring that beats the weaker of two worn rings", function()
    local item = gear({ equipSlot = "INVTYPE_FINGER", quality = 2, itemLevel = 24,
                        equippedInSlots = { { quality = 3, itemLevel = 35 },
                                            { quality = 1, itemLevel = 10 } } })
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)

  it("keeps its verdict when nothing is known about the worn gear", function()
    local item = gear()
    item.equippedInSlots = nil
    assert.are.equal("yellow", (Bagwise.Verdict.Evaluate(item, state)))
  end)

  it("stays silent for an upgrade at the 10-19 level yellow band too", function()
    local item = gear({ reqLevel = 28, quality = 3, itemLevel = 28 })
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state))
  end)
end)

describe("Verdicts in the bank", function()
  local function forBank(rule, verdict, reason)
    return Bagwise.Verdict.ForBank({ verdict = verdict or "green", reason = reason or "Because",
                                     rule = rule })
  end

  it("keeps verdicts that hold for any character", function()
    for _, rule in ipairs({ "level_gap", "poor_quality", "no_recipe_use", "openable" }) do
      assert.are.equal("green", forBank(rule).verdict)
    end
  end)

  it("caps verdicts that depend on this character at yellow, keeping the reason", function()
    for _, rule in ipairs({ "vendor_reagent", "class_reagent", "quest_objective_done",
        "quest_starter_done", "unwearable_white", "outgeared_white", "mana_potion",
        "outleveled_consumable" }) do
      local result = forBank(rule, "green", "Why")
      assert.are.equal("yellow", result.verdict)
      assert.are.equal("Why", result.reason)
    end
  end)

  it("treats a rule it does not know as character specific", function()
    assert.are.equal("yellow", forBank("brand_new_rule").verdict)
    assert.are.equal("yellow", forBank(nil).verdict)
  end)

  it("drops hints that tell you to bank something already in the bank", function()
    assert.is_nil(forBank("recipe", "yellow", "Bank it, needs level 40").verdict)
    assert.is_nil(forBank("distant_reagent", "yellow", "Bank it, used from Alchemy 200").verdict)
  end)

  it("drops the abandon-the-quest hint", function()
    assert.is_nil(forBank("trivial_quest_item", "yellow", "Quest is far below you").verdict)
  end)

  it("keeps the recipe hint about a missing profession", function()
    local result = forBank("recipe", "yellow", "You don't have this profession. May sell on AH")
    assert.are.equal("yellow", result.verdict)
  end)

  it("leaves silence alone and never edits the shared result", function()
    assert.is_nil(Bagwise.Verdict.ForBank(nil))
    local shared = { verdict = "green", reason = "Why", rule = "vendor_reagent" }
    Bagwise.Verdict.ForBank(shared)
    assert.are.equal("green", shared.verdict)
  end)

  it("reports the rule that decided, so the bank can tell them apart", function()
    local item = { id = 1, quality = 0, sellPrice = 5, classID = 15, subClassID = 0 }
    local _, _, _, _, rule = Bagwise.Verdict.Evaluate(item, { class = "Mage", level = 20 })
    assert.are.equal("poor_quality", rule)
  end)
end)

describe("Verdicts in the warband bank", function()
  it("does not keep a low level gear green there, since an alt may use it", function()
    local result = Bagwise.Verdict.ForBank({ verdict = "green", reason = "Very low level gear",
                                              rule = "level_gap" }, true)
    assert.are.equal("yellow", result.verdict)
  end)

  it("still keeps verdicts that hold for any character", function()
    local result = Bagwise.Verdict.ForBank({ verdict = "green", reason = "Sells for 2c",
                                              rule = "poor_quality" }, true)
    assert.are.equal("green", result.verdict)
  end)
end)
