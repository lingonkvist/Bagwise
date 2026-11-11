-- Bagwise: picking the auction market of the player's region and faction.

Bagwise = nil
dofile("src/market.lua")

describe("Market: region", function()
  it("reads the region from a Forever realm name", function()
    assert.are.equal("eu", Bagwise.Market.RegionOf("CAMWOWEU4Realm2PvP", nil))
    assert.are.equal("us", Bagwise.Market.RegionOf("CAMWOWUS1Realm1", 3))
  end)

  it("falls back to the region id when the name says nothing", function()
    assert.are.equal("eu", Bagwise.Market.RegionOf("Stormrage", 3))
    assert.are.equal("us", Bagwise.Market.RegionOf(nil, 1))
  end)

  it("is nil for a region the data does not cover", function()
    assert.is_nil(Bagwise.Market.RegionOf("Stormrage", 5))
    assert.is_nil(Bagwise.Market.RegionOf("CAMWOWKR1Realm1", nil))
    assert.is_nil(Bagwise.Market.RegionOf(nil, nil))
  end)
end)

describe("Market: key", function()
  it("joins a region and a faction", function()
    assert.are.equal("eu.Horde", Bagwise.Market.Key("eu", "Horde"))
    assert.are.equal("us.Alliance", Bagwise.Market.Key("us", "Alliance"))
  end)

  it("is nil without a known region or faction", function()
    assert.is_nil(Bagwise.Market.Key(nil, "Horde"))
    assert.is_nil(Bagwise.Market.Key("eu", nil))
    assert.is_nil(Bagwise.Market.Key("eu", "Neutral"))
  end)
end)

describe("Market: select", function()
  local function freshData()
    Bagwise.Data = {
      AuctionMarkets = {
        ["eu.Horde"] = { Ceiling = { [1] = 100 }, Variant = { [2] = { ["5"] = 7 } }, AboveCap = { [3] = true } },
        ["us.Alliance"] = { Ceiling = { [1] = 900 }, Variant = {}, AboveCap = {} },
      },
    }
  end

  it("makes the player's market the active tables", function()
    freshData()
    assert.are.equal("eu.Horde", Bagwise.Market.Select("eu", "Horde"))
    assert.are.equal(100, Bagwise.Data.AuctionPriceCeiling[1])
    assert.are.equal(7, Bagwise.Data.AuctionVariantCeiling[2]["5"])
    assert.are.equal(true, Bagwise.Data.AuctionAboveCap[3])
    assert.are.equal("eu.Horde", Bagwise.Data.AuctionMarket)
    assert.is_nil(Bagwise.Data.AuctionMarketMissing)
  end)

  it("switches cleanly to another market", function()
    freshData()
    Bagwise.Market.Select("eu", "Horde")
    Bagwise.Market.Select("us", "Alliance")
    assert.are.equal(900, Bagwise.Data.AuctionPriceCeiling[1])
    assert.is_nil(Bagwise.Data.AuctionVariantCeiling[2])
  end)

  it("clears the tables and marks the market missing when there is none", function()
    freshData()
    Bagwise.Market.Select("eu", "Horde")
    assert.is_nil(Bagwise.Market.Select("us", "Horde"))
    assert.is_nil(Bagwise.Data.AuctionPriceCeiling)
    assert.is_nil(Bagwise.Data.AuctionMarket)
    assert.are.equal(true, Bagwise.Data.AuctionMarketMissing)
  end)

  it("marks it missing when the faction is unknown", function()
    freshData()
    assert.is_nil(Bagwise.Market.Select("eu", nil))
    assert.are.equal(true, Bagwise.Data.AuctionMarketMissing)
  end)

  it("leaves data without markets alone", function()
    Bagwise.Data = { AuctionPriceCeiling = { [1] = 5 } }
    assert.is_nil(Bagwise.Market.Select("eu", "Horde"))
    assert.are.equal(5, Bagwise.Data.AuctionPriceCeiling[1])
    assert.is_nil(Bagwise.Data.AuctionMarketMissing)
  end)
end)
