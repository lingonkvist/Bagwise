-- Bagwise: verdict unit tests
-- Run with: lua5.1 tests/verdict_spec.lua (from the Bagwise/ root)

-- Stub the global namespace before loading the module
_G.Bagwise = nil

dofile("data/vendor_reagents.lua")
dofile("data/class_reagents.lua")
dofile("src/verdict.lua")

-- Stories 1.1 + 1.2 (class restriction check) are disabled:
-- IsUsableItem() checks right-click usability, not whether your class
-- can equip gear. Tests will be added back when we implement proper
-- class restriction detection (tooltip scanning or proficiency table).

describe("Story 1.3: soulbound gear far below my level (reqLevel)", function()
  it("green when soulbound and 20+ levels below", function()
    local item = {
      id = 33001,
      isBound = true,
      isEquippable = true,
      reqLevel = 20,
    }
    local state = { class = "Warrior", race = "Human", level = 45 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Required level"))
    assert.is_truthy(reason:find("20"))
    assert.is_truthy(reason:find("45"))
  end)

  it("yellow when soulbound and 10-19 levels below", function()
    local item = {
      id = 33002,
      isBound = true,
      isEquippable = true,
      reqLevel = 30,
    }
    local state = { class = "Warrior", race = "Human", level = 42 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
    assert.is_truthy(reason:find("30"))
  end)

  it("no dot when soulbound but only 9 levels below", function()
    local item = {
      id = 33003,
      isBound = true,
      isEquippable = true,
      reqLevel = 31,
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when NOT soulbound even if 20+ levels below", function()
    local item = {
      id = 33004,
      isBound = false,
      isEquippable = true,
      reqLevel = 10,
    }
    local state = { class = "Warrior", race = "Human", level = 50 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("green at exactly 20 levels below", function()
    local item = {
      id = 33006,
      isBound = true,
      isEquippable = true,
      reqLevel = 20,
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("yellow at exactly 10 levels below", function()
    local item = {
      id = 33007,
      isBound = true,
      isEquippable = true,
      reqLevel = 30,
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
  end)

  it("no dot for an item with no signals at all", function()
    local item = { id = 99999 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
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
    assert.is_truthy(reason:find("Item level"))
    assert.is_truthy(reason:find("10"))
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
    assert.is_truthy(reason:find("Item level"))
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

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
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

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
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

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
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
    assert.is_truthy(reason:find("Required level"))
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

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("The Lost Idol"))
    assert.is_truthy(reason:find("completed"))
  end)

  it("no dot when item starts a quest that is NOT completed", function()
    local item = {
      id = 55002,
      startsQuestID = 1234,
      startsQuestCompleted = false,
      startsQuestName = "The Lost Idol",
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when item does not start any quest", function()
    local item = {
      id = 55003,
      startsQuestID = nil,
      startsQuestCompleted = false,
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("green with fallback text when quest name is nil", function()
    local item = {
      id = 55004,
      startsQuestID = 9999,
      startsQuestCompleted = true,
      startsQuestName = nil,
    }
    local state = { class = "Warrior", race = "Human", level = 30 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("quest 9999"))
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
    assert.is_truthy(reason:find("Required level"))
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

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("green when player has one profession but reagent needs two others", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(171)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("no dot when player matches ONE of multiple professions", function()
    local item = { id = 2320 }
    local state = stateWithProfessions(197, 171)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot for items NOT in the vendor reagent table", function()
    local item = { id = 12345 }
    local state = stateWithProfessions(171)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when player has no professions at all (empty set)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions()

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("no dot when professionSkillLines is nil (API unavailable)", function()
    local item = { id = 3371 }
    local state = { class = "Mage", race = "Human", level = 60 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Salt shows green only when player has none of Tailoring, LW, or Cooking", function()
    local item = { id = 4289 }

    local state1 = stateWithProfessions(185)
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state1))

    local state2 = stateWithProfessions(165)
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state2))

    local state3 = stateWithProfessions(171, 333)
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state3)))
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
    local item = { id = 3371 }
    local state = stateWithProfessions("ROGUE", 164, 197)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Rogue without Alchemy gets nil on Leaded Vial", function()
    local item = { id = 3372 }
    local state = stateWithProfessions("ROGUE", 164, 197)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Rogue without Alchemy gets nil on Crystal Vial", function()
    local item = { id = 8925 }
    local state = stateWithProfessions("ROGUE", 164, 197)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Mage without Alchemy still gets green on Empty Vial", function()
    local item = { id = 3371 }
    local state = stateWithProfessions("MAGE", 164, 197)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("Rogue WITH Alchemy gets nil on Empty Vial (has the profession)", function()
    local item = { id = 3371 }
    local state = stateWithProfessions("ROGUE", 171, 165)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Imbued Vial has no excludeClasses, so Rogue without Alchemy gets green", function()
    local item = { id = 18256 }
    local state = stateWithProfessions("ROGUE", 164, 197)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)
end)

describe("Class reagent verdict", function()
  -- World-drop reagents: yellow when wrong class

  it("returns yellow for Light Feather on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 },
      { playerClass = "WARRIOR" }
    )
    assert.are.equal("yellow", verdict)
    assert.are.equal("Light Feather (Mage/Priest only)", reason)
  end)

  it("returns nil for Light Feather on a mage", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 },
      { playerClass = "MAGE" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns nil for Light Feather on a priest", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 },
      { playerClass = "PRIEST" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns yellow for Shiny Fish Scales on a paladin", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17057 },
      { playerClass = "PALADIN" }
    )
    assert.are.equal("yellow", verdict)
    assert.are.equal("Shiny Fish Scales (Shaman only)", reason)
  end)

  it("returns nil for Shiny Fish Scales on a shaman", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17057 },
      { playerClass = "SHAMAN" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  -- Vendor-sold reagents: green when wrong class

  it("returns green for Arcane Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17020 },
      { playerClass = "WARRIOR" }
    )
    assert.are.equal("green", verdict)
    assert.are.equal("Arcane Powder (Mage only)", reason)
  end)

  it("returns nil for Arcane Powder on a mage", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17020 },
      { playerClass = "MAGE" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns green for Ankh on a druid", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17030 },
      { playerClass = "DRUID" }
    )
    assert.are.equal("green", verdict)
    assert.are.equal("Ankh (Shaman only)", reason)
  end)

  it("returns nil for Ankh on a shaman", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17030 },
      { playerClass = "SHAMAN" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns green for Maple Seed on a hunter", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17034 },
      { playerClass = "HUNTER" }
    )
    assert.are.equal("green", verdict)
    assert.are.equal("Maple Seed (Druid only)", reason)
  end)

  it("returns nil for Maple Seed on a druid", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17034 },
      { playerClass = "DRUID" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns green for Symbol of Kings on a mage", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 21177 },
      { playerClass = "MAGE" }
    )
    assert.are.equal("green", verdict)
    assert.are.equal("Symbol of Kings (Paladin only)", reason)
  end)

  it("returns green for Flash Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 5140 },
      { playerClass = "WARRIOR" }
    )
    assert.are.equal("green", verdict)
    assert.are.equal("Flash Powder (Rogue only)", reason)
  end)

  it("returns yellow for Blinding Powder on a warrior", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 5530 },
      { playerClass = "WARRIOR" }
    )
    assert.are.equal("yellow", verdict)
    assert.are.equal("Blinding Powder (Rogue only)", reason)
  end)

  -- Edge cases

  it("returns nil for a non-reagent item regardless of class", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 99999 },
      { playerClass = "WARRIOR" }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns nil when playerClass is missing from state", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 },
      {}
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)

  it("returns nil when playerClass is nil", function()
    local verdict, reason = Bagwise.Verdict.Evaluate(
      { id = 17056 },
      { playerClass = nil }
    )
    assert.is_nil(verdict)
    assert.is_nil(reason)
  end)
end)
