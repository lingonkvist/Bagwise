-- Bagwise: scanner smoke tests against a fake client.
-- The scanner talks to the game, so these stub the few calls it makes and
-- check the parts that decide things: free slots, stacking loot, openables.

_G.Bagwise = nil
dofile("src/bags.lua")
dofile("src/safety.lua")
dofile("src/verdict.lua")
dofile("src/makeroom.lua")
Bagwise.Data = { ReagentProfessions = {}, VendorReagents = {}, ClassReagents = {}, QuestItems = {}, QuestInfo = {} }
Bagwise.Overrides = { IsKept = function() return false end, IsFlagged = function() return false end }

-- id -> { name, quality, ilvl, req, maxStack, equipSlot, sell, class, subclass }
local ITEMS = {
  [100] = { "Wolf Meat", 1, 5, 0, 20, "", 4, 7, 8 },
  [200] = { "Small Clam", 1, 10, 0, 1, "", 15, 7, 11 },
  [300] = { "Torn Rag", 0, 1, 0, 1, "", 2, 15, 0 },
  [400] = { "Fine Rag", 0, 1, 0, 1, "", 9, 15, 0 },
  [500] = { "Shiny Thing", 1, 1, 0, 1, "", 50, 15, 0 },
}
local bags, freeByBag, loot

local function setUp(layout, free, lootWindow)
  bags, freeByBag, loot = layout, free, lootWindow or {}
  _G.NUM_BAG_SLOTS = 4
  _G.UnitClass = function() return "Warrior", "WARRIOR" end
  _G.UnitRace = function() return "Human" end
  _G.UnitLevel = function() return 20 end
  _G.UnitFactionGroup = function() return "Alliance" end
  _G.GetProfessions = nil
  _G.GetNumSkillLines = function() return 1 end
  _G.GetSkillLineInfo = function() return "Professions", true, true end
  _G.C_QuestLog = { IsQuestFlaggedCompleted = function() return false end, GetQuestInfo = function() end }
  _G.GetInventoryItemLink = function() return nil end
  _G.GetItemInfo = function(id)
    local it = ITEMS[id]
    if not it then return nil end
    return it[1], "link", it[2], it[3], it[4], "", "", it[5], it[6], "", it[7], it[8], it[9], 0
  end
  _G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot)
      local cell = bags[bag] and bags[bag][slot]
      if not cell then return nil end
      return { itemID = cell.id, stackCount = cell.count or 1, isBound = false, hasLoot = cell.opens }
    end,
    GetContainerItemQuestInfo = function() return nil end,
    GetContainerNumFreeSlots = function(bag) return freeByBag[bag] or 0, 0 end,
  }
  _G.GetNumLootItems = function() return #loot end
  _G.GetLootSlotLink = function(slot) return "|Hitem:" .. loot[slot].id .. "|h" end
  _G.GetLootSlotInfo = function(slot) return nil, nil, loot[slot].qty end
  dofile("src/scanner.lua")
end

describe("Scanner: openable items", function()
  it("gives a clam that opens for loot no verdict", function()
    setUp({ [0] = { { id = 200, opens = true }, { id = 200, opens = false } } }, {})
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.GetResult(0, 1).verdict)
    assert.are.equal("green", Bagwise.Scanner.GetResult(0, 2).verdict) -- no flag, no protection
  end)

  it("explains an item from the real bag slot when you carry one", function()
    setUp({ [0] = { { id = 200, opens = true } } }, {})
    local explained = Bagwise.Scanner.Explain(200)
    assert.are.equal(true, explained.fromBag)
    assert.are.equal("openable", explained.protections[1])
  end)
end)

describe("Scanner: make room", function()
  it("counts only empty slots in general bags as room", function()
    setUp({ [0] = { { id = 300 } } }, { [0] = 0, [1] = 3 })
    _G.C_Container.GetContainerNumFreeSlots = function(bag)
      if bag == 1 then return 3, 1 end -- a quiver: not room for loot
      return 0, 0
    end
    local loot = { { id = 500, qty = 1 } }
    setUp({ [0] = { { id = 300 } }, [1] = {} }, {}, loot)
    _G.C_Container.GetContainerNumFreeSlots = function(bag)
      if bag == 1 then return 3, 1 end
      return 0, 0
    end
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(0, Bagwise.Scanner.MakeRoomSummary().freeSlots)
    assert.are.equal(true, Bagwise.Scanner.MakeRoomSummary().active)
  end)

  it("does not ask for room when the loot joins a stack you carry", function()
    setUp({ [0] = { { id = 100, count = 5 } } }, { [0] = 0 }, { { id = 100, qty = 3 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(false, Bagwise.Scanner.MakeRoomSummary().active)
  end)

  it("asks for room when the stack is full, and marks the cheapest junk", function()
    setUp({ [0] = { { id = 100, count = 20 }, { id = 300 }, { id = 400 } } },
      { [0] = 0 }, { { id = 100, qty = 3 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(true, Bagwise.Scanner.MakeRoomSummary().active)
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 2).glow) -- Torn Rag sells for least
    assert.is_nil(Bagwise.Scanner.GetResult(0, 3).glow)
  end)
end)

describe("Scanner: professions", function()
  it("holds back profession-based greens when a Skills header is collapsed", function()
    setUp({ [0] = {} }, {})
    _G.GetSkillLineInfo = function() return "Professions", true, false end
    Bagwise.Scanner.ClearCache()
    local explained = Bagwise.Scanner.Explain(100)
    assert.are.equal(false, explained.professionsKnown)
  end)
end)
