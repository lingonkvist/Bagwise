-- Bagwise: the Auctionator price reader.

_G.Bagwise = nil
dofile("src/live.lua")

describe("Live prices: reading Auctionator", function()
  local function api(price, age, calls)
    return {
      GetAuctionPriceByItemLink = function(caller, link)
        if calls then calls[#calls + 1] = caller end
        return price
      end,
      GetAuctionAgeByItemLink = function() return age end,
    }
  end
  local item = { link = "|Hitem:1234|h", isBound = false }

  it("returns a price seen today or within the last 3 days", function()
    assert.are.equal(400, Bagwise.Live.FreshPrice(item, api(400, 0)))
    assert.are.equal(400, Bagwise.Live.FreshPrice(item, api(400, 3)))
  end)

  it("ignores a price older than 3 days", function()
    assert.is_nil(Bagwise.Live.FreshPrice(item, api(400, 4)))
    assert.is_nil(Bagwise.Live.FreshPrice(item, api(400, 20)))
  end)

  it("ignores a missing price or age, and a zero price", function()
    assert.is_nil(Bagwise.Live.FreshPrice(item, api(nil, 0)))
    assert.is_nil(Bagwise.Live.FreshPrice(item, api(400, nil)))
    assert.is_nil(Bagwise.Live.FreshPrice(item, api(0, 0)))
  end)

  it("never asks for soulbound items or items without a link", function()
    assert.is_nil(Bagwise.Live.FreshPrice({ link = "x", isBound = true }, api(400, 0)))
    assert.is_nil(Bagwise.Live.FreshPrice({ isBound = false }, api(400, 0)))
  end)

  it("returns the age with the price", function()
    local _, age = Bagwise.Live.FreshPrice(item, api(400, 2))
    assert.are.equal(2, age)
  end)

  it("ignores a price Auctionator holds for another version of the item", function()
    local inexact = api(400, 0)
    inexact.IsAuctionDataExactByItemLink = function() return false end
    assert.is_nil(Bagwise.Live.FreshPrice(item, inexact))
    local exact = api(400, 0)
    exact.IsAuctionDataExactByItemLink = function() return true end
    assert.are.equal(400, Bagwise.Live.FreshPrice(item, exact))
  end)

  local function fakeAuctionator(history, keys)
    return {
      Database = {
        GetPrice = function(_, key) return key == "7" and 300 or nil end,
        GetPriceHistory = function() return history end,
      },
      Utilities = { DBKeyFromLink = function(_, callback) callback(keys or { "g:7:20", "7" }) end },
    }
  end
  local days = {
    { rawDay = "2505", minSeen = 300, maxSeen = 500 },
    { rawDay = "2504", minSeen = 600, maxSeen = 700 },
    { rawDay = "2501", minSeen = 900, maxSeen = 900 },
  }

  it("averages the daily lows or highs of the last 3 days of data, ignoring older days", function()
    -- days 2505 and 2504 count, 2501 is too old
    assert.are.equal(450, Bagwise.Live.RecentAverage(item, fakeAuctionator(days), "low"))
    assert.are.equal(600, Bagwise.Live.RecentAverage(item, fakeAuctionator(days), "high"))
  end)

  it("judges green and cheaper items on the middle of each day and blue on the highs", function()
    -- middles: 2505 (300+500)/2 = 400, 2504 (600+700)/2 = 650, average 525
    local green, blue = { link = item.link, quality = 2 }, { link = item.link, quality = 3 }
    assert.are.equal(525, (Bagwise.Live.FreshPrice(green, api(300, 0), fakeAuctionator(days))))
    assert.are.equal(600, (Bagwise.Live.FreshPrice(blue, api(300, 0), fakeAuctionator(days))))
  end)

  it("judges on that average when it is above the price Auctionator shows, never below", function()
    assert.are.equal(525, (Bagwise.Live.FreshPrice(item, api(300, 0), fakeAuctionator(days))))
    assert.are.equal(900, (Bagwise.Live.FreshPrice(item, api(900, 0), fakeAuctionator(days))))
  end)

  it("uses the shown price when the history cannot be read", function()
    assert.are.equal(300, (Bagwise.Live.FreshPrice(item, api(300, 0), {})))
    local broken = fakeAuctionator(days)
    broken.Database.GetPriceHistory = function() error("changed") end
    assert.is_nil(Bagwise.Live.RecentAverage(item, broken))
    assert.are.equal(300, (Bagwise.Live.FreshPrice(item, api(300, 0), broken)))
    assert.is_nil(Bagwise.Live.RecentAverage(item, fakeAuctionator({})))
  end)

  it("finds the newest day whatever order the history comes in", function()
    local shuffled = { days[3], days[2], days[1] }
    assert.are.equal(450, Bagwise.Live.RecentAverage(item, fakeAuctionator(shuffled), "low"))
    assert.are.equal(2505, Bagwise.Live.History(item, fakeAuctionator(shuffled))[1].day)
  end)

  it("keeps answers briefly so a bag scan does not read the history for every slot", function()
    local reads, clock = 0, 100
    _G.GetTime = function() return clock end
    _G.Auctionator = { API = { v1 = {
      GetAuctionPriceByItemLink = function() reads = reads + 1 return 400 end,
      GetAuctionAgeByItemLink = function() return 0 end,
    } } }
    Bagwise.Live.ClearCache()
    Bagwise.Live.FreshPrice(item)
    Bagwise.Live.FreshPrice(item)
    assert.are.equal(1, reads)
    clock = 131
    Bagwise.Live.FreshPrice(item)
    assert.are.equal(2, reads)
    _G.GetTime, _G.Auctionator = nil, nil
    Bagwise.Live.ClearCache()
  end)

  it("lists the recorded days as text", function()
    Bagwise.Verdict = Bagwise.Verdict or {}
    Bagwise.Verdict.FormatMoney = function(copper) return copper .. "c" end
    local text = Bagwise.Live.HistoryText(item, fakeAuctionator(days))
    assert.is_truthy(text:find("day 2505: 300c to 500c", 1, true))
    assert.is_truthy(text:find("day 2504: 600c to 700c", 1, true))
    assert.are.equal("", Bagwise.Live.HistoryText(item, {}))
  end)

  it("calls a price steady when at least two of the last 3 days agree within a quarter", function()
    local function steady(history) return Bagwise.Live.IsSteady(item, fakeAuctionator(history)) end
    assert.are.equal(true, steady({ { rawDay = "2507", minSeen = 1800, maxSeen = 1800 }, { rawDay = "2506", minSeen = 1800, maxSeen = 1800 } }))
    assert.are.equal(true, steady({ { rawDay = "2507", minSeen = 1000, maxSeen = 1200 }, { rawDay = "2506", minSeen = 1100, maxSeen = 1250 } }))
    -- one day only, a wide range, or a second day too old to count
    assert.are.equal(false, steady({ { rawDay = "2507", minSeen = 1800, maxSeen = 1800 } }))
    assert.are.equal(false, steady({ { rawDay = "2507", minSeen = 1000, maxSeen = 2000 }, { rawDay = "2506", minSeen = 1000, maxSeen = 1000 } }))
    assert.are.equal(false, steady({ { rawDay = "2507", minSeen = 1800, maxSeen = 1800 }, { rawDay = "2503", minSeen = 1800, maxSeen = 1800 } }))
    assert.are.equal(false, Bagwise.Live.IsSteady(item, {}))
  end)

  it("returns whether the price is steady as a third value", function()
    local one = { { rawDay = "2507", minSeen = 300, maxSeen = 300 }, { rawDay = "2506", minSeen = 300, maxSeen = 300 } }
    local _, _, steady = Bagwise.Live.FreshPrice(item, api(300, 0), fakeAuctionator(one))
    assert.are.equal(true, steady)
  end)

  it("describes what Auctionator reports, unfiltered", function()
    local text = Bagwise.Live.Describe(item, api(400, 9))
    assert.is_truthy(text:find("price 400 copper", 1, true))
    assert.is_truthy(text:find("9 days ago", 1, true))
    assert.is_truthy(Bagwise.Live.Describe(item, nil):find("not found", 1, true))
  end)

  it("identifies itself with a caller id", function()
    local calls = {}
    Bagwise.Live.FreshPrice(item, api(400, 0, calls))
    assert.are.equal("Bagwise", calls[1])
  end)

  it("survives an error inside Auctionator", function()
    local broken = {
      GetAuctionPriceByItemLink = function() error("boom") end,
      GetAuctionAgeByItemLink = function() return 0 end,
    }
    assert.is_nil(Bagwise.Live.FreshPrice(item, broken))
    local brokenAge = {
      GetAuctionPriceByItemLink = function() return 400 end,
      GetAuctionAgeByItemLink = function() error("boom") end,
    }
    assert.is_nil(Bagwise.Live.FreshPrice(item, brokenAge))
  end)

  it("gives nothing when Auctionator is not installed", function()
    _G.Auctionator = nil
    assert.is_nil(Bagwise.Live.Api())
    assert.is_nil(Bagwise.Live.FreshPrice(item))
  end)

  it("finds the public API when it is installed", function()
    _G.Auctionator = { API = { v1 = api(400, 0) } }
    assert.are.equal(400, Bagwise.Live.FreshPrice(item))
    _G.Auctionator = nil
  end)
end)
