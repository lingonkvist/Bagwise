-- Bagwise: user override lists
-- Manages the keep-list and flag-list in SavedVariables.

Bagwise = Bagwise or {}
Bagwise.Overrides = {}

function Bagwise.Overrides.IsKept(itemID)
    return BagwiseDB and BagwiseDB.keepList[itemID] or false
end

function Bagwise.Overrides.IsFlagged(itemID)
    return BagwiseDB and BagwiseDB.flagList[itemID] or false
end

function Bagwise.Overrides.AddKeep(itemID, itemName)
    if not BagwiseDB then return end
    BagwiseDB.keepList[itemID] = itemName or true
    BagwiseDB.flagList[itemID] = nil  -- keep overrides flag
end

function Bagwise.Overrides.AddFlag(itemID, itemName)
    if not BagwiseDB then return end
    BagwiseDB.flagList[itemID] = itemName or true
    BagwiseDB.keepList[itemID] = nil  -- flag overrides keep
end
