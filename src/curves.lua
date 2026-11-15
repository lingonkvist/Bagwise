-- Bagwise: how much more than a vendor the auction house may pay before a
-- "just vendor it" verdict is withheld.
--
-- Two curves, because the two kinds of price are not equally trustworthy:
--   live      Auctionator's price from the player's own realm, read in the last
--             days. It is what the item costs now, so it is taken as it is.
--   snapshot  The price file shipped with Bagwise: the cheap end of a market
--             (a region and faction) on the day it was read. Another realm and
--             another week can differ, so the price is read as possibly higher
--             than it says before it is compared.
--
-- Both start from the same break-even. Selling at the auction house keeps 95%
-- of the price, and the deposit is only lost when a listing expires. So the
-- auction is worth a trip when 95% of its price clears the vendor price by a
-- margin: a share of the vendor price (large for cheap items, where a failed
-- listing costs more than it earns, small for dear ones) plus a flat amount for
-- the trip itself. Both parts grow with the vendor price, so the limit never
-- falls as the vendor price rises.
-- Three kinds of auction are treated on their own terms (Bagwise.Curves.Config):
--   stackable  Sold by the stack, priced per unit, a tight market of undercutters.
--   gear       Weapons and armor sold one at a time: random versions, slow sales.
--   other      Everything else sold one at a time (bags, recipes, quest items):
--              thin markets, so the price is the least certain.
Bagwise = Bagwise or {}
Bagwise.Curves = {}

local NET_OF_CUT = 0.95 -- what a seller keeps at a faction auction house

-- One row per kind of auction. Every figure here is the only place it is set.
--   shareCheap, shareDear, shareKnee   the margin over the vendor price as a share
--       of it: shareCheap for the cheapest items, shareDear for very dear ones,
--       halfway between at shareKnee copper
--   flatMargin    copper for the trip itself
--   unitsPerListing   how many items one trip sells (a stack for stackables)
--   uncertainty   how much higher than the snapshot says the price may be on this
--       realm. Measured on the shipped data: one item priced in four markets comes
--       in at this multiple of its median at the 75th percentile (1.08 gear, 1.11
--       other, 1.16 stackables). One price in four is higher, so a green is given
--       when the price raised by this much is still no better than the vendor.
--   outlierFactor   a price above this many times the typical one is a lone
--       hopeful listing and is left out (src/live.lua); tight markets get less room
--   saleFraction   what a snapshot's cheap end is expected to fetch on a bad
--       realm (the 10th percentile of the same comparison: 0.71 to 0.78)
-- The margin shape and the trip cost are the same for every kind today; a row
-- only states what differs.
local function row(own)
  local r = { shareCheap = 0.45, shareDear = 0.04, shareKnee = 600,
              flatMargin = 100, unitsPerListing = 1 }
  for key, value in pairs(own) do r[key] = value end
  return r
end
local CONFIG = {
  stackable = row{ unitsPerListing = 20, uncertainty = 1.15, outlierFactor = 2, saleFraction = 0.75 },
  gear      = row{ uncertainty = 1.10, outlierFactor = 3, saleFraction = 0.8 },
  other     = row{ uncertainty = 1.12, outlierFactor = 3, saleFraction = 0.75 },
}
Bagwise.Curves.Config = CONFIG

local GEAR_CLASSES = { [2] = true, [4] = true }

--- Which kind of auction an item is: "stackable", "gear" or "other". The one place
-- that decides it, so every price check treats an item the same way.
function Bagwise.Curves.TypeOf(item)
  if (item.maxStack or 1) > 1 then return "stackable" end
  if GEAR_CLASSES[item.classID] then return "gear" end
  return "other"
end

local function configFor(kind) return CONFIG[kind] or CONFIG.other end

--- How far above the typical price a listing may be before it is left out.
function Bagwise.Curves.OutlierFactor(kind)
  return configFor(kind).outlierFactor
end

-- A version's snapshot price is already the pricey end of that version
-- (75th percentile, see tools/build_auction_prices.py), so it gets no more.
local PADDED_SOURCES = { version = true, versions = true }

-- Prices move, most of all in the first weeks of a new realm. A snapshot older
-- than a week is read as a little higher for every day beyond it, up to a cap.
local FREE_AGE_DAYS = 7
local UNCERTAINTY_PER_DAY = 0.01
local MAX_AGE_UNCERTAINTY = 0.15

-- Days after which the shipped auction prices are no longer a basis for a green:
-- an unreviewed snapshot that old is a guess about a market that has moved.
Bagwise.Curves.STALE_SNAPSHOT_DAYS = 14
-- Days after which the player is reminded, at login and in /bagwise status, to
-- update the addon before the cutoff.
Bagwise.Curves.REMIND_SNAPSHOT_DAYS = 7

--- How old the shipped auction prices are, in whole days (never negative).
-- @param dateString string  "YYYY-MM-DD", as written into the price data
-- @param nowSeconds number  the current time in seconds
-- @return number|nil nil when the date is missing or not in that shape
function Bagwise.Curves.SnapshotAgeDays(dateString, nowSeconds)
  local year, month, day = tostring(dateString or ""):match("^(%d+)-(%d+)-(%d+)$")
  local toTime = _G.time or os.time
  if not (year and type(nowSeconds) == "number") then return nil end
  local ok, read = pcall(toTime, { year = tonumber(year), month = tonumber(month),
                                   day = tonumber(day), hour = 12 })
  if not (ok and type(read) == "number") then return nil end
  return math.max(0, math.floor((nowSeconds - read) / 86400))
end

--- The margin over the vendor price the auction must clear, per item, in copper.
-- @param vendor number  vendor sell price of one item
-- @param kind string  "stackable", "gear" or "other"
function Bagwise.Curves.Margin(vendor, kind)
  local c = configFor(kind)
  local share = c.shareDear + (c.shareCheap - c.shareDear) / (1 + vendor / c.shareKnee)
  return vendor * share + c.flatMargin / c.unitsPerListing
end

--- How far the price may be off, as a factor the price is multiplied with.
-- 1 for a live price.
function Bagwise.Curves.Uncertainty(source, kind, snapshotAgeDays)
  if source == "live" then return 1 end
  local factor = PADDED_SOURCES[source] and 1 or configFor(kind).uncertainty
  local over = (snapshotAgeDays or 0) - FREE_AGE_DAYS
  if over > 0 then
    factor = factor + math.min(MAX_AGE_UNCERTAINTY, over * UNCERTAINTY_PER_DAY)
  end
  return factor
end

--- The most an item may fetch at auction (per item, copper) and still read as
-- "about the same as the vendor". At or under it, vendoring loses nothing worth
-- the trip.
-- @param vendor number  vendor sell price of one item
-- @param source string  "live", or a snapshot source ("item", "version", "versions")
-- @param kind string  "stackable", "gear" or "other"
-- @param snapshotAgeDays number|nil  days since the snapshot was read
function Bagwise.Curves.Limit(vendor, source, kind, snapshotAgeDays)
  local needed = vendor + Bagwise.Curves.Margin(vendor, kind)
  return needed / (NET_OF_CUT * Bagwise.Curves.Uncertainty(source, kind, snapshotAgeDays))
end

--- What one item is expected to fetch at auction after the cut, for weighing
-- loot against junk. Careful: a price that may be too high is scaled down.
-- A version's price is the pricey end, so about 0.6 of it is the cheap end.
local VERSION_SALE_FRACTION = 0.6
function Bagwise.Curves.SaleValue(price, source, kind)
  if source == "live" then return price * NET_OF_CUT end
  if PADDED_SOURCES[source] then return price * VERSION_SALE_FRACTION end
  return price * NET_OF_CUT * configFor(kind).saleFraction
end

--- The login reminder about old price data, or nil when there is nothing to say.
-- @param ageDays number|nil  from SnapshotAgeDays
-- @return string|nil
function Bagwise.Curves.SnapshotNotice(ageDays)
  if type(ageDays) ~= "number" or ageDays <= Bagwise.Curves.REMIND_SNAPSHOT_DAYS then return nil end
  local cutoff = Bagwise.Curves.STALE_SNAPSHOT_DAYS
  if ageDays > cutoff then
    return "The auction price data is " .. ageDays .. " days old and is no longer used for"
        .. " recommendations. Update Bagwise for up-to-date prices."
  end
  local left = cutoff - ageDays
  return "The auction price data is " .. ageDays .. " days old. Update Bagwise within "
      .. left .. (left == 1 and " day" or " days") .. " for up-to-date prices, or recommendations"
      .. " that rely on it will stop."
end
