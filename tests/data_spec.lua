-- Bagwise: sanity checks on the shipped data files.
--
-- A bad regeneration (an API that changed shape, a half-written file) should
-- fail here, not in a player's bags. Counts are floors, far below the real
-- sizes: they catch "empty" or "tiny", not normal changes between builds.

Bagwise = nil
local DATA_FILES = {
  "reagent_professions", "reagent_chains", "vendor_reagents", "class_reagents",
  "quest_items", "mana_consumables", "protected_items", "auction_prices", "library_books", "quest_availability",
  "weapon_skills",
}
for _, file in ipairs(DATA_FILES) do
  dofile("data/" .. file .. ".lua")
end
local Data = Bagwise.Data

-- Price data is kept per market ("eu.Horde"). A data file made before that has
-- the three tables at the top, and counts as one market.
local function markets()
  local found = {}
  if Data.AuctionMarkets then
    for name, market in pairs(Data.AuctionMarkets) do
      found[#found + 1] = { name = name, Ceiling = market.Ceiling, Variant = market.Variant, AboveCap = market.AboveCap }
    end
  else
    found[1] = { name = "(single table)", Ceiling = Data.AuctionPriceCeiling,
      Variant = Data.AuctionVariantCeiling, AboveCap = Data.AuctionAboveCap }
  end
  return found
end

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
    assert.is_truthy(count(Data.LibraryBooks) >= 30)
    for _, market in ipairs(markets()) do
      assert.is_truthy(count(market.Ceiling) >= 100)
    end
  end)
end)

describe("Data files: shape", function()
  it("reagent_professions rows are { profession, recipes, min, max, green }", function()
    for id, rows in pairs(Data.ReagentProfessions) do
      assert.are.equal("number", type(id))
      assert.is_truthy(#rows >= 1)
      for _, row in ipairs(rows) do
        assert.are.equal("string", type(row[1]))
        assert.are.equal("number", type(row[2]))
        assert.are.equal("number", type(row[3]))
        assert.are.equal("number", type(row[4]))
        assert.is_truthy(row[3] <= row[4])
        -- the green point is optional in older data, and never before the best recipe
        if row[5] and row[5] > 0 then assert.is_truthy(row[5] >= row[4]) end
      end
    end
  end)

  it("reagent_chains, when generated, has { profession, min, max, green } rows", function()
    for id, rows in pairs(Data.ReagentChains or {}) do
      assert.are.equal("number", type(id))
      for _, row in ipairs(rows) do
        assert.are.equal("string", type(row[1]))
        assert.are.equal("number", type(row[2]))
        assert.are.equal("number", type(row[3]))
        assert.is_truthy(row[2] <= row[3])
        if row[4] and row[4] > 0 then assert.is_truthy(row[4] >= row[3]) end
      end
    end
  end)

  it("weapon_skills lists the nine classes' real access, and every weapon type has some class", function()
    local known = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
                    SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true }
    for _, table_ in ipairs({ Data.WeaponClasses, Data.AmmoClasses }) do
      local count = 0
      for subClassID, classes in pairs(table_) do
        assert.are.equal("number", type(subClassID))
        local any = false
        for name in pairs(classes) do
          assert.is_truthy(known[name])
          any = true
        end
        assert.is_truthy(any)
        count = count + 1
      end
      assert.is_truthy(count >= 2)
    end
    -- Forever's own data: rogues use axes, priests never do.
    assert.is_truthy(Data.WeaponClasses[0].ROGUE)
    assert.is_nil(Data.WeaponClasses[0].PRIEST)
    assert.is_nil(Data.AmmoClasses[2].MAGE)
  end)

  it("library books are item IDs that the quest data also knows", function()
    for id, flag in pairs(Data.LibraryBooks) do
      assert.are.equal("number", type(id))
      assert.are.equal(true, flag)
      assert.is_truthy(Data.QuestItems[id] ~= nil)
    end
  end)

  it("required levels are whole levels for quests the quest data describes", function()
    local count = 0
    for id, level in pairs(Data.QuestRequiredLevels) do
      count = count + 1
      assert.are.equal("number", type(id))
      assert.is_truthy(level >= 11 and level <= 70)
      assert.is_truthy(Data.QuestInfo[id] ~= nil)
    end
    assert.is_truthy(count >= 500)
  end)

  it("Vibrant Plumes opens at level 30 although the quest is level 60, and is a Faire quest", function()
    assert.are.equal(60, Data.QuestInfo[7902][1])
    assert.are.equal(30, Data.QuestRequiredLevels[7902])
    assert.are.equal("Darkmoon Faire", Data.QuestEvents[7902])
  end)

  it("event quests are named and known to the quest data", function()
    local count = 0
    for id, name in pairs(Data.QuestEvents) do
      count = count + 1
      assert.are.equal("string", type(name))
      assert.is_truthy(Data.QuestInfo[id] ~= nil)
    end
    assert.is_truthy(count >= 50)
  end)

  it("auction ceilings are positive numbers", function()
    for _, market in ipairs(markets()) do
      for id, ceiling in pairs(market.Ceiling) do
        assert.are.equal("number", type(id))
        assert.is_truthy(type(ceiling) == "number" and ceiling > 0)
      end
    end
  end)

  it("every market is a region and a faction, with its three tables", function()
    for name, market in pairs(Data.AuctionMarkets or {}) do
      assert.is_truthy(name:match("^%l%l%.%u%l+$") ~= nil)
      assert.are.equal("table", type(market.Ceiling))
      assert.are.equal("table", type(market.Variant))
      assert.are.equal("table", type(market.AboveCap))
    end
  end)

  it("auction versions are keyed by sorted bonus ids with positive ceilings", function()
    for _, market in ipairs(markets()) do
      for id, versions in pairs(market.Variant or {}) do
        assert.are.equal("number", type(id))
        for key, ceiling in pairs(versions) do
          assert.is_truthy(type(key) == "string" and key:match("^%d+[%d%-]*$") ~= nil)
          assert.is_truthy(type(ceiling) == "number" and ceiling > 0)
        end
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

describe("Data files: auction prices above the cap", function()
  it("an item over the cap has no price, and every mark is true", function()
    -- The table is absent in data made before it existed, which is fine.
    for _, market in ipairs(markets()) do
      for id, flag in pairs(market.AboveCap or {}) do
        assert.are.equal("number", type(id))
        assert.are.equal(true, flag)
        assert.is_nil(market.Ceiling[id])
      end
    end
  end)
end)

describe("Data files: auction price date", function()
  it("is a YYYY-MM-DD day when the data has one", function()
    if Data.AuctionPricesDate then
      assert.is_truthy(Data.AuctionPricesDate:match("^%d%d%d%d%-%d%d%-%d%d$"))
    end
  end)
end)

