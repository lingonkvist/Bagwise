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

describe("Commands.SplitInput", function()
  it("splits a command from its argument at the first space", function()
    local cmd, argument = Bagwise.Commands.SplitInput("  keep Linen Cloth ")
    assert.are.equal("keep", cmd)
    assert.are.equal("Linen Cloth", argument)
  end)

  it("splits where a shift-clicked link starts when there is no space", function()
    local link = "|cnIQ1:|Hitem:5060::::::::24:1488::::::|h[Thieves' Tools]|h|r"
    local cmd, argument = Bagwise.Commands.SplitInput("why" .. link)
    assert.are.equal("why", cmd)
    assert.are.equal(5060, Bagwise.Commands.ParseItemID(argument))
  end)

  it("treats an empty message as no command", function()
    assert.are.equal("", (Bagwise.Commands.SplitInput("")))
    assert.are.equal("", (Bagwise.Commands.SplitInput(nil)))
  end)
end)

describe("Commands.PriceAgeDays", function()
  local noon = os.time({ year = 2026, month = 11, day = 20, hour = 12 })

  it("counts whole days from the date in the price data", function()
    assert.are.equal(10, Bagwise.Commands.PriceAgeDays("2026-11-10", noon))
    assert.are.equal(0, Bagwise.Commands.PriceAgeDays("2026-11-20", noon))
  end)

  it("gives nothing for a missing or odd date", function()
    assert.is_nil(Bagwise.Commands.PriceAgeDays(nil, noon))
    assert.is_nil(Bagwise.Commands.PriceAgeDays("last week", noon))
  end)
end)



describe("Commands.SummaryLine", function()
  Bagwise.Verdict = Bagwise.Verdict or {}
  Bagwise.Verdict.FormatMoney = Bagwise.Verdict.FormatMoney or function(copper) return copper .. "c" end

  it("says greens with their vendor value and yellows", function()
    local line = Bagwise.Commands.SummaryLine({ green = 9, yellow = 5, greenValue = 214 })
    assert.are.equal("9 green (214c at a vendor), 5 yellow", line)
  end)

  it("leaves out what is zero", function()
    assert.are.equal("5 yellow", Bagwise.Commands.SummaryLine({ green = 0, yellow = 5, greenValue = 0 }))
    assert.are.equal("2 green (30c at a vendor)", Bagwise.Commands.SummaryLine({ green = 2, yellow = 0, greenValue = 30 }))
  end)

  it("gives nothing when nothing is marked", function()
    assert.is_nil(Bagwise.Commands.SummaryLine({ green = 0, yellow = 0, greenValue = 0 }))
  end)
end)
