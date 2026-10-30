-- Bagwise: verdict unit tests
-- Run with: busted tests/verdict_spec.lua (from the Bagwise/ root)

-- Stub the global namespace before loading the module
_G.Bagwise = nil

dofile("src/verdict.lua")

describe("Story 1.1: soulbound gear my class cannot use", function()
  it("green when soulbound and class-restricted to another class", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      classRestriction = { "Paladin", "Warrior" },
    }
    local state = { class = "Mage" }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Mage"))
  end)

  it("no dot when soulbound but the player's class IS in the list", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      classRestriction = { "Paladin", "Warrior" },
    }
    local state = { class = "Warrior" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when class-restricted but NOT soulbound", function()
    local item = {
      id = 12345,
      isBound = false,
      isEquippable = true,
      classRestriction = { "Paladin" },
    }
    local state = { class = "Mage" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when soulbound but no class restriction", function()
    local item = {
      id = 12345,
      isBound = true,
      isEquippable = true,
      classRestriction = nil,
    }
    local state = { class = "Mage" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when item is not equippable", function()
    local item = {
      id = 99999,
      isBound = true,
      isEquippable = false,
      classRestriction = { "Paladin" },
    }
    local state = { class = "Mage" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot for an item with no signals at all", function()
    local item = { id = 99999 }
    local state = { class = "Warrior" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)
end)

describe("Story 1.2: soulbound gear restricted to another race", function()
  it("green when soulbound and race-restricted to another race", function()
    local item = {
      id = 22345,
      isBound = true,
      isEquippable = true,
      raceRestriction = { "Dwarf", "Gnome" },
    }
    local state = { class = "Warrior", race = "Orc" }

    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)

    assert.are.equal("green", verdict)
    assert.is_truthy(reason:find("Dwarf"))
  end)

  it("no dot when soulbound but the player's race IS in the list", function()
    local item = {
      id = 22345,
      isBound = true,
      isEquippable = true,
      raceRestriction = { "Dwarf", "Gnome" },
    }
    local state = { class = "Warrior", race = "Dwarf" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when race-restricted but NOT soulbound", function()
    local item = {
      id = 22345,
      isBound = false,
      isEquippable = true,
      raceRestriction = { "Dwarf" },
    }
    local state = { class = "Warrior", race = "Orc" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)

  it("no dot when soulbound but no race restriction", function()
    local item = {
      id = 22345,
      isBound = true,
      isEquippable = true,
      raceRestriction = nil,
    }
    local state = { class = "Warrior", race = "Orc" }

    local verdict = Bagwise.Verdict.Evaluate(item, state)

    assert.is_nil(verdict)
  end)
end)
