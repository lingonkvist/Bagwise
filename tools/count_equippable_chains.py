"""
How much of reagent_chains.lua depends on a crafted piece of gear in the middle?

A chain passes through an item that one recipe makes and another consumes.
When that item is equippable (goggles, an upgrade ladder), the later recipe
needs the finished gear, not more of the original reagent. This script builds
the chains twice, once as shipped and once with every equippable product cut
out, and lists each reagent whose reach changes.

Usage:
  python3 tools/count_equippable_chains.py --build 1.60.1.70938 --cache /tmp/cache
Needs the cached or downloadable SpellReagents, SkillLineAbility, SkillLine,
SpellEffect and ItemSparse tables (the same ones build_reagent_professions.py uses).
"""
import argparse
import csv
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("builder", os.path.join(HERE, "build_reagent_professions.py"))
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


def equippable_ids(item_sparse_rows):
    """Items with a non-zero InventoryType (anything you can wear or wield)."""
    out = set()
    for row in item_sparse_rows:
        item_id = builder.int_or(builder.csv_get(row, "ID"))
        if item_id > 0 and builder.int_or(builder.csv_get(row, "InventoryType")) > 0:
            out.add(item_id)
    return out


def summarise(chains, names):
    """{itemID: {profession: highest learn level reached through chains}}"""
    out = {}
    for item_id, by_prof in chains.items():
        out[item_id] = {prof: max(e[1] for e in entries) for prof, entries in by_prof.items() if entries}
    return out


def compare(spell_reagents, abilities, prof_names, products, equippable, item_names):
    full = builder.build_chains(spell_reagents, abilities, prof_names, products)
    cut_products = {s: p for s, p in products.items() if p not in equippable}
    cut = builder.build_chains(spell_reagents, abilities, prof_names, cut_products)
    a, b = summarise(full, item_names), summarise(cut, item_names)
    changed = []
    for item_id in sorted(a):
        for prof, top in sorted(a[item_id].items()):
            now = b.get(item_id, {}).get(prof)
            if now != top:
                changed.append((item_id, item_names.get(item_id, "?"), prof, top, now))
    return len(full), changed


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--build", required=True)
    ap.add_argument("--cache", default=None)
    args = ap.parse_args()

    def table(name):
        return builder.fetch_csv_table(name, args.build, args.cache)

    spell_reagents = builder.parse_spell_reagents(table("SpellReagents"))
    abilities = builder.parse_skill_line_ability(table("SkillLineAbility"))
    prof_names = builder.parse_skill_line(table("SkillLine"))
    products = builder.parse_spell_products(table("SpellEffect"))
    sparse = table("ItemSparse")
    total, changed = compare(spell_reagents, abilities, prof_names, products,
                             equippable_ids(sparse), builder.parse_item_sparse(sparse))
    print(f"{total} reagents have chain entries; {len(changed)} (reagent, profession) uses change "
          f"when chains may not pass through gear:")
    for item_id, name, prof, before, after in changed:
        print(f"  {item_id:>6} {name}: {prof} chain reach {before} -> {after if after else 'none'}")


if __name__ == "__main__":
    main()
