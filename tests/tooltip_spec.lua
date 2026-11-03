-- Bagwise: tooltip unit tests
-- Run with: lua5.1 tests/tooltip_spec.lua (from the Bagwise/ root)

_G.GameTooltip = {
  HookScript = function() end,
  IsShown = function() return false end,
  GetOwner = function() return nil end,
}
_G.CreateFrame = function()
  return {
    RegisterEvent = function() end,
    SetScript = function() end,
  }
end
_G.C_Container = {
  GetBagName = function(id) return id == 0 and "Backpack" or nil end,
  GetContainerItemInfo = function() return nil end,
}

_G.Bagwise = nil
dofile("src/tooltip.lua")

local function makeTooltip(itemLink, ownerParent, bag, slot)
  local lines = {}
  return {
    GetItem = function() return "ItemName", itemLink end,
    AddLine = function(self, text, r, g, b)
      lines[#lines + 1] = { text = text, r = r, g = g, b = b }
    end,
    AddDoubleLine = function(self, textL, textR, rL, gL, bL, rR, gR, bR)
      lines[#lines + 1] = {
        text = textL,
        textR = textR,
        r = rL,
        g = gL,
        b = bL,
        rR = rR,
        gR = gR,
        bR = bR,
      }
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

describe("tooltip basic output", function()
  it("shows verdict line for a bag item", function()
    Bagwise.Data = Bagwise.Data or {}
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Well below your level" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:123:...|h[Old Sword]|h|r",
      "ContainerFrame1", 0, 5)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Safe to delete: Well below your level", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)
    assert.are.equal(0.9, tt.lines[1].g)
  end)

  it("yellow level verdict: single line", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Below your level" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:124:...|h[Decent Sword]|h|r",
      "ContainerFrame1", 0, 5)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Probably sell: Below your level", tt.lines[1].text)
    assert.are.equal(1.0, tt.lines[1].r)
    assert.are.equal(0.9, tt.lines[1].g)
  end)

  it("no output at all when item has no data", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function() return nil end,
    }

    local tt = makeTooltip("|cff...|Hitem:999:...|h[Unknown]|h|r")
    Bagwise.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)
end)

describe("tooltip profession info (no verdict)", function()
  it("single profession, no extras", function()
    Bagwise.Data = Bagwise.Data or {}
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    Bagwise.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(1%-50%)"))
    assert.is_truthy(tt.lines[1].text:find("|T136240:16:16|t"))
  end)

  it("3 professions, player has none: top 2 by range + extras", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 }, -- range 75
        { "Blacksmithing", 3, 180, 300 }, -- range 120
        { "Tailoring",     3, 170, 195 }, -- range 25
      },
    }
    Bagwise.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Blacksmithing %(180%-300%)"))
    assert.is_truthy(tt.lines[2].text:find("Alchemy %(215%-290%) %+1"))
  end)

  it("5 professions, player has none: top 2 + +3", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 }, -- 75
        { "Blacksmithing",  3, 180, 300 }, -- 120
        { "Tailoring",      3, 170, 195 }, -- 25
        { "Engineering",    6, 160, 195 }, -- 35
        { "Leatherworking", 4, 170, 200 }, -- 30
      },
    }
    Bagwise.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Blacksmithing %(180%-300%)"))
    assert.is_truthy(tt.lines[2].text:find("Alchemy %(215%-290%) %+3"))
  end)

  it("player has the profession: shows it, no extras", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 4, 170, 200 },
      },
    }
    Bagwise.Scanner = {
      professionNames = { Leatherworking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Leatherworking %(170%-200%)"))
  end)

  it("player has 2 matching: both shown, main first", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 4, 170, 200 },
      },
    }
    Bagwise.Scanner = {
      professionNames = { Alchemy = true, Leatherworking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(215%-290%)"))
    assert.is_truthy(tt.lines[2].text:find("Leatherworking %(170%-200%)"))
  end)

  it("player has secondary prof: sorted after main", function()
    Bagwise.Data.ReagentProfessions = {
      [159] = {
        { "Cooking",     7, 50,  275 },
        { "Engineering", 3, 100, 275 },
      },
    }
    Bagwise.Scanner = {
      professionNames = { Engineering = true, Cooking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:159:...|h[Refreshing Spring Water]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("Engineering %(100%-275%)"))
    assert.is_truthy(tt.lines[2].text:find("Cooking %(50%-275%)"))
  end)

  it("shows single number when min equals max", function()
    Bagwise.Data.ReagentProfessions = {
      [100] = { { "Cooking", 3, 75, 75 } },
    }
    Bagwise.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:100:...|h[Test]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Cooking %(75%)"))
  end)

  it("uses info blue color for default text", function()
    Bagwise.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    Bagwise.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0.5, tt.lines[1].r)
    assert.are.equal(0.8, tt.lines[1].g)
    assert.are.equal(1.0, tt.lines[1].b)
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

describe("tooltip vendor reagent verdict", function()
  it("single line with professions in parens, no detail rows", function()
    Bagwise.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    Bagwise.Data.VendorReagents = {
      [3371] = { 171 },
    }
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Vendor reagent (Alchemy)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:3371:...|h[Empty Vial]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Safe to delete: Vendor reagent (Alchemy)", tt.lines[1].text)
    Bagwise.Data.VendorReagents = nil
  end)

  it("multi-prof vendor: two lines because of comma", function()
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
      GetResult = function()
        return {
          verdict = "green",
          reason = "Vendor reagent (Leatherworking, Tailoring)"
        }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Safe to delete:", tt.lines[1].text)
    assert.are.equal("Vendor reagent (Leatherworking, Tailoring)", tt.lines[2].text)
    Bagwise.Data.VendorReagents = nil
  end)
end)

describe("tooltip merged verdict lines", function()
  it("green class reagent: single line", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Rogue only (vendor)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:5140:...|h[Flash Powder]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Safe to delete: Rogue only (vendor)", tt.lines[1].text)
    assert.are.equal(0.4, tt.lines[1].r)
  end)

  it("yellow class reagent: single line", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Rogue only (world drop)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:5530:...|h[Soul Shard]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Probably sell: Rogue only (world drop)", tt.lines[1].text)
  end)

  it("quest verdict: single line", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return {
          verdict = "green",
          reason = "Quest already completed"
        }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:200:...|h[Lost Necklace]|h|r", "ContainerFrame1", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Safe to delete: Quest already completed", tt.lines[1].text)
  end)
end)

describe("tooltip verdict edge cases", function()
  it("skips verdict for non-bag tooltips", function()
    Bagwise.Data.ReagentProfessions = {}
    Bagwise.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "test" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:789:...|h[AH Item]|h|r", "AuctionFrame", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)

  it("does not show reagent info for non-bag tooltip", function()
    Bagwise.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    Bagwise.Scanner = { professionNames = nil }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "AuctionFrame", 0, 1)
    Bagwise.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)
end)
