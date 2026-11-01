-- Bagwise: tooltip unit tests
-- Run with: lua5.1 tests/tooltip_spec.lua (from the Bagwise/ root)

-- Stub WoW API globals before loading the module
_G.IsShiftKeyDown = function() return false end
_G.GameTooltip = {
  HookScript = function() end,
  IsShown = function() return false end,
}
_G.CreateFrame = function()
  return {
    RegisterEvent = function() end,
    SetScript = function() end,
  }
end

_G.Bagwise = nil
dofile("src/tooltip.lua")

-- Helper: fake tooltip that records AddLine calls
local function makeTooltip(itemLink, ownerParent, bag, slot)
  local lines = {}
  return {
    GetItem = function()
      return "ItemName", itemLink
    end,
    AddLine = function(self, text, r, g, b)
      lines[#lines + 1] = { text = text, r = r, g = g, b = b }
    end,
    Show = function() end,
    GetOwner = function()
      if not ownerParent then return nil end
      return {
        GetID = function() return slot or 1 end,
        GetParent = function()
          return {
            GetName = function() return ownerParent end,
            GetID = function() return bag or 0 end,
          }
        end,
      }
    end,
    lines = lines,
  }
end

describe("tooltip reagent info (default, no shift)", function()
  it("shows single profession with skill range", function()
    Bagwise.Data = Bagwise.Data or {}
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (1-50)", tt.lines[1].text)
  end)

  it("lists multiple professions without range and shows hint", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
        { "Tailoring",     3, 170, 195 },
      },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal(
      "Alchemy, Blacksmithing, Tailoring reagent",
      tt.lines[1].text)
    assert.are.equal("Hold Shift for details", tt.lines[2].text)
  end)

  it("uses info color for reagent line", function()
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0.5, tt.lines[1].r)
    assert.are.equal(0.8, tt.lines[1].g)
    assert.are.equal(1.0, tt.lines[1].b)
  end)

  it("uses dim color for hold-shift hint", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0.5, tt.lines[2].r)
    assert.are.equal(0.5, tt.lines[2].g)
    assert.are.equal(0.5, tt.lines[2].b)
  end)

  it("no hint for single-profession items", function()
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
  end)

  it("shows single number when min equals max", function()
    Bagwise.Data.ReagentProfessions = {
      [100] = { { "Cooking", 3, 75, 75 } },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:100:...|h[Test]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Cooking reagent (75)", tt.lines[1].text)
  end)

  it("does nothing when item has no reagent data", function()
    Bagwise.Data.ReagentProfessions = {}
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip("|cff...|Hitem:999:...|h[Unknown]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)

  it("does nothing when link is nil", function()
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    local tt = makeTooltip(nil)
    Bagwise.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)
end)

describe("tooltip reagent info (shift held)", function()
  it("expands multi-profession to per-profession with skill range", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Alchemy reagent (215-290)", tt.lines[1].text)
    assert.are.equal("Blacksmithing reagent (180-300)", tt.lines[2].text)
  end)

  it("shows compact for single profession (nothing to expand)", function()
    Bagwise.Data.ReagentProfessions = {
      [100] = { { "Cooking", 3, 75, 75 } },
    }
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip("|cff...|Hitem:100:...|h[Test]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Cooking reagent (75)", tt.lines[1].text)
  end)

  it("shows per-profession in yellow when verdict fires (multi)", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Alchemy, Blacksmithing reagent" }
      end,
    }
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip(
      "|cff...|Hitem:7067:...|h[Elemental Earth]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- Per-profession lines colored yellow, no separate verdict line
    assert.are.equal(2, #tt.lines)
    assert.are.equal("Alchemy reagent (215-290)", tt.lines[1].text)
    assert.are.equal("Blacksmithing reagent (180-300)", tt.lines[2].text)
    assert.are.equal(1.0, tt.lines[1].r)
    assert.are.equal(0.9, tt.lines[1].g)
  end)

  it("shift does NOT expand vendor reagent", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Alchemy reagent (vendor)" }
      end,
    }
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip(
      "|cff...|Hitem:3371:...|h[Empty Vial]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- Vendor format in green, no expansion
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (vendor)", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)
end)

describe("tooltip verdict lines", function()
  it("shows verdict reason in green", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function(bag, slot)
        return { verdict = "green", reason = "Very low level: 20" }
      end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:123:...|h[Old Sword]|h|r",
      "ContainerFrame1", 0, 5)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Very low level: 20", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)
    assert.are.equal(0.9, tt.lines[1].g)
    assert.are.equal(0.4, tt.lines[1].b)
  end)

  it("uses yellow color for yellow reagent verdict", function()
    Bagwise.Data.ReagentProfessions = {
      [456] = { { "Tailoring", 4, 200, 300 } },
    }
    Bagwise.Scanner = {
      GetResult = function(bag, slot)
        return { verdict = "yellow", reason = "Tailoring reagent (200-300)" }
      end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:456:...|h[Naga Scale]|h|r",
      "ContainerFrame2", 1, 3)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- Reagent info line colored yellow (merged verdict)
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Tailoring reagent (200-300)", tt.lines[1].text)
    assert.are.equal(1.0, tt.lines[1].r)
    assert.are.equal(0.9, tt.lines[1].g)
    assert.are.equal(0.3, tt.lines[1].b)
  end)

  it("skips verdict for non-bag tooltips", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function() return { verdict = "green", reason = "test" } end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:789:...|h[AH Item]|h|r",
      "AuctionFrame", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)

  it("skips verdict when scanner has no result", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:111:...|h[Bag Item]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)
end)

describe("tooltip reagent + verdict interaction", function()
  it("vendor verdict: shows info in green, no separate verdict line", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Alchemy reagent (vendor)" }
      end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:3371:...|h[Empty Vial]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- One line: vendor format in green
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (vendor)", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)

  it("crafting verdict: info in yellow + hint (multi prof)", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Alchemy, Blacksmithing reagent" }
      end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:7067:...|h[Elemental Earth]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- Compact info line in yellow + hint
    assert.are.equal(2, #tt.lines)
    assert.are.equal("Alchemy, Blacksmithing reagent", tt.lines[1].text)
    assert.are.equal(1.0, tt.lines[1].r)     -- yellow
    assert.are.equal("Hold Shift for details", tt.lines[2].text)
  end)

  it("shows reagent line when no verdict (player has the profession)", function()
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (1-50)", tt.lines[1].text)
  end)

  it("sorts player professions first in compact line", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 3, 170, 195 },
      },
    }
    Bagwise.Scanner = Bagwise.Scanner or {}
    Bagwise.Scanner.professionNames = { Leatherworking = true }
    Bagwise.Scanner.GetResult = function() return nil end
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:7067:...|h[Elemental Earth]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(
      "Leatherworking, Alchemy, Blacksmithing reagent",
      tt.lines[1].text)
    -- Clean up
    Bagwise.Scanner.professionNames = nil
  end)

  it("sorts player professions first in expanded view", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 3, 170, 195 },
      },
    }
    Bagwise.Scanner = Bagwise.Scanner or {}
    Bagwise.Scanner.professionNames = { Leatherworking = true }
    Bagwise.Scanner.GetResult = function() return nil end
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip(
      "|cff...|Hitem:7067:...|h[Elemental Earth]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal("Leatherworking reagent (170-195)", tt.lines[1].text)
    assert.are.equal("Alchemy reagent (215-290)", tt.lines[2].text)
    assert.are.equal("Blacksmithing reagent (180-300)", tt.lines[3].text)
    -- Clean up
    Bagwise.Scanner.professionNames = nil
  end)

  it("vendor reagent shows (vendor) instead of skill range", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:3371:...|h[Empty Vial]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (vendor)", tt.lines[1].text)
    assert.are.equal(0.5, tt.lines[1].r)     -- blue info color
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)

  it("vendor reagent not expandable with shift", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }
    _G.IsShiftKeyDown = function() return true end

    local tt = makeTooltip(
      "|cff...|Hitem:3371:...|h[Empty Vial]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (vendor)", tt.lines[1].text)
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)

  it("vendor reagent multi-prof: no expand, no hint", function()
    Bagwise.Data.ReagentProfessions = {
      [2320] = {
        { "Leatherworking", 10, 1, 300 },
        { "Tailoring",      10, 1, 300 },
      },
    }
    Bagwise.Data.VendorReagents = {
      [2320] = { 165, 197 },
    }
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:2320:...|h[Coarse Thread]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Leatherworking, Tailoring reagent (vendor)", tt.lines[1].text)
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)

  it("vendor reagent with green verdict: same text, green color", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Alchemy reagent (vendor)" }
      end,
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:3371:...|h[Empty Vial]|h|r",
      "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    -- Same text, just colored green
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Alchemy reagent (vendor)", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)     -- green verdict color
    -- Clean up
    Bagwise.Data.VendorReagents = nil
  end)

  it("shows reagent line + hint for non-bag tooltips (AH, mail)", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    _G.IsShiftKeyDown = function() return false end

    local tt = makeTooltip(
      "|cff...|Hitem:7067:...|h[Elemental Earth]|h|r",
      "AuctionFrame", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Alchemy, Blacksmithing reagent", tt.lines[1].text)
    assert.are.equal("Hold Shift for details", tt.lines[2].text)
  end)
end)
