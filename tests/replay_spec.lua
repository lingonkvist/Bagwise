-- Bagwise: real-inventory replay tests.
-- The fixtures are /bagwise dump files from real characters. Replaying them
-- catches rule changes that would put a dot on something that should stay
-- quiet, using items nobody invented.

local Replay = dofile("tests/inventory_replay.lua")
local DIR = "tests/fixtures/inventories/"
local FIXTURES = { "warrior_18_horde", "druid_18_horde" }

local function verdictOf(results, itemName)
  for _, result in ipairs(results) do
    if result.row.name == itemName then return result.verdict end
  end
  return "missing"
end

describe("Real inventories, as dumped", function()
  for _, name in ipairs(FIXTURES) do
    it(name .. " gets no green: nothing in it is safe to delete yet", function()
      local results = Replay.Evaluate(Replay.Load(DIR .. name .. ".txt"))
      for _, result in ipairs(results) do
        assert.is_truthy(result.verdict ~= "green")
      end
    end)
  end

  it("does not call a level 18 character's ilvl 24 green low level", function()
    local results = Replay.Evaluate(Replay.Load(DIR .. "warrior_18_horde.txt"))
    assert.is_nil(verdictOf(results, "The Stitcher"))
  end)
end)

describe("Openable items", function()
  it("never marks a Small Barnacled Clam, which opens for loot", function()
    local results = Replay.Evaluate(Replay.Load(DIR .. "warrior_18_horde.txt"))
    assert.is_nil(verdictOf(results, "Small Barnacled Clam"))
  end)
end)

describe("Real inventories, other situations", function()
  -- Whatever the level, class or faction, an item a recipe uses must never be
  -- called safe to delete by a quest or gear rule.
  local situations = {
    { level = 18 }, { level = 30 }, { level = 40 }, { level = 60 },
    { class = "MAGE", level = 30 }, { class = "ROGUE", level = 50 },
    { faction = "Alliance" }, { faction = "Alliance", level = 45 },
  }

  for _, name in ipairs(FIXTURES) do
    it(name .. ": recipe reagents are never green", function()
      local snapshot = Replay.Load(DIR .. name .. ".txt")
      for _, situation in ipairs(situations) do
        for _, result in ipairs(Replay.Evaluate(snapshot, situation)) do
          if result.row.recipeProfs ~= "" and result.row.class == "7" then
            assert.are.equal(nil, result.verdict)
          end
        end
      end
    end)
  end

  it("flags old soulbound gear once the level has moved on", function()
    local results = Replay.Evaluate(Replay.Load(DIR .. "druid_18_horde.txt"), { level = 40 })
    assert.are.equal("green", verdictOf(results, "The Stitcher"))
  end)
end)
