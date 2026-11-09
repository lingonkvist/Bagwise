-- Items the game data cannot tell us are in use.
--
-- Hand-kept. Each entry is an item with a real use that no recipe, quest or
-- reagent table records: new Forever mechanics, camp objects and the like.
-- Safety never lets a rule call these safe to delete, and the tooltip shows
-- the note so the dot's silence is explained. Add an entry when the trade
-- goods audit (tools/audit_trade_goods.py) turns up something that is used.

Bagwise      = Bagwise or {}
Bagwise.Data = Bagwise.Data or {}

Bagwise.Data.ProtectedItems = {
  -- Herbalism camp items (Forever): the Greenhouse (Herbalism 140) grows herbs
  -- from seeds, the Seed Hybridizer (Herbalism 300) combines seeds into the
  -- next tier. Both are placed beside a campfire.
  [268415] = "Plant in a Herbalism Greenhouse, or combine in a Seed Hybridizer", -- Commonplace Herb Seeds
  [268416] = "Plant in a Herbalism Greenhouse, or combine in a Seed Hybridizer", -- Uncommon Herb Seeds
  [268417] = "Plant in a Herbalism Greenhouse, or combine in a Seed Hybridizer", -- Unusual Herb Seeds
  [268418] = "Plant in a Herbalism Greenhouse (camp item)", -- Scarce Herb Seeds
  -- Found by the trade goods audit
  [11099] = "Smelts into Dark Iron Bars at the Black Forge", -- Dark Iron Ore
  [273295] = "Forever seasonal item, use unknown", -- Seasonal Fish Steaks
}
