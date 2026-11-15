-- MakeSpace: command parsing and override list tests

_G.MakeSpace = nil
_G.MakeSpaceDB = { keepList = {}, flagList = {}, version = 1 }

dofile("src/overrides.lua")
dofile("src/curves.lua")
dofile("src/auction.lua")
dofile("src/commands.lua")

describe("Commands.ParseItemID", function()
  it("reads the ID out of a shift-clicked item link", function()
    local link = "|cff1eff00|Hitem:2589::::::::60:::::|h[Linen Cloth]|h|r"

    assert.are.equal(2589, MakeSpace.Commands.ParseItemID(link))
  end)

  it("accepts a bare numeric ID", function()
    assert.are.equal(2589, MakeSpace.Commands.ParseItemID("2589"))
  end)

  it("resolves a name through the injected lookup", function()
    local lookup = function(name)
      if name == "Linen Cloth" then return "|Hitem:2589::|h[Linen Cloth]|h" end
    end

    assert.are.equal(2589, MakeSpace.Commands.ParseItemID("Linen Cloth", lookup))
  end)

  it("returns nil for an unknown name or empty text", function()
    local lookup = function() return nil end

    assert.is_nil(MakeSpace.Commands.ParseItemID("Nonsense", lookup))
    assert.is_nil(MakeSpace.Commands.ParseItemID(""))
    assert.is_nil(MakeSpace.Commands.ParseItemID(nil))
  end)
end)

describe("Import from the old Bagwise saved data", function()
  it("copies both lists and the auto-open setting", function()
    local new = {}
    local copied = MakeSpace.Overrides.ImportOld(
      { keepList = { [1] = "A" }, flagList = { [2] = true }, autoOpenBags = false }, new)
    assert.is_truthy(copied)
    assert.are.equal("A", new.keepList[1])
    assert.is_truthy(new.flagList[2])
    assert.are.equal(false, new.autoOpenBags)
  end)

  it("does nothing without old data", function()
    local new = {}
    assert.are.equal(false, MakeSpace.Overrides.ImportOld(nil, new))
    assert.is_nil(new.keepList)
  end)
end)

describe("Overrides lists", function()
  it("keep clears flag and flag clears keep", function()
    MakeSpace.Overrides.AddFlag(100, "Thing")
    MakeSpace.Overrides.AddKeep(100, "Thing")

    assert.is_truthy(MakeSpace.Overrides.IsKept(100))
    assert.is_nil(MakeSpaceDB.flagList[100])

    MakeSpace.Overrides.AddFlag(100, "Thing")

    assert.is_truthy(MakeSpace.Overrides.IsFlagged(100))
    assert.is_nil(MakeSpaceDB.keepList[100])
  end)

  it("remove returns true only when the item was listed", function()
    MakeSpace.Overrides.AddKeep(200, "Thing")

    assert.are.equal(true, MakeSpace.Overrides.Remove(200))
    assert.are.equal(false, MakeSpace.Overrides.Remove(200))
    assert.are.equal(false, MakeSpace.Overrides.IsKept(200))
  end)
end)

describe("Commands.SplitInput", function()
  it("splits a command from its argument at the first space", function()
    local cmd, argument = MakeSpace.Commands.SplitInput("  keep Linen Cloth ")
    assert.are.equal("keep", cmd)
    assert.are.equal("Linen Cloth", argument)
  end)

  it("splits where a shift-clicked link starts when there is no space", function()
    local link = "|cnIQ1:|Hitem:5060::::::::24:1488::::::|h[Thieves' Tools]|h|r"
    local cmd, argument = MakeSpace.Commands.SplitInput("why" .. link)
    assert.are.equal("why", cmd)
    assert.are.equal(5060, MakeSpace.Commands.ParseItemID(argument))
  end)

  it("treats an empty message as no command", function()
    assert.are.equal("", (MakeSpace.Commands.SplitInput("")))
    assert.are.equal("", (MakeSpace.Commands.SplitInput(nil)))
  end)
end)

describe("Commands.SummaryLine", function()
  MakeSpace.Verdict = MakeSpace.Verdict or {}
  MakeSpace.Verdict.FormatMoney = MakeSpace.Verdict.FormatMoney or function(copper) return copper .. "c" end

  it("says greens with their vendor value and yellows", function()
    local line = MakeSpace.Commands.SummaryLine({ green = 9, yellow = 5, greenValue = 214 })
    assert.are.equal("9 green (214c at a vendor), 5 yellow", line)
  end)

  it("leaves out what is zero", function()
    assert.are.equal("5 yellow", MakeSpace.Commands.SummaryLine({ green = 0, yellow = 5, greenValue = 0 }))
    assert.are.equal("2 green (30c at a vendor)", MakeSpace.Commands.SummaryLine({ green = 2, yellow = 0, greenValue = 30 }))
  end)

  it("gives nothing when nothing is marked", function()
    assert.is_nil(MakeSpace.Commands.SummaryLine({ green = 0, yellow = 0, greenValue = 0 }))
  end)
end)
