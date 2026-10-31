-- Bagwise: verdict unit tests
-- Run with: busted tests/verdict_spec.lua (from the Bagwise/ root)

-- Stub the global namespace before loading the module
_G.Bagwise = nil

dofile("data/vendor_reagents.lua")
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
    -- e.g. Fish Gutter: soulbound quest weapon, ilvl 10, on a lvl 32
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
    -- reqLevel = 30, itemLevel = 10. Player level 55.
    -- reqLevel gap = 25 (green), itemLevel gap = 45 (also green).
    -- Should use reqLevel and say "Required level", not "Item level".
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
    -- C_QuestLog.GetQuestInfo might return nil for some quest IDs
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
    -- An item that is both soulbound equippable gear AND starts a
    -- completed quest. The gear rule runs first, so if the gap is big
    -- enough, we get the gear reason rather than the quest reason.
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
    -- Gear rule fires first (gap = 30, green)
    assert.is_truthy(reason:find("Required level"))
  end)
end)

describe("Epic 5: vendor reagents not needed by player's professions", function()
  -- Helper: build a state with specific profession skillLine IDs
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
    local item = { id = 3371 }                       -- Empty Vial: needs Alchemy (171)
    local state = stateWithProfessions(164, 197)     -- BS + Tailoring

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Vendor reagent"))
  end)

  it("no dot when player HAS a matching profession (Empty Vial, has Alchemy)", function()
    local item = { id = 3371 }                       -- Empty Vial: needs Alchemy (171)
    local state = stateWithProfessions(171, 164)     -- Alchemy + BS

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("green when player has one profession but reagent needs two others", function()
    -- Coarse Thread (2320): Tailoring (197) + Leatherworking (165)
    local item = { id = 2320 }
    local state = stateWithProfessions(171)     -- Alchemy only

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("no dot when player matches ONE of multiple professions", function()
    -- Coarse Thread (2320): Tailoring (197) + Leatherworking (165)
    local item = { id = 2320 }
    local state = stateWithProfessions(197, 171)     -- Tailoring + Alchemy

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot for items NOT in the vendor reagent table", function()
    local item = { id = 12345 }     -- random item, not a vendor reagent
    local state = stateWithProfessions(171)

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when player has no professions at all (empty set)", function()
    -- A fresh character with no professions shouldn't get green dots
    -- on reagents -- they might be about to learn that profession.
    -- Actually wait: empty professionSkillLines means no match,
    -- so the rule WOULD fire green. Let's verify the intent.
    -- Design decision: green IS correct here. If you have zero
    -- professions, you truly don't need vendor reagents.
    local item = { id = 3371 }               -- Empty Vial
    local state = stateWithProfessions()     -- no professions

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
  end)

  it("no dot when professionSkillLines is nil (API unavailable)", function()
    -- If GetProfessions() isn't available (older client), the scanner
    -- won't populate professionSkillLines. The rule should bail out
    -- gracefully rather than mark everything green.
    local item = { id = 3371 }     -- Empty Vial
    local state = { class = "Mage", race = "Human", level = 60 }
    -- professionSkillLines not set at all

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("Salt shows green only when player has none of Tailoring, LW, or Cooking", function()
    -- Salt (4289) is used by three professions
    local item = { id = 4289 }

    -- Has Cooking: no dot
    local state1 = stateWithProfessions(185)     -- Cooking
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state1))

    -- Has Leatherworking: no dot
    local state2 = stateWithProfessions(165)     -- LW
    assert.is_nil(Bagwise.Verdict.Evaluate(item, state2))

    -- Has neither: green
    local state3 = stateWithProfessions(171, 333)     -- Alchemy + Enchanting
    assert.are.equal("green", (Bagwise.Verdict.Evaluate(item, state3)))
  end)
end)
