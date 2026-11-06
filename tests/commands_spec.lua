-- Bagwise: command parsing and override list tests

_G.Bagwise = nil
_G.BagwiseDB = { keepList = {}, flagList = {}, version = 1 }

dofile("src/overrides.lua")
dofile("src/commands.lua")

describe("Commands.ParseItemID", function()
  it("reads the ID out of a shift-clicked item link", function()
    local link = "|cff1eff00|Hitem:2589::::::::60:::::|h[Linen Cloth]|h|r"

    assert.are.equal(2589, Bagwise.Commands.ParseItemID(link))
  end)

  it("accepts a bare numeric ID", function()
    assert.are.equal(2589, Bagwise.Commands.ParseItemID("2589"))
  end)

  it("resolves a name through the injected lookup", function()
    local lookup = function(name)
      if name == "Linen Cloth" then return "|Hitem:2589::|h[Linen Cloth]|h" end
    end

    assert.are.equal(2589, Bagwise.Commands.ParseItemID("Linen Cloth", lookup))
  end)

  it("returns nil for an unknown name or empty text", function()
    local lookup = function() return nil end

    assert.is_nil(Bagwise.Commands.ParseItemID("Nonsense", lookup))
    assert.is_nil(Bagwise.Commands.ParseItemID(""))
    assert.is_nil(Bagwise.Commands.ParseItemID(nil))
  end)
end)

describe("Overrides lists", function()
  it("keep clears flag and flag clears keep", function()
    Bagwise.Overrides.AddFlag(100, "Thing")
    Bagwise.Overrides.AddKeep(100, "Thing")

    assert.is_truthy(Bagwise.Overrides.IsKept(100))
    assert.is_nil(BagwiseDB.flagList[100])

    Bagwise.Overrides.AddFlag(100, "Thing")

    assert.is_truthy(Bagwise.Overrides.IsFlagged(100))
    assert.is_nil(BagwiseDB.keepList[100])
  end)

  it("remove returns true only when the item was listed", function()
    Bagwise.Overrides.AddKeep(200, "Thing")

    assert.are.equal(true, Bagwise.Overrides.Remove(200))
    assert.are.equal(false, Bagwise.Overrides.Remove(200))
    assert.are.equal(false, Bagwise.Overrides.IsKept(200))
  end)
end)
