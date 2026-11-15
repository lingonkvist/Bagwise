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
-- A price older than MAX_AGE_DAYS is not used to judge, but up to this old it still
-- tells that an item is cheap: it only ever drops a "may sell at auction" hint.
Bagwise.Live.MAX_STALE_DAYS = 14

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

--- The readings behind a live price: Auctionator's current price and the lowest
-- and highest reading of each recent day, newest first.
-- @return table list of copper values (empty when the history cannot be read)
function Bagwise.Live.Samples(item, price, auctionator)
  local samples = { price }
  local days = Bagwise.Live.History(item, auctionator)
  if days then
    local newest = days[1].day
    for _, d in ipairs(days) do
      if d.day >= newest - (Bagwise.Live.MAX_AGE_DAYS - 1) then
        samples[#samples + 1] = d.low
        if d.high ~= d.low then samples[#samples + 1] = d.high end
      end
    end
  end
  return samples
end

local function median(values)
  local sorted = {}
  for i = 1, #values do sorted[i] = values[i] end
  table.sort(sorted)
  local n = #sorted
  if n % 2 == 1 then return sorted[(n + 1) / 2] end
  return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

--- The typical price among some readings, with hopeful highs left out: a reading
-- above `factor` times the median is one lone listing (the cheap ones sold out and
-- the lowest price jumped), not the market. Nothing is dropped from fewer than 3
-- readings, since a median of one or two says nothing; then the lowest of them
-- is the price, never a lone high.
-- @param samples table  copper values
-- @param factor number  how far above the median a reading may be
-- @return number|nil copper
function Bagwise.Live.Typical(samples, factor)
  if #samples == 0 then return nil end
  if #samples < 3 then
    local lowest = samples[1]
    for i = 2, #samples do if samples[i] < lowest then lowest = samples[i] end end
    return lowest
  end
  local limit = median(samples) * factor
  local kept = {}
  for i = 1, #samples do
    if samples[i] <= limit then kept[#kept + 1] = samples[i] end
  end
  return math.floor(median(kept))
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

--- The fresh auction price in copper for one item, and its age in days, or nil.
-- Also, when the newest price is too old to judge by, that stale price and its age.
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
    return cached.price, cached.age, cached.steady, cached.stale, cached.staleAge
  end
  local price, age, steady, stale, staleAge = Bagwise.Live.ReadPrice(item, api, auctionator)
  if not injected and now then
    priceCache[item.link] = { at = now, price = price, age = age, steady = steady,
                              stale = stale, staleAge = staleAge }
  end
  return price, age, steady, stale, staleAge
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
  if not ageOk or type(age) ~= "number" or age < 0 or age > Bagwise.Live.MAX_STALE_DAYS then
    return nil
  end
  -- Typical, not highest: a lone overpriced listing never lifts the price.
  local factor = Bagwise.Curves.OutlierFactor(Bagwise.Curves.TypeOf(item))
  local typical = Bagwise.Live.Typical(Bagwise.Live.Samples(item, price, auctionator), factor)
  if typical and typical > 0 then price = typical end
  -- Too old to judge by: handed back apart, as the stale price and its age.
  if age > Bagwise.Live.MAX_AGE_DAYS then return nil, nil, nil, price, age end
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
      .. ", typical over the last days " .. tostring(Bagwise.Live.Typical(
          Bagwise.Live.Samples(item, tonumber((select(2, pcall(api.GetAuctionPriceByItemLink, CALLER_ID, item.link)))) or 0, nil),
          Bagwise.Curves.OutlierFactor(Bagwise.Curves.TypeOf(item))))
      .. " copper (readings above " .. Bagwise.Curves.OutlierFactor(Bagwise.Curves.TypeOf(item))
      .. "x the median are left out; " .. Bagwise.Curves.TypeOf(item) .. ")"
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
