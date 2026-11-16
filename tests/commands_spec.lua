-- MakeSpace: command parsing and override list tests

_G.MakeSpace = nil
_G.MakeSpaceDB = { version = 1 }
_G.MakeSpaceAccountDB = { marks = {} }

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

describe("Item marks", function()
  it("one mark per item: the last one set wins", function()
    MakeSpace.Overrides.Set(100, "yellow", "Thing")
    MakeSpace.Overrides.Set(100, "none", "Thing")

    assert.is_truthy(MakeSpace.Overrides.IsKept(100))
    assert.are.equal(false, MakeSpace.Overrides.IsFlagged(100))
    assert.are.equal("none", MakeSpace.Overrides.Get(100))

    MakeSpace.Overrides.Set(100, "green")

    assert.is_truthy(MakeSpace.Overrides.IsMarkedGreen(100))
    assert.are.equal("Thing", MakeSpaceAccountDB.marks[100].name) -- the name stays
  end)

  it("keep and flag are the old names for the none and yellow marks", function()
    MakeSpace.Overrides.AddKeep(101, "A")
    MakeSpace.Overrides.AddFlag(102, "B")

    assert.are.equal("none", MakeSpace.Overrides.Get(101))
    assert.are.equal("yellow", MakeSpace.Overrides.Get(102))
  end)

  it("default or nil goes back to the normal rules, and says whether anything changed", function()
    MakeSpace.Overrides.Set(200, "none", "Thing")

    assert.are.equal(true, MakeSpace.Overrides.Set(200, "default"))
    assert.are.equal(false, MakeSpace.Overrides.Set(200, nil))
    assert.is_nil(MakeSpace.Overrides.Get(200))
    assert.are.equal(true, MakeSpace.Overrides.Set(201, "green"))
    assert.are.equal(true, MakeSpace.Overrides.Remove(201))
    assert.are.equal(false, MakeSpace.Overrides.Remove(201))
  end)

  it("an unknown mark is refused", function()
    assert.are.equal(false, MakeSpace.Overrides.Set(300, "purple"))
    assert.is_nil(MakeSpace.Overrides.Get(300))
  end)

  it("counts the marks of each kind", function()
    MakeSpaceAccountDB.marks = {}
    MakeSpace.Overrides.Set(1, "green")
    MakeSpace.Overrides.Set(2, "green")
    MakeSpace.Overrides.Set(3, "none")

    local counts = MakeSpace.Overrides.Counts()
    assert.are.equal(2, counts.green)
    assert.are.equal(0, counts.yellow)
    assert.are.equal(1, counts.none)
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
