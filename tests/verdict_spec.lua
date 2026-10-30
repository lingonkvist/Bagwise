-- Bagwise: verdict unit tests
-- Run with: busted tests/verdict_spec.lua (from the Bagwise/ root)

-- Stub the global namespace before loading the module
_G.Bagwise = nil

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
