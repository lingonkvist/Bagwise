--- Which auction prices apply to this player.
--
-- The price data is kept per market: a region (us or eu) and a faction
-- (Alliance or Horde). A player reads only their own, so a Horde player on EU is
-- never judged by US or Alliance listings. This file is pure: the entry point
-- reads the realm, region and faction from the game and passes them in.
--
-- When the player's market is not in the data (an unknown region or faction),
-- Data.AuctionMarketMissing is set and verdict.lua refuses to call a tradable
-- item safe, because it cannot tell what the item sells for.
Bagwise = Bagwise or {}
Bagwise.Market = {}

-- GetCurrentRegion() returns these for the regions the data covers.
local REGION_BY_ID = { [1] = "us", [3] = "eu" }
local FACTIONS = { Alliance = true, Horde = true }

--- The region from a realm name such as "CAMWOWEU4Realm2PvP", else from the
-- region id the game reports. nil when neither says us or eu.
function Bagwise.Market.RegionOf(realmName, regionID)
  if type(realmName) == "string" then
    local code = realmName:upper():match("WOW(%u%u)")
    if code == "US" or code == "EU" then return code:lower() end
  end
  return REGION_BY_ID[regionID]
end

--- "eu.Horde" for a region and faction the data can cover, else nil.
function Bagwise.Market.Key(region, faction)
  if not region or not FACTIONS[faction] then return nil end
  return region .. "." .. faction
end

--- Make the player's market the active price tables.
-- Data without markets (an older data file) is left alone.
-- @return string|nil the market key, nil when there is none
function Bagwise.Market.Select(region, faction)
  local data = Bagwise.Data
  local markets = data and data.AuctionMarkets
  if not markets then return nil end
  data.AuctionMarket, data.AuctionMarketMissing = nil, nil
  data.AuctionPriceCeiling, data.AuctionVariantCeiling, data.AuctionAboveCap = nil, nil, nil
  local key = Bagwise.Market.Key(region, faction)
  local market = key and markets[key]
  if not market then
    data.AuctionMarketMissing = true
    return nil
  end
  data.AuctionMarket = key
  data.AuctionPriceCeiling = market.Ceiling
  data.AuctionVariantCeiling = market.Variant
  data.AuctionAboveCap = market.AboveCap
  return key
end
