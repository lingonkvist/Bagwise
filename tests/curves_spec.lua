-- MakeSpace: the limit curves for live and snapshot auction prices.

MakeSpace = nil
dofile("src/curves.lua")
dofile("src/auction.lua")

local Curves = MakeSpace.Curves

describe("Curves: the live curve", function()
  it("asks for a bigger margin over a cheap vendor price, in share terms", function()
    local cheap = Curves.Limit(100, "live", "gear") / 100
    local dear = Curves.Limit(10000, "live", "gear") / 10000
    assert.is_truthy(cheap > 2)
    assert.is_truthy(dear < 1.15)
  end)

  it("never asks for less than the vendor price after the cut", function()
    for _, vendor in ipairs({ 1, 50, 500, 5000, 50000 }) do
      assert.is_truthy(Curves.Limit(vendor, "live", "gear") * 0.95 > vendor)
    end
  end)

  it("lets a stack be judged per unit: the trip is shared by the stack", function()
    assert.is_truthy(Curves.Limit(10, "live", "stackable") < Curves.Limit(10, "live", "gear"))
  end)
end)

describe("Curves: the snapshot curve", function()
  it("is stricter than the live curve, since the price may be higher on this realm", function()
    for _, vendor in ipairs({ 5, 100, 1000, 10000 }) do
      assert.is_truthy(Curves.Limit(vendor, "item", "gear") < Curves.Limit(vendor, "live", "gear"))
    end
  end)

  it("does not pad a version price twice: it is already the pricey end", function()
    assert.are.equal(Curves.Limit(500, "live", "gear"), Curves.Limit(500, "version", "gear"))
    assert.are.equal(Curves.Limit(500, "live", "gear"), Curves.Limit(500, "versions", "gear"))
  end)

  it("reads an old snapshot as pricier, a day at a time after the first week", function()
    local fresh = Curves.Limit(1000, "item", false, 7)
    assert.are.equal(fresh, Curves.Limit(1000, "item", false, 0))
    assert.is_truthy(Curves.Limit(1000, "item", false, 10) < fresh)
    assert.is_truthy(Curves.Limit(1000, "item", false, 14) < Curves.Limit(1000, "item", false, 10))
  end)

  it("stops tightening at a cap, so a very old snapshot is not silenced entirely", function()
    assert.are.equal(Curves.Limit(1000, "item", false, 60), Curves.Limit(1000, "item", false, 600))
  end)

  it("an age never changes a live price", function()
    assert.are.equal(Curves.Limit(1000, "live", "gear"), Curves.Limit(1000, "live", false, 90))
  end)
end)

describe("Curves: no cliffs", function()
  it("the limit never falls as the vendor price rises", function()
    for _, source in ipairs({ "live", "item", "version" }) do
      for _, kind in ipairs({ "gear", "stackable", "other" }) do
        local last = 0
        for vendor = 1, 60000, 7 do
          local limit = Curves.Limit(vendor, source, kind, 20)
          assert.is_truthy(limit >= last)
          last = limit
        end
      end
    end
  end)
end)

describe("Curves: what an item fetches", function()
  it("takes the cut off a live price", function()
    assert.are.equal(950, Curves.SaleValue(1000, "live", "gear"))
  end)

  it("scales a snapshot's cheap end down once, not twice", function()
    assert.is_truthy(math.abs(Curves.SaleValue(1000, "item", "gear") - 760) < 0.001)
  end)

  it("scales a version's pricey end to its cheap end", function()
    assert.is_truthy(math.abs(Curves.SaleValue(1000, "version", "gear") - 600) < 0.001)
  end)
end)

describe("Curves: one configuration per kind of auction", function()
  it("tells stackables, gear and the rest apart in one place", function()
    assert.are.equal("stackable", Curves.TypeOf({ maxStack = 20, classID = 7 }))
    assert.are.equal("stackable", Curves.TypeOf({ maxStack = 200, classID = 4 })) -- thrown weapons
    assert.are.equal("gear", Curves.TypeOf({ maxStack = 1, classID = 4 }))
    assert.are.equal("gear", Curves.TypeOf({ classID = 2 }))
    assert.are.equal("other", Curves.TypeOf({ maxStack = 1, classID = 9 }))
    assert.are.equal("other", Curves.TypeOf({}))
  end)

  it("every kind sets every figure, so none falls back by accident", function()
    for _, kind in ipairs({ "stackable", "gear", "other" }) do
      for _, key in ipairs({ "shareCheap", "shareDear", "shareKnee", "flatMargin",
          "unitsPerListing", "uncertainty", "outlierFactor", "saleFraction" }) do
        assert.is_truthy(type(Curves.Config[kind][key]) == "number")
      end
    end
  end)

  it("a stack shares the trip, so its limit is nearer the vendor price than a single item's", function()
    assert.is_truthy(Curves.Limit(10, "live", "stackable") < Curves.Limit(10, "live", "gear"))
  end)

  it("thin markets ('other') are read as less certain than gear", function()
    assert.is_truthy(Curves.Limit(1000, "item", "other") < Curves.Limit(1000, "item", "gear"))
  end)

  it("stackables are trimmed harder than the rest", function()
    assert.is_truthy(Curves.OutlierFactor("stackable") < Curves.OutlierFactor("gear"))
  end)
end)

describe("Curves.SnapshotAgeDays", function()
  local noon = os.time({ year = 2026, month = 11, day = 20, hour = 12 })

  it("counts whole days from the date in the price data", function()
    assert.are.equal(10, MakeSpace.Curves.SnapshotAgeDays("2026-11-10", noon))
    assert.are.equal(0, MakeSpace.Curves.SnapshotAgeDays("2026-11-20", noon))
  end)

  it("gives nothing for a missing or odd date", function()
    assert.is_nil(MakeSpace.Curves.SnapshotAgeDays(nil, noon))
    assert.is_nil(MakeSpace.Curves.SnapshotAgeDays("last week", noon))
  end)
end)

describe("Curves.SnapshotNotice", function()
  it("says nothing for fresh data or an unknown age", function()
    assert.is_nil(MakeSpace.Curves.SnapshotNotice(nil))
    assert.is_nil(MakeSpace.Curves.SnapshotNotice(0))
    assert.is_nil(MakeSpace.Curves.SnapshotNotice(7))
  end)

  it("reminds after a week and says how long is left", function()
    local text = MakeSpace.Curves.SnapshotNotice(9)
    assert.is_truthy(text:find("9 days old", 1, true))
    assert.is_truthy(text:find("within 5 days", 1, true))
    assert.is_truthy(MakeSpace.Curves.SnapshotNotice(13):find("within 1 day ", 1, true))
  end)

  it("says plainly that the data is no longer used after two weeks", function()
    local text = MakeSpace.Curves.SnapshotNotice(15)
    assert.is_truthy(text:find("no longer used", 1, true))
  end)
end)
