-- Bagwise: fresh auction prices from Auctionator, when it is installed.
--
-- Bagwise ships a price snapshot, which is careful but old and covers only some
-- items. Auctionator records what the player's own auction house charges, and
-- knows how many days ago it last saw each item. A price seen in the last few
-- days is trusted as the real price (verdict.lua decides what to do with it);
-- anything older is ignored and the snapshot decides.
--
-- Only Auctionator's public API is used, and every call is guarded: a missing
-- addon, a missing function or an error all mean "no live price".
Bagwise = Bagwise or {}
Bagwise.Live = {}

local CALLER_ID = "Bagwise"

--- A price counts as fresh when Auctionator saw the item at most this many days
-- ago. Auctionator counts whole days, so 3 means "today or the last 3 days".
Bagwise.Live.MAX_AGE_DAYS = 3

--- Auctionator's public price API, or nil when it is not installed.
function Bagwise.Live.Api()
  local auctionator = rawget(_G, "Auctionator")
  local api = auctionator and auctionator.API and auctionator.API.v1
  if api and api.GetAuctionPriceByItemLink and api.GetAuctionAgeByItemLink then
    return api
  end
  return nil
end

--- The fresh auction price in copper for one item, or nil.
-- Soulbound items cannot be sold at auction, so they never get one.
-- @param item table  needs link and isBound
-- @param api  table|nil  Auctionator's API, for tests; defaults to the real one
function Bagwise.Live.FreshPrice(item, api)
  if not item or not item.link or item.isBound then return nil end
  api = api or Bagwise.Live.Api()
  if not api then return nil end

  local ok, price = pcall(api.GetAuctionPriceByItemLink, CALLER_ID, item.link)
  if not ok or type(price) ~= "number" or price <= 0 then return nil end

  local ageOk, age = pcall(api.GetAuctionAgeByItemLink, CALLER_ID, item.link)
  if not ageOk or type(age) ~= "number" or age < 0 or age > Bagwise.Live.MAX_AGE_DAYS then
    return nil
  end
  return price
end
