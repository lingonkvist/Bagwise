-- MakeSpace: what the auction house pays for an item, as the verdict reads it.
-- Pure, like the verdict. The limit curves and per-kind settings live in
-- src/curves.lua, the live prices in src/live.lua, the shipped snapshot in
-- data/auction_prices_*.lua (one file per market). This module joins them into one answer per item:
--   CeilingFor    the price to judge by, and where it came from
--   SellLimit     the most it may pay and still read as "just vendor it"
--   Blocker       why a green must not stand (auction pays more)
--   PriceLine     the tooltip line for a hint that suggests the auction house
--   SlotValueIfKnown, SaleValue   what a stack or one item fetches

MakeSpace = MakeSpace or {}
MakeSpace.Auction = {}

-- bindType values from GetItemInfo.
local BIND_ON_PICKUP = 1
local BIND_QUEST = 4

-- Can this be listed at the auction house? Not once it is soulbound or bound to
-- a quest.
local function isTradeable(item)
  return not (item.isBound or item.bindType == BIND_ON_PICKUP or item.bindType == BIND_QUEST)
end

-- Stackables are sold by the stack, gear one at a time, the rest in thin markets:
-- src/curves.lua holds the configuration of each kind and the limit curves.
--- The most the auction may pay for this item and still read as "just vendor it".
local function sellLimit(item, source, state)
  return MakeSpace.Curves.Limit(item.sellPrice or 0, source, MakeSpace.Curves.TypeOf(item),
      state and state.priceAgeDays)
end

--- The bonus ids of an item link as "12744" or "12727-12800" (sorted), or nil
-- when it has none or the link is not in the shape we expect. Links read
-- itemID:enchant:gem1..gem4:suffix:unique:linkLevel:spec:modifiersMask:context:
-- numBonusIDs:bonus1... so the count is the 13th field.
local BONUS_COUNT_FIELD = 13
local function bonusKey(link)
  if type(link) ~= "string" then return nil end
  local body = link:match("item:([^|]*)")
  if not body then return nil end
  local fields, position = {}, 1
  while true do
    local colon = body:find(":", position, true)
    fields[#fields + 1] = body:sub(position, colon and colon - 1 or #body)
    if not colon then break end
    position = colon + 1
  end
  local count = tonumber(fields[BONUS_COUNT_FIELD])
  if not count or count < 1 then return nil end
  local ids = {}
  for i = 1, count do
    local id = tonumber(fields[BONUS_COUNT_FIELD + i])
    if not id then return nil end
    ids[#ids + 1] = id
  end
  table.sort(ids)
  return table.concat(ids, "-")
end

--- The auction ceiling for this very item. Random-suffix gear is one item id
-- with very different prices, so when the data lists versions of the item,
-- only the player's own version counts: a version the data has no price for
-- gives nothing (it may be the rare, expensive one), never the item's price.
-- @return number|nil ceiling, string source ("version", "item" or "unknown")
local function snapshotCeilingFor(item)
  local data = MakeSpace.Data or {}
  local versions = data.AuctionVariantCeiling and data.AuctionVariantCeiling[item.id]
  if versions then
    local own = item.bonusKey and versions[item.bonusKey]
    if own then return own, "version" end
    return nil, "unknown"
  end
  local prices = data.AuctionPriceCeiling
  return prices and prices[item.id], "item"
end

-- A fresh price from the player's own auction house (item.livePrice, set by the
-- scanner only when Auctionator saw the item in the last few days). It is the
-- lowest listing, so one cheap listing can make an item look worth less than it
-- is. The snapshot is the check: a live price far below the snapshot's cheap end
-- is not trusted, and the careful snapshot rules decide instead.
local LIVE_LOWBALL_FRACTION = 0.5
-- Days: a live price with no snapshot price next to it must be this fresh.
local LIVE_UNBACKED_MAX_AGE_DAYS = 1

--- The live price to use for this item, or nil.
-- @return number|nil price, string|nil why it was not used (for /makespace why)
local function liveCeiling(item)
  local live = item.livePrice
  if type(live) ~= "number" or live <= 0 then return nil end
  local snapshot, source = snapshotCeilingFor(item)
  local backed = snapshot and source ~= "unknown"
  -- Without a snapshot price to compare against, only a very fresh price counts.
  if not backed and (type(item.liveAge) ~= "number"
      or item.liveAge > LIVE_UNBACKED_MAX_AGE_DAYS) then
    return nil, "live price " .. MakeSpace.Verdict.FormatMoney(live)
        .. " is not confirmed by the snapshot and is over a day old, so it is ignored"
  end
  -- (a versioned item is not ignored here: its live price is floored in ceilingFor)
  -- A price that several recent days agree on (item.liveSteady) is the market's
  -- own, not a one-off lowball, even when it differs from the snapshot.
  if backed and not item.bonusKey and not item.liveSteady and live < snapshot * LIVE_LOWBALL_FRACTION then
    return nil, "live price " .. MakeSpace.Verdict.FormatMoney(live)
        .. " is far below the snapshot (" .. MakeSpace.Verdict.FormatMoney(snapshot)
        .. "), so it may be a lowball and is ignored"
  end
  return live
end

-- A version's snapshot price is the pricey end of that version (the 75th
-- percentile of its listings, build_auction_prices.py), a margin kept on purpose
-- to be careful. Its cheap end, about what a seller gets, is roughly this
-- fraction of it. A live price can bring the ceiling of a versioned item down to
-- this floor and no further, since Auctionator's price is the cheapest version's.
local VERSION_FLOOR_FRACTION = 0.6

-- Versions the data must list before the dearest of them stands in for a
-- version it has no price for. A handful of listed versions means the market
-- was seen well; a single one proves nothing about the rest.
local MIN_LISTED_VERSIONS = 3

--- The dearest listed version of a random-suffix item, for the player's version
-- when the data has no price for it. Most such items cost about the same in
-- every version or are all worth selling, and the dearest version can only keep
-- a green away, never give one that the dearest version would not.
-- @return number|nil
local function dearestVersionCeiling(item)
  local data = MakeSpace.Data or {}
  local versions = data.AuctionVariantCeiling and data.AuctionVariantCeiling[item.id]
  if not versions then return nil end
  local count, dearest = 0, 0
  for _, price in pairs(versions) do
    count = count + 1
    if price > dearest then dearest = price end
  end
  if count < MIN_LISTED_VERSIONS or dearest <= 0 then return nil end
  return dearest
end

--- The shipped prices are too old to base a green on.
local function snapshotTooOld(state)
  local age = state and state.priceAgeDays
  return type(age) == "number" and age > MakeSpace.Curves.STALE_SNAPSHOT_DAYS
end

-- @return number|nil ceiling, string source ("live", "version", "versions", "item" or "unknown")
local function ceilingFor(item)
  local live = liveCeiling(item)
  local snapshot, source = snapshotCeilingFor(item)
  if source == "unknown" then
    local dearest = dearestVersionCeiling(item)
    if dearest then snapshot, source = dearest, "versions" end
  end
  if not live then return snapshot, source end
  -- Auctionator files every version of a random-suffix item under one key, so
  -- its price is the cheapest version's. For a versioned item (the link carries
  -- bonus ids) it may lower the snapshot's price only down to a floor: the
  -- snapshot is the pricey end of this version (see VERSION_FLOOR_FRACTION), and
  -- the floor is roughly its cheap end. With no snapshot price it decides nothing.
  if item.bonusKey then
    if not snapshot or source == "unknown" then return snapshot, source end
    local fraction = source == "item" and LIVE_LOWBALL_FRACTION or VERSION_FLOOR_FRACTION
    return math.max(live, snapshot * fraction), source
  end
  return live, "live"
end

--- What one of this item fetches when sold the better way, careful about the
-- auction side so that a loot decision never leans on a price that is too high.
-- Used to weigh loot against the junk it would replace.
-- @return number copper per item (the vendor price at least)
local function saleValue(item)
  local vendor = item.sellPrice or 0
  if not isTradeable(item) then return vendor end
  local ceiling, source = ceilingFor(item)
  if not ceiling or source == "unknown" then return vendor end
  return math.max(vendor, math.floor(MakeSpace.Curves.SaleValue(ceiling, source, MakeSpace.Curves.TypeOf(item))))
end

--- "Vendor 5c, auction about 8s": the real prices, not the rounded ones.
-- The auction side of a price is a guess, so it is shown rounded up to whole
-- silver: "4s 87c" reads as "5s". Under a silver the copper stays, since rounding
-- 20c up to 1s would be a different guess.
local COPPER_PER_SILVER = 100
local function roundUpToSilver(copper)
  if copper < COPPER_PER_SILVER then return copper end
  return math.ceil(copper / COPPER_PER_SILVER) * COPPER_PER_SILVER
end

local function priceNote(item, ceiling, source)
  local money = MakeSpace.Verdict.FormatMoney
  -- A live price is the real price now ("about"); the snapshot is a cheap-end
  -- ceiling ("up to").
  local approx = source == "live" and "about " or "up to "
  local vendor = item.sellPrice or 0
  local vendorText = vendor > 0 and ("vendor " .. money(vendor)) or "no vendor price"
  return vendorText:sub(1, 1):upper() .. vendorText:sub(2) .. ", auction " .. approx .. money(roundUpToSilver(ceiling))
end

--- The dearest price Auctionator has shown for this item, however old or
-- unconfirmed. It is never trusted to say an item is cheap, but it is enough to
-- say it might not be: a green waits for a price that may be high, even when
-- that price is a week old or the snapshot has nothing to back it.
local function dearestReading(item)
  local reading
  for _, price in ipairs({ item.livePrice or 0, item.stalePrice or 0 }) do
    if type(price) == "number" and price > (reading or 0) then reading = price end
  end
  return reading
end

--- Why a green on a vendor-trash item must not stand: the auction house may pay
-- more than a vendor. Only for items that can be traded at all. Where the data
-- has no price for an item, nobody lists it often enough to matter, so the green
-- stands. A version the data does not know (it may be the pricey one) is
-- silenced, as in the sell rule.
-- @return string|nil the reason it is blocked, for /makespace why
-- @return string|nil a short "Vendor 5c, auction about 8s" for the tooltip, only
--   when the block is about the price (not an unknown version or market)
local function blocker(item, state)
  if not isTradeable(item) then return nil end
  local ceiling, source = ceilingFor(item)
  if source ~= "live" and snapshotTooOld(state) then
    return "the price data is over " .. MakeSpace.Curves.STALE_SNAPSHOT_DAYS .. " days old"
  end
  if source ~= "live" and MakeSpace.Data and MakeSpace.Data.AuctionMarketMissing then
    return "no auction prices for your region and faction"
  end
  if source == "unknown" then
    return "this version may sell for more at auction"
  end
  -- A reading the price rules did not trust (older than a few days, or not
  -- backed by the snapshot) still blocks when it is high, never when it is low.
  local reading = dearestReading(item)
  if reading and (not ceiling or reading > ceiling)
      and reading > sellLimit(item, "live", state) then
    ceiling, source = reading, "live"
  end
  if not ceiling or ceiling <= sellLimit(item, source, state) then return nil end
  -- The same facts for the tooltip, which tells the player why there is no dot.
  local note = priceNote(item, ceiling, source)
  return "it may be worth more at auction (" .. note:sub(1, 1):lower() .. note:sub(2) .. ")", note
end

-- Under this a stack is not worth the trip to the auction house, whatever a
-- vendor pays: a reagent that lists for a couple of copper is vendor trash.
local MIN_LISTING_PER_ITEM = 50

--- An old Auctionator price (too old to judge a green by) that is still clearly
-- under the listing limit, even raised for its age: the item is cheap, so the
-- hint to auction it can go, and its price is shown in place of the snapshot's.
-- Never gives a green by itself.
local function staleSaysCheap(item, state)
  local price = item.stalePrice
  if type(price) ~= "number" or price <= 0 then return false end
  local kind = MakeSpace.Curves.TypeOf(item)
  local raised = price * MakeSpace.Curves.Uncertainty("item", kind, item.staleAge)
  return raised <= sellLimit(item, "live", state)
end

--- The price line for a hint that suggests selling at the auction house. It
-- only shows when the auction is worth it: the price is at least the listing
-- floor and clearly above what the same sell check allows over a vendor. A
-- price that is known but not worth it returns nothing and says so, so the hint
-- can stop suggesting the auction house. Never blocks anything.
-- @return string|nil the price line
-- @return boolean true when the price is known and not worth listing
-- @return boolean|nil true when the line shows Auctionator's own number, which
--   its tooltip already shows, so a repeat of it adds nothing
local function priceLine(item, state)
  if not isTradeable(item) then return nil end
  local ceiling, source = ceilingFor(item)
  -- Your own auction house's old reading beats the snapshot's other-realm ceiling:
  -- show it, and say the auction is not worth it.
  if source ~= "live" and staleSaysCheap(item, state) then
    return priceNote(item, item.stalePrice, "live"), true, true
  end
  -- The same high reading that blocks a green is shown as the price.
  local reading = dearestReading(item)
  if reading and (not ceiling or reading > ceiling) and reading >= MIN_LISTING_PER_ITEM
      and reading > sellLimit(item, "live", state) then
    return priceNote(item, reading, "live"), nil, true
  end
  if source ~= "live" and MakeSpace.Data and MakeSpace.Data.AuctionMarketMissing then return nil end
  if not ceiling or source == "unknown" then return nil end
  if ceiling >= MIN_LISTING_PER_ITEM
      and ceiling > sellLimit(item, source, state) then
    return priceNote(item, ceiling, source), nil, source == "live"
  end
  return nil, true
end

--- What the stack in this slot fetches, careful about the auction side, or nil
-- when the price is not known. A price counts as known only when the data lists
-- the item: a missing price means nobody lists it, which may mean rare, so it is
-- never read as "worth little". An item that cannot be traded is worth its
-- vendor price.
-- @return number|nil copper for the whole slot
local function slotValueIfKnown(item, state)
  local vendor = item.sellPrice or 0
  local count = item.count or 1
  if not isTradeable(item) then return vendor * count end
  local ceiling, source = ceilingFor(item)
  -- An old but clearly low reading from your own auction house stands in for
  -- the snapshot, raised for its age. What is at stake is bounded by the
  -- worth-little bar the caller compares this with.
  if source ~= "live" and staleSaysCheap(item, state) then
    local raised = item.stalePrice * MakeSpace.Curves.Uncertainty("item", MakeSpace.Curves.TypeOf(item), item.staleAge)
    return math.max(vendor, raised) * count
  end
  if source ~= "live" and snapshotTooOld(state) then return nil end
  if source ~= "live" and MakeSpace.Data and MakeSpace.Data.AuctionMarketMissing then return nil end
  if not ceiling or source == "unknown" then return nil end
  local padded = ceiling * MakeSpace.Curves.Uncertainty(source, MakeSpace.Curves.TypeOf(item),
      state and state.priceAgeDays)
  return math.max(vendor, padded) * count
end

MakeSpace.Auction.IsTradeable = isTradeable
MakeSpace.Auction.SellLimit = sellLimit
MakeSpace.Auction.BonusKey = bonusKey
MakeSpace.Auction.SnapshotCeilingFor = snapshotCeilingFor
MakeSpace.Auction.LiveCeiling = liveCeiling
MakeSpace.Auction.CeilingFor = ceilingFor
MakeSpace.Auction.SaleValue = saleValue
MakeSpace.Auction.PriceNote = priceNote
MakeSpace.Auction.Blocker = blocker
MakeSpace.Auction.PriceLine = priceLine
MakeSpace.Auction.SlotValueIfKnown = slotValueIfKnown
MakeSpace.Auction.SnapshotTooOld = snapshotTooOld

MakeSpace.Auction.LIVE_LOWBALL_FRACTION = LIVE_LOWBALL_FRACTION
MakeSpace.Auction.VERSION_FLOOR_FRACTION = VERSION_FLOOR_FRACTION
