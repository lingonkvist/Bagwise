-- The entry point's loot handling: a loot window with no items (gold) must not
-- cost a full bag scan, and one with items must still get one.

local handlers, scans, lootUpdates, hasLoot

local function loadEntry()
  scans, lootUpdates, hasLoot = 0, 0, false
  handlers = nil
  _G.CreateFrame = function()
    return {
      RegisterEvent = function() end,
      UnregisterEvent = function() end,
      SetScript = function(_, name, fn) if name == "OnEvent" then handlers = fn end end,
    }
  end
  _G.C_Timer = nil
  _G.OpenAllBags, _G.CloseAllBags = nil, nil
  _G.MakeSpaceDB = nil
  _G.MakeSpace = {
    Bags = {},
    Scanner = {
      ScanAll = function() scans = scans + 1 end,
      ClearCache = function() end,
      HasLoot = function() return hasLoot end,
      RefreshLoot = function() end,
      ClearLoot = function() hasLoot = false end,
      MakeRoomSummary = function() return { active = false } end,
    },
    Overlay = {
      UpdateAll = function() end,
      UpdateLoot = function() lootUpdates = lootUpdates + 1 end,
      SetVendorOpen = function() end,
    },
  }
  dofile("MakeSpace.lua")
end

local function fire(event, ...) handlers(nil, event, ...) end

describe("Entry point: loot events", function()
  it("does not scan the bags for a window with no items", function()
    loadEntry()
    fire("LOOT_OPENED")
    fire("LOOT_SLOT_CLEARED", 1)
    fire("LOOT_CLOSED")
    assert.are.equal(0, scans)
    assert.are.equal(0, lootUpdates)
  end)

  it("scans when the window opens with items in it", function()
    loadEntry()
    _G.MakeSpace.Scanner.RefreshLoot = function() hasLoot = true end
    fire("LOOT_OPENED")
    assert.are.equal(1, scans)
  end)

  it("scans when the last item is taken, so the plan is taken down", function()
    loadEntry()
    hasLoot = true
    _G.MakeSpace.Scanner.RefreshLoot = function() hasLoot = false end
    fire("LOOT_SLOT_CLEARED", 1)
    assert.are.equal(1, scans)
  end)

  it("scans when the window closes with items left, and not otherwise", function()
    loadEntry()
    hasLoot = true
    fire("LOOT_CLOSED")
    assert.are.equal(1, scans)
    assert.are.equal(1, lootUpdates)
    fire("LOOT_CLOSED")
    assert.are.equal(1, scans)
  end)
end)
