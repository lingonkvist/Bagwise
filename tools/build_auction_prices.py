#!/usr/bin/env python3
"""
Build data/auction_prices.lua from the Blizzard WoW Forever auction house API.

Prices are kept per market: a region (us or eu) and a faction (Alliance or
Horde). The neutral houses are left out. A player reads only the market of
their own region and faction, so a Horde player on EU is never priced from US
or Alliance listings.

For each item with enough listings, a market stores a ceiling for its price:
the median, across the market's auction houses, of each house's 25th-percentile
unit buyout, which is about what a seller gets, since the cheap listings sell
first. Gear with random-suffix versions (the same item id, different bonus ids) also
gets a ceiling per version, so a cheap version is judged by its own price and
not by the pricey ones. Bagwise compares that with the vendor price, and tells
you to sell green tradeable gear that the auction house pays about the vendor
price for.
Ordinary auctions (mostly gear) and commodities (stackable materials) are both
read. Only items under a price cap get a price, to keep the file small. Items
that have enough listings but sit over the cap are listed in AuctionAboveCap, so
"worth more than the cap" can be told apart from "nobody lists it".

Usage:
    BNET_CLIENT_ID=... BNET_CLIENT_SECRET=... python3 tools/build_auction_prices.py
    python3 tools/build_auction_prices.py --regions us,eu --max-copper 50000
    python3 tools/build_auction_prices.py --summary         (also print what the data looks like)
    python3 tools/build_auction_prices.py --selftest        (no network, no keys)

Keys come from https://develop.battle.net (a free client). The Forever auction
endpoints are not documented by Blizzard yet. This was written from a community
description of them, so if a response is not what it expects it says so and
stops without writing the file.

Requirements: Python 3.8+, stdlib only.
"""

import argparse
import base64
import gzip
import http.client
import json
import math
import os
import sys
import time
import urllib.error
import urllib.request

RULESET = 1  # the ruleset to read; --ruleset changes it. Rulesets 1, 2, 3 and 5 have houses.
HOUSE_LABELS = []  # one label per kept house, in the order fetch_region returns them
HOUSE_REGIONS = []   # the same houses: "us" or "eu"
HOUSE_FACTIONS = []  # the same houses: "Alliance", "Horde" or None for a neutral house
DEFAULT_REGIONS = "us,eu"
DEFAULT_MAX_COPPER = 50000  # 5 gold: items priced above this are not stored
PERCENTILE = 0.25         # the cheap end: cheap listings sell first, so that is what you would get
# Commodities are bought cheapest first, so a seller gets the low end of the
# market. The pricey tail of optimistic listings never sells and would make a
# 3s item look like 22s.
COMMODITY_PERCENTILE = 0.25
# A listing priced above this many times its house's median for the item is a
# hopeful outlier, not the market: it is dropped before any percentile is read.
# Only done where there are enough listings for a median to mean something.
TRIM_FACTOR = 5
MIN_LISTINGS_PER_HOUSE = 10  # fewer listings and a house says nothing
MIN_HOUSES = 2  # houses in one market (a region and a faction) that must list an item
VARIANT_PERCENTILE = 0.75   # a version is judged on its own, pooled over the market, nearer the pricey end
MIN_VARIANT_LISTINGS = 8
MIN_VARIANT_HOUSES = 2
OUTPUT = os.path.join(os.path.dirname(__file__), "..", "data", "auction_prices.lua")


class ApiError(Exception):
    pass


# ----- the part that decides (pure, tested by --selftest) -----

def percentile(sorted_prices, fraction):
    """Nearest-rank percentile of an ascending list."""
    index = max(0, min(len(sorted_prices) - 1, math.ceil(fraction * len(sorted_prices)) - 1))
    return sorted_prices[index]


def unit_prices(auctions):
    """item id -> unit buyout prices in copper, skipping bid-only auctions."""
    result = {}
    for auction in auctions:
        item = auction.get("item") or {}
        item_id = item.get("id")
        buyout = auction.get("buyout")
        quantity = auction.get("quantity") or 1
        if not item_id or not buyout:
            continue
        result.setdefault(item_id, []).append(buyout // quantity)
    return result


def trim_outliers(sorted_prices, min_listings, factor=TRIM_FACTOR):
    """(prices without the hopeful outliers, how many were dropped).

    sorted_prices is ascending. With fewer than min_listings there is no
    trustworthy median, so nothing is dropped. The cheap end is never touched:
    only listings above factor times the median go.
    """
    if len(sorted_prices) < min_listings:
        return sorted_prices, 0
    limit = percentile(sorted_prices, 0.5) * factor
    kept = [price for price in sorted_prices if price <= limit]
    return kept, len(sorted_prices) - len(kept)


def commodity_unit_prices(entries):
    """item id -> unit prices for commodity listings (priced per unit already)."""
    result = {}
    for entry in entries or []:
        item = entry.get("item") or {}
        item_id = item.get("id")
        price = entry.get("unit_price")
        if not item_id or not price:
            continue
        result.setdefault(item_id, []).append(price)
    return result


def merge_prices(*price_maps):
    """Combine several {item id: [prices]} maps into one."""
    merged = {}
    for prices_by_item in price_maps:
        for item_id, prices in prices_by_item.items():
            merged.setdefault(item_id, []).extend(prices)
    return merged


def variant_key(item):
    """The bonus ids of a listing as '12744' or '12727-12800' (sorted), or None."""
    bonus = item.get("bonus_lists")
    if not bonus:
        return None
    return "-".join(str(b) for b in sorted(bonus))


def variant_prices(auctions):
    """(item id, variant key) -> unit buyout prices, for listings with bonus ids."""
    result = {}
    for auction in auctions:
        item = auction.get("item") or {}
        item_id = item.get("id")
        buyout = auction.get("buyout")
        quantity = auction.get("quantity") or 1
        key = variant_key(item)
        if not item_id or not buyout or not key:
            continue
        result.setdefault((item_id, key), []).append(buyout // quantity)
    return result


def variant_ceilings(variant_houses, item_ceilings, max_copper):
    """{item id: {variant key: ceiling}} for gear that comes in versions.

    Prices of one version are pooled over all houses. A version is kept when it
    has enough listings in enough houses. An item that has versions always gets
    an entry, empty if no version qualified: Bagwise reads "the item has an
    entry but not for my version" as "unknown version, say nothing", so a rare,
    expensive version can never borrow the cheap item's price. Versions over the
    cap are kept for an item that has a ceiling (they block a green) and dropped
    otherwise (nothing to block).
    """
    pooled = {}
    seen_in = {}
    for house in variant_houses:
        for pair, prices in house.items():
            pooled.setdefault(pair, []).extend(prices)
            seen_in[pair] = seen_in.get(pair, 0) + 1
    result = {}
    for (item_id, key), prices in pooled.items():
        versions = result.setdefault(item_id, {})
        if len(prices) < MIN_VARIANT_LISTINGS or seen_in[(item_id, key)] < MIN_VARIANT_HOUSES:
            continue
        kept, _ = trim_outliers(sorted(prices), MIN_VARIANT_LISTINGS)
        ceiling = percentile(kept, VARIANT_PERCENTILE)
        if ceiling > max_copper and item_id not in item_ceilings:
            continue
        versions[key] = ceiling
    # Nothing to say about an item that has no price at all and no priced version.
    return {item_id: versions for item_id, versions in result.items()
            if versions or item_id in item_ceilings}


def all_ceilings(houses, commodity_items=None, stats=None):
    """houses: list of {item id: [unit prices]}. Returns {item id: ceiling copper}
    for every item with enough listings in enough houses, whatever its price.

    The ceiling is the median of those houses' low-end prices (PERCENTILE for
    ordinary items, COMMODITY_PERCENTILE for commodities): one odd house cannot
    move it alone. With two houses the higher of the two is taken.
    """
    commodity_items = commodity_items or ()
    stats = stats if stats is not None else {}
    by_item = {}
    for house in houses:
        for item_id, prices in house.items():
            by_item.setdefault(item_id, []).append(sorted(prices))

    ceilings = {}
    for item_id, per_house in by_item.items():
        counted = []
        for prices in per_house:
            if len(prices) < MIN_LISTINGS_PER_HOUSE:
                continue
            kept, dropped = trim_outliers(prices, MIN_LISTINGS_PER_HOUSE)
            stats["listings"] = stats.get("listings", 0) + len(prices)
            stats["trimmed"] = stats.get("trimmed", 0) + dropped
            counted.append(kept)
        if len(counted) < MIN_HOUSES:
            continue
        fraction = COMMODITY_PERCENTILE if item_id in commodity_items else PERCENTILE
        house_figures = sorted(percentile(prices, fraction) for prices in counted)
        ceilings[item_id] = house_figures[len(house_figures) // 2]
    return ceilings


def price_ceilings(houses, max_copper, commodity_items=None):
    """The items worth storing a price for: those at or under max_copper."""
    return {item_id: ceiling for item_id, ceiling in all_ceilings(houses, commodity_items).items()
            if ceiling <= max_copper}


def above_cap_items(houses, max_copper, commodity_items=None):
    """Items with enough listings whose ceiling is over max_copper, as a sorted list.

    They get no price, but Bagwise must tell "worth more than the cap" from
    "nobody lists it": a missing entry means the second, this list the first.
    """
    return sorted(item_id for item_id, ceiling in all_ceilings(houses, commodity_items).items()
                  if ceiling > max_copper)


def faction_of(house_name):
    """"Alliance" or "Horde" for a faction's house, None for a neutral one."""
    for faction in ("Alliance", "Horde"):
        if house_name.startswith(faction):
            return faction
    return None


def split_markets(houses, variant_houses, regions, factions):
    """{"eu.Horde": (houses, variant houses)} from parallel lists, neutral houses left out."""
    markets = {}
    for house, variant_house, region, faction in zip(houses, variant_houses, regions, factions):
        if faction is None:
            continue
        entry = markets.setdefault("%s.%s" % (region, faction), ([], []))
        entry[0].append(house)
        entry[1].append(variant_house)
    return markets


def market_data(houses, variant_houses, max_copper, commodity_items, stats=None):
    """One market's tables: {"items", "variants", "above_cap"}, or None if nothing qualified."""
    ceilings = all_ceilings(houses, commodity_items, stats)
    items = {item_id: ceiling for item_id, ceiling in ceilings.items() if ceiling <= max_copper}
    if not items:
        return None
    return {
        "items": items,
        "variants": variant_ceilings(variant_houses, items, max_copper),
        "above_cap": sorted(item_id for item_id, ceiling in ceilings.items() if ceiling > max_copper),
        "ceilings": ceilings,
    }


def render_lua(markets, max_copper, generated, house_count):
    """markets: {"eu.Horde": {"items": {id: ceiling}, "variants": {...}, "above_cap": [ids]}}."""
    lines = [
        "-- Generated by tools/build_auction_prices.py from the Blizzard auction house API.",
        "-- AuctionMarkets: \"region.Faction\" -> the prices of that region and faction only.",
        "--   Ceiling: item id -> a ceiling for its auction price, in copper: the median over the",
        "--     market's houses of each house's cheap-end (25th percentile) buyout. Items over %d copper are left out." % max_copper,
        "--   Variant: item id -> { bonus ids of a version -> its own ceiling }. An item listed",
        "--     there with no entry for your version gets no verdict.",
        "--   AboveCap: item id -> true. Listed often enough, but over the cap above, so no price.",
        "-- AuctionPricesDate: the day the prices were read, shown by /bagwise status.",
        "-- Generated %s from %d auction houses. Do not edit by hand." % (generated, house_count),
        "Bagwise = Bagwise or {}",
        "Bagwise.Data = Bagwise.Data or {}",
        "",
        'Bagwise.Data.AuctionPricesDate = "%s"' % generated,
        "",
        "Bagwise.Data.AuctionMarkets={",
    ]
    for key in sorted(markets):
        market = markets[key]
        # No spaces inside an entry: the file is about 40% smaller, one entry per line.
        lines.append('["%s"]={' % key)
        lines.append("Ceiling={")
        items = market["items"]
        lines += ["[%d]=%d," % (item_id, items[item_id]) for item_id in sorted(items)]
        lines.append("},")
        lines.append("Variant={")
        variants = market.get("variants") or {}
        for item_id in sorted(variants):
            versions = variants[item_id]
            parts = ",".join('["%s"]=%d' % (name, versions[name]) for name in sorted(versions))
            lines.append("[%d]={%s}," % (item_id, parts))
        lines.append("},")
        lines.append("AboveCap={")
        lines += ["[%d]=true," % item_id for item_id in sorted(market.get("above_cap") or [])]
        lines.append("},")
        lines.append("},")
    lines.append("}")
    return "\n".join(lines) + "\n"


# ----- talking to the API -----

def request(url, headers, retries=4):
    for attempt in range(retries):
        req = urllib.request.Request(url, headers=dict(headers, **{"Accept-Encoding": "gzip"}))
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                body = response.read()
                if response.headers.get("Content-Encoding") == "gzip":
                    body = gzip.decompress(body)
                return json.loads(body)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if error.code in (429, 500, 502, 503, 504) and attempt < retries - 1:
                time.sleep(2 ** attempt * 2)
                continue
            raise ApiError("%s returned HTTP %d" % (url, error.code))
        except (urllib.error.URLError, TimeoutError, http.client.IncompleteRead, ConnectionError) as error:
            if attempt < retries - 1:
                time.sleep(2 ** attempt * 2)
                continue
            raise ApiError("%s failed: %s" % (url, error))


def get_token(client_id, client_secret):
    credentials = base64.b64encode(("%s:%s" % (client_id, client_secret)).encode()).decode()
    req = urllib.request.Request(
        "https://oauth.battle.net/token",
        data=b"grant_type=client_credentials",
        headers={"Authorization": "Basic " + credentials,
                 "Content-Type": "application/x-www-form-urlencoded"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            return json.loads(response.read())["access_token"]
    except urllib.error.HTTPError as error:
        raise ApiError("Battle.net refused the keys (HTTP %d)" % error.code)


# For --raw: collects a few untouched auction entries of one item id, and the
# set of field names seen in every auction's "item" object.
RAW = {"item": None, "samples": [], "item_keys": set(), "listing_keys": set()}


def collect_raw(auctions):
    for auction in auctions:
        RAW["listing_keys"].update(auction.keys())
        item = auction.get("item") or {}
        RAW["item_keys"].update(item.keys())
        if item.get("id") == RAW["item"] and len(RAW["samples"]) < 12:
            RAW["samples"].append(auction)


def print_raw():
    print("Fields in an auction entry: %s" % ", ".join(sorted(RAW["listing_keys"])))
    print("Fields in its item object:  %s" % ", ".join(sorted(RAW["item_keys"])))
    print("First %d raw entries for item %s:" % (len(RAW["samples"]), RAW["item"]))
    for sample in RAW["samples"]:
        print("  " + json.dumps(sample, sort_keys=True))


def print_house_index(token, regions):
    """Show what the API says about auction houses and rulesets, untouched.

    Used to find out which house belongs to which ruleset and faction."""
    headers = {"Authorization": "Bearer " + token}
    for region in [r.strip() for r in regions.split(",") if r.strip()]:
        for ruleset in range(1, 7):
            url = ("https://%s.api.blizzard.com/data/wow/ruleset/%d/auctions/?namespace=dynamic-forever-%s"
                   % (region, ruleset, region))
            try:
                reply = request(url, headers)
            except ApiError as error:
                print("%s ruleset %d: %s" % (region, ruleset, error))
                continue
            if not reply:
                print("%s ruleset %d: nothing" % (region, ruleset))
                continue
            entries = reply.get("auctions") or []
            print("%s ruleset %d: %d houses, keys %s" % (region, ruleset, len(entries), sorted(reply)))
            for entry in entries:
                print("  " + json.dumps(entry, sort_keys=True))


def fetch_region(region, token):
    """Unit prices per auction house for one region: (houses, variant houses, ids seen as commodities)."""
    headers = {"Authorization": "Bearer " + token}
    base = "https://%s.api.blizzard.com/data/wow/ruleset/%d/auctions" % (region, RULESET)
    namespace = "?namespace=dynamic-forever-" + region

    index = request(base + "/" + namespace, headers)
    if not index or "auctions" not in index:
        raise ApiError("%s: the auction index did not have an 'auctions' list. "
                       "The Forever endpoints may have changed." % region)
    house_ids = [entry["id"] for entry in index["auctions"] if "id" in entry]
    house_names = {entry["id"]: (entry.get("name") or {}).get("en_US", "?") for entry in index["auctions"] if "id" in entry}
    print("%s: %d auction houses" % (region, len(house_ids)))

    houses = []
    variant_houses = []
    commodity_items = set()
    commodities_missing = False
    for house_id in house_ids:
        detail = request("%s/%d%s" % (base, house_id, namespace), headers)
        auctions = (detail or {}).get("auctions") or []  # some houses have no auctions field
        ordinary = unit_prices(auctions)
        if RAW["item"] and auctions:
            collect_raw(auctions)

        commodity = {}
        if not commodities_missing:
            # Stackable materials live here, per house, priced per unit.
            reply = request("%s/%d/commodities%s" % (base, house_id, namespace), headers)
            if reply is None:
                commodities_missing = True
                print("  house %d: no commodities endpoint, reading ordinary auctions only" % house_id)
            else:
                commodity = commodity_unit_prices(reply.get("auctions"))
                commodity_items.update(commodity)

        if not ordinary and not commodity:
            print("  house %d: no auctions" % house_id)
            continue
        print("  house %d: %d auctions, %d items; commodities: %d items"
              % (house_id, len(auctions), len(ordinary), len(commodity)))
        houses.append(merge_prices(ordinary, commodity))
        HOUSE_LABELS.append("%s %d %s" % (region, house_id, house_names.get(house_id, "?")[:9]))
        HOUSE_REGIONS.append(region)
        HOUSE_FACTIONS.append(faction_of(house_names.get(house_id, "")))
        variant_houses.append(variant_prices(auctions))
    return houses, variant_houses, commodity_items


def explain_item(houses, item_id, variant_houses=None):
    """Print what each auction house showed for one item, to see why it got its ceiling."""
    print("Item %d, per auction house (copper per unit):" % item_id)
    for number, house in enumerate(houses, 1):
        prices = sorted(house.get(item_id, []))
        label = HOUSE_LABELS[number - 1] if number <= len(HOUSE_LABELS) else "house %d" % number
        if not prices:
            print("  %-22s none" % label)
            continue
        print("  %-22s %3d listings, min %d, p25 %d, median %d, p90 %d, max %d"
              % (label, len(prices), prices[0], percentile(prices, PERCENTILE), percentile(prices, 0.5),
                 percentile(prices, 0.9), prices[-1]))
    if not variant_houses:
        return
    pooled = {}
    for house in variant_houses:
        for (iid, key), prices in house.items():
            if iid == item_id:
                pooled.setdefault(key, []).extend(prices)
    if pooled:
        print("Per version (bonus ids), all houses pooled:")
        for key in sorted(pooled, key=lambda k: percentile(sorted(pooled[k]), VARIANT_PERCENTILE)):
            prices = sorted(pooled[key])
            print("  %-14s %4d listings, min %d, median %d, ceiling (p75) %d"
                  % (key, len(prices), prices[0], percentile(prices, 0.5), percentile(prices, VARIANT_PERCENTILE)))


# ----- what the data looks like (for tuning the rules) -----

QUALITY_NAMES = {0: "Poor", 1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic", 5: "Legendary"}
PRICE_BANDS = [(100, "up to 1s"), (1000, "up to 10s"), (5000, "up to 50s"),
               (20000, "up to 2g"), (None, "up to the cap"), (float("inf"), "over the cap")]
VENDOR_RATIOS = [(1.5, "up to 1.5x vendor"), (3, "up to 3x vendor"), (10, "up to 10x vendor"),
                 (float("inf"), "over 10x vendor")]


def band_label(ceiling, max_copper):
    for limit, label in PRICE_BANDS:
        limit = max_copper if limit is None else limit
        if ceiling <= limit:
            return label
    return PRICE_BANDS[-1][1]


def summarize(ceilings, max_copper, commodity_items, items=None):
    """Lines describing the data. ceilings: {id: ceiling} with no cap applied.

    items is optional {id: {"quality": n, "sell": copper}} from the game's item
    tables. With it the summary also splits by quality and compares each ceiling
    with the vendor price, which is what the blue rules will be tuned on.
    """
    stored = [i for i, c in ceilings.items() if c <= max_copper]
    above = [i for i, c in ceilings.items() if c > max_copper]
    seen_as_commodity = [i for i in ceilings if i in commodity_items]
    lines = [
        "Items with enough listings: %d" % len(ceilings),
        "  priced (at or under the cap of %d copper): %d" % (max_copper, len(stored)),
        "  above the cap: %d" % len(above),
        "  of all of them, listed as commodities: %d" % len(seen_as_commodity),
        "By price band:",
    ]
    counts = {}
    for ceiling in ceilings.values():
        label = band_label(ceiling, max_copper)
        counts[label] = counts.get(label, 0) + 1
    for _, label in PRICE_BANDS:
        lines.append("  %-14s %5d" % (label, counts.get(label, 0)))

    if not items:
        lines.append("No item tables given, so no split by quality (use --summary with a build or cache).")
        return lines

    lines.append("By quality (priced / above cap), and how the priced ones compare with the vendor price:")
    by_quality = {}
    unknown = 0
    for item_id, ceiling in ceilings.items():
        info = items.get(item_id)
        if info is None:
            unknown += 1
            continue
        entry = by_quality.setdefault(info.get("quality", 0), {"priced": 0, "above": 0, "ratios": {}, "no_vendor": 0})
        if ceiling > max_copper:
            entry["above"] += 1
            continue
        entry["priced"] += 1
        sell = info.get("sell", 0)
        if sell <= 0:
            entry["no_vendor"] += 1
            continue
        ratio = ceiling / float(sell)
        for limit, label in VENDOR_RATIOS:
            if ratio <= limit:
                entry["ratios"][label] = entry["ratios"].get(label, 0) + 1
                break
    for quality in sorted(by_quality):
        entry = by_quality[quality]
        lines.append("  %s: %d priced, %d above cap" % (QUALITY_NAMES.get(quality, str(quality)), entry["priced"], entry["above"]))
        parts = ["%s %d" % (label, entry["ratios"].get(label, 0)) for _, label in VENDOR_RATIOS]
        parts.append("no vendor price %d" % entry["no_vendor"])
        lines.append("      " + ", ".join(parts))
    if unknown:
        lines.append("  not in the item tables: %d" % unknown)
    return lines


ITEM_CLASS_NAMES = {0: "Consumable", 1: "Container", 3: "Gem", 5: "Reagent", 7: "Trade goods",
                    9: "Recipe", 12: "Quest", 15: "Miscellaneous"}
GEAR_CLASSES = (2, 4)  # weapons and armor: judged by the other rules
OUTLIER_MIN_RATIO = 3      # the auction pays at least this many times the vendor price...
OUTLIER_MIN_GAIN = 100     # ...and at least this many copper more
OUTLIER_ROWS_PER_CLASS = 12


def outlier_report(by_market, items, max_copper):
    """Lines on cheap-to-vendor items that auction for clearly more: the ones a player
    might hesitate over, like the Shredder pages (vendor 5c, auction 8s).

    by_market: {market: {item id: ceiling}}. An item's figure is the median over
    the markets that price it. items: {id: {name, class, quality, sell}} from the
    game's item tables. Gear is left out; poor to uncommon quality only.
    """
    figures = {}
    for ceilings in by_market.values():
        for item_id, ceiling in ceilings.items():
            figures.setdefault(item_id, []).append(ceiling)
    found = {}
    for item_id, values in figures.items():
        info = items.get(item_id)
        if not info or info.get("class") in GEAR_CLASSES or info.get("quality", 0) > 2:
            continue
        ceiling = sorted(values)[len(values) // 2]
        sell = info.get("sell", 0)
        if ceiling > max_copper or sell <= 0 or ceiling < sell * OUTLIER_MIN_RATIO or ceiling - sell < OUTLIER_MIN_GAIN:
            continue
        found.setdefault(info.get("class"), []).append((ceiling - sell, item_id, info.get("name", "?"), sell, ceiling))
    if not found:
        return ["No cheap-to-vendor items auction for clearly more."]
    money = lambda copper: "%dg %ds" % divmod(copper // 100, 100) if copper >= 10000 else (
        "%ds %dc" % divmod(copper, 100) if copper >= 100 else "%dc" % copper)
    lines = ["Items that vendor for little but auction for at least %dx more and %dc more (not gear):"
             % (OUTLIER_MIN_RATIO, OUTLIER_MIN_GAIN)]
    for item_class in sorted(found, key=lambda c: -len(found[c])):
        rows = sorted(found[item_class], reverse=True)
        lines.append("%s: %d items, biggest gains first" % (ITEM_CLASS_NAMES.get(item_class, "Class %s" % item_class), len(rows)))
        for _, item_id, name, sell, ceiling in rows[:OUTLIER_ROWS_PER_CLASS]:
            lines.append("  %6d  %-42s vendor %-8s auction %s" % (item_id, name[:42], money(sell), money(ceiling)))
    return lines


def compare_regions(by_region, limit=8):
    """Lines on how much the regions disagree, for deciding on per-region data.

    by_region: {region: {item id: ceiling}}. Only items both regions price are
    compared; the ratio is the higher over the lower.
    """
    names = sorted(by_region)
    if len(names) < 2:
        return ["Regions: only one region read, nothing to compare."]
    first, second = names[0], names[1]
    a, b = by_region[first], by_region[second]
    both = sorted(set(a) & set(b))
    ratios = {i: max(a[i], b[i]) / float(min(a[i], b[i])) for i in both if min(a[i], b[i]) > 0}
    lines = ["Regions %s and %s: %d items priced in both, %d only in %s, %d only in %s"
             % (first, second, len(both), len(set(a) - set(b)), first, len(set(b) - set(a)), second)]
    for limit_ratio in (1.25, 1.5, 2, 3):
        count = sum(1 for r in ratios.values() if r > limit_ratio)
        share = 100.0 * count / len(ratios) if ratios else 0
        lines.append("  differ by more than %sx: %d (%.0f%%)" % (limit_ratio, count, share))
    worst = sorted(ratios, key=lambda i: -ratios[i])[:limit]
    if worst:
        lines.append("  biggest gaps (item id: %s / %s, copper):" % (first, second))
        for item_id in worst:
            lines.append("    %d: %d / %d" % (item_id, a[item_id], b[item_id]))
    return lines


def load_item_facts(build, cache_dir):
    """{id: {"quality", "sell"}} from the game's item tables, or None if they cannot be had."""
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import build_reagent_professions as base
        import audit_trade_goods as audit
        build = build or base.resolve_build("forever")
        print("Reading item tables for build %s" % build)
        tables = {name: base.fetch_csv_table(name, build, cache_dir) for name in ("Item", "ItemSparse")}
        parsed = audit.parse_items(tables["Item"], tables["ItemSparse"])
        return {i: {"quality": info["quality"], "sell": info["sell"], "name": info["name"], "class": info["class"]}
                for i, info in parsed.items()}
    except Exception as error:  # the summary is optional, never stop the build for it
        print("Could not read the item tables (%s). Showing the summary without quality." % error)
        return None


# ----- self test -----

def selftest():
    def house(prices_by_item):
        return {item: list(prices) * 3 for item, prices in prices_by_item.items()}  # 12 listings each

    steady = [house({1: [100, 120, 150, 90], 2: [100, 120, 150, 90], 3: [90000, 100000, 120000, 99000]})
              for _ in range(5)]
    result = price_ceilings(steady, 50000)
    assert sorted(result) == [1, 2], result          # item 3 is over the cap
    assert result[1] == 90   # the cheap end: a quarter of listings are at or under it

    # one pricey house does not set the ceiling, but pricey houses in the majority do
    mixed = [house({1: [100, 100, 100, 100]}) for _ in range(4)]
    mixed.append(house({1: [900, 1000, 1200, 990]}))
    assert price_ceilings(mixed, 50000)[1] == 100
    mostly = [house({1: [100, 100, 100, 100]}) for _ in range(2)]
    mostly += [house({1: [900, 1000, 1200, 990]}) for _ in range(3)]
    assert price_ceilings(mostly, 50000)[1] == 900

    # a house with too few listings neither counts nor raises the ceiling
    thin = [house({1: [100, 100, 100, 100]}) for _ in range(4)]
    thin.append(house({1: [999999]}))
    assert price_ceilings(thin, 50000) == {1: 100}

    # too few houses (a market needs MIN_HOUSES), or houses with too few listings to count
    assert price_ceilings([house({1: [100, 100, 100, 100]})], 50000) == {}
    assert price_ceilings([house({1: [100, 100, 100, 100]}) for _ in range(2)], 50000) == {1: 100}
    # with two houses the higher figure counts
    assert price_ceilings([house({1: [100] * 4}), house({1: [900] * 4})], 50000) == {1: 900}
    assert price_ceilings([house({1: [100, 100, 100]}) for _ in range(4)], 50000) == {}  # 9 per house

    # a listing far above the median is not the market, and the cheap end decides
    variants = [house({1: [100, 100, 100, 5000]}) for _ in range(5)]
    assert price_ceilings(variants, 50000)[1] == 100
    spread = [house({1: [100, 200, 300, 400]}) for _ in range(5)]  # 100..400, nothing past 5x
    assert price_ceilings(spread, 50000)[1] == 100

    # trimming: only above 5x the median, only with enough listings, and the stats count it
    assert trim_outliers([100] * 9 + [5000] * 3, 10) == ([100] * 9, 3)
    assert trim_outliers([100] * 9 + [500], 10) == ([100] * 9 + [500], 0)   # exactly 5x stays
    assert trim_outliers([100, 100, 5000], 10) == ([100, 100, 5000], 0)      # too few to judge
    stats = {}
    all_ceilings(variants, None, stats)
    assert stats == {"listings": 60, "trimmed": 15}, stats

    # unit price and bid-only handling
    auctions = [
        {"item": {"id": 7}, "buyout": 300, "quantity": 3},
        {"item": {"id": 7}, "buyout": 500, "quantity": 1},
        {"item": {"id": 7}, "bid": 50, "quantity": 1},
        {"item": {}, "buyout": 10, "quantity": 1},
    ]
    assert unit_prices(auctions) == {7: [100, 500]}

    assert percentile([1, 2, 3, 4], 0.75) == 3
    assert percentile([5], 0.75) == 5

    # versions: a cheap version of an item with pricey ones gets its own ceiling
    def vhouse(cheap, pricey):
        return {(5, "12744"): [cheap] * 3, (5, "12722"): [pricey] * 3}
    vh = [vhouse(800, 27000) for _ in range(3)]
    result = variant_ceilings(vh, {5: 8700}, 50000)
    assert result == {5: {"12744": 800, "12722": 27000}}, result
    # too few houses: no version qualifies, but the item is still marked as versioned
    assert variant_ceilings(vh[:2], {5: 8700}, 50000) == {5: {}}
    # an item with no price and no priced version is not mentioned at all
    assert variant_ceilings(vh[:2], {}, 50000) == {}
    # a version equal to the item's ceiling is stored too, so "known" is explicit
    assert variant_ceilings(vh, {5: 800}, 50000) == {5: {"12744": 800, "12722": 27000}}
    # an over-cap version of an item with no ceiling is dropped
    assert variant_ceilings(vh, {}, 5000) == {5: {"12744": 800}}
    assert variant_key({"bonus_lists": [12744, 12700]}) == "12700-12744"
    assert variant_key({"id": 5}) is None

    # commodities are priced per unit already, and merge with ordinary listings
    assert commodity_unit_prices([{"item": {"id": 9}, "unit_price": 40, "quantity": 20},
                                  {"item": {"id": 9}, "unit_price": 55, "quantity": 1},
                                  {"item": {"id": 9}, "quantity": 1}, {"item": {}, "unit_price": 3}]) == {9: [40, 55]}
    assert commodity_unit_prices(None) == {}
    assert merge_prices({1: [5], 2: [7]}, {1: [6]}) == {1: [5, 6], 2: [7]}

    # over-cap items are listed apart, so "pricey" differs from "never listed"
    assert above_cap_items(steady, 50000) == [3]
    assert above_cap_items(steady, 500000) == []
    assert all_ceilings(steady)[3] == 90000

    lines = summarize({1: 80, 2: 900, 3: 9000, 4: 90000}, 50000, {2, 4})
    assert lines[0] == "Items with enough listings: 4" and "above the cap: 1" in lines[2]
    assert "listed as commodities: 2" in lines[3]
    facts = {1: {"quality": 1, "sell": 60}, 2: {"quality": 2, "sell": 600}, 3: {"quality": 3, "sell": 100},
             4: {"quality": 3, "sell": 0}}
    detail = "\n".join(summarize({1: 80, 2: 900, 3: 9000, 4: 90000}, 50000, set(), facts))
    assert "Rare: 1 priced, 1 above cap" in detail and "over 10x vendor 1" in detail, detail
    assert "Uncommon: 1 priced" in detail and "up to 1.5x vendor 1, up to 3x vendor 0" in detail, detail

    # a market of 3s listings with a pricey tail is 3s, not 22s, for items and commodities alike
    tail = [house({1: [300, 300, 300, 300, 300, 300, 1400]}) for _ in range(5)]  # 21 listings, a pricey tail under 5x
    assert price_ceilings(tail, 50000)[1] == 300
    assert price_ceilings(tail, 50000, {1})[1] == 300
    assert above_cap_items(tail, 100, {1}) == [1]

    # outliers: cheap vendor items that auction for much more, gear and rare quality left out
    info = {1: {"name": "Page", "class": 12, "quality": 1, "sell": 5}, 2: {"name": "Cloth", "class": 7, "quality": 1, "sell": 50},
            3: {"name": "Sword", "class": 2, "quality": 2, "sell": 10}, 4: {"name": "Blue", "class": 12, "quality": 3, "sell": 5},
            5: {"name": "Free", "class": 12, "quality": 1, "sell": 0}, 6: {"name": "Small", "class": 15, "quality": 1, "sell": 5},
            7: {"name": "Gold", "class": 12, "quality": 1, "sell": 5}}
    report = "\n".join(outlier_report({"a": {1: 800, 2: 60, 3: 900, 4: 900, 5: 900, 6: 50, 7: 90000},
                                       "b": {1: 600}}, info, 50000))
    assert "Page" in report and "vendor 5c" in report and "auction 8s 0c" in report, report
    assert "Cloth" not in report and "Sword" not in report and "Blue" not in report, report
    assert "Free" not in report and "Small" not in report and "Gold" not in report, report
    assert outlier_report({"a": {2: 60}}, info, 50000) == ["No cheap-to-vendor items auction for clearly more."]

    # the region comparison
    lines = compare_regions({"us": {1: 100, 2: 100, 3: 100}, "eu": {1: 100, 2: 200, 3: 400, 4: 5}})
    assert "3 items priced in both" in lines[0] and "only in eu" in lines[0]
    assert "more than 1.5x: 2 (67%)" in "\n".join(lines) and "more than 3x: 1 (33%)" in "\n".join(lines)
    assert lines[-3].strip() == "3: 400 / 100", lines  # eu first, biggest gap first
    assert "nothing to compare" in compare_regions({"us": {1: 1}})[0]

    # markets: a region and a faction, neutral houses left out
    assert faction_of("Horde Auction House") == "Horde" and faction_of("Alliance Auction House") == "Alliance"
    assert faction_of("Blackwater Auction House") is None and faction_of("") is None
    markets = split_markets(["h1", "h2", "h3", "h4", "h5"], ["v1", "v2", "v3", "v4", "v5"],
                            ["us", "us", "us", "eu", "eu"], ["Horde", None, "Alliance", "Horde", "Horde"])
    assert sorted(markets) == ["eu.Horde", "us.Alliance", "us.Horde"], sorted(markets)
    assert markets["eu.Horde"] == (["h4", "h5"], ["v4", "v5"]) and markets["us.Horde"] == (["h1"], ["v1"])
    one = market_data([house({1: [100] * 4, 3: [90000] * 4})] * 2, [{}, {}], 50000, set())
    assert one["items"] == {1: 100} and one["above_cap"] == [3] and one["variants"] == {}
    assert market_data([house({1: [100] * 4})], [{}], 50000, set()) is None  # one house is too few

    data = {"eu.Horde": {"items": {9: 120, 3: 80}, "variants": {5: {"12744": 800}}, "above_cap": [7, 4]},
            "us.Alliance": {"items": {2: 5}, "variants": {}, "above_cap": []}}
    text = render_lua(data, 50000, "2026-11-10", 5)
    assert text.index('["eu.Horde"]') < text.index('["us.Alliance"]')
    assert "Bagwise.Data.AuctionMarkets={" in text and "AboveCap={" in text
    assert text.index("[4]=true,") < text.index("[7]=true,")
    assert '[5]={["12744"]=800},' in text
    assert text.index("[3]=80,") < text.index("[9]=120,") and text.endswith("}\n")
    assert chr(0x2014) not in text
    print("selftest ok")


# ----- main -----

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--regions", default=DEFAULT_REGIONS)
    parser.add_argument("--max-copper", type=int, default=DEFAULT_MAX_COPPER)
    parser.add_argument("--output", default=OUTPUT)
    parser.add_argument("--selftest", action="store_true")
    parser.add_argument("--raw", type=int, help="Print the raw fields of auction entries for this item id, then stop.")
    parser.add_argument("--item", type=int, help="Also print per-house listing figures for this item id.")
    parser.add_argument("--ruleset", type=int, default=1, help="Which ruleset's auction houses to read (1, 2, 3 or 5).")
    parser.add_argument("--compare-item", type=int,
                        help="Print per-house figures for this item id in every ruleset that has houses, then stop.")
    parser.add_argument("--houses", action="store_true",
                        help="Print the raw auction house list for rulesets 1 to 6 in each region, then stop.")
    parser.add_argument("--outliers", action="store_true",
                        help="Also list cheap-to-vendor items that auction for much more (needs the item tables, like --summary).")
    parser.add_argument("--summary", action="store_true",
                        help="Also print what the data looks like, split by quality when the item tables can be read.")
    parser.add_argument("--build", help="With --summary: the game build for the item tables (default: latest).")
    parser.add_argument("--cache-dir", help="With --summary: cache the downloaded item tables here.")
    args = parser.parse_args()

    if args.selftest:
        selftest()
        return 0

    client_id = os.environ.get("BNET_CLIENT_ID")
    client_secret = os.environ.get("BNET_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("Set BNET_CLIENT_ID and BNET_CLIENT_SECRET (a free client from develop.battle.net).")
        return 1

    if args.houses:
        try:
            print_house_index(get_token(client_id, client_secret), args.regions)
        except ApiError as error:
            print("Stopped: %s" % error)
            return 1
        return 0

    if args.compare_item:
        global RULESET
        try:
            token = get_token(client_id, client_secret)
            for ruleset in (1, 2, 3, 5):
                RULESET = ruleset
                for tags in (HOUSE_LABELS, HOUSE_REGIONS, HOUSE_FACTIONS):
                    del tags[:]
                found = []
                for region in [r.strip() for r in args.regions.split(",") if r.strip()]:
                    found += fetch_region(region, token)[0]
                print("=== ruleset %d ===" % ruleset)
                explain_item(found, args.compare_item)
        except ApiError as error:
            print("Stopped: %s" % error)
            return 1
        return 0

    RULESET = args.ruleset

    if args.raw:
        RAW["item"] = args.raw
        args.regions = args.regions.split(",")[0]  # one region is enough to look at fields
    try:
        token = get_token(client_id, client_secret)
        houses = []
        variant_houses = []
        commodity_items = set()
        for region in [r.strip() for r in args.regions.split(",") if r.strip()]:
            region_houses, region_variants, region_commodities = fetch_region(region, token)
            houses += region_houses
            variant_houses += region_variants
            commodity_items |= region_commodities
    except ApiError as error:
        print("Stopped, nothing written: %s" % error)
        return 1

    if args.raw:
        print_raw()
        return 0

    if len(houses) < MIN_HOUSES:
        print("Stopped, nothing written: only %d auction houses had data (need %d)."
              % (len(houses), MIN_HOUSES))
        return 1

    if args.item:
        explain_item(houses, args.item, variant_houses)

    trim_stats = {}
    markets = {}
    for key, (market_houses, market_variants) in sorted(
            split_markets(houses, variant_houses, HOUSE_REGIONS, HOUSE_FACTIONS).items()):
        data = market_data(market_houses, market_variants, args.max_copper, commodity_items, trim_stats)
        if data is None:
            print("  market %s: %d houses, no item had enough listings, left out" % (key, len(market_houses)))
            continue
        markets[key] = data
        print("  market %s: %d houses, %d items priced, %d above the cap, %d version prices"
              % (key, len(market_houses), len(data["items"]), len(data["above_cap"]),
                 sum(len(v) for v in data["variants"].values())))
    if not markets:
        print("Stopped, nothing written: no market had enough listings. The thresholds or the data are off.")
        return 1

    with open(args.output, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(render_lua(markets, args.max_copper, time.strftime("%Y-%m-%d", time.gmtime()), len(houses)))
    print("Wrote %d markets from %d auction houses to %s" % (len(markets), len(houses), args.output))
    if trim_stats.get("listings"):
        print("Trimmed %d of %d listings (%.1f%%) priced above %dx their house's median."
              % (trim_stats["trimmed"], trim_stats["listings"],
                 100.0 * trim_stats["trimmed"] / trim_stats["listings"], TRIM_FACTOR))
    if args.outliers:
        facts = load_item_facts(args.build, args.cache_dir)
        print("")
        if facts:
            print("\n".join(outlier_report({key: markets[key]["ceilings"] for key in markets}, facts, args.max_copper)))
        else:
            print("Could not read the item tables, so no outlier list.")
    if args.summary:
        facts = load_item_facts(args.build, args.cache_dir)
        print("")
        for key in sorted(markets):
            print("Market %s" % key)
            print("\n".join(summarize(markets[key]["ceilings"], args.max_copper, commodity_items, facts)))
            print("")
        by_market = {key: markets[key]["ceilings"] for key in markets}
        print("\n".join(compare_regions(by_market)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
