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
