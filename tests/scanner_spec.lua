-- Bagwise: scanner smoke tests against a fake client.
-- The scanner talks to the game, so these stub the few calls it makes and
-- check the parts that decide things: free slots, stacking loot, openables.

_G.Bagwise = nil
dofile("src/bags.lua")
dofile("src/safety.lua")
dofile("src/progress.lua")
dofile("src/notes.lua")
dofile("src/verdict.lua")
dofile("src/bank.lua")
dofile("src/makeroom.lua")
Bagwise.Data = { ReagentProfessions = {}, VendorReagents = {}, ClassReagents = {}, QuestItems = {}, QuestInfo = {} }
Bagwise.Overrides = { IsKept = function() return false end, IsFlagged = function() return false end }

-- id -> { name, quality, ilvl, req, maxStack, equipSlot, sell, class, subclass }
local ITEMS = {
  [100] = { "Wolf Meat", 1, 5, 0, 20, "", 4, 7, 8 },
  [200] = { "Small Clam", 1, 10, 0, 1, "", 15, 7, 9 },
  [300] = { "Torn Rag", 0, 1, 0, 1, "", 2, 15, 0 },
  [400] = { "Fine Rag", 0, 1, 0, 1, "", 9, 15, 0 },
  [500] = { "Shiny Thing", 1, 1, 0, 1, "", 50, 15, 0 },
  [600] = { "Odd Trinket", 0, 1, 0, 1, "", 500, 15, 0 },
  [700] = { "Odd Bauble", 0, 1, 0, 1, "", 800, 15, 0 },
  [800] = { "Recipe: Fancy Elixir", 1, 1, 0, 1, "", 100, 9, 6 },
  [1100] = { "Healing Draught", 1, 1, 1, 5, "", 10, 0, 1 }, -- potion
  [1003] = { "Spent Token", 1, 1, 0, 1, "", 5, 12, 0 },   -- quest item, 5c
  [1004] = { "Gray Totem", 0, 1, 0, 1, "", 5, 15, 0 },    -- gray, 5c
  [1001] = { "Strange Mineral", 1, 1, 0, 20, "", 0, 7, 7 }, -- white, no vendor price
  [1002] = { "Broken Fang", 0, 1, 0, 1, "", 0, 15, 0 },     -- gray, no vendor price
  [1000] = { "Odd Scroll", 1, 1, 0, 1, "", 0, 12, 0 }, -- a quest item: no vendor price
  [903] = { "Green Cloak", 2, 20, 10, 1, "INVTYPE_CLOAK", 20, 4, 1 }, -- sells for 20c
  [900] = { "Old Blue Chest", 3, 10, 10, 1, "INVTYPE_CHEST", 300, 4, 1 },
  [901] = { "Worn White Chest", 1, 30, 20, 1, "INVTYPE_CHEST", 100, 4, 1 },
  [902] = { "Worn Blue Chest", 3, 40, 30, 1, "INVTYPE_CHEST", 900, 4, 1 },
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
    if type(id) == "string" then id = tonumber(id:match("item:(%d+)")) end
    local it = ITEMS[id]
    if not it then return nil end
    return it[1], "link", it[2], it[3], it[4], "", "", it[5], it[6], "", it[7], it[8], it[9], 0
  end
  _G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot)
      local cell = bags[bag] and bags[bag][slot]
      if not cell then return nil end
      return { itemID = cell.id, stackCount = cell.count or 1, isBound = cell.bound or false, hasLoot = cell.opens }
    end,
    GetContainerItemQuestInfo = function() return nil end,
    GetContainerNumFreeSlots = function(bag) return freeByBag[bag] or 0, 0 end,
  }
  _G.GetNumLootItems = function() return #loot end
  _G.GetLootSlotLink = function(slot) return "|Hitem:" .. loot[slot].id .. "|h" end
  _G.GetLootSlotInfo = function(slot) return nil, nil, loot[slot].qty end
  dofile("src/live.lua")
  dofile("src/scanner.lua")
end

describe("Scanner: openable items", function()
  it("gives a clam that opens for loot a yellow, never a green", function()
    setUp({ [0] = { { id = 200, opens = true }, { id = 200, opens = false } } }, {})
    Bagwise.Scanner.ScanAll()
    local clam = Bagwise.Scanner.GetResult(0, 1)
    assert.are.equal("yellow", clam.verdict)
    assert.are.equal("Open it, the contents may stack", clam.reason)
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

  it("knows whether a loot window has anything in it", function()
    setUp({ [0] = { { id = 300 } } }, { [0] = 0 }, { { id = 500, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    assert.are.equal(true, Bagwise.Scanner.HasLoot())
    Bagwise.Scanner.ClearLoot()
    assert.are.equal(false, Bagwise.Scanner.HasLoot())
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

describe("Scanner: reagents in the loot window", function()
  local function giveCooking(rank)
    _G.GetNumSkillLines = function() return 2 end
    _G.GetSkillLineInfo = function(i)
      if i == 1 then return "Professions", true, true end
      return "Cooking", false, nil, rank
    end
  end
  local function lootDecisionFor(itemID, rank)
    setUp({ [0] = { { id = 700 } } }, { [0] = 0 }, { { id = itemID, qty = 3 } }) -- one junk: 8s
    giveCooking(rank)
    Bagwise.Data.ReagentChains = {}
    Bagwise.Data.ReagentProfessions = { [100] = { { "Cooking", 5, 1, 100 } }, [1001] = { { "Cooking", 5, 1, 100 } } }
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    return Bagwise.Scanner.LootDecision(1)
  end

  it("skips an outleveled reagent that is worth less than your junk", function()
    assert.are.equal("leave", lootDecisionFor(100, 300))
  end)

  it("skips a reagent still in use when it is worth less than your junk", function()
    assert.are.equal("leave", lootDecisionFor(100, 50))
  end)

  it("still takes a reagent with no price, since a price cannot judge it", function()
    assert.are.equal("consider", lootDecisionFor(1001, 50))
  end)
end)

describe("Scanner: robustness", function()
  it("scans a quest-starting item on a client with no quest title function", function()
    setUp({ [0] = { { id = 300 }, { id = 400 } } }, {})
    _G.C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
    _G.C_Container.GetContainerItemQuestInfo = function(bag, slot)
      if slot == 1 then return { questID = 77 } end
    end
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.LastError())
    assert.is_truthy(Bagwise.Scanner.GetResult(0, 2))
  end)

  it("one item that raises an error does not take the other dots with it", function()
    setUp({ [0] = { { id = 300 }, { id = 400 } } }, {})
    local real = _G.C_Container.GetContainerItemInfo
    _G.C_Container.GetContainerItemInfo = function(bag, slot)
      if slot == 1 then error("boom") end
      return real(bag, slot)
    end
    Bagwise.Scanner.ScanAll()
    assert.is_truthy(Bagwise.Scanner.LastError():find("boom", 1, true))
    assert.is_truthy(Bagwise.Scanner.GetResult(0, 2))
  end)
end)

describe("Scanner: looted slots", function()
  it("leaves a just-looted slot out of the loot list", function()
    setUp({ [0] = { { id = 100, count = 20 }, { id = 300 } } }, { [0] = 0 },
      { { id = 100, qty = 3 }, { id = 500, qty = 1 } })
    Bagwise.Scanner.RefreshLoot(2)
    assert.are.equal(1, Bagwise.Scanner.MakeRoomSummary().lootItems)
  end)

  it("a looted slot is told neither to take nor to leave", function()
    setUp({ [0] = { { id = 300 }, { id = 300 } } }, { [0] = 0 },
      { { id = 500, qty = 1 }, { id = 500, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.is_truthy(Bagwise.Scanner.LootDecision(1))
    Bagwise.Scanner.RefreshLoot(1)
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.LootDecision(1))
    assert.is_truthy(Bagwise.Scanner.LootDecision(2))
  end)
end)

describe("Scanner: grays worth some silver", function()
  it("warns yellow on the cheapest gray when even it is worth real money", function()
    setUp({ [0] = { { id = 600 }, { id = 700 } } }, { [0] = 0 })
    Bagwise.Scanner.ScanAll()
    local cheapest, dearer = Bagwise.Scanner.GetResult(0, 1), Bagwise.Scanner.GetResult(0, 2)
    assert.are.equal("yellow", cheapest.verdict)
    assert.are.equal("Cheapest gray, but worth 5s", cheapest.reason)
    assert.is_nil(dearer.verdict)
  end)

  it("lets a cheap green gray win over a gray worth silver", function()
    setUp({ [0] = { { id = 600 }, { id = 300 } } }, { [0] = 0 })
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.GetResult(0, 1).verdict)
    assert.are.equal("green", Bagwise.Scanner.GetResult(0, 2).verdict)
  end)
end)

describe("Scanner: recipes", function()
  local function giveSkills(lines)
    _G.GetNumSkillLines = function() return #lines + 1 end
    _G.GetSkillLineInfo = function(i)
      if i == 1 then return "Professions", true, true end
      local line = lines[i - 1]
      return line[1], false, nil, line[2]
    end
  end
  local function giveTooltip(text)
    _G.ITEM_MIN_SKILL = "Requires %s (%d)"
    _G.UIParent = {}
    _G.BagwiseSkillTipTextLeft2 = { GetText = function() return text end }
    _G.CreateFrame = function()
      return {
        SetOwner = function() end, ClearLines = function() end,
        SetBagItem = function() end, NumLines = function() return 2 end,
      }
    end
  end

  it("reads the skill a recipe needs from its tooltip and banks one that is far off", function()
    setUp({ [0] = { { id = 800 } } }, { [0] = 0 })
    giveSkills({ { "Alchemy", 100 } })
    giveTooltip("Requires Alchemy (225)")
    Bagwise.Scanner.ScanAll()
    local result = Bagwise.Scanner.GetResult(0, 1)
    assert.are.equal("yellow", result.verdict)
    assert.are.equal("Bank it, needs Alchemy 225", result.reason)
  end)

  it("finds secondary professions the modern API leaves out", function()
    setUp({ [0] = { { id = 800 } } }, { [0] = 0 })
    -- GetProfessions knows cooking, but not first aid, which the Skills tab has.
    _G.GetProfessions = function() return nil, nil, nil, nil, 1 end
    _G.GetProfessionInfo = function() return "Cooking", 0, 40, 75, 0, 0, 185 end
    giveSkills({ { "Cooking", 40 }, { "First Aid", 120 } })
    giveTooltip("Requires Cooking (200)")
    Bagwise.Scanner.ScanAll()
    local summary = Bagwise.Scanner.ProfessionSummary()
    assert.is_truthy(summary:find("Cooking 40", 1, true))
    assert.is_truthy(summary:find("First Aid 120", 1, true))
    _G.GetProfessions = nil
  end)

  it("stays quiet when the skill is already enough", function()
    setUp({ [0] = { { id = 800 } } }, { [0] = 0 })
    giveSkills({ { "Alchemy", 125 } })
    giveTooltip("Requires Alchemy (125)")
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.GetResult(0, 1).verdict)
  end)

  it("banks a recipe one point out of reach once the profession has gone idle", function()
    local saved = _G.BagwiseDB
    _G.BagwiseDB = { skillProgress = { ["?-?"] = { Alchemy = { rank = 100, quiet = 1, seen = 0, gained = 0 } } } }
    Bagwise.Progress.ResetSession()
    setUp({ [0] = { { id = 800 } } }, { [0] = 0 })
    giveSkills({ { "Alchemy", 100 } })
    giveTooltip("Requires Alchemy (101)")
    Bagwise.Scanner.ScanAll()
    local result = Bagwise.Scanner.GetResult(0, 1)
    _G.BagwiseDB = saved
    assert.are.equal("yellow", result.verdict)
    assert.are.equal("Bank it, needs Alchemy 101", result.reason)
  end)

  it("forgets the history of a profession you no longer have, and shows idle in the summary", function()
    local saved = _G.BagwiseDB
    _G.BagwiseDB = { skillProgress = { ["?-?"] = {
      Alchemy = { rank = 100, quiet = 1, seen = 0, gained = 0 },
      Tailoring = { rank = 50, quiet = 1, seen = 0, gained = 0 },
    } } }
    Bagwise.Progress.ResetSession()
    setUp({ [0] = {} }, { [0] = 0 })
    giveSkills({ { "Alchemy", 100 } })
    Bagwise.Scanner.ScanAll()
    local store = _G.BagwiseDB.skillProgress["?-?"]
    local summary = Bagwise.Scanner.ProfessionSummary()
    _G.BagwiseDB = saved
    assert.is_nil(store.Tailoring)
    assert.is_truthy(summary:find("Alchemy 100 idle", 1, true))
  end)

  it("says a recipe is for another profession when you do not have it", function()
    setUp({ [0] = { { id = 800 } } }, { [0] = 0 })
    giveSkills({ { "Mining", 50 } })
    giveTooltip("Requires Alchemy (125)")
    Bagwise.Scanner.ScanAll()
    local result = Bagwise.Scanner.GetResult(0, 1)
    assert.are.equal("yellow", result.verdict)
    assert.is_truthy(result.reason:find("You don't have this profession", 1, true))
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

describe("Scanner: repeatable quests", function()
  local function withQuest(repeatable)
    setUp({ [0] = { { id = 500 } } }, {})
    _G.C_QuestLog.IsQuestFlaggedCompleted = function() return true end
    Bagwise.Data.QuestItems = { [500] = { 55 } }
    Bagwise.Data.RepeatableQuests = repeatable and { [55] = true } or nil
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
  end

  it("a finished one-time quest still counts as done", function()
    withQuest(false)
    assert.are.equal(true, Bagwise.Scanner.Explain(500).quests[1].done)
    Bagwise.Data.QuestItems = {}
  end)

  it("a finished repeatable quest never counts as done, so its items are kept", function()
    withQuest(true)
    assert.are.equal(false, Bagwise.Scanner.Explain(500).quests[1].done)
    local result = Bagwise.Scanner.GetResult(0, 1)
    assert.is_truthy(not result or result.verdict ~= "green")
    Bagwise.Data.QuestItems = {}
    Bagwise.Data.RepeatableQuests = nil
  end)
end)


describe("Scanner: low level gear that could be an upgrade", function()
  -- A level 40 character carrying a bound blue chest from level 10. wornChest
  -- is the item ID in the chest slot, or nil for an empty slot.
  local function scanWith(wornChest)
    setUp({ [0] = { { id = 900, bound = true } } }, {})
    _G.UnitLevel = function() return 40 end
    _G.GetInventoryItemLink = function(_, slot)
      if slot == 5 then return wornChest end
      return nil
    end
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
    return Bagwise.Scanner.GetResult(0, 1)
  end

  it("gives no verdict while the chest slot is empty", function()
    local result = scanWith(nil)
    assert.is_truthy(not result or result.verdict == nil)
  end)

  it("gives no verdict when a white chest is worn, however old the blue is", function()
    local result = scanWith(901)
    assert.is_truthy(not result or result.verdict == nil)
  end)

  it("hints it is low level when the worn chest is better in rarity and item level", function()
    local result = scanWith(902)
    assert.is_truthy(result)
    assert.are.equal("yellow", result.verdict)
  end)
end)


describe("Scanner: the bank", function()
  -- Bag 5 is a bank bag here (4 bags carried, no reagent bag); -1 is the bank itself.
  local function scanWithBank(carried, bank)
    local layout = { [0] = carried }
    for bag, cells in pairs(bank) do layout[bag] = cells end
    setUp(layout, {})
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
  end

  it("paints bank items with the verdict that fits the bank", function()
    scanWithBank({ { id = 300 } }, { [5] = { { id = 300 } } })
    -- A gray is worthless whoever you play, so it keeps its verdict in the bank.
    assert.are.equal("green", Bagwise.Scanner.GetResult(0, 1).verdict)
    assert.are.equal("green", Bagwise.Scanner.GetResult(5, 1).verdict)
  end)

  it("counts only what you carry in the status numbers", function()
    scanWithBank({ { id = 300 } }, { [5] = { { id = 300 }, { id = 300 } } })
    assert.are.equal(1, Bagwise.Scanner.Counts().items)
  end)

  it("recognises carried and bank bag IDs, and nothing else", function()
    assert.is_truthy(Bagwise.Bags.IsScanned(0))
    assert.is_truthy(Bagwise.Bags.IsScanned(5))
    assert.is_truthy(not Bagwise.Bags.IsScanned(-1)) -- the keyring on Forever
    assert.is_truthy(not Bagwise.Bags.IsScanned(-2))
    assert.is_truthy(not Bagwise.Bags.IsScanned(nil))
    assert.is_truthy(not Bagwise.Bags.IsScanned(400))
  end)
end)

describe("Scanner: make room with only a pricey gray in the bags", function()
  -- Odd Bauble (700) is a gray that sells for 8s: yellow, "worth some".
  -- Shiny Thing (500) is a white that sells for 50c. Odd Trinket (600) is a
  -- gray that sells for 5s.
  local function scanFull(lootID)
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = lootID, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
  end

  it("glows the gray when the loot is worth more than it", function()
    setUp({ [0] = { { id = 600 }, { id = 100 } } }, { [0] = 0 }, { { id = 700, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    local gray = Bagwise.Scanner.GetResult(0, 1)
    assert.are.equal(true, gray.glow)
    assert.is_truthy(not gray.quiet)
    assert.are.equal("take", Bagwise.Scanner.LootDecision(1))
    assert.are.equal("Odd Trinket", Bagwise.Scanner.MakeRoomSummary().deleteNames[1])
  end)

  it("glows the gray for loot that must be taken, however little the gray is worth", function()
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = 1000, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 1).glow)
    assert.are.equal("consider", Bagwise.Scanner.LootDecision(1))
  end)

  it("takes loot with no vendor price: it may be worth more elsewhere", function()
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = 1001, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal("consider", Bagwise.Scanner.LootDecision(1))
  end)

  it("a gray with no vendor price is just junk, not must-take", function()
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = 1002, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal("leave", Bagwise.Scanner.LootDecision(1))
  end)

  it("must-take loot with nothing to delete is no-room, not not-needed", function()
    setUp({ [0] = { { id = 903 }, { id = 902 } } }, { [0] = 0 }, { { id = 1000, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal("noroom", Bagwise.Scanner.LootDecision(1))
    assert.are.equal(1, Bagwise.Scanner.MakeRoomSummary().noRoom)
  end)

  local function lootDecisionWith(itemID, questID, finished)
    Bagwise.Data.QuestItems = { [itemID] = { questID } }
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = itemID, qty = 1 } })
    _G.C_QuestLog.IsQuestFlaggedCompleted = function() return finished end
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    local decision = Bagwise.Scanner.LootDecision(1)
    Bagwise.Data.QuestItems = {}
    return decision
  end

  it("takes a quest item while its quest is open", function()
    assert.are.equal("consider", lootDecisionWith(1003, 77, false))
  end)

  it("a quest item for a finished quest is only worth its price", function()
    assert.are.equal("leave", lootDecisionWith(1003, 77, true))
  end)

  it("takes even a gray while an open quest wants it", function()
    assert.are.equal("consider", lootDecisionWith(1004, 78, false))
  end)

  it("leaves the loot, keeps the dots, and names the junk it lost to", function()
    scanFull(500)
    local summary = Bagwise.Scanner.MakeRoomSummary()
    assert.are.equal(true, summary.active)
    assert.are.equal(0, summary.deletes)
    assert.are.equal(1, summary.leaving)
    assert.are.equal("Odd Bauble", summary.cheapestJunkName)
    assert.are.equal(800, summary.cheapestJunkValue)
    assert.are.equal("leave", Bagwise.Scanner.LootDecision(1))
    local gray = Bagwise.Scanner.GetResult(0, 1)
    assert.is_nil(gray.glow)
    assert.is_truthy(not gray.quiet)
    assert.are.equal("yellow", gray.verdict)
  end)

  it("always takes green gear, even when it sells for less than the junk", function()
    setUp({ [0] = { { id = 700 }, { id = 100 } } }, { [0] = 0 }, { { id = 903, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal("consider", Bagwise.Scanner.LootDecision(1))
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 1).glow)
  end)
end)

describe("Scanner: potions outleveled", function()
  local function giveTooltipLine(text)
    _G.UIParent = {}
    _G.BagwiseSkillTipTextLeft2 = { GetText = function() return text end }
    _G.CreateFrame = function()
      return {
        SetOwner = function() end, ClearLines = function() end,
        SetBagItem = function() end, NumLines = function() return 2 end,
      }
    end
  end

  local function resultFor(line)
    setUp({ [0] = { { id = 1100 } } }, { [0] = 0 })
    _G.UnitLevel = function() return 40 end
    giveTooltipLine(line)
    Bagwise.Scanner.ScanAll()
    return Bagwise.Scanner.GetResult(0, 1)
  end

  it("flags a healing potion made for a much lower level", function()
    assert.are.equal("yellow", resultFor("Use: Restores 40 to 60 health.").verdict)
  end)

  it("leaves a utility potion alone", function()
    assert.is_nil(resultFor("Use: Increases swim speed by 50% for 30 sec.").verdict)
  end)

  it("tells a warrior that a drink is no use to them", function()
    local result = resultFor("Use: Restores 835 mana over 30 sec. Must remain seated while drinking.")
    assert.are.equal("yellow", result.verdict)
    assert.is_truthy(result.reason:find("have no mana", 1, true))
  end)

  it("does not call something that also heals a drink", function()
    local result = resultFor("Use: Restores 400 health and 400 mana.")
    assert.is_truthy(not (result.reason or ""):find("have no mana", 1, true))
  end)
end)

describe("Scanner: deleting while the loot window is open", function()
  it("moves the mark to the next cheapest junk after the marked one is deleted", function()
    setUp({ [0] = { { id = 300 }, { id = 400 }, { id = 100, count = 20 } } }, { [0] = 0 },
      { { id = 500, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 1).glow) -- the cheapest, Torn Rag
    assert.is_nil(Bagwise.Scanner.GetResult(0, 2).glow)

    -- The player deletes it, then takes nothing yet: the slot is empty, and
    -- the loot still has no room because the stack there is full.
    bags[0][1] = false
    freeByBag[0] = 1
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.GetResult(0, 1))
    assert.are.equal(false, Bagwise.Scanner.MakeRoomSummary().active) -- one free slot now fits the loot
  end)

  it("marks the next cheapest when two pieces of loot need room and one slot is freed", function()
    setUp({ [0] = { { id = 300 }, { id = 400 }, { id = 100, count = 20 } } }, { [0] = 0 },
      { { id = 500, qty = 1 }, { id = 500, qty = 1 } })
    Bagwise.Scanner.RefreshLoot()
    Bagwise.Scanner.ScanAll()
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 1).glow)
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 2).glow)

    bags[0][1] = false
    freeByBag[0] = 1
    Bagwise.Scanner.ScanAll()
    assert.is_nil(Bagwise.Scanner.GetResult(0, 1))
    assert.are.equal(true, Bagwise.Scanner.GetResult(0, 2).glow)
    assert.is_nil(Bagwise.Scanner.GetResult(0, 3) and Bagwise.Scanner.GetResult(0, 3).glow)
  end)
end)
