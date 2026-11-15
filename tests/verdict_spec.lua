-- MakeSpace: verdict unit tests
-- Run with: lua5.1 tests/verdict_spec.lua (from the MakeSpace/ root)

_G.MakeSpace = nil

dofile("data/vendor_reagents.lua")
dofile("data/reagent_professions.lua")
dofile("data/class_reagents.lua")
dofile("data/quest_items.lua")
dofile("data/weapon_skills.lua")
dofile("src/safety.lua")
dofile("src/notes.lua")
dofile("src/curves.lua")
dofile("src/auction.lua")
dofile("src/live.lua")
dofile("src/verdict.lua")
dofile("src/bank.lua")

describe("Story 1.3: soulbound gear far below my level (reqLevel)", function()
  it("green when soulbound and 20+ levels below", function()
    local item = { id = 33001, isBound = true, isEquippable = true, reqLevel = 20 }
    local state = { class = "Warrior", race = "Human", level = 45 }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear (needs 20, you are 45)", reason)
  end)

  it("yellow when soulbound and 10-19 levels below", function()
    local item = { id = 33002, isBound = true, isEquippable = true, reqLevel = 30 }
    local state = { class = "Warrior", race = "Human", level = 42 }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Low level gear (needs 30, you are 42)", reason)
  end)

  it("no dot when soulbound but only 9 levels below", function()
    local item = { id = 33003, isBound = true, isEquippable = true, reqLevel = 31 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot when NOT soulbound even if 20+ levels below", function()
    local item = { id = 33004, isBound = false, isEquippable = true, reqLevel = 10 }
    local state = { class = "Warrior", race = "Human", level = 50 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("green at exactly 20 levels below", function()
    local item = { id = 33006, isBound = true, isEquippable = true, reqLevel = 20 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("yellow at exactly 10 levels below", function()
    local item = { id = 33007, isBound = true, isEquippable = true, reqLevel = 30 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("no dot for an item with no signals at all", function()
    local item = { id = 99999 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)
end)

describe("Gear with an effect gets no verdict", function()
  local state = { class = "Warrior", race = "Human", level = 45 }

  it("a soulbound trinket far below your level is left alone", function()
    local item = { id = 33090, isBound = true, isEquippable = true, reqLevel = 10, hasEffect = true }
    assert.is_nil((MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("the same gear without an effect still gets green", function()
    local item = { id = 33091, isBound = true, isEquippable = true, reqLevel = 10 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state)))
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low item level (10 for level 32)", reason)
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Low item level (22 for level 32)", reason)
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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear (needs 30, you are 55)", reason)
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

    local verdict, reason, detail = MakeSpace.Verdict.Evaluate(item, state)

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

    local verdict, reason, detail = MakeSpace.Verdict.Evaluate(item, state)

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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot when item does not start any quest", function()
    local item = { id = 55003, startsQuestID = nil, startsQuestCompleted = false }
    local state = { class = "Warrior", race = "Human", level = 30 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("green with fallback text when quest name is nil", function()
    local item = {
      id = 55004,
      startsQuestID = 9999,
      startsQuestCompleted = true,
      startsQuestName = nil,
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict, reason, detail = MakeSpace.Verdict.Evaluate(item, state)

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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear (needs 10, you are 40)", reason)
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
  end)

  it("no dot when player HAS a matching profession (Empty Vial, has Alchemy)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions(171, 164)

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("green when player has one profession but reagent needs two others", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(171)

    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("no dot when player matches ONE of multiple professions", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(197, 171)

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot for items NOT in the vendor reagent table", function()
    local item = { id = 12345 }
    local state = stateWithProfessions(171)

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("green when player has no professions at all (empty set)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions()

    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("no dot when professionSkillLines is nil (API unavailable)", function()
    local item = { id = 3371 }
    local state = { class = "Mage", race = "Human", level = 60 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("Salt shows green only when player has none of Tailoring, LW, or Cooking", function()
    local item = { id = 4289 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, stateWithProfessions(185)))
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, stateWithProfessions(165)))
    assert.are.equal("green",
      (MakeSpace.Verdict.Evaluate(item, stateWithProfessions(171, 333))))
  end)

  it("ReagentProfessions wins over VendorReagents when they disagree", function()
    MakeSpace.Data.VendorReagents[2604] = { 165, 197 }
    MakeSpace.Data.ReagentProfessions[2604] = {
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
    assert.is_truthy(reason:find("Tailoring"))

    MakeSpace.Data.VendorReagents[2604] = nil
    MakeSpace.Data.ReagentProfessions[2604] = nil
  end)

  it("collapses 3+ professions to count", function()
    MakeSpace.Data.VendorReagents[99901] = { 171, 164, 185 }
    MakeSpace.Data.ReagentProfessions[99901] = {
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Vendor reagent (3 professions)", reason)

    MakeSpace.Data.VendorReagents[99901] = nil
    MakeSpace.Data.ReagentProfessions[99901] = nil
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
    assert.is_nil(MakeSpace.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Rogue without Alchemy gets nil on Leaded Vial", function()
    assert.is_nil(MakeSpace.Verdict.Evaluate(
      { id = 3372 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Rogue without Alchemy gets nil on Crystal Vial", function()
    assert.is_nil(MakeSpace.Verdict.Evaluate(
      { id = 8925 }, stateWithProfessions("ROGUE", 164, 197)))
  end)

  it("Mage without Alchemy still gets green on Empty Vial", function()
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("MAGE", 164, 197))))
  end)

  it("Rogue WITH Alchemy gets nil on Empty Vial (has the profession)", function()
    assert.is_nil(MakeSpace.Verdict.Evaluate(
      { id = 3371 }, stateWithProfessions("ROGUE", 171, 165)))
  end)

  it("Imbued Vial has no excludeClasses, so Rogue without Alchemy gets green", function()
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(
      { id = 18256 }, stateWithProfessions("ROGUE", 164, 197))))
  end)
end)

describe("Class reagent verdict", function()
  it("returns yellow for Light Feather on a warrior", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "WARRIOR" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Mage, Priest only (world drop)", reason)
  end)

  it("returns nil for Light Feather on a mage", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "MAGE" })))
  end)

  it("returns nil for Light Feather on a priest", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17056 }, { playerClass = "PRIEST" })))
  end)

  it("returns yellow for Shiny Fish Scales on a paladin", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 17057 }, { playerClass = "PALADIN" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Shaman only (world drop)", reason)
  end)

  it("returns nil for Shiny Fish Scales on a shaman", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17057 }, { playerClass = "SHAMAN" })))
  end)

  it("returns green for Arcane Powder on a warrior", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 17020 }, { playerClass = "WARRIOR" })
    assert.are.equal("green", verdict)
    assert.are.equal("Mage only (vendor)", reason)
  end)

  it("returns nil for Arcane Powder on a mage", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17020 }, { playerClass = "MAGE" })))
  end)

  it("returns green for Ankh on a druid", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 17030 }, { playerClass = "DRUID" })
    assert.are.equal("green", verdict)
    assert.are.equal("Shaman only (vendor)", reason)
  end)

  it("returns nil for Ankh on a shaman", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17030 }, { playerClass = "SHAMAN" })))
  end)

  it("returns green for Maple Seed on a hunter", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 17034 }, { playerClass = "HUNTER" })
    assert.are.equal("green", verdict)
    assert.are.equal("Druid only (vendor)", reason)
  end)

  it("returns nil for Maple Seed on a druid", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 17034 }, { playerClass = "DRUID" })))
  end)

  it("returns green for Symbol of Kings on a mage", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 21177 }, { playerClass = "MAGE" })
    assert.are.equal("green", verdict)
    assert.are.equal("Paladin only (vendor)", reason)
  end)

  it("returns green for Flash Powder on a warrior", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 5140 }, { playerClass = "WARRIOR" })
    assert.are.equal("green", verdict)
    assert.are.equal("Rogue only (vendor)", reason)
  end)

  it("returns yellow for Blinding Powder on a warrior", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(
      { id = 5530 }, { playerClass = "WARRIOR" })
    assert.are.equal("yellow", verdict)
    assert.are.equal("Rogue only (world drop)", reason)
  end)

  it("returns nil for a non-reagent item regardless of class", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
      { id = 99999 }, { playerClass = "WARRIOR" })))
  end)

  it("returns nil when playerClass is missing from state", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate({ id = 17056 }, {})))
  end)

  it("returns nil when playerClass is nil", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot when item has no quest associations", function()
    local item = { id = 66003 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot when questItemQuestIDs is nil", function()
    local item = {
      id = 66004,
      questItemQuestIDs = nil,
      allQuestObjectivesCompleted = nil,
    }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 40 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear (needs 10, you are 40)", reason)
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

    local verdict, reason, detail = MakeSpace.Verdict.Evaluate(item, state)

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

    local verdict, reason, detail = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Quest completed", reason)
    assert.are.equal("[36] Crushridge Bounty", detail)
  end)
end)

describe("Epic 5.1: flag Trade Goods not used in any recipe", function()
  -- Use an item ID that is NOT in any data table
  local ORPHAN_ITEM_ID = 88888

  -- Ensure test isolation: this ID must not be in any table
  assert(not MakeSpace.Data.ReagentProfessions[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in ReagentProfessions")
  assert(not MakeSpace.Data.QuestItems[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in QuestItems")
  assert(not MakeSpace.Data.VendorReagents[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in VendorReagents")
  assert(not MakeSpace.Data.ClassReagents[ORPHAN_ITEM_ID],
    "test setup: orphan ID must not be in ClassReagents")

  it("green for Trade Goods item not used in any recipe or quest", function()
    local item = { id = ORPHAN_ITEM_ID, classID = 7, subClassID = 9, sellPrice = 20 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

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
    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    if verdict then
      assert.is_truthy(reason ~= "Not used for any quest or recipe")
    end
  end)

  it("no dot when item IS in QuestItems (quest objective)", function()
    -- Refreshing Spring Water (159) is in QuestItems for quest 16
    local item = { id = 159, classID = 7 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

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

    local verdict = MakeSpace.Verdict.Evaluate(item, state)

    -- Has Alchemy, so vendor reagent rule returns nil; 5.1 should also skip
    assert.is_nil(verdict)
  end)

  it("no dot for non-Trade-Goods items (consumable, gear, etc.)", function()
    -- classID 0 = Consumable, not Trade Goods
    local item = { id = ORPHAN_ITEM_ID, classID = 0 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("no dot when classID is nil", function()
    local item = { id = ORPHAN_ITEM_ID, classID = nil }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
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

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    -- Level gap rule should fire first, not 5.1
    assert.are.equal("green", verdict)
    assert.are.equal("Very low level gear (needs 10, you are 60)", reason)
  end)

  it("no dot when item is in ClassReagents", function()
    -- Temporarily add a fake classID=7 class reagent to test exclusion
    MakeSpace.Data.ClassReagents[ORPHAN_ITEM_ID] = {
      classes = { MAGE = true },
      verdict = "green",
    }

    local item = { id = ORPHAN_ITEM_ID, classID = 7 }
    local state = { class = "Warrior", playerClass = "WARRIOR", level = 60 }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    -- ClassReagent rule fires first: "Mage only (vendor)"
    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Mage"))

    MakeSpace.Data.ClassReagents[ORPHAN_ITEM_ID] = nil
  end)
end)

describe("Epic 6: player overrides", function()
  local belowLevelGear = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20 }
  local state = { class = "Warrior", race = "Human", level = 45 }

  it("kept item gets no dot even when a rule would make it green", function()
    local item = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20, isKept = true }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("flagged item is yellow even when no rule fires", function()
    local item = { id = 33011, isBound = false, isEquippable = false, isFlagged = true }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Flagged by you", reason)
  end)

  it("flagged item stays yellow even when a rule would make it green", function()
    local item = { id = 33010, isBound = true, isEquippable = true, reqLevel = 20, isFlagged = true }

    local verdict = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
  end)

  it("unmarked item still follows the normal rules", function()
    local verdict = MakeSpace.Verdict.Evaluate(belowLevelGear, state)

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

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, mage))
  end)

  it("no dot on food that is also a vendor reagent (milk)", function()
    local item = { id = ICE_COLD_MILK, classID = CONSUMABLE }

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, mage))
  end)

  it("a flagged consumable is still yellow: your own mark wins", function()
    local item = { id = REFRESHING_SPRING_WATER, classID = CONSUMABLE, isFlagged = true }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, mage)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Flagged by you", reason)
  end)

  it("real vendor reagents that are not consumables keep their green dot", function()
    local item = { id = EMPTY_VIAL, classID = TRADE_GOODS }

    local verdict, reason = MakeSpace.Verdict.Evaluate(item, mage)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
  end)
end)


describe("Verdict.QuestsForFaction", function()
  local savedInfo

  local function withQuestInfo(info)
    savedInfo = MakeSpace.Data.QuestInfo
    MakeSpace.Data.QuestInfo = info
  end

  local function restore()
    MakeSpace.Data.QuestInfo = savedInfo
  end

  it("drops quests only the other faction can take", function()
    withQuestInfo({
      [1] = { 10, "Elwynn Forest", "Alliance version", "A" },
      [2] = { 10, "Durotar", "Horde version", "H" },
    })

    local alliance = MakeSpace.Verdict.QuestsForFaction({ 1, 2 }, "Alliance")
    local horde = MakeSpace.Verdict.QuestsForFaction({ 1, 2 }, "Horde")
    restore()

    assert.are.equal(1, #alliance)
    assert.are.equal(1, alliance[1])
    assert.are.equal(1, #horde)
    assert.are.equal(2, horde[1])
  end)

  it("keeps quests open to both factions", function()
    withQuestInfo({ [3] = { 40, "Tanaris", "Neutral quest" } })

    local kept = MakeSpace.Verdict.QuestsForFaction({ 3 }, "Horde")
    restore()

    assert.are.equal(1, #kept)
  end)

  it("keeps quests it has no data for, so the item stays needed", function()
    withQuestInfo({})

    local kept = MakeSpace.Verdict.QuestsForFaction({ 99 }, "Alliance")
    restore()

    assert.are.equal(1, #kept)
  end)

  it("keeps everything when the faction is unknown", function()
    withQuestInfo({ [2] = { 10, "Durotar", "Horde version", "H" } })

    local kept = MakeSpace.Verdict.QuestsForFaction({ 2 }, nil)
    restore()

    assert.are.equal(1, #kept)
  end)

  it("returns an empty list when every quest belongs to the other faction", function()
    withQuestInfo({ [2] = { 10, "Durotar", "Horde version", "H" } })

    local kept = MakeSpace.Verdict.QuestsForFaction({ 2 }, "Alliance")
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
    local verdict, reason = MakeSpace.Verdict.Evaluate(whiteArmor(), state)

    assert.are.equal("green", verdict)
    assert.are.equal("Worse than your equipped gear", reason)
  end)

  it("is silent when the equipped item is also white", function()
    local item = whiteArmor({ equippedInSlots = { { quality = 1, itemLevel = 30 } } })

    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("is silent when the slot is empty or unknown", function()
    local unknown = whiteArmor()
    unknown.equippedInSlots = nil

    assert.is_nil(MakeSpace.Verdict.Evaluate(unknown, state))
    assert.is_nil(MakeSpace.Verdict.Evaluate(whiteArmor({ equippedInSlots = {} }), state))
  end)

  it("needs both ring or trinket slots to be better", function()
    local oneWeak = whiteArmor({
      equippedInSlots = { { quality = 2, itemLevel = 20 }, { quality = 1, itemLevel = 5 } },
    })
    local bothBetter = whiteArmor({
      equippedInSlots = { { quality = 2, itemLevel = 20 }, { quality = 3, itemLevel = 25 } },
    })

    assert.is_nil(MakeSpace.Verdict.Evaluate(oneWeak, state))
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(bothBetter, state)))
  end)

  it("leaves green and better items alone", function()
    local green = whiteArmor({ quality = 2 })

    assert.is_nil(MakeSpace.Verdict.Evaluate(green, state))
  end)

  it("leaves weapons alone", function()
    local weapon = whiteArmor({ classID = 2 })

    assert.is_nil(MakeSpace.Verdict.Evaluate(weapon, state))
  end)

  it("never overrides a kept item", function()
    local kept = whiteArmor({ isKept = true })

    assert.is_nil(MakeSpace.Verdict.Evaluate(kept, state))
  end)
end)

describe("Verdict.FormatMoney", function()
  it("writes gold, silver and copper, leaving out zero parts", function()
    assert.are.equal("1g 20s 5c", MakeSpace.Verdict.FormatMoney(12005))
    assert.are.equal("2g", MakeSpace.Verdict.FormatMoney(20000))
    assert.are.equal("45s", MakeSpace.Verdict.FormatMoney(4500))
    assert.are.equal("7c", MakeSpace.Verdict.FormatMoney(7))
    assert.are.equal("0c", MakeSpace.Verdict.FormatMoney(0))
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
    local verdict, reason = MakeSpace.Verdict.Evaluate(gray(), stateAtLevel(30))

    assert.are.equal("green", verdict)
    assert.are.equal("Poor quality, sells for 10c", reason)
  end)

  it("grays with no vendor value are green", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(gray({ sellPrice = 0 }), stateAtLevel(30))

    assert.are.equal("green", verdict)
    assert.are.equal("Poor quality, no vendor value", reason)
  end)

  it("a gray that sells for real money is yellow and says so", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(gray({ sellPrice = 500 }), stateAtLevel(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Gray, but worth 5s", reason)
  end)

  it("judges the whole stack, not one item", function()
    local verdict = MakeSpace.Verdict.Evaluate(gray({ sellPrice = 20, count = 20 }), stateAtLevel(30))

    assert.are.equal("yellow", verdict)
  end)

  it("the bar rises with level: 60c is worth a glance at level 1 but not at level 60", function()
    local early = MakeSpace.Verdict.Evaluate(gray({ sellPrice = 60 }), stateAtLevel(1))
    local late = MakeSpace.Verdict.Evaluate(gray({ sellPrice = 60 }), stateAtLevel(60))

    assert.are.equal("yellow", early)
    assert.are.equal("green", late)
  end)

  it("leaves a gray alone while a quest still lists it", function()
    local verdict = MakeSpace.Verdict.Evaluate(gray({ questItemQuestIDs = { 55 } }), stateAtLevel(30))

    assert.is_nil(verdict)
  end)

  it("leaves a gray alone when a recipe uses it", function()
    MakeSpace.Data.ReagentProfessions = { [7001] = { { "Cooking", 1, 1, 50 } } }

    local verdict = MakeSpace.Verdict.Evaluate(gray(), stateAtLevel(30))
    MakeSpace.Data.ReagentProfessions = nil

    assert.is_nil(verdict)
  end)

  it("does not touch white or better items", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(gray({ quality = 1 }), stateAtLevel(30))))
  end)

  it("keeps a kept gray silent and a flagged gray yellow", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(gray({ isKept = true }), stateAtLevel(30))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(gray({ isFlagged = true }), stateAtLevel(30))))
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
    local verdict, reason = MakeSpace.Verdict.Evaluate(unusedTradeGood({ sellPrice = 20 }), state)

    assert.are.equal("green", verdict)
    assert.are.equal("Not used for any quest or recipe", reason)
  end)

  it("one that sells for real money is yellow and says how much", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(unusedTradeGood({ sellPrice = 4000 }), state)

    assert.are.equal("yellow", verdict)
    assert.are.equal("Not used for any quest or recipe, sells for 40s", reason)
  end)

  it("a stack of cheap ones can add up to yellow", function()
    local verdict = MakeSpace.Verdict.Evaluate(unusedTradeGood({ sellPrice = 50, count = 20 }), state)

    assert.are.equal("yellow", verdict)
  end)

  it("things you use directly are never called unused: parts, devices, explosives, rods, oils, generic goods", function()
    for _, subClassID in ipairs({ 0, 1, 2, 3, 11, 12, 14, 15 }) do
      assert.is_nil((MakeSpace.Verdict.Evaluate(unusedTradeGood({ sellPrice = 20, subClassID = subClassID }), state)))
    end
  end)

  it("a known-use item such as a Greenhouse seed is never called unused", function()
    MakeSpace.Data.ProtectedItems = { [268415] = "Herb seed, used in the Herbalism Greenhouse" }
    local seed = unusedTradeGood({ id = 268415, sellPrice = 10, subClassID = 9 })
    assert.is_nil((MakeSpace.Verdict.Evaluate(seed, state)))
    MakeSpace.Data.ProtectedItems = nil
  end)

  it("an item with no vendor value is a token, not a leftover, so it gets no verdict", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(unusedTradeGood({ sellPrice = 0 }), state)))
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
    local verdict, reason = MakeSpace.Verdict.Evaluate(whiteArmor(3), stateFor("ROGUE"))

    assert.are.equal("green", verdict)
    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("plate and leather are checked per class", function()
    assert.are.equal("Hunters can't wear plate",
      select(2, MakeSpace.Verdict.Evaluate(whiteArmor(4), stateFor("HUNTER"))))
    assert.are.equal("Mages can't wear leather",
      select(2, MakeSpace.Verdict.Evaluate(whiteArmor(2), stateFor("MAGE"))))
  end)

  it("shields and class relics follow the same rule", function()
    assert.are.equal("Rogues can't use shields",
      select(2, MakeSpace.Verdict.Evaluate(whiteArmor(6), stateFor("ROGUE"))))
    assert.are.equal("Priests can't use totems",
      select(2, MakeSpace.Verdict.Evaluate(whiteArmor(9), stateFor("PRIEST"))))
  end)

  it("armor the class learns later is green until that level", function()
    local early = MakeSpace.Verdict.Evaluate(whiteArmor(4), stateFor("WARRIOR"))
    local _, reason = MakeSpace.Verdict.Evaluate(whiteArmor(4), stateFor("WARRIOR"))

    assert.are.equal("green", early)
    assert.are.equal("Warriors can't wear plate until 40", reason)
    local _, shamanReason = MakeSpace.Verdict.Evaluate(whiteArmor(3), stateFor("SHAMAN"))
    assert.are.equal("Shamans can't wear mail until 40", shamanReason)
  end)

  it("goes silent once the class can wear it", function()
    local atForty = { level = 40, playerClass = "WARRIOR", professionNames = {}, professionSkillLines = {} }

    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(4), atForty)))
    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(1), stateFor("MAGE"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(3), stateFor("WARRIOR"))))
  end)

  it("stays silent for classes it doesn't know", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(3), stateFor("SOMETHINGNEW"))))
  end)

  it("takes priority over the outgeared-white wording", function()
    local item = whiteArmor(3, { equippedInSlots = { { quality = 2, itemLevel = 20 } } })

    local _, reason = MakeSpace.Verdict.Evaluate(item, stateFor("ROGUE"))

    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("only applies to white armor", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(3, { quality = 2 }), stateFor("ROGUE"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(whiteArmor(3, { classID = 2 }), stateFor("ROGUE"))))
  end)
end)

describe("Verdict.SilenceAllButCheapest", function()
  local function entry(key, bag, slot, value)
    return { key = key, bag = bag, slot = slot, value = value }
  end

  it("keeps only the cheapest entry green", function()
    local silenced = MakeSpace.Verdict.SilenceAllButCheapest({
      entry("0:1", 0, 1, 50), entry("0:2", 0, 2, 5), entry("1:1", 1, 1, 20),
    }, 1)

    assert.is_nil(silenced["0:2"])
    assert.is_truthy(silenced["0:1"])
    assert.is_truthy(silenced["1:1"])
  end)

  it("breaks ties by bag and slot so the choice is stable", function()
    local silenced = MakeSpace.Verdict.SilenceAllButCheapest({
      entry("2:3", 2, 3, 10), entry("1:9", 1, 9, 10), entry("1:2", 1, 2, 10),
    }, 1)

    assert.is_nil(silenced["1:2"])
    assert.is_truthy(silenced["1:9"])
    assert.is_truthy(silenced["2:3"])
  end)

  it("silences nothing when there are no more entries than allowed", function()
    local silenced = MakeSpace.Verdict.SilenceAllButCheapest({ entry("0:1", 0, 1, 5) }, 1)

    assert.is_nil(next(silenced))
  end)

  it("lets more through when the limit is raised", function()
    local silenced = MakeSpace.Verdict.SilenceAllButCheapest({
      entry("0:1", 0, 1, 1), entry("0:2", 0, 2, 2), entry("0:3", 0, 3, 3),
    }, 2)

    assert.is_nil(silenced["0:1"])
    assert.is_nil(silenced["0:2"])
    assert.is_truthy(silenced["0:3"])
  end)

  it("gray verdicts carry the tag the scanner uses to find them", function()
    local item = { id = 1, quality = 0, classID = 15, sellPrice = 5, count = 1 }
    local _, _, _, tag = MakeSpace.Verdict.Evaluate(item, { level = 30 })

    assert.are.equal(MakeSpace.Verdict.POOR_QUALITY_TAG, tag)
  end)
end)

describe("Reason wording", function()
  local state = { level = 30, playerClass = "ROGUE", professionNames = {}, professionSkillLines = {} }

  it("unwearable white armor keeps its reason short, with no price", function()
    local item = {
      id = 9001, quality = 1, isEquippable = true, classID = 4, subClassID = 3,
      itemLevel = 10, sellPrice = 120, count = 1,
    }

    local _, reason = MakeSpace.Verdict.Evaluate(item, state)

    assert.are.equal("Rogues can't wear mail", reason)
  end)

  it("a green is sellable when a vendor buys it, and only then", function()
    local item = {
      id = 9001, quality = 1, isEquippable = true, classID = 4, subClassID = 3,
      itemLevel = 10, sellPrice = 120, count = 1,
    }
    local verdict = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
    assert.is_truthy(MakeSpace.Verdict.Sellable(item, verdict))

    item.sellPrice = 0
    verdict = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
    assert.is_truthy(not MakeSpace.Verdict.Sellable(item, verdict))
    assert.is_truthy(not MakeSpace.Verdict.Sellable({ sellPrice = 50 }, "yellow"))
  end)

  it("the gray that keeps its dot says it is the cheapest", function()
    assert.are.equal("Cheapest gray, sells for 5c", MakeSpace.Verdict.PoorQualityReason(5, true))
    assert.are.equal("Cheapest gray, no vendor value", MakeSpace.Verdict.PoorQualityReason(0, true))
    assert.are.equal("Poor quality, sells for 5c", MakeSpace.Verdict.PoorQualityReason(5, false))
  end)
end)

describe("Level gap and item level", function()
  local state = { level = 18, professions = {}, class = "WARRIOR" }
  local function gear(reqLevel, itemLevel)
    return { id = 990100, isBound = true, isEquippable = true, quality = 2, classID = 4,
             reqLevel = reqLevel, itemLevel = itemLevel, count = 1 }
  end

  it("does not call gear low level when its item level is above the player's level", function()
    local verdict = MakeSpace.Verdict.Evaluate(gear(8, 24), state)
    assert.is_nil(verdict)
  end)

  it("still flags gear whose requirement and item level are both well below", function()
    local verdict = MakeSpace.Verdict.Evaluate(gear(5, 6), state)
    assert.are.equal("yellow", verdict)
  end)
end)

describe("Reagents are never made safe by a finished quest", function()
  local state = { level = 30, professions = {}, class = "DRUID" }

  it("leaves an Alchemy herb that finished quests also use without a verdict", function()
    MakeSpace.Data.ReagentProfessions = { [2449] = { { "Alchemy", 9, 20, 175 } } }
    local verdict = MakeSpace.Verdict.Evaluate({
      id = 2449, classID = 7, quality = 1, count = 1,
      questItemQuestIDs = { 6123, 6128 }, allQuestObjectivesCompleted = true,
    }, state)
    assert.is_nil(verdict)
    MakeSpace.Data.ReagentProfessions = {}
  end)

  it("still marks a plain quest item green once its quests are done", function()
    MakeSpace.Data.ReagentProfessions = {}
    local verdict = MakeSpace.Verdict.Evaluate({
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
    local item = gear(2)
    local verdict = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
    assert.is_truthy(MakeSpace.Verdict.Sellable(item, verdict))
  end)

  it("is only yellow for rare and better gear, however far below", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(gear(3), state)))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(gear(4), state)))
  end)
end)


describe("A yellow hint does not hide a later green", function()
  it("white boots below your level are green when blue boots outclass them", function()
    local item = { id = 33900, isBound = true, isEquippable = true, classID = 4,
      quality = 1, reqLevel = 8, itemLevel = 10,
      equippedInSlots = { { quality = 3, itemLevel = 20 } } }
    local verdict, reason = MakeSpace.Verdict.Evaluate(item, { class = "Warrior", race = "Tauren", level = 20 })
    assert.are.equal("green", verdict)
    assert.are.equal("Worse than your equipped gear", reason)
  end)

  it("stays yellow when nothing else is certain", function()
    local item = { id = 33901, isBound = true, isEquippable = true, classID = 4,
      quality = 1, reqLevel = 8, itemLevel = 10 }
    local verdict = MakeSpace.Verdict.Evaluate(item, { class = "Warrior", race = "Tauren", level = 20 })
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
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(white(), state)))
  end)

  it("is not green against a white or grey you wear", function()
    local item = white({ equippedInSlots = { { quality = 1, itemLevel = 30 } } })
    assert.is_nil((MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("is not green when you cannot wear it yet", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(white({ reqLevel = 25 }), state)))
  end)
end)

describe("Vendor reagents when the professions could not be read", function()
  local VENDOR_ID
  for id in pairs(MakeSpace.Data.VendorReagents) do VENDOR_ID = id; break end

  it("stays silent instead of calling a profession you may have unneeded", function()
    local item = { id = VENDOR_ID, classID = 7, quality = 1, count = 1, sellPrice = 5 }
    local base = { class = "Warrior", playerClass = "WARRIOR", level = 20,
      professionNames = {}, professionSkillLines = {} }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, base)))

    base.professionsKnown = false
    assert.is_nil((MakeSpace.Verdict.Evaluate(item, base)))
  end)
end)

describe("Ordinary items that a finished quest also asked for", function()
  local state = { class = "Rogue", playerClass = "ROGUE", level = 30 }

  it("get no verdict, so a tool or mat the quest used is left alone", function()
    local tools = { id = 990401, classID = 15, quality = 1, sellPrice = 5, count = 1,
      questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.is_nil((MakeSpace.Verdict.Evaluate(tools, state)))
  end)

  it("still go green when the game's own quest item is finished with", function()
    local scroll = { id = 990402, classID = 12, quality = 1, sellPrice = 0, count = 1,
      questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(scroll, state)))
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
  MakeSpace.Data.ReagentProfessions = {
    [3860] = { { "Alchemy", 1, 240, 240 }, { "Blacksmithing", 54, 200, 260 },
               { "Engineering", 37, 1, 320 } },
  }

  it("recipe for a profession you do not have is yellow and says whose it is", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(recipe(), state({ Mining = 50 }))

    assert.are.equal("yellow", verdict)
    assert.is_truthy(reason:find("You don't have this profession", 1, true))
  end)

  it("recipe whose level requirement is far above yours says to bank it", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(recipe({ reqLevel = 45 }), state({ Alchemy = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, needs level 45", reason)
  end)

  it("a recipe at or below your level is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe({ reqLevel = 30 }), state({ Alchemy = 100 }))))
  end)

  it("a recipe up to three levels above yours is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe({ reqLevel = 33 }), state({ Alchemy = 100 }))))
  end)

  it("a recipe four levels above yours says to bank it", function()
    local _, reason = MakeSpace.Verdict.Evaluate(recipe({ reqLevel = 34 }), state({ Alchemy = 100 }))
    assert.are.equal("Bank it, needs level 34", reason)
  end)

  it("recipe far above your skill says to bank it", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 200 }), state({ Alchemy = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, needs Alchemy 200", reason)
  end)

  it("recipe within 25 skill points stays silent while you level the profession", function()
    local verdict = MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 125 }), state({ Alchemy = 100 }))

    assert.is_nil(verdict)
  end)

  it("recipe 26 skill points out of reach says to bank it", function()
    local _, reason = MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 126 }), state({ Alchemy = 100 }))

    assert.are.equal("Bank it, needs Alchemy 126", reason)
  end)

  it("a profession you have stopped leveling banks any recipe out of reach", function()
    local idleState = state({ Alchemy = 100 })
    idleState.professionIdle = { Alchemy = true }

    local _, reason = MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 101 }), idleState)
    assert.are.equal("Bank it, needs Alchemy 101", reason)
    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 100 }), idleState)))
  end)

  it("idle only counts for its own profession", function()
    local mixed = state({ Alchemy = 100, Tailoring = 100 })
    mixed.professionIdle = { Tailoring = true }

    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 101 }), mixed)))
  end)

  it("recipe with an unknown skill requirement stays silent", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe(), state({ Alchemy = 100 }))))
  end)

  it("says nothing about recipes while the profession list is incomplete", function()
    local verdict = MakeSpace.Verdict.Evaluate(recipe(), state({}, { professionsKnown = false }))

    assert.is_nil(verdict)
  end)

  it("recipes are never green, whatever else is true", function()
    local verdict = MakeSpace.Verdict.Evaluate(recipe({ requiredSkill = 300 }), state({ Alchemy = 1 }))

    assert.is_truthy(verdict ~= "green")
  end)

  it("reagent your profession will not use for a long while says to bank it", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 100 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Bank it, used from Blacksmithing 200", reason)
  end)

  it("reagent within reach stays silent", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 160 }))))
  end)

  it("an active profession banks a reagent from 50 points out", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 150 }))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 149 }))))
  end)

  it("a profession that has gone quiet for a while banks it from 25 points out", function()
    local settling = state({ Blacksmithing = 175 })
    settling.professionSettling = { Blacksmithing = true }
    assert.is_nil((MakeSpace.Verdict.Evaluate(MITHRIL_BAR, settling)))
    settling.professionRanks.Blacksmithing = 174
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(MITHRIL_BAR, settling)))
  end)

  it("an idle profession banks a reagent from 25 points out, not on any shortfall", function()
    local idleState = state({ Blacksmithing = 199 })
    idleState.professionIdle = { Blacksmithing = true }
    assert.is_nil((MakeSpace.Verdict.Evaluate(MITHRIL_BAR, idleState)))
    idleState.professionRanks.Blacksmithing = 174
    local _, reason = MakeSpace.Verdict.Evaluate(MITHRIL_BAR, idleState)
    assert.are.equal("Bank it, used from Blacksmithing 200", reason)
  end)

  it("reagent another of your professions already uses stays silent", function()
    local verdict = MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Blacksmithing = 100, Engineering = 100 }))

    assert.is_nil(verdict)
  end)

  it("reagent for professions you do not have is not a bank-it case", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(MITHRIL_BAR, state({ Mining = 50 }))))
  end)
end)

describe("Outleveled consumables", function()
  local function consumable(overrides)
    local item = { id = 9100, classID = 0, subClassID = 5, quality = 1, reqLevel = 5, count = 10, sellPrice = 4,
                  restoresHealthOrMana = true }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function at(level) return { level = level, professionNames = {}, professionsKnown = true } end

  it("food made for a level 5 character is yellow at level 30", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(consumable(), at(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Low-level food (level 5, you are 30)", reason)
  end)

  it("food that gives a buff, or that we could not read as healing, is never flagged", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable({ givesBuff = true }), at(60))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable({ restoresHealthOrMana = false }), at(60))))
    local unread = consumable()
    unread.restoresHealthOrMana = nil
    assert.is_nil((MakeSpace.Verdict.Evaluate(unread, at(60))))
  end)

  it("stays silent while it is still within 20 levels", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable(), at(24))))
  end)

  it("covers potions, bandages, elixirs and flasks", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(
      consumable({ subClassID = 1, restoresHealthOrMana = true }), at(40))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(consumable({ subClassID = 7 }), at(40))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(consumable({ subClassID = 2, givesStats = true }), at(40))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(consumable({ subClassID = 3, givesStats = true }), at(40))))
  end)

  it("a utility potion (swim speed, water walking) is never outleveled", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable({ subClassID = 1, restoresHealthOrMana = false }), at(60))))
    local unread = consumable({ subClassID = 1 })
    unread.restoresHealthOrMana = nil
    assert.is_nil((MakeSpace.Verdict.Evaluate(unread, at(60))))
  end)

  it("says nothing when the item has no level requirement or serves a quest you are on", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable({ reqLevel = 0 }), at(50))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable({ questItemQuestIDs = { 1 }, openQuestIDs = { 1 },
      onOpenQuest = true }), at(50))))
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
  MakeSpace.Data.ReagentChains = {}
  MakeSpace.Data.ReagentProfessions = {
    [2589] = { { "Tailoring", 10, 1, 125 } },
    [2592] = { { "Tailoring", 10, 1, 125 }, { "First Aid", 3, 1, 260 } },
  }

  it("is yellow once every profession of yours that uses it is far past it", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 250 }))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Outleveled, Tailoring recipes use it up to 125", reason)
  end)

  it("shows the vendor and auction prices, so you can see which pays more", function()
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = { [2589] = 3100 }
    local verdict, _, _, _, rule, _, note = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 250 }))
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.are.equal("yellow", verdict)
    assert.are.equal("outleveled_reagent", rule)
    assert.are.equal("Vendor 13c, auction up to 31s", note)
  end)

  it("stays silent while an unfinished quest still wants it", function()
    local wanted = { id = 2589, classID = 7, subClassID = 5, quality = 1, sellPrice = 13, count = 5,
                     questItemQuestIDs = { 4001 }, openQuestIDs = { 4001 } }
    assert.is_nil((MakeSpace.Verdict.Evaluate(wanted, state({ Tailoring = 250 }))))
    -- once every quest that wants it is done, the hint is back
    local done = { id = 2589, classID = 7, subClassID = 5, quality = 1, sellPrice = 13, count = 5,
                   questItemQuestIDs = { 4001 }, openQuestIDs = {}, allQuestObjectivesCompleted = true }
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(done, state({ Tailoring = 250 }))))
  end)

  it("waits for the green point when the data has one, and says where the recipes turn green", function()
    local saved = MakeSpace.Data.ReagentProfessions
    MakeSpace.Data.ReagentProfessions = { [2589] = { { "Tailoring", 10, 1, 125, 170 } } }
    local still = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 169 }))
    local verdict, reason = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 170 }))
    MakeSpace.Data.ReagentProfessions = saved
    assert.is_nil(still)
    assert.are.equal("yellow", verdict)
    assert.are.equal("Outleveled, recipes turn green at Tailoring 170", reason)
  end)

  it("uses the latest green point of what it is turned into", function()
    local saved = MakeSpace.Data.ReagentProfessions
    MakeSpace.Data.ReagentProfessions = { [2589] = { { "Tailoring", 10, 1, 125, 170 } } }
    MakeSpace.Data.ReagentChains[2589] = { { "Tailoring", 40, 225, 275 } }
    local silent = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 274 }))
    local _, reason = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 275 }))
    MakeSpace.Data.ReagentChains[2589] = {}
    MakeSpace.Data.ReagentProfessions = saved
    assert.is_nil(silent)
    assert.are.equal("Outleveled, recipes turn green at Tailoring 275", reason)
  end)

  it("ignores an open quest far below you, but not one near your level", function()
    local savedInfo = MakeSpace.Data.QuestInfo
    MakeSpace.Data.QuestInfo = { [4001] = { 6, nil, "Restocking the Larders" }, [4002] = { 55, nil, "A Late Quest" } }
    local function withQuest(id)
      return { id = 2589, classID = 7, subClassID = 5, quality = 1, sellPrice = 13, count = 5,
               questItemQuestIDs = { id }, openQuestIDs = { id }, allQuestObjectivesCompleted = false }
    end
    local trivial = MakeSpace.Verdict.Evaluate(withQuest(4001), state({ Tailoring = 250 }))
    local near = MakeSpace.Verdict.Evaluate(withQuest(4002), state({ Tailoring = 250 }))
    MakeSpace.Data.QuestInfo = savedInfo
    assert.are.equal("yellow", trivial)
    assert.is_nil(near)
  end)

  it("stays silent while something made from it is still in demand", function()
    MakeSpace.Data.ReagentChains[2589] = { { "Tailoring", 40, 225 } }
    local silent = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 225 }))
    local past = MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 226 }))
    MakeSpace.Data.ReagentChains[2589] = nil
    assert.is_nil(silent)
    assert.are.equal("yellow", past)
  end)

  it("stays silent when the downstream data is not loaded", function()
    local saved = MakeSpace.Data.ReagentChains
    MakeSpace.Data.ReagentChains = nil
    assert.is_nil((MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 250 }))))
    MakeSpace.Data.ReagentChains = saved
  end)

  it("stays silent while a recipe of yours still uses it", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 100 }))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 125 }))))
  end)

  it("is yellow the moment you are past the best recipe, not 50 points later", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(LINEN, state({ Tailoring = 126 }))))
  end)

  it("counts what it is turned into: Rough Stone at Blacksmithing 126 with products up to 115", function()
    MakeSpace.Data.ReagentProfessions[2835] = { { "Blacksmithing", 4, 15, 45 }, { "Engineering", 1, 20, 20 }, { "Mining", 1, 20, 20 } }
    MakeSpace.Data.ReagentChains[2835] = { { "Blacksmithing", 65, 115 }, { "Enchanting", 130, 130 }, { "Engineering", 25, 90 } }
    local stone = { id = 2835, classID = 7, subClassID = 7, quality = 1, sellPrice = 10, count = 5 }
    local mining = state({ Mining = 115, Blacksmithing = 126 })
    local verdict, reason = MakeSpace.Verdict.Evaluate(stone, mining)
    assert.are.equal("yellow", verdict)
    assert.are.equal("Outleveled, Blacksmithing recipes use it up to 115", reason)
    assert.is_nil((MakeSpace.Verdict.Evaluate(stone, state({ Mining = 115, Blacksmithing = 100 }))))
    MakeSpace.Data.ReagentProfessions[2835], MakeSpace.Data.ReagentChains[2835] = nil, nil
  end)

  it("stays silent when one of your professions still uses it", function()
    local wool = { id = 2592, classID = 7, subClassID = 5, quality = 1, sellPrice = 20, count = 5 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(wool, state({ Tailoring = 250, ["First Aid"] = 200 }))))
  end)

  it("says nothing without a profession that uses it", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(LINEN, state({ Mining = 250 }))))
  end)
end)

describe("Mana potions for classes without mana", function()
  local function potion(id) return { id = id, classID = 0, subClassID = 1, quality = 1, reqLevel = 0, count = 5, sellPrice = 50 } end
  local function as(class, level) return { level = level or 30, playerClass = class, professionNames = {}, professionsKnown = true } end

  it("a warrior or rogue gets a yellow", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(potion(3827), as("WARRIOR"))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Warriors have no mana. May sell at the auction house", reason)
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(potion(13443), as("ROGUE"))))
  end)

  it("shows the price line when the auction pays more than a vendor", function()
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = { [3827] = 5000 }
    local _, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(potion(3827), as("WARRIOR"))
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.are.equal("Vendor 50c, auction up to 50s", note)
  end)

  it("a class with mana, including a druid, does not", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(potion(3827), as("MAGE"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(potion(3827), as("DRUID"))))
  end)

  it("other potions are not touched", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(potion(929), as("WARRIOR"))))
  end)

  it("uses the generated mana-only list, so new potions are covered", function()
    local saved = MakeSpace.Data.ManaOnlyConsumables
    MakeSpace.Data.ManaOnlyConsumables = { [99001] = true }
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(potion(99001), as("WARRIOR"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(potion(99002), as("WARRIOR"))))
    MakeSpace.Data.ManaOnlyConsumables = saved
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
  MakeSpace.Data.QuestInfo = MakeSpace.Data.QuestInfo or {}
  MakeSpace.Data.QuestInfo[5001] = { 5, "Elwynn Forest", "Wolf Problem" }
  MakeSpace.Data.QuestInfo[5002] = { 28, "Duskwood", "Deep Trouble" }

  it("is yellow and suggests abandoning a quest that is in your log", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(questItem(), at(30))

    assert.are.equal("yellow", verdict)
    assert.are.equal("Quest is far below you, consider abandoning it", reason)
  end)

  it("says it is probably not worth taking when the quest is not in your log", function()
    local _, reason = MakeSpace.Verdict.Evaluate(questItem({ onOpenQuest = false }), at(30))

    assert.are.equal("Quest is far below you, probably not worth taking", reason)
  end)

  it("stays silent while the quest is within 10 levels", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(14))))
  end)

  it("stays silent when any open quest for the item is not far below you", function()
    local item = questItem({ questItemQuestIDs = { 5001, 5002 }, openQuestIDs = { 5001, 5002 } })

    assert.is_nil((MakeSpace.Verdict.Evaluate(item, at(30))))
  end)

  it("never applies to an ordinary item that a quest also asks for", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(questItem({ classID = 15 }), at(30))))
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
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("stays silent when the bag piece has the higher item level, even at lower rarity", function()
    local item = gear({ quality = 1, itemLevel = 33,
                        equippedInSlots = { { quality = 2, itemLevel = 30 } } })
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("stays silent when the slot is empty", function()
    local item = gear({ equippedInSlots = { { quality = 0, itemLevel = 0 } } })
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("keeps its verdict when the worn piece is better in rarity and item level", function()
    local item = gear({ quality = 2, itemLevel = 18,
                        equippedInSlots = { { quality = 3, itemLevel = 35 } } })
    local verdict = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
  end)

  it("keeps its verdict when worn gear ties it on rarity and item level", function()
    local item = gear({ quality = 2, itemLevel = 18,
                        equippedInSlots = { { quality = 2, itemLevel = 18 } } })
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("stays silent for a ring that beats the weaker of two worn rings", function()
    local item = gear({ equipSlot = "INVTYPE_FINGER", quality = 2, itemLevel = 24,
                        equippedInSlots = { { quality = 3, itemLevel = 35 },
                                            { quality = 1, itemLevel = 10 } } })
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)

  it("keeps its verdict when nothing is known about the worn gear", function()
    local item = gear()
    item.equippedInSlots = nil
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(item, state)))
  end)

  it("stays silent for an upgrade at the 10-19 level yellow band too", function()
    local item = gear({ reqLevel = 28, quality = 3, itemLevel = 28 })
    assert.is_nil(MakeSpace.Verdict.Evaluate(item, state))
  end)
end)

describe("Verdicts in the bank", function()
  local function forBank(rule, verdict, reason, heading)
    return MakeSpace.Verdict.ForBank({ verdict = verdict or "green", reason = reason or "Because",
                                     rule = rule, heading = heading })
  end

  it("keeps the price line, so the bank tooltip shows it too", function()
    local note = "Vendor 5c, auction about 8s"
    local kept = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Whatever", rule = "poor_quality",
                                           auctionNote = note })
    assert.are.equal(note, kept.auctionNote)
    local converted = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Whatever", rule = "recipe",
                                                heading = { title = "Not your profession" }, auctionNote = note })
    assert.are.equal(note, converted.auctionNote)
  end)

  it("keeps verdicts that hold for any character", function()
    for _, rule in ipairs({ "level_gap", "poor_quality", "no_recipe_use", "openable" }) do
      assert.are.equal("green", forBank(rule).verdict)
    end
  end)

  it("caps verdicts that depend on this character at yellow, keeping the reason", function()
    for _, rule in ipairs({ "vendor_reagent", "class_reagent", "quest_objective_done",
        "quest_starter_done", "unwearable_white", "outgeared_white", "mana_consumable",
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
    local _, bankLevel = MakeSpace.Verdict.Note("bank_level", 40)
    local _, usedFrom = MakeSpace.Verdict.Note("bank_used_from", "Alchemy", 200)
    assert.is_nil(forBank("recipe", "yellow", "Bank it, needs level 40", bankLevel).verdict)
    assert.is_nil(forBank("distant_reagent", "yellow", "Bank it, used from Alchemy 200", usedFrom).verdict)
  end)

  it("drops the abandon-the-quest hint", function()
    assert.is_nil(forBank("trivial_quest_item", "yellow", "Quest is far below you").verdict)
  end)

  it("keeps the recipe hint about a missing profession", function()
    local result = forBank("recipe", "yellow", "You don't have this profession. May sell at the auction house")
    assert.are.equal("yellow", result.verdict)
  end)

  it("a green capped to yellow keeps the bag's words as its heading", function()
    local result = forBank("quest_objective_done", "green", "Quest completed")
    assert.are.equal("yellow", result.verdict)
    assert.are.equal("Quest completed", result.heading.title)
    assert.is_nil(result.heading.detail)
  end)

  it("a yellow that already has a heading keeps it", function()
    local heading = { title = "Not your profession", detail = "Used by Alchemy" }
    local result = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Whatever", rule = "recipe",
      heading = heading })
    assert.are.equal(heading, result.heading)
  end)

  it("leaves silence alone and never edits the shared result", function()
    assert.is_nil(MakeSpace.Verdict.ForBank(nil))
    local shared = { verdict = "green", reason = "Why", rule = "vendor_reagent" }
    MakeSpace.Verdict.ForBank(shared)
    assert.are.equal("green", shared.verdict)
  end)

  it("reports the rule that decided, so the bank can tell them apart", function()
    local item = { id = 1, quality = 0, sellPrice = 5, classID = 15, subClassID = 0 }
    local _, _, _, _, rule = MakeSpace.Verdict.Evaluate(item, { class = "Mage", level = 20 })
    assert.are.equal("poor_quality", rule)
  end)
end)

describe("Verdicts in the warband bank", function()
  it("does not keep a low level gear green there, since an alt may use it", function()
    local result = MakeSpace.Verdict.ForBank({ verdict = "green", reason = "Very low level gear",
                                              rule = "level_gap" }, true)
    assert.are.equal("yellow", result.verdict)
  end)

  it("still keeps verdicts that hold for any character", function()
    local result = MakeSpace.Verdict.ForBank({ verdict = "green", reason = "Sells for 2c",
                                              rule = "poor_quality" }, true)
    assert.are.equal("green", result.verdict)
  end)
end)

describe("Safe to vendor: the auction price is close to the vendor price", function()
  local function greenBoe(overrides)
    local item = { id = 41001, classID = 4, subClassID = 2, quality = 2, itemLevel = 20,
      reqLevel = 18, sellPrice = 300, count = 1, isBound = false, liveAge = 0,
      equippedInSlots = { { quality = 2, itemLevel = 25 } } }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local state = { level = 20, professionNames = {}, professionsKnown = true }

  local saved
  local function setPrices(prices)
    saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = prices
  end
  local function restore() MakeSpace.Data.AuctionPriceCeiling = saved end

  it("green when the ceiling is close to the vendor price", function()
    setPrices({ [41001] = 400 })
    local verdict, reason, _, tag, rule = MakeSpace.Verdict.Evaluate(greenBoe(), state)
    restore()
    assert.are.equal("green", verdict)
    assert.are.equal("Vendor 3s, auction up to 4s", reason)
    assert.is_nil(tag)
    assert.are.equal("sell_at_vendor", rule)
  end)

  it("is not shown in the bank", function()
    local bank = MakeSpace.Verdict.ForBank({ verdict = "green", reason = "Vendor 3s, auction up to 4s",
      sellable = true, rule = "sell_at_vendor" })
    assert.is_nil(bank.verdict)
  end)

  it("still green up to the limit, silent above it", function()
    -- 3s vendor, snapshot price: the limit is about 4s 72c (see src/curves.lua)
    local limit = math.floor(MakeSpace.Curves.Limit(300, "item", "gear"))
    setPrices({ [41001] = limit })
    local atLimit = MakeSpace.Verdict.Evaluate(greenBoe(), state)
    MakeSpace.Data.AuctionPriceCeiling[41001] = limit + 1
    local above = MakeSpace.Verdict.Evaluate(greenBoe(), state)
    restore()
    assert.are.equal("green", atLimit)
    assert.is_nil(above)
  end)

  it("the allowed margin shrinks as the vendor price grows", function()
    local function passes(vendor, ceiling)
      setPrices({ [41001] = ceiling })
      local verdict = MakeSpace.Verdict.Evaluate(greenBoe({ sellPrice = vendor }), state)
      restore()
      return verdict == "green"
    end
    local lastRatio = math.huge
    for _, vendor in ipairs({ 100, 500, 1000, 3000, 10000, 50000 }) do
      local limit = math.floor(MakeSpace.Curves.Limit(vendor, "item", "gear"))
      assert.is_truthy(passes(vendor, limit))
      assert.is_truthy(not passes(vendor, limit + 1))
      local ratio = limit / vendor
      assert.is_truthy(ratio < lastRatio)
      lastRatio = ratio
    end
  end)

  it("low prices get a flat margin for the trip", function()
    -- 90c vendor: the limit is about 2s 16c, however low the share of the vendor price
    setPrices({ [41001] = 200 })
    local verdict = MakeSpace.Verdict.Evaluate(greenBoe({ sellPrice = 90 }), state)
    MakeSpace.Data.AuctionPriceCeiling[41001] = 300
    local above = MakeSpace.Verdict.Evaluate(greenBoe({ sellPrice = 90 }), state)
    restore()
    assert.are.equal("green", verdict)
    assert.is_nil(above)
  end)

  it("an old snapshot tightens the limit, a live price does not", function()
    local limit = math.floor(MakeSpace.Curves.Limit(300, "item", "gear"))
    setPrices({ [41001] = limit })
    local fresh = MakeSpace.Verdict.Evaluate(greenBoe(), state)
    local oldState = { level = 20, professionNames = {}, professionsKnown = true, priceAgeDays = 12 }
    local old = MakeSpace.Verdict.Evaluate(greenBoe(), oldState)
    local live = MakeSpace.Verdict.Evaluate(greenBoe({ livePrice = limit }), oldState)
    restore()
    assert.are.equal("green", fresh)
    assert.is_nil(old)
    assert.are.equal("green", live)
  end)

  it("silent without price data, or without a vendor price to compare", function()
    setPrices({})
    local noData = MakeSpace.Verdict.Evaluate(greenBoe(), state)
    MakeSpace.Data.AuctionPriceCeiling[41001] = 10
    local noVendor = MakeSpace.Verdict.Evaluate(greenBoe({ sellPrice = 0 }), state)
    restore()
    assert.is_nil(noData)
    assert.is_nil(noVendor)
  end)

  it("silent when it could be an upgrade, or when the worn gear is unknown", function()
    setPrices({ [41001] = 300 })
    local upgrade = MakeSpace.Verdict.Evaluate(greenBoe({ itemLevel = 30 }), state)
    local unknown = greenBoe()
    unknown.equippedInSlots = nil
    local a = MakeSpace.Verdict.Evaluate(unknown, state)
    restore()
    assert.is_nil(upgrade)
    assert.is_nil(a)
  end)

  it("only green gear that is still tradeable", function()
    setPrices({ [41001] = 300 })
    local blue = MakeSpace.Verdict.Evaluate(greenBoe({ quality = 3 }), state)
    local bound = MakeSpace.Verdict.Evaluate(greenBoe({ isBound = true }), state)
    restore()
    assert.is_nil(blue)
    assert.is_nil(bound)
  end)

  it("a protected item is never green", function()
    setPrices({ [41001] = 300 })
    local verdict = MakeSpace.Verdict.Evaluate(greenBoe({ isKept = true }), state)
    restore()
    assert.is_nil(verdict)
  end)

  it("a recipe stays yellow however cheap it is: Safety never allows a green on one", function()
    setPrices({ [41002] = 100 })
    local recipe = { id = 41002, classID = 9, subClassID = 1, quality = 1, count = 1, sellPrice = 100 }
    local verdict = MakeSpace.Verdict.Evaluate(recipe, state)
    restore()
    assert.are.equal("yellow", verdict)
  end)
end)

describe("Yellow headings", function()
  local note = MakeSpace.Verdict.Note

  it("defines each yellow once: reason, short heading, detail underneath", function()
    local cases = {
      { { "low_item_level", 30, 50 },       "Low item level (30 for level 50)",           "Outleveled gear",     "Item level 30, you are 50" },
      { { "low_level_gear", 30, 45 },       "Low level gear (needs 30, you are 45)",     "Outleveled gear",     "Required level 30, you are 45" },
      { { "very_low_level_gear", 10, 40 },  "Very low level gear (needs 10, you are 40)", "Outleveled gear",    "Required level 10, you are 40" },
      { { "very_low_item_level", 30, 60 },  "Very low item level (30 for level 60)",      "Outleveled gear",     "Item level 30, you are 60" },
      { { "quest_abandon" },                "Quest is far below you, consider abandoning it", "Low-level quest", "Consider abandoning it" },
      { { "quest_not_worth" },              "Quest is far below you, probably not worth taking", "Low-level quest", "Probably not worth it" },
      { { "gray_worth", "4s 65c", false },  "Gray, but worth 4s 65c",                    "Save for vendor",     "Gray, but worth 4s 65c" },
      { { "gray_worth", "4s 65c", true },   "Cheapest gray, but worth 4s 65c",           "Save for vendor",     "Cheapest gray, but worth 4s 65c" },
      { { "no_known_use", "3s" },           "Not used for any quest or recipe, sells for 3s", "No known use",   nil },
      { { "not_your_profession" },          "You don't have this profession. May sell at the auction house", "Not your profession", nil },
      { { "bank_skill", "Alchemy", 126 },   "Bank it, needs Alchemy 126",                "Bank it",             "Needs Alchemy 126" },
      { { "bank_level", 30 },               "Bank it, needs level 30",                   "Bank it",             "Needs level 30" },
      { { "bank_used_from", "Mining", 175 }, "Bank it, used from Mining 175",            "Bank it",             "Used from Mining 175" },
      { { "outleveled_reagent", "Mining", 125 }, "Outleveled, Mining recipes use it up to 125", "Outleveled reagent", "Mining recipes use it up to 125" },
      { { "low_level_consumable", "food", 5, 30 }, "Low-level food (level 5, you are 30)", "Low-level food",    "Level 5, you are 30" },
      { { "weak_bandage", 400, 9, 4500 },    "Weak bandage", "Weak bandage", "Heals 9% of your health (400 of 4500)" },
      { { "open_it" },                      "Open it, the contents may stack",           "Open it",             "Contents may stack" },
      { { "no_mana", "Warriors" },          "Warriors have no mana. May sell at the auction house", "Not for your class", "No mana for Warriors" },
      { { "wrong_class_reagent", "Mage, Priest only (world drop)" }, "Mage, Priest only (world drop)", "Wrong class reagent", "Mage, Priest only (world drop)" },
      { { "other_profession_reagent", { "Alchemy", "Tailoring" } }, "Only used by professions you don't have. May sell at the auction house", "Not your profession", "Used by Alchemy, Tailoring" },
      { { "other_profession_reagent", { "A", "B", "C", "D" } }, "Only used by professions you don't have. May sell at the auction house", "Not your profession", "Used by 4 professions" },
      { { "library_book", "Alliance" },     "Library book, hand it in to Garion Wendell in Stormwind", "Library book", "Hand in to Garion Wendell, Stormwind" },
      { { "library_book", "Horde" },        "Library book, hand it in to Owen Thadd in Undercity", "Library book", "Hand in to Owen Thadd, Undercity" },
      { { "library_book", nil },            "Library book, hand it in to the librarian in Stormwind or Undercity", "Library book", "Hand in to Stormwind or Undercity" },
      { { "shard_buff" },                   "Trade 4 of these to Mangletooth for a buff in the Barrens", "Trade for a buff", "Mangletooth, Camp Taurajo" },
      { { "flagged" },                      "Flagged by you",                            "Flagged by you",      nil },
    }
    for _, case in ipairs(cases) do
      local reason, heading = note(unpack(case[1]))
      assert.are.equal(case[2], reason)
      assert.are.equal(case[3], heading.title)
      assert.are.equal(case[4], heading.detail)
      local words = 0
      for _ in heading.title:gmatch("%S+") do words = words + 1 end
      assert.is_truthy(words <= 4)
    end
  end)

  it("a rule hands its heading out with its verdict", function()
    local state = { level = 42, class = "Warrior", race = "Human" }
    local item = { id = 33002, isBound = true, isEquippable = true, reqLevel = 30 }
    local verdict, reason, _, _, rule, heading = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("yellow", verdict)
    assert.are.equal("level_gap", rule)
    assert.are.equal("Outleveled gear", heading.title)
    assert.are.equal("Required level 30, you are 42", heading.detail)
    local _, _, _, _, _, flagged = MakeSpace.Verdict.Evaluate({ id = 1, isFlagged = true }, state)
    assert.are.equal("Flagged by you", flagged.title)
  end)

  it("every yellow a rule can give carries a heading", function()
    -- A new kind of yellow added without a heading would show its full reason as
    -- the heading; this keeps that from happening quietly.
    local state = { level = 60, class = "Warrior", race = "Human", professionsKnown = true,
                    professionNames = {}, professionRanks = {}, playerClass = "WARRIOR" }
    local samples = {
      { id = 1, isBound = true, isEquippable = true, reqLevel = 45 },
      { id = 2, classID = 0, subClassID = 5, quality = 1, reqLevel = 5, count = 1, sellPrice = 4, restoresHealthOrMana = true },
      { id = 3, classID = 9, subClassID = 1, quality = 1, count = 1, sellPrice = 100 },
      { id = 4, hasLoot = true, classID = 0 },
    }
    for _, item in ipairs(samples) do
      local verdict, reason, _, _, _, heading = MakeSpace.Verdict.Evaluate(item, state)
      if verdict == "yellow" then
        assert.is_truthy(heading and heading.title)
      end
    end
  end)
end)

describe("Sell-at-vendor facts for /makespace why", function()
  local function joined(item)
    return table.concat(MakeSpace.Verdict.SellAtVendorFacts(item), "\n")
  end
  local base = { id = 777001, classID = 4, quality = 2, sellPrice = 200, itemLevel = 10,
                 equippedInSlots = { { quality = 2, itemLevel = 12 } } }

  it("says the numbers and whether the AH is within the limit", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777001] = 250 }
    local text = joined(base)
    assert.is_truthy(text:find("vendor 2s", 1, true))
    assert.is_truthy(text:find("auction ceiling 2s 50c", 1, true))
    assert.is_truthy(text:find("(within)", 1, true))
    MakeSpace.Data.AuctionPriceCeiling = { [777001] = 900 }
    assert.is_truthy(joined(base):find("auction pays too much", 1, true))
    MakeSpace.Data.AuctionPriceCeiling = nil
  end)

  it("names what blocks it: quality, binding, missing price, upgrade", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777001] = 250 }
    assert.is_truthy(joined({ id = 777001, classID = 4, quality = 1 }):find("only green gear", 1, true))
    assert.is_truthy(joined({ id = 777001, classID = 4, quality = 2, isBound = true }):find("soulbound", 1, true))
    assert.is_truthy(joined({ id = 777002, classID = 4, quality = 2, sellPrice = 5 }):find("no auction price", 1, true))
    local upgrade = { id = 777001, classID = 4, quality = 2, sellPrice = 200, itemLevel = 30,
                      equippedInSlots = { { quality = 2, itemLevel = 12 } } }
    assert.is_truthy(joined(upgrade):find("could be an upgrade", 1, true))
    assert.are.equal(0, #MakeSpace.Verdict.SellAtVendorFacts({ classID = 7, quality = 2 }))
    MakeSpace.Data.AuctionPriceCeiling = nil
  end)
end)

describe("Auction price per version of an item", function()
  it("reads the bonus ids from an item link", function()
    local link = "|cff1eff00|Hitem:9811::::::::25:0::1:1:12744|h[Fortified Bracers]|h|r"
    assert.are.equal("12744", MakeSpace.Auction.BonusKey(link))
    local two = "item:9811::::::::25:0::0:2:12800:12727"
    assert.are.equal("12727-12800", MakeSpace.Auction.BonusKey(two))
  end)

  it("gives nothing for a plain link or one in an unexpected shape", function()
    assert.is_nil(MakeSpace.Auction.BonusKey("item:9811::::::::25:0::0:0"))
    assert.is_nil(MakeSpace.Auction.BonusKey("item:9811"))
    assert.is_nil(MakeSpace.Auction.BonusKey("item:9811:0:0:0:0:0:0:0:25:0:0:0:2:5"))
    assert.is_nil(MakeSpace.Auction.BonusKey(nil))
  end)

  local gear = { id = 777010, classID = 4, quality = 2, sellPrice = 725, itemLevel = 10, bonusKey = "12744",
                 equippedInSlots = { { quality = 2, itemLevel = 12 } } }
  local state = { level = 30, class = "Warrior" }

  it("uses the version's own price, so a cheap version is sellable under a pricey item", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777010] = 8700 }
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12744"] = 800, ["12722"] = 27000 } }
    local verdict = MakeSpace.Verdict.Evaluate(gear, state)
    assert.are.equal("green", verdict)
    MakeSpace.Data.AuctionPriceCeiling = nil
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)

  it("a pricey version of a cheap item gets no green", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777010] = 800 }
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12722"] = 27000 } }
    local pricey = {}
    for k, v in pairs(gear) do pricey[k] = v end
    pricey.bonusKey = "12722"
    assert.is_nil((MakeSpace.Verdict.Evaluate(pricey, state)))
    MakeSpace.Data.AuctionPriceCeiling = nil
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)

  it("stays silent for a version it has no price for, even when the item itself is cheap", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777010] = 800 }
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12744"] = 800 } }
    local rare = {}
    for k, v in pairs(gear) do rare[k] = v end
    rare.bonusKey = "12723"
    assert.is_nil((MakeSpace.Verdict.Evaluate(rare, state)))
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(gear, state)))
    local text = table.concat(MakeSpace.Verdict.SellAtVendorFacts(rare), "\n")
    assert.is_truthy(text:find("this version has no auction price", 1, true))
    MakeSpace.Data.AuctionPriceCeiling = nil
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)

  it("a version with no price follows the dearest listed version when several are listed", function()
    local unlisted = {}
    for k, v in pairs(gear) do unlisted[k] = v end
    unlisted.bonusKey = "12723"
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12744"] = 800, ["12745"] = 700, ["12746"] = 900 } }
    local verdict, reason = MakeSpace.Verdict.Evaluate(unlisted, state)
    assert.are.equal("green", verdict)
    assert.are.equal("Vendor 7s 25c, auction up to 9s", reason)
    -- one dear version among the listed ones keeps the green away
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12744"] = 800, ["12745"] = 700, ["12746"] = 27000 } }
    assert.is_nil((MakeSpace.Verdict.Evaluate(unlisted, state)))
    -- two listed versions are too few to stand in for the rest
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = { ["12744"] = 800, ["12745"] = 700 } }
    assert.is_nil((MakeSpace.Verdict.Evaluate(unlisted, state)))
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)

  it("an item marked as having versions but none priced stays silent", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777010] = 800 }
    MakeSpace.Data.AuctionVariantCeiling = { [777010] = {} }
    assert.is_nil((MakeSpace.Verdict.Evaluate(gear, state)))
    MakeSpace.Data.AuctionPriceCeiling = nil
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)

  it("an item with no versions in the data uses its own ceiling", function()
    MakeSpace.Data.AuctionPriceCeiling = { [777010] = 800 }
    MakeSpace.Data.AuctionVariantCeiling = {}
    local plain = {}
    for k, v in pairs(gear) do plain[k] = v end
    plain.bonusKey = nil
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(plain, state)))
    MakeSpace.Data.AuctionPriceCeiling = nil
    MakeSpace.Data.AuctionVariantCeiling = nil
  end)
end)

describe("Enchanters and bound recipes", function()
  local function state(professions)
    local names = {}
    for name in pairs(professions) do names[name] = true end
    return { level = 40, professionNames = names, professionRanks = professions,
             professionSkillLines = {}, professionsKnown = true }
  end
  local greenBoe = { id = 41002, classID = 4, subClassID = 2, quality = 2, itemLevel = 20,
    reqLevel = 18, sellPrice = 300, count = 1, isBound = false,
    equippedInSlots = { { quality = 2, itemLevel = 25 } } }

  it("green gear to vendor is left alone for an Enchanter", function()
    MakeSpace.Data.AuctionPriceCeiling = { [41002] = 400 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(greenBoe, state({}))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(greenBoe, state({ Enchanting = 100 }))))
    MakeSpace.Data.AuctionPriceCeiling = nil
  end)

  it("a bound green far below you is only yellow for an Enchanter", function()
    local item = { id = 41003, isBound = true, isEquippable = true, quality = 2, reqLevel = 10,
      itemLevel = 12, sellPrice = 100, count = 1 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(item, state({}))))
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(item, state({ Enchanting = 100 }))))
  end)

  it("a bound recipe for another profession gets no auction hint", function()
    local recipe = { id = 9002, classID = 9, subClassID = 6, quality = 1, isBound = true }
    assert.is_nil((MakeSpace.Verdict.Evaluate(recipe, state({ Mining = 50 }))))
    recipe.isBound = false
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(recipe, state({ Mining = 50 }))))
  end)
end)

describe("Gear with a low required level but a real item level", function()
  local state = { level = 27, professionNames = {}, professionsKnown = true }

  it("requires 1 but item level 24 is only 3 below you, so no verdict", function()
    local stitcher = { id = 7, isBound = true, isEquippable = true, quality = 2,
      reqLevel = 1, itemLevel = 24, sellPrice = 100, count = 1 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(stitcher, state)))
  end)

  it("judges by item level when it is the higher number", function()
    local item = { id = 8, isBound = true, isEquippable = true, quality = 2,
      reqLevel = 1, itemLevel = 5, sellPrice = 100, count = 1 }
    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)
    assert.are.equal("green", verdict)
    assert.are.equal("Very low item level (5 for level 27)", reason)
  end)
end)

describe("Tradable items the auction house may value more than a vendor", function()
  local state = { level = 30, professionNames = {}, professionsKnown = true }
  local function manual(overrides)
    local item = { id = 16645, classID = 12, quality = 1, count = 1, sellPrice = 5, isBound = false,
      bindType = 0, questItemQuestIDs = { 7 }, allQuestObjectivesCompleted = true }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  it("with price data over 14 days old, a tradeable green rests on nothing and stays silent", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 20 }
    local old = { level = 30, professionNames = {}, professionsKnown = true, priceAgeDays = 15 }
    local fresh = { level = 30, professionNames = {}, professionsKnown = true, priceAgeDays = 14 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual(), fresh)))
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual(), old)))
    -- an item that cannot be sold at auction never depended on the data
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ isBound = true, bindType = 4 }), old)))
    -- a fresh Auctionator price does not depend on the snapshot either
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ livePrice = 20, liveAge = 0 }), old)))
    MakeSpace.Data.AuctionPriceCeiling = nil
  end)

  it("a finished quest item stays green when the auction pays about the vendor price", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 20 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual(), state)))
  end)

  it("a finished quest item that auctions for much more gets no verdict", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 800 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual(), state)))
    local trace = MakeSpace.Verdict.Trace(manual(), state)
    assert.are.equal("quest_objective_done", trace[1].rule)
    assert.is_truthy(trace[1].blockedBy:find("auction up to 8s", 1, true))
  end)

  it("a stackable is judged by the stack: 4c vendor and 1s 75c auction is no green", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 175 }
    local blackmouth = manual({ sellPrice = 4, maxStack = 20, count = 7 })
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(blackmouth, state)
    assert.is_nil(verdict)
    assert.are.equal("Vendor 4c, auction up to 1s 75c", note)
    -- a single item is judged by itself: 1s 75c for a 4c item is still a trip worth making
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual({ sellPrice = 4 }), state)))
  end)

  it("a stackable that auctions for about the vendor price is still green", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 40 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ sellPrice = 30, maxStack = 20 }), state)))
    -- 50c is 20c more apiece, 4s over a stack: worth listing
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 50 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual({ sellPrice = 30, maxStack = 20 }), state)))
  end)

  it("a dropped green hands back a note with both prices for the tooltip", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 800 }
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(manual(), state)
    assert.is_nil(verdict)
    assert.are.equal("Vendor 5c, auction up to 8s", note)
  end)

  it("a manual that auctions for about the vendor price has no note", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 20 }
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(manual(), state)
    assert.are.equal("green", verdict)
    assert.is_nil(note)
  end)

  it("an item with no vendor price says so in the note", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 800 }
    local _, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(manual({ sellPrice = 0 }), state)
    assert.are.equal("No vendor price, auction up to 8s", note)
  end)

  it("an unknown market gives no price note, since there is no price to show", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 800 }
    MakeSpace.Data.AuctionMarketMissing = true
    local _, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(manual(), state)
    MakeSpace.Data.AuctionMarketMissing = nil
    assert.is_nil(note)
  end)

  it("a finished quest item gets no green when the player's market is unknown", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 20 }
    MakeSpace.Data.AuctionMarketMissing = true
    local verdict = MakeSpace.Verdict.Evaluate(manual(), state)
    local trace = MakeSpace.Verdict.Trace(manual(), state)
    MakeSpace.Data.AuctionMarketMissing = nil
    assert.is_nil(verdict)
    assert.is_truthy(trace[1].blockedBy:find("your region and faction", 1, true))
  end)

  it("an item that cannot be listed stays green even when the market is unknown", function()
    MakeSpace.Data.AuctionMarketMissing = true
    local verdict = MakeSpace.Verdict.Evaluate(manual({ isBound = true }), state)
    MakeSpace.Data.AuctionMarketMissing = nil
    assert.are.equal("green", verdict)
  end)

  it("a soulbound or quest-bound item cannot be listed, so the price is ignored", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 300 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ isBound = true }), state)))
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ bindType = 4 }), state)))
  end)

  it("an item the auction has no price for stays green", function()
    MakeSpace.Data.AuctionPriceCeiling = { [99999] = 300 }
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual(), state)))
  end)

  it("an item with no vendor price is held back once the auction pays real money", function()
    MakeSpace.Data.AuctionPriceCeiling = { [16645] = 500 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual({ sellPrice = 0 }), state)))
  end)

  it("a version the data does not know is silenced", function()
    MakeSpace.Data.AuctionPriceCeiling = {}
    MakeSpace.Data.AuctionVariantCeiling = { [16645] = { ["1111"] = 10 } }
    assert.is_nil((MakeSpace.Verdict.Evaluate(manual({ bonusKey = "2222" }), state)))
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(manual({ bonusKey = "1111" }), state)))
  end)

  it("an unused trade good worth more at auction than at a vendor is not green", function()
    MakeSpace.Data.ReagentProfessions = {}
    local good = { id = 777, classID = 7, subClassID = 9, quality = 1, count = 1, sellPrice = 10, isBound = false }
    MakeSpace.Data.AuctionPriceCeiling = {}
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(good, state)))
    MakeSpace.Data.AuctionPriceCeiling = { [777] = 800 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(good, state)))
  end)

  it("a vendor reagent for a profession you lack is not green when the auction pays more", function()
    MakeSpace.Data.VendorReagents = { [3371] = {} }
    MakeSpace.Data.ReagentProfessions = { [3371] = { { "Alchemy", 1, 1, 100 } } }
    local vial = { id = 3371, classID = 7, quality = 1, count = 1, sellPrice = 2, isBound = false }
    MakeSpace.Data.AuctionPriceCeiling = {}
    assert.are.equal("green", (MakeSpace.Verdict.Evaluate(vial, state)))
    MakeSpace.Data.AuctionPriceCeiling = { [3371] = 800 }
    assert.is_nil((MakeSpace.Verdict.Evaluate(vial, state)))
  end)

  it("a blue is never green, whatever the data says", function()
    MakeSpace.Data.AuctionPriceCeiling = { [41100] = 100 }
    local blue = { id = 41100, classID = 4, subClassID = 2, quality = 3, itemLevel = 12, reqLevel = 10,
      sellPrice = 500, count = 1, isBound = false, isEquippable = true,
      equippedInSlots = { { quality = 3, itemLevel = 30 } } }
    for _, bound in ipairs({ false, true }) do
      blue.isBound = bound
      assert.is_truthy((MakeSpace.Verdict.Evaluate(blue, state)) ~= "green")
    end
  end)
end)


describe("The limit has no cliffs", function()
  local state = { level = 20, professionNames = {}, professionsKnown = true }
  local function gear(vendor)
    return { id = 41200, classID = 4, subClassID = 2, quality = 2, itemLevel = 20, reqLevel = 18,
      sellPrice = vendor, count = 1, isBound = false,
      equippedInSlots = { { quality = 2, itemLevel = 25 } } }
  end

  it("the limit never falls as the vendor price rises, for either curve", function()
    for _, source in ipairs({ "live", "item", "version" }) do
      for _, stackable in ipairs({ false, true }) do
        local last = 0
        for vendor = 1, 30000 do
          local limit = MakeSpace.Curves.Limit(vendor, source, stackable)
          assert.is_truthy(limit >= last)
          last = limit
        end
      end
    end
  end)

  it("tells /makespace why the real prices and the limit", function()
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = { [41200] = 778 }
    local facts = table.concat(MakeSpace.Verdict.SellAtVendorFacts(gear(577)), "\n")
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.is_truthy(facts:find("vendor 5s 77c", 1, true))
    assert.is_truthy(facts:find("auction ceiling 7s 78c", 1, true))
    assert.is_truthy(facts:find("limit ", 1, true))
  end)

  it("the tooltip note for a dropped green still shows the real prices", function()
    local savedReagents, savedPrices = MakeSpace.Data.ReagentProfessions, MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.AuctionPriceCeiling = { [777] = 899 }
    local good = { id = 777, classID = 7, subClassID = 9, quality = 1, count = 1, sellPrice = 100, isBound = false }
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(good, state)
    MakeSpace.Data.ReagentProfessions, MakeSpace.Data.AuctionPriceCeiling = savedReagents, savedPrices
    assert.is_nil(verdict)
    assert.are.equal("Vendor 1s, auction up to 8s 99c", note)
  end)
end)

describe("Repeatable quests and hint items", function()
  local function questItem(overrides)
    local item = { id = 9301, classID = 12, quality = 1, questItemQuestIDs = { 5101 },
                   allQuestObjectivesCompleted = false, openQuestIDs = { 5101 }, onOpenQuest = false }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function as(faction, level)
    return { level = level or 60, faction = faction, professionNames = {}, professionsKnown = true }
  end
  MakeSpace.Data.QuestInfo = MakeSpace.Data.QuestInfo or {}
  MakeSpace.Data.QuestInfo[5101] = { 5, "Elwynn Forest", "Wolf Problem" }

  local function withRepeatable(fn)
    local saved = MakeSpace.Data.RepeatableQuests
    MakeSpace.Data.RepeatableQuests = { [5101] = true }
    local ok, err = pcall(fn)
    MakeSpace.Data.RepeatableQuests = saved
    assert.is_truthy(ok, err)
  end
  local function withBooks(fn)
    local saved = MakeSpace.Data.LibraryBooks
    MakeSpace.Data.LibraryBooks = { [99500] = true }
    local ok, err = pcall(fn)
    MakeSpace.Data.LibraryBooks = saved
    assert.is_truthy(ok, err)
  end

  it("an item for a repeatable quest is not called low-level, however low the quest", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(questItem(), as("Horde"))))
    withRepeatable(function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), as("Horde"))))
    end)
  end)

  it("a Blood Shard tells a Horde character what to trade it for", function()
    local shard = questItem({ id = 5075, questItemQuestIDs = { 5101 } })
    withRepeatable(function()
      local verdict, reason, _, _, rule, heading = MakeSpace.Verdict.Evaluate(shard, as("Horde"))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Trade 4 of these to Mangletooth for a buff in the Barrens", reason)
      assert.are.equal("item_hint", rule)
      assert.are.equal("Trade for a buff", heading.title)
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(shard, as(nil))))
    end)
  end)

  it("an Alliance character gets no Blood Shard hint", function()
    local shard = questItem({ id = 5075 })
    withRepeatable(function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(shard, as("Alliance"))))
    end)
  end)

  it("a library book says where to hand it in, by faction", function()
    withBooks(function()
      local book = { id = 99500, classID = 12, quality = 1, sellPrice = 0, count = 1 }
      local verdict, reason, _, _, rule = MakeSpace.Verdict.Evaluate(book, as("Alliance"))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Library book, hand it in to Garion Wendell in Stormwind", reason)
      assert.are.equal("item_hint", rule)
      local _, horde = MakeSpace.Verdict.Evaluate(book, as("Horde"))
      assert.are.equal("Library book, hand it in to Owen Thadd in Undercity", horde)
      local _, either = MakeSpace.Verdict.Evaluate(book, as(nil))
      assert.are.equal("Library book, hand it in to the librarian in Stormwind or Undercity", either)
    end)
  end)

  it("a library book is never called a low-level quest item", function()
    withBooks(function()
      local book = questItem({ id = 99500 })
      local _, reason = MakeSpace.Verdict.Evaluate(book, as("Horde", 60))
      assert.are.equal("Library book, hand it in to Owen Thadd in Undercity", reason)
    end)
  end)

  it("a book that is a consumable still gets its hint", function()
    withBooks(function()
      local book = { id = 99500, classID = 0, subClassID = 0, quality = 1, sellPrice = 0, count = 1 }
      local verdict, _, _, _, rule = MakeSpace.Verdict.Evaluate(book, as("Horde"))
      assert.are.equal("yellow", verdict)
      assert.are.equal("item_hint", rule)
    end)
  end)

  it("a book that can no longer be handed in gets no hint", function()
    withBooks(function()
      local misc = { id = 99500, classID = 15, quality = 1, sellPrice = 0, count = 1, startsQuestCompleted = true }
      assert.is_nil((MakeSpace.Verdict.Evaluate(misc, as("Horde"))))
      local done = { id = 99500, classID = 15, quality = 1, sellPrice = 0, count = 1,
        questItemQuestIDs = { 5101 }, allQuestObjectivesCompleted = true }
      assert.is_nil((MakeSpace.Verdict.Evaluate(done, as("Horde"))))
    end)
  end)

  it("a book whose quest is already finished is still green", function()
    withBooks(function()
      local book = { id = 99500, classID = 12, quality = 1, sellPrice = 0, count = 1,
        startsQuestID = 5101, startsQuestCompleted = true }
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(book, as("Horde"))))
    end)
  end)
end)

describe("Drinks for classes without mana", function()
  local function drink(overrides)
    local item = { id = 9451, classID = 0, subClassID = 5, quality = 1, reqLevel = 25, count = 5,
      sellPrice = 40, restoresHealthOrMana = true, restoresManaOnly = true }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function as(class)
    return { level = 30, playerClass = class, professionNames = {}, professionsKnown = true }
  end

  it("a warrior or rogue gets the no-mana yellow on a drink", function()
    local verdict, reason, _, _, rule = MakeSpace.Verdict.Evaluate(drink(), as("WARRIOR"))
    assert.are.equal("yellow", verdict)
    assert.are.equal("Warriors have no mana. May sell at the auction house", reason)
    assert.are.equal("mana_consumable", rule)
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(drink(), as("ROGUE"))))
  end)

  it("a class with mana keeps its drinks", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(drink(), as("MAGE"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(drink(), as("DRUID"))))
  end)

  it("food that also heals is not a drink", function()
    local feast = drink({ restoresManaOnly = false })
    assert.is_nil((MakeSpace.Verdict.Evaluate(feast, as("WARRIOR"))))
  end)
end)

describe("Reagents only used by professions you lack", function()
  local function item(overrides)
    local good = { id = 8001, classID = 7, subClassID = 7, quality = 1, count = 4, sellPrice = 100, isBound = false }
    for key, value in pairs(overrides or {}) do good[key] = value end
    return good
  end
  local function player(professions)
    local names, ranks = {}, {}
    for name, rank in pairs(professions) do names[name] = true; ranks[name] = rank end
    return { level = 40, playerClass = "WARRIOR", professionNames = names, professionRanks = ranks,
             professionsKnown = true }
  end
  local TWO = { Mining = 100, Blacksmithing = 100 }

  local function withData(overrides, fn)
    local keys = { "ReagentProfessions", "ReagentChains", "VendorReagents", "ClassReagents", "AuctionPriceCeiling" }
    local saved = {}
    for _, key in ipairs(keys) do saved[key] = MakeSpace.Data[key] end
    MakeSpace.Data.ReagentProfessions = { [8001] = { { "Alchemy", 1, 1, 100 } } }
    MakeSpace.Data.ReagentChains, MakeSpace.Data.VendorReagents = nil, nil
    MakeSpace.Data.ClassReagents, MakeSpace.Data.AuctionPriceCeiling = nil, nil
    for key, value in pairs(overrides or {}) do MakeSpace.Data[key] = value end
    local ok, err = pcall(fn)
    for _, key in ipairs(keys) do MakeSpace.Data[key] = saved[key] end
    assert.is_truthy(ok, err)
  end

  it("is yellow with the professions that use it", function()
    withData(nil, function()
      local verdict, reason, _, _, rule, heading = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Only used by professions you don't have. May sell at the auction house", reason)
      assert.are.equal("other_profession_reagent", rule)
      assert.are.equal("Used by Alchemy", heading.detail)
    end)
  end)

  it("shows the vendor and auction prices when the auction is worth it", function()
    withData({ AuctionPriceCeiling = { [8001] = 800 } }, function()
      local _, reason, _, _, _, _, note = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.are.equal("Vendor 1s, auction up to 8s", note)
      assert.is_truthy(reason:find("May sell at the auction house", 1, true))
    end)
    withData(nil, function()
      local verdict, reason, _, _, _, _, note = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.are.equal("yellow", verdict)
      assert.is_nil(note)
      -- no price data: the hint cannot say either way, so it keeps suggesting it
      assert.is_truthy(reason:find("May sell at the auction house", 1, true))
    end)
  end)

  it("leaves the price line out, and stops suggesting the auction house, when it pays next to nothing", function()
    -- a couple of copper at the auction, and a vendor price it does not clearly beat
    withData({ AuctionPriceCeiling = { [8001] = 3 } }, function()
      local verdict, reason, _, _, _, _, note = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.are.equal("yellow", verdict)
      assert.is_nil(note)
      assert.are.equal("Only used by professions you don't have", reason)
    end)
    -- worth more than a vendor, under the listing floor, but a stack worth real money
    withData({ AuctionPriceCeiling = { [8001] = 40 } }, function()
      local verdict, reason = MakeSpace.Verdict.Evaluate(
        { id = 8001, classID = 7, subClassID = 5, quality = 1, sellPrice = 2, maxStack = 20, count = 20 }, player(TWO))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Only used by professions you don't have", reason)
    end)
  end)

  it("an old price that is clearly low shows its own number and can make a small stack green", function()
    withData({ AuctionPriceCeiling = { [8001] = 800 } }, function()
      local small = item()
      small.sellPrice, small.stalePrice, small.staleAge, small.count = 20, 26, 4, 3
      local verdict, reason, _, _, _, _, note = MakeSpace.Verdict.Evaluate(small, player(TWO))
      assert.are.equal("green", verdict)
      assert.are.equal("Worth very little", reason)
      -- the old reading is shown instead of the snapshot's 8s
      assert.are.equal("Vendor 20c, auction about 26c", note)
    end)
  end)

  it("with an old low price, a stack worth real money stays a yellow without the auction nudge", function()
    withData({ AuctionPriceCeiling = { [8001] = 800 } }, function()
      local big = item()
      big.sellPrice, big.stalePrice, big.staleAge, big.count = 20, 26, 4, 20
      local verdict, reason, _, _, _, _, note = MakeSpace.Verdict.Evaluate(big, player(TWO))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Only used by professions you don't have", reason)
      assert.are.equal("Vendor 20c, auction about 26c", note)
    end)
  end)

  it("an old high price keeps the hint", function()
    withData(nil, function()
      local dear = item()
      dear.sellPrice, dear.stalePrice, dear.staleAge = 20, 500, 4
      local _, reason = MakeSpace.Verdict.Evaluate(dear, player(TWO))
      assert.is_truthy(reason:find("May sell at the auction house", 1, true))
    end)
  end)

  describe("worth very little", function()
    local cheap = { id = 8001, classID = 7, subClassID = 5, quality = 1, sellPrice = 2, maxStack = 20, count = 3 }

    it("is green when the price is known, low, and the whole stack is worth next to nothing", function()
      withData({ AuctionPriceCeiling = { [8001] = 8 } }, function()
        local verdict, reason, _, _, rule, _, note = MakeSpace.Verdict.Evaluate(cheap, player(TWO))
        assert.are.equal("green", verdict)
        assert.are.equal("Worth very little", reason)
        assert.are.equal("other_profession_reagent", rule)
        assert.are.equal("Vendor 2c, auction up to 8c", note)
      end)
    end)

    it("never from a missing price: an item nobody lists may be rare", function()
      withData(nil, function()
        assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(cheap, player(TWO))))
      end)
    end)

    it("not when the stack adds up: 20 of them is real money", function()
      withData({ AuctionPriceCeiling = { [8001] = 8 } }, function()
        local big = { id = 8001, classID = 7, subClassID = 5, quality = 1, sellPrice = 40, maxStack = 20, count = 20 }
        assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(big, player(TWO))))
      end)
    end)

    it("the bar rises with the level, since money does", function()
      withData({ AuctionPriceCeiling = { [8001] = 8 } }, function()
        local stack = { id = 8001, classID = 7, subClassID = 5, quality = 1, sellPrice = 8, maxStack = 20, count = 12 }
        local low, high = player(TWO), player(TWO)
        low.level, high.level = 5, 60
        assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(stack, low)))   -- about 1s 10c on a 50c bar
        assert.are.equal("green", (MakeSpace.Verdict.Evaluate(stack, high)))   -- the same stack on a 3s bar
      end)
    end)

    it("an item a vendor sells for the profession's own use stays protected", function()
      withData({ AuctionPriceCeiling = { [8001] = 8 }, VendorReagents = { [8001] = { 171 } } }, function()
        assert.is_truthy((MakeSpace.Verdict.Evaluate(cheap, player(TWO))) ~= "green")
      end)
    end)
  end)

  it("stays silent until both primary professions are taken", function()
    withData(nil, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player({ Mining = 100 }))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player({}))))
      -- secondary professions do not fill a primary slot
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player({ Mining = 100, Cooking = 50, ["First Aid"] = 50 }))))
    end)
  end)

  it("stays silent when one of your professions uses it, directly or through a chain", function()
    withData({ ReagentProfessions = { [8001] = { { "Alchemy", 1, 1, 100 }, { "Blacksmithing", 1, 1, 100 } } } }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player(TWO))))
    end)
    withData({ ReagentChains = { [8001] = { { "Mining", 1, 300 } } } }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player(TWO))))
    end)
  end)

  it("stays silent for a bag of only gathering professions", function()
    withData(nil, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player({ Mining = 100, Herbalism = 100 }))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player({ Skinning = 100, Mining = 100 }))))
      -- one crafting profession is enough to speak
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(item(), player({ Skinning = 100, Tailoring = 100 }))))
    end)
  end)

  it("stays silent when Cooking, First Aid or Fishing uses it, since anyone can learn those", function()
    withData({ ReagentProfessions = { [8001] = { { "Alchemy", 1, 1, 100 }, { "First Aid", 1, 1, 100 } } } }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player(TWO))))
    end)
    withData({ ReagentChains = { [8001] = { { "Cooking", 1, 100 } } } }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), player(TWO))))
    end)
  end)

  it("is not shown in the bank, where mats for another character wait", function()
    local bank = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Only used by professions you don't have",
      rule = "other_profession_reagent" })
    assert.is_nil(bank.verdict)
  end)

  it("leaves vendor-sold reagents to the vendor reagent rule", function()
    withData({ VendorReagents = { [8001] = {} } }, function()
      local verdict, reason = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.are.equal("green", verdict)
      assert.are.equal("Vendor reagent (Alchemy)", reason)
    end)
  end)

  it("stays silent for soulbound items, class reagents and items an open quest wants", function()
    withData(nil, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(item({ isBound = true }), player(TWO))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(item({ questItemQuestIDs = { 1 },
        allQuestObjectivesCompleted = false, openQuestIDs = { 1 } }), player(TWO))))
    end)
    withData({ ClassReagents = { [8001] = { classes = { MAGE = true }, name = "X", verdict = "yellow" } } }, function()
      local _, _, _, _, rule = MakeSpace.Verdict.Evaluate(item(), player(TWO))
      assert.is_truthy(rule ~= "other_profession_reagent")
    end)
  end)

  it("says nothing when the player's professions could not be read", function()
    withData(nil, function()
      local unknown = player(TWO)
      unknown.professionsKnown = false
      assert.is_nil((MakeSpace.Verdict.Evaluate(item(), unknown)))
    end)
  end)
end)

describe("Items for a quest far above you", function()
  local function questItem(overrides)
    local item = { id = 9400, classID = 12, quality = 1, questItemQuestIDs = { 5201 },
                   allQuestObjectivesCompleted = false, openQuestIDs = { 5201 }, onOpenQuest = false }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function at(level) return { level = level, professionNames = {}, professionsKnown = true } end
  MakeSpace.Data.QuestInfo = MakeSpace.Data.QuestInfo or {}
  -- The quest level says 60 for all of these. What matters is the level to accept them.
  MakeSpace.Data.QuestInfo[5201] = { 60, nil, "Far Quest" }
  MakeSpace.Data.QuestInfo[5202] = { 60, nil, "Open Quest" }
  MakeSpace.Data.QuestInfo[5203] = { 60, nil, "Early Quest" }

  local function withRequired(levels, fn, events)
    local savedLevels, savedEvents = MakeSpace.Data.QuestRequiredLevels, MakeSpace.Data.QuestEvents
    MakeSpace.Data.QuestRequiredLevels, MakeSpace.Data.QuestEvents = levels, events
    local ok, err = pcall(fn)
    MakeSpace.Data.QuestRequiredLevels, MakeSpace.Data.QuestEvents = savedLevels, savedEvents
    assert.is_truthy(ok, err)
  end
  local FAR = { [5201] = 55, [5202] = 30, [5203] = 25 }

  it("says to bank an item for a quest you cannot take for a long while", function()
    withRequired(FAR, function()
      local verdict, reason, _, _, rule, heading = MakeSpace.Verdict.Evaluate(questItem(), at(30))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Bank it, quest needs level 55", reason)
      assert.are.equal("distant_quest_item", rule)
      assert.are.equal("Bank it", heading.title)
      assert.are.equal("[60] Far Quest", heading.detail)
    end)
  end)

  it("names the event for an event quest, whatever your level", function()
    -- Vibrant Plumes: a level 60 quest that opens at level 30, offered by the Faire.
    withRequired({ [5201] = 30 }, function()
      local verdict, reason, _, _, rule, heading = MakeSpace.Verdict.Evaluate(questItem(), at(30))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Bank it, for a Darkmoon Faire quest", reason)
      assert.are.equal("distant_quest_item", rule)
      assert.are.equal("Bank it", heading.title)
      assert.are.equal("Darkmoon Faire: [60] Far Quest", heading.detail)
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(questItem(), at(60))))
    end, { [5201] = "Darkmoon Faire" })
  end)

  it("works from the event list alone, and says what it is for a seasonal quest", function()
    withRequired(nil, function()
      local _, reason, _, _, _, heading = MakeSpace.Verdict.Evaluate(questItem(), at(60))
      assert.are.equal("Bank it, for a seasonal event quest", reason)
      assert.are.equal("Seasonal event: [60] Far Quest", heading.detail)
    end, { [5201] = "seasonal event" })
  end)

  it("an event quest does not hide a quest that is within reach", function()
    withRequired({ [5202] = 30 }, function()
      local item = questItem({ questItemQuestIDs = { 5201, 5202 }, openQuestIDs = { 5201, 5202 } })
      assert.is_nil((MakeSpace.Verdict.Evaluate(item, at(30))))
    end, { [5201] = "Darkmoon Faire" })
  end)

  it("when a far quest and an event quest both want it, the far quest is named", function()
    withRequired({ [5203] = 50 }, function()
      local item = questItem({ questItemQuestIDs = { 5201, 5203 }, openQuestIDs = { 5201, 5203 } })
      local _, reason = MakeSpace.Verdict.Evaluate(item, at(30))
      assert.are.equal("Bank it, quest needs level 50", reason)
    end, { [5201] = "Darkmoon Faire" })
  end)

  it("goes by the level to accept the quest, not the quest's own level", function()
    -- Like Vibrant Plumes: a level 60 quest that opens at level 30.
    withRequired({ [5201] = 30 }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(30))))
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(questItem(), at(19))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(20))))
    end)
  end)

  it("stops once the quest is within 10 levels of opening", function()
    withRequired(FAR, function()
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(questItem(), at(44))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(45))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(58))))
    end)
  end)

  it("stays silent for a quest with no known required level, or without the data at all", function()
    withRequired(FAR, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(
        questItem({ questItemQuestIDs = { 9999 }, openQuestIDs = { 9999 } }), at(30))))
    end)
    withRequired(nil, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem(), at(30))))
    end)
  end)

  it("stays silent when any open quest for the item can be taken soon", function()
    withRequired(FAR, function()
      local item = questItem({ questItemQuestIDs = { 5201, 5202 }, openQuestIDs = { 5201, 5202 } })
      assert.is_nil((MakeSpace.Verdict.Evaluate(item, at(30))))
    end)
  end)

  it("names the nearest quest when several are far off", function()
    withRequired({ [5201] = 55, [5203] = 48 }, function()
      local item = questItem({ questItemQuestIDs = { 5201, 5203 }, openQuestIDs = { 5201, 5203 } })
      local _, reason, _, _, _, heading = MakeSpace.Verdict.Evaluate(item, at(30))
      assert.are.equal("Bank it, quest needs level 48", reason)
      assert.are.equal("[60] Early Quest", heading.detail)
    end)
  end)

  it("stays silent for a quest in your log", function()
    withRequired(FAR, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem({ onOpenQuest = true }), at(30))))
    end)
  end)

  it("also covers an item that starts a far quest, until that quest is done", function()
    withRequired(FAR, function()
      local starter = { id = 9401, classID = 12, quality = 1, startsQuestID = 5201, startsQuestCompleted = false }
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(starter, at(30))))
      starter.startsQuestCompleted = true
      assert.is_truthy(select(5, MakeSpace.Verdict.Evaluate(starter, at(30))) ~= "distant_quest_item")
    end)
  end)

  it("a plain material counts too, unless a recipe uses it or it is gear", function()
    withRequired(FAR, function()
      local plume = questItem({ id = 5117, classID = 15 })
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(plume, at(30))))
      local saved = MakeSpace.Data.ReagentProfessions
      MakeSpace.Data.ReagentProfessions = { [5117] = { { "Tailoring", 1, 1, 100 } } }
      local used = MakeSpace.Verdict.Evaluate(plume, at(30))
      MakeSpace.Data.ReagentProfessions = saved
      assert.is_nil(used)
      assert.is_nil((MakeSpace.Verdict.Evaluate(questItem({ id = 5118, classID = 4, isEquippable = true }), at(30))))
    end)
  end)

  it("is not shown in the bank", function()
    local _, heading = MakeSpace.Verdict.Note("bank_quest", 55, "[60] Far Quest")
    local bank = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Bank it, quest needs level 55",
      rule = "distant_quest_item", heading = heading })
    assert.is_nil(bank.verdict)
  end)

  it("never mixes with the far-below hint", function()
    MakeSpace.Data.QuestInfo[5204] = { 5, "Elwynn Forest", "Wolf Problem" }
    withRequired(FAR, function()
      local low = questItem({ questItemQuestIDs = { 5204 }, openQuestIDs = { 5204 } })
      local _, _, _, _, rule = MakeSpace.Verdict.Evaluate(low, at(30))
      assert.are.equal("trivial_quest_item", rule)
    end)
  end)
end)

describe("Live prices from Auctionator", function()
  local function boe(overrides)
    local item = { id = 42001, classID = 4, subClassID = 2, quality = 2, itemLevel = 20,
      reqLevel = 18, sellPrice = 300, count = 1, isBound = false, liveAge = 0,
      equippedInSlots = { { quality = 2, itemLevel = 25 } } }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local state = { level = 20, professionNames = {}, professionsKnown = true }

  local function withSnapshot(prices, fn)
    local saved, missing = MakeSpace.Data.AuctionPriceCeiling, MakeSpace.Data.AuctionMarketMissing
    MakeSpace.Data.AuctionPriceCeiling = prices
    fn()
    MakeSpace.Data.AuctionPriceCeiling, MakeSpace.Data.AuctionMarketMissing = saved, missing
  end

  it("makes green gear green when the live price is close to the vendor price, and says about", function()
    withSnapshot({}, function()
      local verdict, reason, _, _, rule = MakeSpace.Verdict.Evaluate(boe({ livePrice = 400 }), state)
      assert.are.equal("green", verdict)
      assert.are.equal("Vendor 3s, auction about 4s", reason)
      assert.are.equal("sell_at_vendor", rule)
    end)
  end)

  it("covers gear the snapshot has no price for", function()
    withSnapshot({}, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe(), state)))
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350 }), state)))
    end)
  end)

  it("works without any snapshot for the player's market", function()
    withSnapshot(nil, function()
      MakeSpace.Data.AuctionMarketMissing = true
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe(), state)))
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350 }), state)))
    end)
  end)

  it("gives no green when the live price is well above the vendor price", function()
    withSnapshot({}, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 900 }), state)))
    end)
  end)

  it("judges blue gear on a live price, but never white or epic", function()
    withSnapshot({}, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ quality = 1, livePrice = 350 }), state)))
      local worn = { { quality = 4, itemLevel = 25 } }
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ quality = 3, livePrice = 350, equippedInSlots = worn }), state)))
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ quality = 4, livePrice = 350, equippedInSlots = worn }), state)))
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ quality = 3, equippedInSlots = worn }), state)))
    end)
  end)

  it("keeps the upgrade check and the Enchanting check for live prices", function()
    withSnapshot({}, function()
      local upgrade = boe({ quality = 3, livePrice = 350, equippedInSlots = { { quality = 2, itemLevel = 10 } } })
      assert.is_nil((MakeSpace.Verdict.Evaluate(upgrade, state)))
      local enchanter = { level = 20, professionNames = { Enchanting = true }, professionsKnown = true }
      local worn = { { quality = 4, itemLevel = 25 } }
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ quality = 3, livePrice = 350, equippedInSlots = worn }), enchanter)))
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350, quality = 2 }), { level = 20, professionNames = {}, professionsKnown = true })))
    end)
  end)

  it("never greens a soulbound or protected item from a live price", function()
    withSnapshot({}, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ isBound = true, livePrice = 350 }), state)))
    end)
  end)

  it("a versioned item may use a live price to go below the snapshot, but only to a floor of 60% of it", function()
    withSnapshot({}, function()
      local function versions(price) return { [42001] = { ["12744"] = price, ["12745"] = price, ["12746"] = price } } end
      -- snapshot 800: floor 480. Auctionator's 350 (the cheapest version) is lifted to 4s 80c, under the 5s 20c limit
      MakeSpace.Data.AuctionVariantCeiling = versions(800)
      local verdict, reason = MakeSpace.Verdict.Evaluate(boe({ bonusKey = "12744", livePrice = 350 }), state)
      assert.are.equal("green", verdict)
      assert.are.equal("Vendor 3s, auction up to 4s 80c", reason)
      -- snapshot 2000: floor 1200 is over the limit however low Auctionator says
      MakeSpace.Data.AuctionVariantCeiling = versions(2000)
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ bonusKey = "12744", livePrice = 100 }), state)))
      -- a live price above the floor counts as it is
      MakeSpace.Data.AuctionVariantCeiling = versions(900)
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ bonusKey = "12744", livePrice = 1500 }), state)))
      MakeSpace.Data.AuctionVariantCeiling = nil
    end)
  end)

  it("explains in /makespace why how a live price was used on a versioned item", function()
    withSnapshot({}, function()
      MakeSpace.Data.AuctionVariantCeiling = { [42001] = { ["12744"] = 900, ["12745"] = 900, ["12746"] = 900 } }
      local facts = table.concat(MakeSpace.Verdict.SellAtVendorFacts(boe({ bonusKey = "12744", livePrice = 350 }), state), "\n")
      assert.is_truthy(facts:find("cheapest version", 1, true))
      assert.is_truthy(facts:find("60%", 1, true))
      MakeSpace.Data.AuctionVariantCeiling = nil
    end)
  end)

  it("with no snapshot price a live price decides nothing for a versioned item", function()
    withSnapshot({}, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ bonusKey = "12744", livePrice = 350 }), state)))
    end)
  end)

  it("ignores a live price far below the snapshot, since it may be a lowball", function()
    withSnapshot({ [42001] = 2000 }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 350 }), state)))
      local facts = table.concat(MakeSpace.Verdict.SellAtVendorFacts(boe({ livePrice = 350 }), state), "\n")
      assert.is_truthy(facts:find("lowball", 1, true))
    end)
  end)

  it("needs a price seen today or yesterday when the snapshot has nothing to compare", function()
    withSnapshot({}, function()
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350, liveAge = 1 }), state)))
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 350, liveAge = 2 }), state)))
      local noAge = boe({ livePrice = 350 })
      noAge.liveAge = nil
      assert.is_nil((MakeSpace.Verdict.Evaluate(noAge, state)))
      local facts = table.concat(MakeSpace.Verdict.SellAtVendorFacts(boe({ livePrice = 350, liveAge = 3 }), state), "\n")
      assert.is_truthy(facts:find("over a day old", 1, true))
    end)
  end)

  it("accepts a price up to 3 days old when the snapshot is in the same range", function()
    withSnapshot({ [42001] = 400 }, function()
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350, liveAge = 3 }), state)))
    end)
  end)

  it("trusts a live price far below the snapshot when the recent days agree on it", function()
    withSnapshot({ [42001] = 2000 }, function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 350 }), state)))
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe({ livePrice = 350, liveSteady = true }), state)))
      local facts = table.concat(MakeSpace.Verdict.SellAtVendorFacts(boe({ livePrice = 350, liveSteady = true }), state), "\n")
      assert.is_truthy(facts:find("steady over the last days", 1, true))
    end)
  end)

  it("falls back to the snapshot rules when the live price is ignored", function()
    withSnapshot({ [42001] = 900 }, function()
      -- 250 is below half of 900, so the snapshot (900, too much) decides: no green
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 250 }), state)))
    end)
    withSnapshot({ [42001] = 400 }, function()
      -- 250 is not below half of 400, so it is trusted
      local _, reason = MakeSpace.Verdict.Evaluate(boe({ livePrice = 250 }), state)
      assert.are.equal("Vendor 3s, auction about 2s 50c", reason)
    end)
  end)

  it("a live price above the snapshot can drop a green the snapshot allowed", function()
    withSnapshot({ [42001] = 400 }, function()
      assert.are.equal("green", (MakeSpace.Verdict.Evaluate(boe(), state)))
      assert.is_nil((MakeSpace.Verdict.Evaluate(boe({ livePrice = 1500 }), state)))
    end)
  end)

  it("tells the live price from the snapshot in the tooltip note", function()
    local manual = { id = 16645, classID = 12, quality = 1, count = 1, sellPrice = 5, isBound = false,
      bindType = 0, questItemQuestIDs = { 7 }, allQuestObjectivesCompleted = true }
    withSnapshot({ [16645] = 800 }, function()
      local _, _, _, _, _, _, snapshotNote = MakeSpace.Verdict.Evaluate(manual, state)
      assert.are.equal("Vendor 5c, auction up to 8s", snapshotNote)
      manual.livePrice = 800
      local _, _, _, _, _, _, liveNote = MakeSpace.Verdict.Evaluate(manual, state)
      assert.are.equal("Vendor 5c, auction about 8s", liveNote)
    end)
  end)
end)


describe("Weak bandages and outleveled scrolls", function()
  local function bandage(heal, overrides)
    local item = { id = 6450, classID = 0, subClassID = 7, quality = 1, healAmount = heal }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function at(level, health, names)
    return { level = level, maxHealth = health, professionNames = names or {}, professionsKnown = true }
  end

  it("a bandage under 15% of your health is yellow, with the numbers", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(bandage(400), at(60, 4500))
    assert.are.equal("yellow", verdict)
    assert.are.equal("Weak bandage", reason)
  end)

  it("a bandage that heals enough is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(bandage(2000), at(60, 4500))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(bandage(675), at(60, 4500))))
  end)

  it("flags just under the line", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(bandage(674), at(60, 4500))))
  end)

  it("without health or heal data a bandage with no level gets nothing", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(bandage(nil), at(60, 4500))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(bandage(400), at(60, nil))))
  end)

  it("a bandage with no heal data still follows its required level", function()
    local item = bandage(nil, { reqLevel = 5 })
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(item, at(40, 3000))))
  end)

  local function scroll(id, overrides)
    local item = { id = id, classID = 0, subClassID = 4, quality = 1 }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end

  it("a stat scroll made for a much lower level is yellow", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(scroll(2289, { reqLevel = 25 }), at(45, 3000))
    assert.are.equal("yellow", verdict)
    assert.are.equal("Low-level scroll (level 25, you are 45)", reason)
  end)

  it("not yet when the gap is under 20 levels", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(scroll(2289, { reqLevel = 25 }), at(44, 3000))))
  end)

  it("a scroll without a required level uses its item level", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(scroll(3013, { itemLevel = 10 }), at(40, 3000))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(scroll(3013, { itemLevel = 10 }), at(29, 3000))))
  end)

  it("an Enchanter keeps scrolls that are Enchanting reagents", function()
    local state = at(60, 4500, { Enchanting = true })
    assert.is_nil((MakeSpace.Verdict.Evaluate(scroll(2289, { reqLevel = 25 }), state)))
  end)

  it("scrolls that are not stat scrolls are left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(scroll(211780, { reqLevel = 1 }), at(60, 4500))))
  end)
end)


describe("Outleveled consumables say when the auction pays well", function()
  local state = { level = 40, professionNames = {}, professionsKnown = true }
  local function food()
    return { id = 42001, classID = 0, subClassID = 5, quality = 1, reqLevel = 5, sellPrice = 10,
             count = 20, restoresHealthOrMana = true }
  end

  it("carries a price note when the auction is worth it", function()
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = { [42001] = 900 }
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(food(), state)
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.are.equal("yellow", verdict)
    assert.is_truthy(note and note:find("auction", 1, true))
  end)

  it("has no note when the auction pays next to nothing", function()
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = { [42001] = 12 }
    local verdict, _, _, _, _, _, note = MakeSpace.Verdict.Evaluate(food(), state)
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.are.equal("yellow", verdict)
    assert.is_nil(note)
  end)
end)


describe("Elixirs and flasks made for a much lower level", function()
  local state = { level = 50, professionNames = {}, professionsKnown = true }
  local function consumable(subClassID, reqLevel)
    return { id = 43001, classID = 0, subClassID = subClassID, quality = 1, reqLevel = reqLevel,
             givesStats = true }
  end

  it("an elixir 20 levels below you is yellow", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(consumable(2, 10), state)
    assert.are.equal("yellow", verdict)
    assert.are.equal("Low-level elixir (level 10, you are 50)", reason)
  end)

  it("a flask is judged the same way", function()
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(consumable(3, 20), state)))
  end)

  it("one closer to your level is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable(2, 35), state)))
  end)

  it("an elixir with no required level is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(consumable(2, 0), state)))
  end)

  it("water breathing, speed and other utility effects work at any level", function()
    local utility = consumable(2, 8)
    utility.givesStats = false
    assert.is_nil((MakeSpace.Verdict.Evaluate(utility, state)))
  end)

  it("an elixir whose tooltip was not read is left alone", function()
    local unread = consumable(3, 10)
    unread.givesStats = nil
    assert.is_nil((MakeSpace.Verdict.Evaluate(unread, state)))
  end)

  it("an effect with its own level limit gets no level verdict", function()
    for _, subClassID in ipairs({ 1, 2, 3, 5 }) do
      local limited = consumable(subClassID, 5)
      limited.levelLimited = true
      limited.restoresHealthOrMana = true
      assert.is_nil((MakeSpace.Verdict.Evaluate(limited, state)))
    end
  end)
end)


describe("Weapons and ammo your class can never use", function()
  local function weapon(subClassID, overrides)
    local item = { id = 44001, classID = 2, subClassID = subClassID, quality = 1, isEquippable = true }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local function as(playerClass, level)
    return { playerClass = playerClass, level = level or 30, professionNames = {}, professionsKnown = true }
  end

  it("a white axe is green for a priest", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(weapon(0), as("PRIEST"))
    assert.are.equal("green", verdict)
    assert.are.equal("Priests can't use axes", reason)
  end)

  it("a rogue uses axes in Forever, so the same axe is left alone", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(0), as("ROGUE"))))
  end)

  it("a mage can use daggers and swords but not maces", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(15), as("MAGE"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(7), as("MAGE"))))
    assert.are.equal("Mages can't use maces", select(2, MakeSpace.Verdict.Evaluate(weapon(4), as("MAGE"))))
  end)

  it("two-handed types are judged on their own skill", function()
    assert.are.equal("Rogues can't use two-handed swords",
      select(2, MakeSpace.Verdict.Evaluate(weapon(8), as("ROGUE"))))
  end)

  it("greens and better are never called unusable", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(0, { quality = 2 }), as("PRIEST"))))
  end)

  it("an unknown weapon type or class gets no verdict", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(14), as("PRIEST"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(0), as("MONK"))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(weapon(0), { level = 30, professionNames = {}, professionsKnown = true })))
  end)

  local function ammo(subClassID)
    return { id = 44002, classID = 6, subClassID = subClassID, quality = 1 }
  end

  it("arrows are green for a class with no bow or crossbow", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(ammo(2), as("MAGE"))
    assert.are.equal("green", verdict)
    assert.are.equal("Mages can't use arrows", reason)
    assert.are.equal("Paladins can't use bullets", select(2, MakeSpace.Verdict.Evaluate(ammo(3), as("PALADIN"))))
  end)

  it("hunters, warriors and rogues keep their ammo", function()
    for _, class in ipairs({ "HUNTER", "WARRIOR", "ROGUE" }) do
      assert.is_nil((MakeSpace.Verdict.Evaluate(ammo(2), as(class))))
      assert.is_nil((MakeSpace.Verdict.Evaluate(ammo(3), as(class))))
    end
  end)
end)


describe("Quests do not hide a weak bandage", function()
  local function woolBandage(overrides)
    local item = { id = 3530, classID = 0, subClassID = 7, quality = 1, healAmount = 161,
                   questItemQuestIDs = { 8604, 8605 }, openQuestIDs = { 8604, 8605 }, onOpenQuest = false }
    for key, value in pairs(overrides or {}) do item[key] = value end
    return item
  end
  local state = { level = 33, maxHealth = 1500, faction = "Horde", professionNames = {}, professionsKnown = true }

  it("a quest you have not taken (war effort turn-ins) does not stop the hint", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(woolBandage(), state)
    assert.are.equal("yellow", verdict)
    assert.are.equal("Weak bandage", reason)
  end)

  it("a quest you are on still holds it back", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(woolBandage({ onOpenQuest = true }), state)))
  end)

  it("an item that starts a quest is never hinted", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(woolBandage({ startsQuestID = 123 }), state)))
  end)
end)


describe("Banking a reagent when the next use is far ahead", function()
  -- The chain data is loaded for these tests only, so the others keep judging
  -- on direct uses alone.
  local function withChains(fn)
    local saved = MakeSpace.Data.ReagentChains
    dofile("data/reagent_chains.lua")
    local ok, err = pcall(fn)
    MakeSpace.Data.ReagentChains = saved
    if not ok then error(err, 0) end
  end

  local function linenCloth()
    return { id = 2589, classID = 7, subClassID = 5, quality = 1 }
  end
  local function crafter(firstAid, blacksmithing)
    return {
      level = 40, professionsKnown = true,
      professionNames = { ["First Aid"] = true, Blacksmithing = true },
      professionRanks = { ["First Aid"] = firstAid, Blacksmithing = blacksmithing },
      professionIdle = { ["First Aid"] = true, Blacksmithing = true },
    }
  end

  it("is yellow to bank when every use is behind you except one far ahead", function()
    withChains(function()
      local verdict, reason = MakeSpace.Verdict.Evaluate(linenCloth(), crafter(150, 160))
      assert.are.equal("yellow", verdict)
      assert.are.equal("Bank it, used from Blacksmithing 200", reason)
    end)
  end)

  it("stays silent once that use is close", function()
    withChains(function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(linenCloth(), crafter(150, 190))))
    end)
  end)

  it("stays silent while a use is still in reach", function()
    withChains(function()
      assert.is_nil((MakeSpace.Verdict.Evaluate(linenCloth(), crafter(40, 160))))
    end)
  end)
end)

describe("Locked items", function()
  dofile("data/locked_items.lua")
  local lockbox = { id = 4632, classID = 0, hasLoot = true, isLocked = true, quality = 1, count = 1 }
  local function stateOf(canPick)
    return { level = 30, professionsKnown = true, professionNames = {}, professionRanks = {}, canPickLocks = canPick }
  end

  it("a lockbox says open it to someone who can pick it", function()
    local verdict, reason = MakeSpace.Verdict.Evaluate(lockbox, stateOf(true))
    assert.are.equal("yellow", verdict)
    assert.are.equal("Open it, the contents may stack", reason)
  end)

  it("says nothing to a class that cannot pick it", function()
    assert.is_nil((MakeSpace.Verdict.Evaluate(lockbox, stateOf(false))))
    assert.is_nil((MakeSpace.Verdict.Evaluate(lockbox, { level = 30, professionsKnown = true, professionNames = {} })))
  end)

  it("a clam, which nobody needs a key for, still says open it", function()
    local clam = { id = 5523, classID = 0, hasLoot = true, quality = 1, count = 1 }
    assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(clam, stateOf(false))))
  end)

  it("the data lists the known lockboxes", function()
    assert.is_truthy(MakeSpace.Data.LockedItems[4632])
    assert.is_truthy(MakeSpace.Data.LockedItems[16883])
  end)
end)

describe("Recipes for a profession you do not have", function()
  local state = { level = 40, playerClass = "WARRIOR", professionNames = { Mining = true, Blacksmithing = true },
                  professionRanks = { Mining = 100, Blacksmithing = 100 }, professionsKnown = true }
  local function formula(overrides)
    local good = { id = 9501, classID = 9, subClassID = 8, quality = 2, count = 1, sellPrice = 30, isBound = false }
    for key, value in pairs(overrides or {}) do good[key] = value end
    return good
  end
  local function withPrices(prices, fn)
    local saved = MakeSpace.Data.AuctionPriceCeiling
    MakeSpace.Data.AuctionPriceCeiling = prices
    local ok, err = pcall(fn)
    MakeSpace.Data.AuctionPriceCeiling = saved
    assert.is_truthy(ok, err)
  end

  it("suggests the auction house with the price when it pays", function()
    withPrices({ [9501] = 5000 }, function()
      local verdict, reason, _, _, _, heading, note = MakeSpace.Verdict.Evaluate(formula(), state)
      assert.are.equal("yellow", verdict)
      assert.is_truthy(reason:find("May sell at the auction house", 1, true))
      assert.is_nil(heading.detail)
      assert.are.equal("Vendor 30c, auction up to 50s", note)
    end)
  end)

  it("stops suggesting it when the price says it is not worth the trip", function()
    withPrices({ [9501] = 600 }, function()
      -- 6s at auction for a 30c recipe is worth a trip, so the hint stays
      local _, reason = MakeSpace.Verdict.Evaluate(formula({ sellPrice = 900 }), state)
      assert.are.equal("You don't have this profession", reason)
    end)
  end)

  it("keeps the hint as it is without price data", function()
    withPrices(nil, function()
      local verdict, reason, _, _, _, heading = MakeSpace.Verdict.Evaluate(formula(), state)
      assert.are.equal("yellow", verdict)
      assert.is_truthy(reason:find("May sell at the auction house", 1, true))
      assert.is_nil(heading.detail)
    end)
  end)

  it("is green when it is listed, cheap, and worth next to nothing", function()
    withPrices({ [9501] = 20 }, function()
      local verdict, reason = MakeSpace.Verdict.Evaluate(formula({ sellPrice = 10 }), state)
      assert.are.equal("green", verdict)
      assert.are.equal("Worth very little", reason)
    end)
  end)

  it("a bank-it recipe is never turned green by a low price", function()
    withPrices({ [9501] = 20 }, function()
      local mining = { level = 40, playerClass = "WARRIOR", professionNames = { Enchanting = true, Mining = true },
                       professionRanks = { Enchanting = 10, Mining = 100 }, professionsKnown = true }
      local verdict = MakeSpace.Verdict.Evaluate(formula({ requiredSkill = 200, sellPrice = 10 }), mining)
      assert.are.equal("yellow", verdict)
    end)
  end)
end)

describe("Banking a reagent that costs next to nothing to buy again", function()
  local function withChains(fn)
    local saved = { MakeSpace.Data.ReagentProfessions, MakeSpace.Data.ReagentChains, MakeSpace.Data.AuctionPriceCeiling }
    MakeSpace.Data.ReagentProfessions = { [8101] = { { "Blacksmithing", 1, 200, 250, 280 } } }
    MakeSpace.Data.ReagentChains = nil
    local ok, err = pcall(function() fn() end)
    MakeSpace.Data.ReagentProfessions, MakeSpace.Data.ReagentChains, MakeSpace.Data.AuctionPriceCeiling = saved[1], saved[2], saved[3]
    assert.is_truthy(ok, err)
  end
  local state = { level = 40, playerClass = "WARRIOR", professionNames = { Blacksmithing = true },
                  professionRanks = { Blacksmithing = 60 }, professionsKnown = true,
                  professionIdle = { Blacksmithing = true } }
  local function stack(overrides)
    local good = { id = 8101, classID = 7, subClassID = 7, quality = 1, sellPrice = 4, maxStack = 20, count = 10 }
    for key, value in pairs(overrides or {}) do good[key] = value end
    return good
  end

  it("says nothing for a stack worth a few copper", function()
    withChains(function()
      MakeSpace.Data.AuctionPriceCeiling = { [8101] = 6 }
      assert.is_nil((MakeSpace.Verdict.Evaluate(stack(), state)))
    end)
  end)

  it("still says bank it for a stack that is worth the slot", function()
    withChains(function()
      MakeSpace.Data.AuctionPriceCeiling = { [8101] = 90 }
      local verdict, reason = MakeSpace.Verdict.Evaluate(stack({ count = 20 }), state)
      assert.are.equal("yellow", verdict)
      assert.is_truthy(reason:find("Bank it", 1, true))
    end)
  end)

  it("still says bank it with no price data: an unlisted item may be rare", function()
    withChains(function()
      MakeSpace.Data.AuctionPriceCeiling = nil
      assert.are.equal("yellow", (MakeSpace.Verdict.Evaluate(stack(), state)))
    end)
  end)
end)

describe("The bank and a green that says worth very little", function()
  it("drops it for a recipe or an outleveled reagent, like the other vendor hints", function()
    for _, rule in ipairs({ "recipe", "outleveled_reagent", "other_profession_reagent" }) do
      local shown = MakeSpace.Verdict.ForBank({ verdict = "green", reason = "Worth very little", rule = rule })
      assert.is_nil(shown.verdict)
    end
  end)

  it("keeps the yellow outleveled hint in the bank", function()
    local shown = MakeSpace.Verdict.ForBank({ verdict = "yellow", reason = "Outleveled", rule = "outleveled_reagent",
                                            heading = { title = "Outleveled reagent" } })
    assert.are.equal("yellow", shown.verdict)
  end)
end)

describe("Verdict.Judge", function()
  it("gives the same answer as Evaluate, by name", function()
    local item = { id = 1, name = "Rag", quality = 0, sellPrice = 5, classID = 15, subclassID = 0 }
    local state = { level = 20, class = "WARRIOR", professions = {} }
    local verdict, reason = MakeSpace.Verdict.Evaluate(item, state)
    local judged = MakeSpace.Verdict.Judge(item, state)
    assert.are.equal(verdict, judged.verdict)
    assert.are.equal(reason, judged.reason)
    assert.are.equal(MakeSpace.Verdict.Sellable(item, verdict), judged.sellable)
  end)
end)
