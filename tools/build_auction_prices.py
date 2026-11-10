#!/usr/bin/env python3
"""
Build data/auction_prices.lua from the Blizzard WoW Forever auction house API.

For each item with enough listings, it stores a ceiling for its price: the
median, across auction houses, of each house's 90th-percentile unit buyout.
Gear with random-suffix versions (the same item id, different bonus ids) also
gets a ceiling per version, so a cheap version is judged by its own price and
not by the pricey ones. Bagwise compares that with the vendor price, and tells
you to sell green tradeable gear that the auction house pays about the vendor
price for.
Only items under a price cap are stored, to keep the file small. Only ordinary
auctions are read, not commodities (stackable materials), so it is mostly gear.

Usage:
    BNET_CLIENT_ID=... BNET_CLIENT_SECRET=... python3 tools/build_auction_prices.py
    python3 tools/build_auction_prices.py --regions us,eu --max-copper 50000
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
import json
import math
import os
import sys
import time
import urllib.error
import urllib.request

RULESET = 1  # every ruleset lists the same houses and auctions, so one is enough
DEFAULT_REGIONS = "us,eu"
DEFAULT_MAX_COPPER = 50000  # 5 gold: items priced above this are not stored
PERCENTILE = 0.9           # judged by the pricey end, so odd variants count
MIN_LISTINGS_PER_HOUSE = 10  # fewer listings and a house says nothing
MIN_HOUSES = 4
VARIANT_PERCENTILE = 0.75   # a version is judged on its own, pooled over all houses
MIN_VARIANT_LISTINGS = 8
MIN_VARIANT_HOUSES = 3
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
        ceiling = percentile(sorted(prices), VARIANT_PERCENTILE)
        if ceiling > max_copper and item_id not in item_ceilings:
            continue
        versions[key] = ceiling
    # Nothing to say about an item that has no price at all and no priced version.
    return {item_id: versions for item_id, versions in result.items()
            if versions or item_id in item_ceilings}


def price_ceilings(houses, max_copper):
    """houses: list of {item id: [unit prices]}. Returns {item id: ceiling copper}.

    An item is stored when enough houses have enough listings of it. Its ceiling
    is the median of the 90th-percentile prices of those houses: one pricey
    variant raises a house's figure, but one odd house cannot raise the ceiling
    alone. Items over max_copper are left out.
    """
    by_item = {}
    for house in houses:
        for item_id, prices in house.items():
            by_item.setdefault(item_id, []).append(sorted(prices))

    ceilings = {}
    for item_id, per_house in by_item.items():
        counted = [prices for prices in per_house if len(prices) >= MIN_LISTINGS_PER_HOUSE]
        if len(counted) < MIN_HOUSES:
            continue
        house_figures = sorted(percentile(prices, PERCENTILE) for prices in counted)
        ceiling = house_figures[len(house_figures) // 2]
        if ceiling <= max_copper:
            ceilings[item_id] = ceiling
    return ceilings


def render_lua(ceilings, max_copper, house_count, generated, variants=None):
    lines = [
        "-- Generated by tools/build_auction_prices.py from the Blizzard auction house API.",
        "-- AuctionPriceCeiling: item id -> a ceiling for its auction house price, in copper:",
        "-- the median over houses of each house's 90th-percentile buyout. Items over %d copper are left out." % max_copper,
        "-- AuctionVariantCeiling: item id -> { bonus ids of a version -> its own ceiling }.",
        "-- An item listed there with no entry for your version gets no verdict.",
        "-- Generated %s from %d auction houses. Do not edit by hand." % (generated, house_count),
        "Bagwise = Bagwise or {}",
        "Bagwise.Data = Bagwise.Data or {}",
        "",
        "Bagwise.Data.AuctionPriceCeiling = {",
    ]
    lines += ["  [%d] = %d," % (item_id, ceilings[item_id]) for item_id in sorted(ceilings)]
    lines.append("}")
    lines += ["", "Bagwise.Data.AuctionVariantCeiling = {"]
    for item_id in sorted(variants or {}):
        versions = variants[item_id]
        parts = ", ".join('["%s"] = %d' % (key, versions[key]) for key in sorted(versions))
        lines.append("  [%d] = { %s }," % (item_id, parts))
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
        except (urllib.error.URLError, TimeoutError) as error:
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


def fetch_region(region, token):
    """Unit prices per auction house for one region."""
    headers = {"Authorization": "Bearer " + token}
    base = "https://%s.api.blizzard.com/data/wow/ruleset/%d/auctions" % (region, RULESET)
    namespace = "?namespace=dynamic-forever-" + region

    index = request(base + "/" + namespace, headers)
    if not index or "auctions" not in index:
        raise ApiError("%s: the auction index did not have an 'auctions' list. "
                       "The Forever endpoints may have changed." % region)
    house_ids = [entry["id"] for entry in index["auctions"] if "id" in entry]
    print("%s: %d auction houses" % (region, len(house_ids)))

    houses = []
    variant_houses = []
    for house_id in house_ids:
        detail = request("%s/%d%s" % (base, house_id, namespace), headers)
        auctions = (detail or {}).get("auctions")
        if not auctions:  # some houses have no auctions field
            print("  house %d: no auctions" % house_id)
            continue
        if RAW["item"]:
            collect_raw(auctions)
        prices = unit_prices(auctions)
        print("  house %d: %d auctions, %d items" % (house_id, len(auctions), len(prices)))
        houses.append(prices)
        variant_houses.append(variant_prices(auctions))
    return houses, variant_houses


def explain_item(houses, item_id, variant_houses=None):
    """Print what each auction house showed for one item, to see why it got its ceiling."""
    print("Item %d, per auction house (copper per unit):" % item_id)
    for number, house in enumerate(houses, 1):
        prices = sorted(house.get(item_id, []))
        if not prices:
            print("  house %2d: none" % number)
            continue
        print("  house %2d: %3d listings, min %d, median %d, p90 %d, max %d"
              % (number, len(prices), prices[0], percentile(prices, 0.5), percentile(prices, PERCENTILE), prices[-1]))
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


# ----- self test -----

def selftest():
    def house(prices_by_item):
        return {item: list(prices) * 3 for item, prices in prices_by_item.items()}  # 12 listings each

    steady = [house({1: [100, 120, 150, 90], 2: [100, 120, 150, 90], 3: [90000, 100000, 120000, 99000]})
              for _ in range(5)]
    result = price_ceilings(steady, 50000)
    assert sorted(result) == [1, 2], result          # item 3 is over the cap
    assert result[1] == 150

    # one pricey house does not set the ceiling, but pricey houses in the majority do
    mixed = [house({1: [100, 100, 100, 100]}) for _ in range(4)]
    mixed.append(house({1: [900, 1000, 1200, 990]}))
    assert price_ceilings(mixed, 50000)[1] == 100
    mostly = [house({1: [100, 100, 100, 100]}) for _ in range(2)]
    mostly += [house({1: [900, 1000, 1200, 990]}) for _ in range(3)]
    assert price_ceilings(mostly, 50000)[1] == 1200

    # a house with too few listings neither counts nor raises the ceiling
    thin = [house({1: [100, 100, 100, 100]}) for _ in range(4)]
    thin.append(house({1: [999999]}))
    assert price_ceilings(thin, 50000) == {1: 100}

    # too few houses, or houses with too few listings to count
    assert price_ceilings([house({1: [100, 100, 100, 100]}) for _ in range(3)], 50000) == {}
    assert price_ceilings([house({1: [100, 100, 100]}) for _ in range(4)], 50000) == {}  # 9 per house

    # the pricey end decides: one cheap variant cannot hide expensive ones
    variants = [house({1: [100, 100, 100, 5000]}) for _ in range(5)]
    assert price_ceilings(variants, 50000)[1] == 5000

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

    text = render_lua({9: 120, 3: 80}, 50000, 5, "2026-11-10", {5: {"12744": 800}})
    assert '[5] = { ["12744"] = 800 },' in text
    assert text.index("[3] = 80,") < text.index("[9] = 120,") and text.endswith("}\n")
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
    args = parser.parse_args()

    if args.selftest:
        selftest()
        return 0

    client_id = os.environ.get("BNET_CLIENT_ID")
    client_secret = os.environ.get("BNET_CLIENT_SECRET")
    if not client_id or not client_secret:
        print("Set BNET_CLIENT_ID and BNET_CLIENT_SECRET (a free client from develop.battle.net).")
        return 1

    if args.raw:
        RAW["item"] = args.raw
        args.regions = args.regions.split(",")[0]  # one region is enough to look at fields
    try:
        token = get_token(client_id, client_secret)
        houses = []
        variant_houses = []
        for region in [r.strip() for r in args.regions.split(",") if r.strip()]:
            region_houses, region_variants = fetch_region(region, token)
            houses += region_houses
            variant_houses += region_variants
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

    items = price_ceilings(houses, args.max_copper)
    variants = variant_ceilings(variant_houses, items, args.max_copper)
    if not items:
        print("Stopped, nothing written: no item had enough listings. The thresholds or the data are off.")
        return 1

    with open(args.output, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(render_lua(items, args.max_copper, len(houses), time.strftime("%Y-%m-%d", time.gmtime()), variants))
    print("Wrote %d items and %d version prices from %d auction houses to %s"
          % (len(items), sum(len(v) for v in variants.values()), len(houses), args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
