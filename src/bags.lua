-- Bagwise: which bags count
-- One place that knows how far the bag numbering goes, so the scanner, the
-- overlay and the tooltip never disagree.

Bagwise = Bagwise or {}
Bagwise.Bags = {}

--- The highest bag ID Bagwise scans.
-- Backpack is 0 and the equipped bags are 1 to NUM_BAG_SLOTS. Clients that
-- have a reagent bag (Forever, like Mainline) put it right after them.
-- Classic Era has no reagent bag slot, so this stays 4 there.
function Bagwise.Bags.LastScanned()
  local last = NUM_BAG_SLOTS or 4
  local reagentSlots = NUM_REAGENTBAG_SLOTS or 0
  if reagentSlots > 0 then last = last + reagentSlots end
  return last
end
