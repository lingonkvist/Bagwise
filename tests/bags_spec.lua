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
