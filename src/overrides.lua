-- MakeSpace: user override lists
-- Manages the keep-list and flag-list in SavedVariables (per character).
-- Keep and flag are mutually exclusive: setting one clears the other.

MakeSpace = MakeSpace or {}
MakeSpace.Overrides = {}

function MakeSpace.Overrides.IsKept(itemID)
    return MakeSpaceDB and MakeSpaceDB.keepList[itemID] and true or false
end

function MakeSpace.Overrides.IsFlagged(itemID)
    return MakeSpaceDB and MakeSpaceDB.flagList[itemID] and true or false
end

function MakeSpace.Overrides.AddKeep(itemID, itemName)
    if not MakeSpaceDB then return end
    MakeSpaceDB.keepList[itemID] = itemName or true
    MakeSpaceDB.flagList[itemID] = nil  -- keep overrides flag
end

function MakeSpace.Overrides.AddFlag(itemID, itemName)
    if not MakeSpaceDB then return end
    MakeSpaceDB.flagList[itemID] = itemName or true
    MakeSpaceDB.keepList[itemID] = nil  -- flag overrides keep
end

--- Copy a player's lists and settings over from the old addon's saved data
-- (the addon was called Bagwise before 0.6.6). Only fills in what is missing.
-- @return boolean  true if anything was copied
function MakeSpace.Overrides.ImportOld(old, new)
    if type(old) ~= "table" or type(new) ~= "table" then return false end
    local copied = false
    for _, listName in ipairs({ "keepList", "flagList" }) do
        if type(old[listName]) == "table" then
            new[listName] = new[listName] or {}
            for itemID, value in pairs(old[listName]) do
                new[listName][itemID] = value
                copied = true
            end
        end
    end
    if type(old.autoOpenBags) == "boolean" then
        new.autoOpenBags = old.autoOpenBags
        copied = true
    end
    return copied
end

--- Remove an item from both lists, returning it to the normal rules.
-- @return boolean  true if the item was on either list
function MakeSpace.Overrides.Remove(itemID)
    if not MakeSpaceDB then return false end
    local wasListed = MakeSpaceDB.keepList[itemID] ~= nil
        or MakeSpaceDB.flagList[itemID] ~= nil
    MakeSpaceDB.keepList[itemID] = nil
    MakeSpaceDB.flagList[itemID] = nil
    return wasListed
end
