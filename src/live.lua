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
local CACHE_SECONDS = 30
local priceCache = {}

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

--- A price the snapshot cannot back up must be this fresh (days). Auctionator
-- keeps the last minimum it saw until the item is seen again, so an older
-- price may be long gone, and nothing else would catch a wrong one.
Bagwise.Live.MAX_AGE_DAYS_UNBACKED = 1

--- Auctionator's recorded days for this item, newest first, or nil when they
-- cannot be read. Each entry is { day = number, low = copper, high = copper }:
-- the lowest and the highest "lowest price" seen that day.
-- This uses Auctionator's internals, so every step is guarded; any failure
-- means nil and the plain price is used.
function Bagwise.Live.History(item, auctionator)
  auctionator = auctionator or rawget(_G, "Auctionator")
  if type(auctionator) ~= "table" or not item or not item.link then return nil end
  local ok, days = pcall(function()
    local db, util = auctionator.Database, auctionator.Utilities
    if not (db and db.GetPrice and db.GetPriceHistory and util and util.DBKeyFromLink) then return nil end
    local keys
    util.DBKeyFromLink(item.link, function(found) keys = found end)
    if type(keys) == "string" then keys = { keys } end
    if type(keys) ~= "table" then return nil end
    local key
    for _, candidate in ipairs(keys) do
      if db:GetPrice(candidate) ~= nil then key = candidate break end
    end
    if not key then return nil end
    local found = {}
    for _, entry in ipairs(db:GetPriceHistory(key)) do
      local day, high = tonumber(entry.rawDay), entry.maxSeen
      if day and type(high) == "number" then
        found[#found + 1] = { day = day, high = high,
          low = type(entry.minSeen) == "number" and entry.minSeen or high }
      end
    end
    table.sort(found, function(x, y) return x.day > y.day end)
    return found
  end)
  if ok and type(days) == "table" and #days > 0 then return days end
  return nil
end

--- The average over the last 3 days Auctionator has data for, in copper, or nil
-- when the history cannot be read. Each recorded day has a lowest and a highest
-- reading of the cheapest listing; `field` picks which one is averaged.
-- The single price Auctionator shows is the last reading of one day, and for
-- busy items readings differ a lot (3s one scan, 5s the next, 13s the day
-- before). An average over days is steadier than one reading.
-- @param field string  "low", "high" or "mid" (halfway between the two)
function Bagwise.Live.RecentAverage(item, auctionator, field)
  field = (field == "high" or field == "mid") and field or "low"
  local days = Bagwise.Live.History(item, auctionator)
  if not days then return nil end
  local newest, total, count = days[1].day, 0, 0
  for _, d in ipairs(days) do
    if d.day >= newest - (Bagwise.Live.MAX_AGE_DAYS - 1) then
      total = total + (field == "mid" and (d.low + d.high) / 2 or d[field])
      count = count + 1
    end
  end
  if count == 0 then return nil end
  local average = math.floor(total / count)
  return average > 0 and average or nil
end

--- Whether the recent days all agree on the price: at least two recorded days in
-- the last 3, and the dearest reading no more than a quarter above the cheapest.
-- A one-off lowball shows up as a single day or a wide range; a price that
-- several days in a row agree on is the market's own, even when it differs from
-- the snapshot (prices differ between realms).
function Bagwise.Live.IsSteady(item, auctionator)
  local days = Bagwise.Live.History(item, auctionator)
  if not days then return false end
  local newest, count, lowest, highest = days[1].day, 0, nil, nil
  for _, d in ipairs(days) do
    if d.day >= newest - (Bagwise.Live.MAX_AGE_DAYS - 1) then
      count = count + 1
      if not lowest or d.low < lowest then lowest = d.low end
      if not highest or d.high > highest then highest = d.high end
    end
  end
  return count >= 2 and lowest > 0 and highest <= lowest * 1.25
end

--- Which average judges an item. Blue gear is dearer and sells less often, so a
-- dip matters more: it is judged on the highs. Anything cheaper on the middle of
-- each day's range, which is what an item typically goes for without counting
-- one lucky dip or one dear moment.
local RARE_QUALITY = 3
function Bagwise.Live.FieldFor(item)
  return (item.quality or 0) >= RARE_QUALITY and "high" or "mid"
end

--- The fresh auction price in copper for one item, and its age in days, or nil.
-- Soulbound items cannot be sold at auction, so they never get one.
-- @param item table  needs link and isBound
-- @param api  table|nil  Auctionator's API, for tests; defaults to the real one
function Bagwise.Live.FreshPrice(item, api, auctionator)
  if not item or not item.link or item.isBound then return nil end
  local injected = api ~= nil or auctionator ~= nil
  api = api or Bagwise.Live.Api()
  if not api then return nil end

  -- Reading Auctionator's history is not free and a bag scan asks for every
  -- slot, so answers are kept briefly. Its data only changes at the auction house.
  local now = GetTime and GetTime() or nil
  local cached = not injected and now and priceCache[item.link]
  if cached and now - cached.at < CACHE_SECONDS then
    return cached.price, cached.age, cached.steady
  end
  local price, age, steady = Bagwise.Live.ReadPrice(item, api, auctionator)
  if not injected and now then priceCache[item.link] = { at = now, price = price, age = age, steady = steady } end
  return price, age, steady
end

--- Forget kept prices (a test hook, and used when Auctionator's data may have changed).
function Bagwise.Live.ClearCache() priceCache = {} end

--- The uncached read behind FreshPrice.
function Bagwise.Live.ReadPrice(item, api, auctionator)

  -- Auctionator falls back to a price saved under another version of the item
  -- when it has none for this one; only prices for this item itself count.
  if api.IsAuctionDataExactByItemLink then
    local exactOk, exact = pcall(api.IsAuctionDataExactByItemLink, CALLER_ID, item.link)
    if exactOk and exact == false then return nil end
  end

  local ok, price = pcall(api.GetAuctionPriceByItemLink, CALLER_ID, item.link)
  if not ok or type(price) ~= "number" or price <= 0 then return nil end

  local ageOk, age = pcall(api.GetAuctionAgeByItemLink, CALLER_ID, item.link)
  if not ageOk or type(age) ~= "number" or age < 0 or age > Bagwise.Live.MAX_AGE_DAYS then
    return nil
  end
  local average = Bagwise.Live.RecentAverage(item, auctionator, Bagwise.Live.FieldFor(item))
  if average and average > price then price = average end
  return price, age, Bagwise.Live.IsSteady(item, auctionator)
end

--- What Auctionator reports for an item, unfiltered, for /bagwise why.
-- @return string one line
function Bagwise.Live.Describe(item, api)
  api = api or Bagwise.Live.Api()
  if not api then return "Auctionator: not found" end
  if not item or not item.link then return "Auctionator: no item link" end
  local function ask(fn)
    if not fn then return "n/a" end
    local ok, value = pcall(fn, CALLER_ID, item.link)
    if not ok then return "error" end
    return tostring(value)
  end
  return "Auctionator says: price " .. ask(api.GetAuctionPriceByItemLink) .. " copper, last seen "
      .. ask(api.GetAuctionAgeByItemLink) .. " days ago, exact item "
      .. ask(api.IsAuctionDataExactByItemLink)
      .. ", 3-day averages: lows " .. tostring(Bagwise.Live.RecentAverage(item, nil, "low"))
      .. ", middle " .. tostring(Bagwise.Live.RecentAverage(item, nil, "mid"))
      .. ", highs " .. tostring(Bagwise.Live.RecentAverage(item, nil, "high")) .. " copper"
      .. " (judged on the " .. Bagwise.Live.FieldFor(item) .. ")"
      .. (Bagwise.Live.IsSteady(item) and ", steady over the last days" or "")
      .. (item.bonusKey and "; versioned item: Auctionator cannot tell versions apart, so this is the cheapest version's price" or "")
      .. Bagwise.Live.HistoryText(item)
end

--- The recorded days as text for /bagwise why: "day 2505: 3s-5s, day 2504: ...".
function Bagwise.Live.HistoryText(item, auctionator)
  local days = Bagwise.Live.History(item, auctionator)
  if not days then return "" end
  local parts = {}
  for i = 1, math.min(#days, 5) do
    local d = days[i]
    parts[#parts + 1] = "day " .. d.day .. ": " .. Bagwise.Verdict.FormatMoney(d.low)
        .. (d.high ~= d.low and (" to " .. Bagwise.Verdict.FormatMoney(d.high)) or "")
  end
  return "\n  Auctionator history: " .. table.concat(parts, ", ")
end
