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
  -- Herbalism Greenhouse and Seed Hybridizer (Forever camp objects)
  [268415] = "Herb seed, used in the Herbalism Greenhouse", -- Commonplace Herb Seeds
  [268416] = "Herb seed, used in the Herbalism Greenhouse", -- Uncommon Herb Seeds
  [268417] = "Herb seed, used in the Herbalism Greenhouse", -- Unusual Herb Seeds
  [268418] = "Herb seed, used in the Herbalism Greenhouse", -- Scarce Herb Seeds
  -- Found by the trade goods audit
  [11099] = "Smelts into Dark Iron Bars at the Black Forge", -- Dark Iron Ore
  [273295] = "Forever seasonal item, use unknown", -- Seasonal Fish Steaks
}
