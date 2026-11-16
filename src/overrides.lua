-- MakeSpace: your own marks on items
-- One choice per item, kept for the whole account (MakeSpaceAccountDB.marks):
--   "green"  always a green dot, "safe to delete"
--   "yellow" always a yellow dot, "worth a glance"
--   "none"   never a dot
-- An item with no mark follows the normal rules.

MakeSpace = MakeSpace or {}
MakeSpace.Overrides = {}

MakeSpace.Overrides.MARKS = { green = true, yellow = true, none = true }

local function markTable()
    return MakeSpaceAccountDB and MakeSpaceAccountDB.marks
end

--- The mark on an item: "green", "yellow", "none", or nil for the normal rules.
function MakeSpace.Overrides.Get(itemID)
    local entries = markTable()
    local entry = entries and entries[itemID]
    return entry and entry.mark or nil
end

function MakeSpace.Overrides.IsKept(itemID)
    return MakeSpace.Overrides.Get(itemID) == "none"
end

function MakeSpace.Overrides.IsFlagged(itemID)
    return MakeSpace.Overrides.Get(itemID) == "yellow"
end

function MakeSpace.Overrides.IsMarkedGreen(itemID)
    return MakeSpace.Overrides.Get(itemID) == "green"
end

--- Set an item's mark. A nil mark (or "default") goes back to the normal rules.
-- @param itemName string|nil  stored so /makespace list can show it
-- @return boolean  true if the mark changed
function MakeSpace.Overrides.Set(itemID, mark, itemName)
    local entries = markTable()
    if not entries then return false end
    if mark == "default" then mark = nil end
    if mark ~= nil and not MakeSpace.Overrides.MARKS[mark] then return false end
    local before = entries[itemID] and entries[itemID].mark or nil
    if mark == nil then
        entries[itemID] = nil
    else
        local previous = entries[itemID]
        entries[itemID] = { mark = mark, name = itemName or (previous and previous.name) }
    end
    return before ~= mark
end

--- The normal rules again for this item.
-- @return boolean  true if the item had a mark
function MakeSpace.Overrides.Remove(itemID)
    return MakeSpace.Overrides.Set(itemID, nil)
end

function MakeSpace.Overrides.AddKeep(itemID, itemName)
    MakeSpace.Overrides.Set(itemID, "none", itemName)
end

function MakeSpace.Overrides.AddFlag(itemID, itemName)
    MakeSpace.Overrides.Set(itemID, "yellow", itemName)
end

--- Every marked item as { itemID, mark, name }, for /makespace list.
function MakeSpace.Overrides.All()
    local list = {}
    for itemID, entry in pairs(markTable() or {}) do
        list[#list + 1] = { itemID = itemID, mark = entry.mark, name = entry.name }
    end
    return list
end

--- How many items carry each mark.
function MakeSpace.Overrides.Counts()
    local counts = { green = 0, yellow = 0, none = 0 }
    for _, entry in pairs(markTable() or {}) do
        if counts[entry.mark] then counts[entry.mark] = counts[entry.mark] + 1 end
    end
    return counts
end
