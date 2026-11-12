-- Bagwise: bag range tests

dofile("src/bags.lua")

describe("Bags.LastScanned", function()
  it("is 4 on a client with no reagent bag (Classic Era)", function()
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_REAGENTBAG_SLOTS = nil

    assert.are.equal(4, Bagwise.Bags.LastScanned())
  end)

  it("includes the reagent bag when the client has one (Forever)", function()
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_REAGENTBAG_SLOTS = 1

    local last = Bagwise.Bags.LastScanned()
    _G.NUM_REAGENTBAG_SLOTS = nil

    assert.are.equal(5, last)
  end)

  it("falls back to 4 when the constants are missing", function()
    _G.NUM_BAG_SLOTS = nil
    _G.NUM_REAGENTBAG_SLOTS = nil

    assert.are.equal(4, Bagwise.Bags.LastScanned())
    _G.NUM_BAG_SLOTS = 4
  end)
end)

describe("Bank bag discovery", function()
  local saved = {}
  local function stash(...)
    for _, name in ipairs({ ... }) do saved[name] = _G[name] end
  end
  local function restore()
    for name, value in pairs(saved) do _G[name] = value end
    Bagwise.Bags.onNewBankBag = nil
  end

  it("uses the tab IDs the client reports, outside the assumed window", function()
    stash("NUM_BAG_SLOTS", "NUM_REAGENTBAG_SLOTS", "C_Container", "C_Bank", "Enum")
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_REAGENTBAG_SLOTS = 1
    _G.Enum = { BankType = { Character = 0, Account = 2 } }
    _G.C_Bank = {
      FetchPurchasedBankTabData = function(kind)
        if kind == 0 then return { { ID = 40 }, { ID = 41 } } end
        return {}
      end,
    }
    _G.C_Container = { GetContainerNumSlots = function(bag) return (bag == 40 or bag == 41) and 98 or 0 end }

    local ids = Bagwise.Bags.BankBags()
    assert.are.equal(2, #ids)
    assert.are.equal(40, ids[1])
    assert.is_truthy(Bagwise.Bags.IsBank(41))
    assert.is_truthy(Bagwise.Bags.IsScanned(40))
    restore()
  end)

  it("learns a tab ID from a bank button and asks for a rescan once", function()
    stash("NUM_BAG_SLOTS", "NUM_REAGENTBAG_SLOTS", "C_Container", "C_Bank", "Enum")
    _G.C_Bank, _G.Enum = nil, nil
    _G.C_Container = { GetContainerNumSlots = function(bag) return bag == 77 and 98 or 0 end }
    local calls = 0
    Bagwise.Bags.onNewBankBag = function() calls = calls + 1 end

    assert.is_truthy(Bagwise.Bags.NoteBankBag(77))
    assert.is_truthy(not Bagwise.Bags.NoteBankBag(77))
    assert.are.equal(1, calls)
    assert.is_truthy(Bagwise.Bags.IsBank(77))
    assert.are.equal(77, Bagwise.Bags.BankBags()[1])
    restore()
  end)

  it("never treats a carried bag as bank", function()
    _G.NUM_BAG_SLOTS = 4
    _G.NUM_REAGENTBAG_SLOTS = 1
    assert.is_truthy(not Bagwise.Bags.NoteBankBag(2))
    assert.is_truthy(not Bagwise.Bags.NoteBankBag(-1))
    _G.NUM_REAGENTBAG_SLOTS = nil
  end)
end)
