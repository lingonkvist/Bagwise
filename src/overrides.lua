-- Bagwise: user override lists
-- Manages the keep-list and flag-list in SavedVariables (per character).
-- Keep and flag are mutually exclusive: setting one clears the other.

Bagwise = Bagwise or {}
Bagwise.Overrides = {}

function Bagwise.Overrides.IsKept(itemID)
    return BagwiseDB and BagwiseDB.keepList[itemID] and true or false
end

function Bagwise.Overrides.IsFlagged(itemID)
    return BagwiseDB and BagwiseDB.flagList[itemID] and true or false
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

--- Remove an item from both lists, returning it to the normal rules.
-- @return boolean  true if the item was on either list
function Bagwise.Overrides.Remove(itemID)
    if not BagwiseDB then return false end
    local wasListed = BagwiseDB.keepList[itemID] ~= nil
        or BagwiseDB.flagList[itemID] ~= nil
    BagwiseDB.keepList[itemID] = nil
    BagwiseDB.flagList[itemID] = nil
    return wasListed
end
