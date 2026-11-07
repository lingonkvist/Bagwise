-- Bagwise: make room for loot unit tests

dofile("src/bags.lua")
dofile("src/verdict.lua")
dofile("src/makeroom.lua")

local function junk(key, bag, slot, value)
  return { key = key, bag = bag, slot = slot, value = value }
end

describe("MakeRoom.Plan", function()
  it("does nothing when everything fits", function()
    local plan = Bagwise.MakeRoom.Plan({ { slot = 1, value = 10 } }, {}, 2)
    assert.are.equal(false, plan.active)
    assert.are.equal(0, #plan.deletes)
  end)

  it("takes loot that beats the cheapest junk and deletes that junk", function()
    local plan = Bagwise.MakeRoom.Plan(
      { { slot = 1, value = 500 } },
      { junk("0:3", 0, 3, 40), junk("0:1", 0, 1, 10) },
      0)
    assert.are.equal(true, plan.active)
    assert.is_truthy(plan.take[1])
    assert.are.equal("0:1", plan.deletes[1].key)
  end)

  it("leaves loot that is not worth more than the junk", function()
    local plan = Bagwise.MakeRoom.Plan(
      { { slot = 1, value = 5 } },
      { junk("0:1", 0, 1, 10) }, 0)
    assert.is_nil(plan.take[1])
    assert.are.equal(0, #plan.deletes)
  end)

  it("ranks best loot against cheapest junk and stops at the first loss", function()
    local plan = Bagwise.MakeRoom.Plan(
      { { slot = 1, value = 100 }, { slot = 2, value = 60 }, { slot = 3, value = 20 } },
      { junk("a", 0, 1, 10), junk("b", 0, 2, 50), junk("c", 0, 3, 55) }, 0)
    assert.is_truthy(plan.take[1])
    assert.is_truthy(plan.take[2])
    assert.is_nil(plan.take[3])
    assert.are.equal("a", plan.deletes[1].key)
    assert.are.equal("b", plan.deletes[2].key)
  end)

  it("uses free slots before deleting anything", function()
    local plan = Bagwise.MakeRoom.Plan(
      { { slot = 1, value = 100 }, { slot = 2, value = 90 } },
      { junk("a", 0, 1, 10) }, 1)
    assert.is_truthy(plan.take[1])
    assert.is_truthy(plan.take[2])
    assert.are.equal(1, #plan.deletes)
  end)

  it("always takes priority loot, even when it has no value", function()
    local plan = Bagwise.MakeRoom.Plan(
      { { slot = 1, value = 0, priority = true } },
      { junk("a", 0, 1, 10) }, 0)
    assert.is_truthy(plan.take[1])
    assert.are.equal("a", plan.deletes[1].key)
  end)

  it("takes nothing when there is no junk to delete", function()
    local plan = Bagwise.MakeRoom.Plan({ { slot = 1, value = 999 } }, {}, 0)
    assert.is_nil(plan.take[1])
  end)
end)

describe("MakeRoom.IsJunkCandidate", function()
  Bagwise.Data = { ReagentProfessions = {}, VendorReagents = {}, QuestItems = {} }
  local function item(overrides)
    local base = { id = 990001, quality = 0, classID = 15, count = 1, sellPrice = 10 }
    for k, v in pairs(overrides or {}) do base[k] = v end
    return base
  end

  it("accepts grays and plain whites that sell", function()
    assert.are.equal(true, Bagwise.MakeRoom.IsJunkCandidate(item()))
    assert.are.equal(true, Bagwise.MakeRoom.IsJunkCandidate(item({ quality = 1 })))
  end)

  it("rejects items that cannot be sold", function()
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ sellPrice = 0 })))
  end)

  it("rejects consumables, trade goods, recipes, reagents and quest items", function()
    for _, class in ipairs({ 0, 5, 7, 9, 12 }) do
      assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ classID = class })))
    end
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ questItemQuestIDs = { 1 } })))
  end)

  it("rejects the hearthstone and profession tools", function()
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ id = 6948 })))
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ id = 2901 })))
  end)

  it("rejects items the player marked", function()
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ isKept = true })))
  end)

  it("offers white gear only when it is already called safe", function()
    local gear = item({ quality = 1, classID = 4, isEquippable = true })
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(gear))
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(gear, { verdict = "yellow" }))
    assert.are.equal(true, Bagwise.MakeRoom.IsJunkCandidate(gear, { verdict = "green" }))
  end)

  it("rejects greens and better", function()
    assert.are.equal(false, Bagwise.MakeRoom.IsJunkCandidate(item({ quality = 2 })))
  end)
end)

describe("MakeRoom.MarkedResult", function()
  it("keeps the slot's own verdict and adds the delete detail", function()
    local existing = { verdict = "green", reason = "Poor quality, sells for 5c" }
    local result = Bagwise.MakeRoom.MarkedResult(existing, 205)
    assert.are.equal("green", result.verdict)
    assert.are.equal("Poor quality, sells for 5c", result.reason)
    assert.are.equal("Delete to make room for your loot", result.detail)
    assert.is_nil(existing.detail)
  end)

  it("gives a slot with no verdict a yellow dot and the price", function()
    local result = Bagwise.MakeRoom.MarkedResult(nil, 205)
    assert.are.equal("yellow", result.verdict)
    assert.are.equal("Cheapest junk, sells for 2s 5c", result.reason)
  end)
end)

describe("MakeRoom quieting", function()
  it("holds back the dot but keeps the verdict for the tooltip", function()
    local original = { verdict = "green", reason = "x" }
    local quiet = Bagwise.MakeRoom.QuietResult(original)
    assert.are.equal(true, quiet.quiet)
    assert.are.equal("green", quiet.verdict)
    assert.is_nil(original.quiet)
  end)

  it("leaves slots with no verdict alone", function()
    assert.is_nil(Bagwise.MakeRoom.QuietResult(nil))
  end)

  it("restores a quieted slot before it is marked", function()
    local quiet = Bagwise.MakeRoom.QuietResult({ verdict = "green", reason = "x" })
    assert.is_nil(Bagwise.MakeRoom.RestoreResult(quiet).quiet)
  end)
end)
