-- Bagwise: sanity checks on the shipped data files.
--
-- A bad regeneration (an API that changed shape, a half-written file) should
-- fail here, not in a player's bags. Counts are floors, far below the real
-- sizes: they catch "empty" or "tiny", not normal changes between builds.

Bagwise = nil
local DATA_FILES = {
  "reagent_professions", "reagent_chains", "vendor_reagents", "class_reagents",
  "quest_items", "mana_consumables", "protected_items", "auction_prices",
}
for _, file in ipairs(DATA_FILES) do
  dofile("data/" .. file .. ".lua")
end
local Data = Bagwise.Data

local function count(tbl)
  local n = 0
  for _ in pairs(tbl or {}) do n = n + 1 end
  return n
end

describe("Data files: sizes", function()
  it("the big tables are not empty or tiny", function()
    assert.is_truthy(count(Data.ReagentProfessions) >= 400)
    assert.is_truthy(count(Data.QuestItems) >= 1000)
    assert.is_truthy(count(Data.QuestInfo) >= 1000)
    assert.is_truthy(count(Data.VendorReagents) >= 10)
    assert.is_truthy(count(Data.ClassReagents) >= 5)
    assert.is_truthy(count(Data.ManaOnlyConsumables) >= 5)
    assert.is_truthy(count(Data.AuctionPriceCeiling) >= 100)
  end)
end)

describe("Data files: shape", function()
  it("reagent_professions rows are { profession, recipes, min, max }", function()
    for id, rows in pairs(Data.ReagentProfessions) do
      assert.are.equal("number", type(id))
      assert.is_truthy(#rows >= 1)
      for _, row in ipairs(rows) do
        assert.are.equal("string", type(row[1]))
        assert.are.equal("number", type(row[2]))
        assert.are.equal("number", type(row[3]))
        assert.are.equal("number", type(row[4]))
        assert.is_truthy(row[3] <= row[4])
      end
    end
  end)

  it("reagent_chains, when generated, has { profession, min, max } rows", function()
    for id, rows in pairs(Data.ReagentChains or {}) do
      assert.are.equal("number", type(id))
      for _, row in ipairs(rows) do
        assert.are.equal("string", type(row[1]))
        assert.are.equal("number", type(row[2]))
        assert.are.equal("number", type(row[3]))
        assert.is_truthy(row[2] <= row[3])
      end
    end
  end)

  it("auction ceilings are positive numbers", function()
    for id, ceiling in pairs(Data.AuctionPriceCeiling) do
      assert.are.equal("number", type(id))
      assert.is_truthy(type(ceiling) == "number" and ceiling > 0)
    end
  end)

  it("auction versions are keyed by sorted bonus ids with positive ceilings", function()
    for id, versions in pairs(Data.AuctionVariantCeiling or {}) do
      assert.are.equal("number", type(id))
      for key, ceiling in pairs(versions) do
        assert.is_truthy(type(key) == "string" and key:match("^%d+[%d%-]*$") ~= nil)
        assert.is_truthy(type(ceiling) == "number" and ceiling > 0)
      end
    end
  end)

  it("class reagents name their classes and a verdict", function()
    for id, reagent in pairs(Data.ClassReagents) do
      assert.is_truthy(type(reagent.classes) == "table" and next(reagent.classes) ~= nil)
      assert.is_truthy(reagent.verdict == "green" or reagent.verdict == "yellow")
    end
  end)

  it("quest items point at quests the quest table knows", function()
    local missing = 0
    for _, quests in pairs(Data.QuestItems) do
      for _, questID in ipairs(quests) do
        if not Data.QuestInfo[questID] then missing = missing + 1 end
      end
    end
    assert.is_truthy(missing <= count(Data.QuestInfo) * 0.01)
  end)
end)
