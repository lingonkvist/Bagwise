-- Bagwise: verdict unit tests
-- Run with: busted tests/verdict_spec.lua (from the Bagwise/ root)

-- Stub the global namespace before loading the module
_G.Bagwise = nil

dofile("src/verdict.lua")

describe("Stories 1.1 + 1.2: soulbound gear not usable by character", function()
  it("green when soulbound, equippable, and not usable", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      isUsable = false,
    }
    local state = { class = "Mage", race = "Human", level = 40 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Not usable by your character", reason)
  end)

  it("no dot when soulbound and equippable but IS usable", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      isUsable = true,
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when not usable but NOT soulbound", function()
    local item = {
      id = 12345,
      isBound = false,
      isEquippable = true,
      isUsable = false,
    }
    local state = { class = "Mage", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when not usable but not equippable", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = false,
      isUsable = false,
    }
    local state = { class = "Mage", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when isUsable is nil (data not loaded yet)", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      isUsable = nil,
    }
    local state = { class = "Mage", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot for an item with no signals at all", function()
    local item = { id = 99999 }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)
end)

describe("Story 1.3: soulbound gear far below my level", function()
  it("green when soulbound and 20+ levels below", function()
    local item = {
      id = 33001,
      isBound = true,
      isEquippable = true,
      isUsable = true,
      reqLevel = 20,
    }
    local state = { class = "Warrior", race = "Human", level = 45 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("20"))
    assert.is_truthy(reason:find("45"))
  end)

  it("yellow when soulbound and 10-19 levels below", function()
    local item = {
      id = 33002,
      isBound = true,
      isEquippable = true,
      isUsable = true,
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
      isUsable = true,
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
      isUsable = true,
      reqLevel = 10,
    }
    local state = { class = "Warrior", race = "Human", level = 50 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when soulbound but item has no required level", function()
    local item = {
      id = 33005,
      isBound = true,
      isEquippable = true,
      isUsable = true,
      reqLevel = nil,
    }
    local state = { class = "Warrior", race = "Human", level = 60 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("green at exactly 20 levels below", function()
    local item = {
      id = 33006,
      isBound = true,
      isEquippable = true,
      isUsable = true,
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
      isUsable = true,
      reqLevel = 30,
    }
    local state = { class = "Warrior", race = "Human", level = 40 }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("yellow", verdict)
  end)

  it("unusable rule fires before level rule", function()
    local item = {
      id = 33008,
      isBound = true,
      isEquippable = true,
      isUsable = false,
      reqLevel = 10,
    }
    local state = { class = "Mage", race = "Human", level = 60 }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.are.equal("Not usable by your character", reason)
  end)
end)
