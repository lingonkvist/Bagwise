-- MakeSpace: tooltip unit tests
-- Run with: lua5.1 tests/tooltip_spec.lua (from the MakeSpace/ root)

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
_G.C_QuestLog = {
  GetQuestInfo = function(id) return "Test Quest " .. id end,
  IsQuestFlaggedCompleted = function() return false end,
}

_G.MakeSpace = nil
dofile("src/bags.lua")
dofile("src/safety.lua")
dofile("src/notes.lua")
dofile("src/curves.lua")
dofile("src/auction.lua")
dofile("src/verdict.lua")
dofile("src/bank.lua")
dofile("src/tooltip.lua")

-- buttonBagID is optional. When given, the owner button reports its own bag
-- through GetBagID, like Forever's item buttons do. ownerParent and bag then
-- describe the parent frame (the combined bags frame), which is no help.
local function makeTooltip(itemLink, ownerParent, bag, slot, buttonBagID)
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
      local owner = {
        GetID = function() return slot or 1 end,
        GetParent = function()
          return {
            GetName = function() return ownerParent end,
            GetID = function() return bag or 0 end,
          }
        end,
      }
      if buttonBagID then
        owner.GetBagID = function() return buttonBagID end
      end
      return owner
    end,
    lines = lines,
  }
end

-- Coin letters are coloured in tooltip lines; compare the text without them.
local function plainCoins(text)
  return (text:gsub("|cffffffff(%d+)|r", "%1"):gsub("|cff[0-9a-f]+([gsc])|r", "%1"))
end

describe("tooltip basic output", function()
  it("shows verdict line for a bag item", function()
    MakeSpace.Data = MakeSpace.Data or {}
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Well below your level" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:123:...|h[Old Sword]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Well below your level", tt.lines[2].text)
    assert.are.equal(0.33, tt.lines[1].r)
    assert.are.equal(0.87, tt.lines[1].g)
  end)

  it("yellow level verdict: single line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Below your level" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:124:...|h[Decent Sword]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Below your level$"))
    assert.are.equal(0.97, tt.lines[1].r)
    assert.are.equal(0.82, tt.lines[1].g)
  end)

  it("header: dot and verdict in words in the verdict color, detail in info blue", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Below your level",
                 heading = { title = "Outleveled gear", detail = "Below your level" } }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:127:...|h[Old Boots]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("^|T.-textures.-pearl_yellow:14:14|t Outleveled gear$"))
    assert.are.equal(0.97, tt.lines[1].r)
    assert.are.equal(0.82, tt.lines[1].g)
    assert.are.equal("Below your level", tt.lines[2].text)
    assert.are.equal(0.40, tt.lines[2].r)
    assert.are.equal(1.0, tt.lines[2].b)
  end)

  it("a green you set yourself says Safe to delete, and whose call it is", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Marked by you", rule = "marked", sellable = false }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:127:...|h[Mail Belt]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("pearl_green:14:14|t Safe to delete$"))
    assert.are.equal("Marked by you", tt.lines[2].text)
  end)

  it("says Safe to vendor for a green tagged as sellable", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Shamans can't wear mail until level 40",
                 sellable = true }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:127:...|h[Mail Belt]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("pearl_green:14:14|t Safe to vendor$"))
    assert.are.equal("Shamans can't wear mail until level 40", tt.lines[2].text)
  end)

  it("shows a price with white numbers and coloured coin letters", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function() return { auctionNote = "Vendor 1g 20s 5c, auction about 8s" } end,
    }
    local tt = makeTooltip("|cff...|Hitem:127:...|h[Junk]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal("Vendor |cffffffff1|r|cffffd700g|r |cffffffff20|r|cffc7c7cfs|r |cffffffff5|r|cffeda55fc|r, auction about |cffffffff8|r|cffc7c7cfs|r",
        tt.lines[1].text)
  end)

  it("shows the dot header, reason and delete line for a slot picked to make room", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Cheapest junk, sells for 5c",
                 detail = "Delete to make room for your loot" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:127:...|h[Junk]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(plainCoins(tt.lines[1].text):find("Cheapest junk, sells for 5c$"))
    assert.are.equal("Delete to make room for your loot", tt.lines[2].text)
    assert.are.equal(0.40, tt.lines[2].r)
  end)

  it("never adds a blank spacer line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Quest completed", detail = "[34] Bad Medicine" }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:125:...|h[Old Note]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(3, #tt.lines)
    for i = 1, #tt.lines do
      assert.is_truthy(tt.lines[i].text:find("%S"))
    end
  end)

  it("long verdict text breaks at a comma when one fits on the first line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return {
          verdict = "green",
          reason = "Vendor reagent (Alchemy, Enchanting, Tailoring)",
        }
      end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:126:...|h[Many Uses]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(3, #tt.lines)
    assert.are.equal("Vendor reagent (Alchemy, Enchanting,", tt.lines[2].text)
    assert.are.equal("Tailoring)", tt.lines[3].text)
  end)

  it("no output for non-bag tooltips (no owner)", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function() return nil end,
    }

    local tt = makeTooltip("|cff...|Hitem:999:...|h[Unknown]|h|r")
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)

  it("a clicked chat link shows no verdict, even for an item that would have one", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = nil
    MakeSpace.Scanner = {
      EvaluateItem = function() error("a link gets no verdict") end,
      GetResult = function() error("a link is not in a bag") end,
    }
    local tt = makeTooltip("|cff1eff00|Hitem:14406::::::::31:1491|h[Resilient Cord]|h|r")
    tt.GetName = function() return "ItemRefTooltip" end
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)

  it("a clicked chat link shows what a reagent is for even without a verdict", function()
    MakeSpace.Data.ReagentProfessions = { [765] = { { "Alchemy", 5, 1, 50 } } }
    MakeSpace.Data.VendorReagents = nil
    MakeSpace.Scanner = {}
    local tt = makeTooltip("|cffffffff|Hitem:765:::::::|h[Silverleaf]|h|r")
    tt.GetName = function() return "ItemRefTooltip" end
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy", 1, true))
  end)

  it("shows the verdict on a Forever bank button, which knows its own tab and slot", function()
    MakeSpace.Data.ReagentProfessions = {}
    local asked
    MakeSpace.Scanner = {
      GetResult = function(bag, slot)
        asked = bag .. ":" .. slot
        return { verdict = "green", reason = "Well below your level" }
      end,
    }
    local realIsScanned = MakeSpace.Bags.IsScanned
    MakeSpace.Bags.IsScanned = function(bag) return bag == 7 end
    local tt = makeTooltip("|cff...|Hitem:123:...|h[Old Sword]|h|r")
    local button = { GetBankTabID = function() return 7 end, GetContainerSlotID = function() return 3 end,
                     GetID = function() return 99 end, GetParent = function() return {} end }
    tt.GetOwner = function() return button end
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    MakeSpace.Bags.IsScanned = realIsScanned
    assert.are.equal("7:3", asked)
    assert.are.equal(2, #tt.lines)
  end)

  it("explains the missing dot when the auction pays more: no verdict, one price row", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function() return { auctionNote = "Vendor 5c, auction about 8s" } end,
    }
    local tt = makeTooltip("|cff...|Hitem:16645:...|h[Page 1]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Vendor 5c, auction about 8s", plainCoins(tt.lines[1].text))
    assert.are.equal(0.40, tt.lines[1].r)
  end)

  it("keeps the price row on a yellow hint when Auctionator is installed", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Flagged", auctionNote = "Vendor 5c, auction about 8s" }
      end,
    }
    local realLive = MakeSpace.Live
    MakeSpace.Live = { Api = function() return {} end }
    local tt = makeTooltip("|cff...|Hitem:16645:...|h[Page 1]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    MakeSpace.Live = realLive
    local found = false
    for _, line in ipairs(tt.lines) do
      if line.text:find("auction about") then found = true end
    end
    assert.is_truthy(found)
  end)

  it("a price note goes with a yellow verdict too, after its detail", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Flagged", auctionNote = "Vendor 5c, auction about 8s" }
      end,
    }
    local tt = makeTooltip("|cff...|Hitem:16646:...|h[Page 2]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal("Vendor 5c, auction about 8s", plainCoins(tt.lines[#tt.lines].text))
  end)

  it("a worth-very-little green shows the price line instead of its own reason", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = MakeSpace.Verdict.WORTH_LITTLE_REASON,
                 auctionNote = "Vendor 20c, auction about 26c" }
      end,
    }
    local tt = makeTooltip("|cff...|Hitem:6470:...|h[Deviate Scale]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(2, #tt.lines)
    assert.are.equal("Vendor 20c, auction about 26c", plainCoins(tt.lines[2].text))
  end)

  it("a worth-very-little green with no price line keeps its reason", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = MakeSpace.Verdict.WORTH_LITTLE_REASON }
      end,
    }
    local tt = makeTooltip("|cff...|Hitem:6470:...|h[Deviate Scale]|h|r", "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal("Worth very little", plainCoins(tt.lines[2].text))
  end)

  it("shows profession info even when scan result is nil", function()
    MakeSpace.Data = MakeSpace.Data or {}
    MakeSpace.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    MakeSpace.Data.VendorReagents = nil
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return nil end,
    }

    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrame1", 0, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(1%-50%)"))
  end)
end)

describe("tooltip bag and slot lookup", function()
  local function recordLookups()
    local lookups = {}
    MakeSpace.Data = MakeSpace.Data or {}
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function(bag, slot)
        lookups[#lookups + 1] = { bag = bag, slot = slot }
        return { verdict = "green", reason = "Test reason" }
      end,
    }
    return lookups
  end

  it("combined bags: takes the bag from the button, not the parent frame", function()
    local lookups = recordLookups()

    -- Parent is the combined frame (ID 0). The item is really in bag 3, slot 7.
    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrameCombinedBags", 0, 7, 3)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #lookups)
    assert.are.equal(3, lookups[1].bag)
    assert.are.equal(7, lookups[1].slot)
    assert.are.equal("Test reason", tt.lines[2].text)
  end)

  it("combined bags: backpack items still resolve", function()
    local lookups = recordLookups()

    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrameCombinedBags", 0, 2, 0)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, lookups[1].bag)
    assert.are.equal(2, lookups[1].slot)
  end)

  it("button in a bag outside the scanned ranges shows nothing", function()
    local lookups = recordLookups()

    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "SomeFrame", 0, 4, 99)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #lookups)
    assert.are.equal(0, #tt.lines)
  end)

  it("classic frames: slot is the button ID, bag is the parent frame ID", function()
    local lookups = recordLookups()

    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrame2", 2, 9)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, lookups[1].bag)
    assert.are.equal(9, lookups[1].slot)
  end)
end)

describe("tooltip known-use note", function()
  it("explains a silent item that is on the known-use list", function()
    MakeSpace.Data = MakeSpace.Data or {}
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = {}
    MakeSpace.Data.ProtectedItems = { [268415] = "Herb seed, used in the Herbalism Greenhouse" }
    MakeSpace.Scanner = { professionNames = nil, GetResult = function() return {} end }

    local tt = makeTooltip("|cff...|Hitem:268415:...|h[Commonplace Herb Seeds]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Herb seed, used in the Herbalism Greenhouse", tt.lines[1].text)
    MakeSpace.Data.ProtectedItems = nil
  end)
end)

describe("tooltip profession info (no verdict)", function()
  it("single profession, no extras", function()
    MakeSpace.Data = MakeSpace.Data or {}
    MakeSpace.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(1%-50%)"))
    assert.is_truthy(tt.lines[1].text:find("|T136240:16:16|t"))
  end)

  it("3 professions, player has none: top 2 by range + extras", function()
    MakeSpace.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 }, -- range 75
        { "Blacksmithing", 3, 180, 300 }, -- range 120
        { "Tailoring",     3, 170, 195 }, -- range 25
      },
    }
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Blacksmithing %(180%-300%)"))
    assert.is_truthy(tt.lines[2].text:find("Alchemy %(215%-290%) %+1"))
  end)

  it("5 professions, player has none: top 2 + +3", function()
    MakeSpace.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 }, -- 75
        { "Blacksmithing",  3, 180, 300 }, -- 120
        { "Tailoring",      3, 170, 195 }, -- 25
        { "Engineering",    6, 160, 195 }, -- 35
        { "Leatherworking", 4, 170, 200 }, -- 30
      },
    }
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Blacksmithing %(180%-300%)"))
    assert.is_truthy(tt.lines[2].text:find("Alchemy %(215%-290%) %+3"))
  end)

  it("player has the profession: shows it, no extras", function()
    MakeSpace.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 4, 170, 200 },
      },
    }
    MakeSpace.Scanner = {
      professionNames = { Leatherworking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Leatherworking %(170%-200%)"))
  end)

  it("shows the range through a conversion, not just the direct recipes", function()
    MakeSpace.Data.ReagentProfessions = {
      [2838] = { { "Blacksmithing", 3, 100, 100, 112 } },
    }
    MakeSpace.Data.ReagentChains = {
      [2838] = { { "Blacksmithing", 125, 240, 250 } },
    }
    MakeSpace.Scanner = {
      professionNames = { Blacksmithing = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:2838:...|h[Heavy Stone]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    MakeSpace.Data.ReagentChains = nil

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Blacksmithing %(100%-240%)"))
  end)

  it("player has 2 matching: both shown, main first", function()
    MakeSpace.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",        2, 215, 290 },
        { "Blacksmithing",  3, 180, 300 },
        { "Leatherworking", 4, 170, 200 },
      },
    }
    MakeSpace.Scanner = {
      professionNames = { Alchemy = true, Leatherworking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(215%-290%)"))
    assert.is_truthy(tt.lines[2].text:find("Leatherworking %(170%-200%)"))
  end)

  it("player has secondary prof: sorted after main", function()
    MakeSpace.Data.ReagentProfessions = {
      [159] = {
        { "Cooking",     7, 50,  275 },
        { "Engineering", 3, 100, 275 },
      },
    }
    MakeSpace.Scanner = {
      professionNames = { Engineering = true, Cooking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:159:...|h[Refreshing Spring Water]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("Engineering %(100%-275%)"))
    assert.is_truthy(tt.lines[2].text:find("Cooking %(50%-275%)"))
  end)

  it("shows single number when min equals max", function()
    MakeSpace.Data.ReagentProfessions = {
      [100] = { { "Cooking", 3, 75, 75 } },
    }
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:100:...|h[Test]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Cooking %(75%)"))
  end)

  it("uses info blue color for default text", function()
    MakeSpace.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    MakeSpace.Scanner = {
      professionNames = nil,
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0.40, tt.lines[1].r)
    assert.are.equal(0.74, tt.lines[1].g)
    assert.are.equal(1.0, tt.lines[1].b)
  end)

  it("does nothing when link is nil", function()
    MakeSpace.Data.ReagentProfessions = {
      [765] = { { "Alchemy", 5, 1, 50 } },
    }
    local tt = makeTooltip(nil)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    assert.are.equal(0, #tt.lines)
  end)
end)

describe("tooltip vendor reagent verdict", function()
  it("single line with professions in parens, no detail rows", function()
    MakeSpace.Data.ReagentProfessions = {
      [3371] = { { "Alchemy", 20, 1, 300 } },
    }
    MakeSpace.Data.VendorReagents = {
      [3371] = { 171 },
    }
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Vendor reagent (Alchemy)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:3371:...|h[Empty Vial]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Vendor reagent (Alchemy)", tt.lines[2].text)
    MakeSpace.Data.VendorReagents = nil
  end)

  it("multi-prof vendor: a reason that fits stays on one line", function()
    MakeSpace.Data.ReagentProfessions = {
      [2320] = {
        { "Leatherworking", 10, 1, 300 },
        { "Tailoring",      10, 1, 300 },
      },
    }
    MakeSpace.Data.VendorReagents = {
      [2320] = { 165, 197 },
    }
    MakeSpace.Scanner = {
      GetResult = function()
        return {
          verdict = "green",
          reason = "Vendor reagent (Leatherworking, Tailoring)"
        }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Vendor reagent (Leatherworking, Tailoring)", tt.lines[2].text)
    MakeSpace.Data.VendorReagents = nil
  end)

  it("no profession rows when vendor reagent has no verdict", function()
    MakeSpace.Data.ReagentProfessions = {
      [159] = { { "Cooking", 7, 90, 315 }, { "Engineering", 3, 130, 275 } },
    }
    MakeSpace.Data.VendorReagents = {
      [159] = { 185, 202 },
    }
    MakeSpace.Scanner = {
      professionNames = { Cooking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:159:...|h[Refreshing Spring Water]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
    MakeSpace.Data.VendorReagents = nil
  end)
end)

describe("tooltip merged verdict lines", function()
  it("green class reagent: single line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Rogue only (vendor)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:5140:...|h[Flash Powder]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Rogue only (vendor)", tt.lines[2].text)
    assert.are.equal(0.33, tt.lines[1].r)
  end)

  it("yellow class reagent: single line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "yellow", reason = "Rogue only (world drop)" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:5530:...|h[Soul Shard]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Rogue only %(world drop%)$"))
  end)

  it("quest verdict: single line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return {
          verdict = "green",
          reason = "Quest already completed"
        }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:200:...|h[Lost Necklace]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Quest already completed", tt.lines[2].text)
  end)
end)

describe("tooltip: a reagent that a quest wants", function()
  local function setup(result, recipes)
    MakeSpace.Data.ReagentProfessions = { [3470] = { { "Alchemy", recipes or 2, 1, 100 } } }
    MakeSpace.Data.QuestItems = { [3470] = { 301, 302, 303 } }
    MakeSpace.Data.QuestInfo = {
      [301] = { 40, "Tanaris", "First Quest" },
      [302] = { 45, "Un'Goro", "Second Quest" },
      [303] = { 50, "Silithus", "Third Quest" },
    }
    MakeSpace.Data.VendorReagents = {}
    MakeSpace.Scanner = { GetResult = function() return result end, professionNames = nil }
  end

  it("names the quest under the hint, with how many more", function()
    setup({ verdict = "yellow", reason = "Outleveled", heading = { title = "Outleveled reagent", detail = "Recipes turn green at Alchemy 100" } })
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("Outleveled reagent$"))
    assert.are.equal("Recipes turn green at Alchemy 100", tt.lines[2].text)
    assert.are.equal("[40] Test Quest 301 (Tanaris) +2", tt.lines[3].text)
  end)

  it("puts the quest last when there is no hint, below the skill ranges", function()
    setup({ verdict = nil, reason = nil })
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.is_truthy(tt.lines[1].text:find("Alchemy"))
    assert.are.equal("[40] Test Quest 301 (Tanaris) +2", tt.lines[#tt.lines].text)
  end)

  it("leaves out repeatable quests, so they are not on every row", function()
    setup({ verdict = nil, reason = nil })
    MakeSpace.Data.RepeatableQuests = { [301] = true, [302] = true }
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    MakeSpace.Data.RepeatableQuests = nil

    assert.are.equal("[50] Test Quest 303 (Silithus)", tt.lines[#tt.lines].text)
  end)

  it("cuts a long quest name so the tooltip does not stretch", function()
    setup({ verdict = nil, reason = nil })
    MakeSpace.Data.QuestInfo[301] = { 40, "A Very Long Zone Name That Would Stretch The Tooltip Wide", "Quest" }
    MakeSpace.Data.QuestItems = { [3470] = { 301 } }
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    local row = tt.lines[#tt.lines].text
    assert.are.equal(46, #row)
    assert.are.equal("...", row:sub(-3))
  end)

  it("shows a quest in your log in plain words, for any reagent", function()
    setup({ verdict = nil, reason = nil }, 12)
    _G.C_QuestLog.IsOnQuest = function(id) return id == 302 end
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    _G.C_QuestLog.IsOnQuest = nil

    assert.are.equal("In log: Test Quest 302", tt.lines[#tt.lines].text)
  end)

  it("counts the other quests in your log", function()
    setup({ verdict = nil, reason = nil }, 12)
    _G.C_QuestLog.IsOnQuest = function(id) return id ~= 303 end
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    _G.C_QuestLog.IsOnQuest = nil

    assert.are.equal("In log: Test Quest 301 +1", tt.lines[#tt.lines].text)
  end)

  it("says nothing of quests you have not taken on a common material", function()
    setup({ verdict = nil, reason = nil }, 4)
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy"))
  end)

  it("leaves out finished quests, and shows no row when none are left", function()
    setup({ verdict = nil, reason = nil })
    local saved = _G.C_QuestLog.IsQuestFlaggedCompleted
    _G.C_QuestLog.IsQuestFlaggedCompleted = function() return true end
    local tt = makeTooltip("|cff...|Hitem:3470:...|h[Rare Herb]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    _G.C_QuestLog.IsQuestFlaggedCompleted = saved

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy"))
  end)
end)

describe("tooltip: a quest item with no quest found", function()
  local savedInstant
  local function run(classID)
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = {}
    MakeSpace.Data.VendorReagents = {}
    MakeSpace.Scanner = { GetResult = function() return { verdict = nil } end }
    savedInstant = _G.C_Item
    _G.C_Item = { GetItemInfoInstant = function() return 9999, "", "", "", 0, classID, 0 end }
    local tt = makeTooltip("|cff...|Hitem:9999:...|h[Odd Thing]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    _G.C_Item = savedInstant
    return tt
  end

  it("says so once, in one row, for a quest-class item", function()
    local tt = run(12)
    assert.are.equal(1, #tt.lines)
    assert.are.equal("Quest item, no quest found", tt.lines[1].text)
  end)

  it("says nothing for any other item", function()
    assert.are.equal(0, #run(15).lines)
  end)
end)

describe("tooltip quest details with level and zone", function()
  it("shows [level] name (zone) when QuestInfo has both", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3456] = { 204 } }
    MakeSpace.Data.QuestInfo = { [204] = { 34, "Stranglethorn Vale" } }
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = nil, reason = nil }
      end,
      professionNames = nil,
    }

    local tt = makeTooltip("|cff...|Hitem:3456:...|h[Sgt's Cloak]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("[34] Test Quest 204 (Stranglethorn Vale)", tt.lines[1].text)
  end)

  it("leaves out quests only the other faction can take", function()
    local savedFaction = _G.UnitFactionGroup
    _G.UnitFactionGroup = function() return "Horde" end
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3460] = { 8520, 8521, 8522 } }
    MakeSpace.Data.QuestInfo = {
      [8520] = { 60, nil, "Alliance Bandages", "A" },
      [8521] = { 60, nil, "More Alliance Bandages", "A" },
      [8522] = { 60, nil, "Horde Bandages", "H" },
    }
    MakeSpace.Scanner = { GetResult = function() return { verdict = nil, reason = nil } end }

    local tt = makeTooltip("|cff...|Hitem:3460:...|h[Silk Bandage]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    MakeSpace.Data.QuestItems = { [3460] = { 8520 } }
    local tt2 = makeTooltip("|cff...|Hitem:3460:...|h[Silk Bandage]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt2)
    _G.UnitFactionGroup = savedFaction

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Test Quest 8522", 1, true))
    assert.are.equal(0, #tt2.lines)
  end)

  it("shows [level] name when QuestInfo has level but no zone", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3457] = { 100 } }
    MakeSpace.Data.QuestInfo = { [100] = { 22, nil } }
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = nil, reason = nil }
      end,
      professionNames = nil,
    }

    local tt = makeTooltip("|cff...|Hitem:3457:...|h[Test Item]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("[22] Test Quest 100", tt.lines[1].text)
  end)

  it("shows name (zone) when QuestInfo has zone but no level", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3458] = { 300 } }
    MakeSpace.Data.QuestInfo = { [300] = { nil, "Ashenvale" } }
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = nil, reason = nil }
      end,
      professionNames = nil,
    }

    local tt = makeTooltip("|cff...|Hitem:3458:...|h[Test Item]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Test Quest 300 (Ashenvale)", tt.lines[1].text)
  end)

  it("falls back to plain name when no QuestInfo entry", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3459] = { 999 } }
    MakeSpace.Data.QuestInfo = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = nil, reason = nil }
      end,
      professionNames = nil,
    }

    local tt = makeTooltip("|cff...|Hitem:3459:...|h[Test Item]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(1, #tt.lines)
    assert.are.equal("Test Quest 999", tt.lines[1].text)
  end)

  it("respects 2-line limit with overflow count", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Data.QuestItems = { [3460] = { 10, 20, 30 } }
    MakeSpace.Data.QuestInfo = {
      [10] = { 15, "Westfall" },
      [20] = { 25, "Duskwood" },
      [30] = { 35, "Stranglethorn Vale" },
    }
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = nil, reason = nil }
      end,
      professionNames = nil,
    }

    local tt = makeTooltip("|cff...|Hitem:3460:...|h[Multi Quest]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("[15] Test Quest 10 (Westfall)", tt.lines[1].text)
    -- Second line should have +1 overflow
    assert.is_truthy(tt.lines[2].text:find("%+1"))
  end)
end)

describe("tooltip verdict edge cases", function()
  it("skips verdict for non-bag tooltips", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "test" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:789:...|h[AH Item]|h|r", "AuctionFrame", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)

  it("does not show reagent info for non-bag tooltip", function()
    MakeSpace.Data.ReagentProfessions = {
      [7067] = {
        { "Alchemy",       2, 215, 290 },
        { "Blacksmithing", 3, 180, 300 },
      },
    }
    MakeSpace.Scanner = { professionNames = nil }

    local tt = makeTooltip("|cff...|Hitem:7067:...|h[Elemental Earth]|h|r", "AuctionFrame", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
  end)
end)

describe("tooltip quest completed two-line format", function()
  it("renders verdict green and detail info-blue on second line", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Quest completed", detail = "[34] Bad Medicine" }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:2799:...|h[Gorilla Fang]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(3, #tt.lines)
    assert.are.equal("Quest completed", tt.lines[2].text)
    assert.are.equal(0.33, tt.lines[1].r)
    assert.are.equal(0.87, tt.lines[1].g)
    assert.are.equal(0.49, tt.lines[1].b)
    assert.are.equal("[34] Bad Medicine", tt.lines[3].text)
    assert.are.equal(0.40, tt.lines[3].r)
    assert.are.equal(0.74, tt.lines[3].g)
    assert.are.equal(1.0, tt.lines[3].b)
  end)

  it("no detail line when detail is nil", function()
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        return { verdict = "green", reason = "Quest completed", detail = nil }
      end,
    }

    local tt = makeTooltip("|cff...|Hitem:2799:...|h[Gorilla Fang]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Quest completed", tt.lines[2].text)
  end)
end)

describe("tooltip vendor reagent quest row suppression", function()
  it("no quest rows when vendor reagent has no verdict", function()
    MakeSpace.Data.ReagentProfessions = {
      [159] = { { "Cooking", 7, 50, 275 } },
    }
    MakeSpace.Data.QuestItems = { [159] = { 16 } }
    MakeSpace.Data.QuestInfo = { [16] = { 10, "Elwynn Forest", "Give Gerard a Drink" } }
    MakeSpace.Data.VendorReagents = {
      [159] = { 185, 202 },
    }
    MakeSpace.Scanner = {
      professionNames = { Cooking = true },
      GetResult = function() return {} end,
    }

    local tt = makeTooltip("|cff...|Hitem:159:...|h[Refreshing Spring Water]|h|r", "ContainerFrame1", 0, 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)

    assert.are.equal(0, #tt.lines)
    MakeSpace.Data.VendorReagents = nil
  end)
end)


describe("tooltip reagent bag (Forever)", function()
  it("resolves items in bag 5 when the client has a reagent bag slot", function()
    local lookups = {}
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function(bag, slot)
        lookups[#lookups + 1] = { bag = bag, slot = slot }
        return { verdict = "green", reason = "Test reason" }
      end,
    }

    _G.NUM_REAGENTBAG_SLOTS = 1
    local tt = makeTooltip(
      "|cff...|Hitem:765:...|h[Silverleaf]|h|r",
      "ContainerFrameCombinedBags", 0, 3, 5)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    _G.NUM_REAGENTBAG_SLOTS = nil

    assert.are.equal(1, #lookups)
    assert.are.equal(5, lookups[1].bag)
    assert.are.equal(3, lookups[1].slot)
  end)
end)

describe("tooltip in the loot window", function()
  local lootFrame

  -- A tooltip whose owner sits `depth` levels below LootFrame.
  local function makeLootTooltip(itemLink, depth)
    local tt = makeTooltip(itemLink, "x", 0, 1)
    local parent = lootFrame
    for _ = 1, depth do
      local up = parent
      parent = { GetParent = function() return up end, GetID = function() return 0 end }
    end
    local owner = {
      GetParent = function() return parent end,
      GetID = function() return 1 end,
    }
    tt.GetOwner = function() return owner end
    return tt
  end

  local function installScanner(result)
    local calls = { bagLookups = 0, evaluated = {} }
    MakeSpace.Data.ReagentProfessions = {}
    MakeSpace.Scanner = {
      GetResult = function()
        calls.bagLookups = calls.bagLookups + 1
        return { verdict = "yellow", reason = "From a bag" }
      end,
      EvaluateItem = function(itemID)
        calls.evaluated[#calls.evaluated + 1] = itemID
        return result
      end,
    }
    return calls
  end

  local function setup()
    lootFrame = {}
    _G.LootFrame = lootFrame
  end

  local function teardown()
    _G.LootFrame = nil
  end

  it("shows the verdict with loot wording: green means not needed", function()
    setup()
    local calls = installScanner({ verdict = "green", reason = "Vendor reagent (Alchemy)" })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Not needed$"))
    assert.are.equal("Vendor reagent (Alchemy)", tt.lines[2].text)
    assert.are.equal(2320, calls.evaluated[1])
  end)

  it("does not call a taken item 'not needed': the plan says take it", function()
    setup()
    installScanner({ verdict = "green", reason = "Vendor reagent (Alchemy)" })
    MakeSpace.Scanner.LootDecision = function() return "take" end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    for _, line in ipairs(tt.lines) do
      assert.is_truthy(not line.text:find("Not needed"))
    end
    assert.is_truthy(tt.lines[#tt.lines].text:find("Take it$"))
  end)

  it("a single skipped item with no junk to compare says it is not worth a slot", function()
    setup()
    installScanner(nil)
    MakeSpace.Scanner.LootDecision = function() return "leave" end
    MakeSpace.Scanner.MakeRoomSummary = function() return {} end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Skip it$"))
    assert.are.equal("Not worth a slot", tt.lines[2].text)
  end)

  it("explains the X on an item that already has its own verdict", function()
    setup()
    installScanner({ verdict = "yellow", reason = "Some unlisted hint" })
    MakeSpace.Scanner.LootDecision = function() return "leave" end
    MakeSpace.Scanner.MakeRoomSummary = function()
      return { cheapestJunkValue = 800, cheapestJunkName = "Odd Bauble", cheapestJunkQuality = 0 }
    end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Some unlisted hint$"))
    assert.are.equal("Worth less than |cff9d9d9dOdd Bauble|r (8s)", plainCoins(tt.lines[2].text))
  end)

  it("says a must-take item has no room even when it has its own verdict", function()
    setup()
    installScanner({ verdict = "yellow", reason = "Some unlisted hint" })
    MakeSpace.Scanner.LootDecision = function() return "noroom" end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal("Nothing safe to delete", tt.lines[2].text)
  end)

  it("says to consider an item taken for a reason a price cannot judge", function()
    setup()
    installScanner(nil)
    MakeSpace.Scanner.LootDecision = function() return "consider" end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal("May be needed", tt.lines[#tt.lines].text)
    assert.is_truthy(tt.lines[#tt.lines - 1].text:find("Take it", 1, true))
    assert.are.equal(0.33, tt.lines[#tt.lines - 1].r)
  end)

  it("names the cheapest gray on one line, item and coins coloured", function()
    setup()
    installScanner(nil)
    MakeSpace.Scanner.LootDecision = function() return "leave" end
    MakeSpace.Scanner.MakeRoomSummary = function()
      return { cheapestJunkValue = 117, cheapestJunkName = "Odd Bauble", cheapestJunkQuality = 0 }
    end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(2, #tt.lines)
    assert.are.equal("Worth less than |cff9d9d9dOdd Bauble|r (1s 17c)", plainCoins(tt.lines[2].text))
  end)

  it("a skipped gray does not repeat its own price", function()
    setup()
    installScanner({ verdict = "green", reason = "Cheapest gray, sells for 1s 1c",
                     tag = MakeSpace.Verdict.POOR_QUALITY_TAG })
    MakeSpace.Scanner.LootDecision = function() return "leave" end
    MakeSpace.Scanner.MakeRoomSummary = function()
      return { cheapestJunkValue = 117, cheapestJunkName = "Odd Bauble", cheapestJunkQuality = 0 }
    end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Skip it$"))
    assert.is_truthy(tt.lines[2].text:find("^Worth less than"))
  end)

  it("does not repeat a gray's own sell price next to the comparison", function()
    setup()
    installScanner({ verdict = "green", reason = "Cheapest gray, sells for 1s 1c",
      tag = MakeSpace.Verdict.POOR_QUALITY_TAG })
    MakeSpace.Scanner.LootDecision = function() return "leave" end
    MakeSpace.Scanner.MakeRoomSummary = function()
      return { cheapestJunkValue = 117, cheapestJunkName = "Odd Bauble", cheapestJunkQuality = 0 }
    end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    tt:GetOwner().slot = 1
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(2, #tt.lines)
    assert.is_truthy(tt.lines[2].text:find("Worth less than", 1, true))
  end)

  it("names a recognised yellow by what was found, detail underneath", function()
    setup()
    installScanner({ verdict = "yellow", reason = "Outleveled, Mining recipes use it up to 125",
      heading = { title = "Outleveled reagent", detail = "Mining recipes use it up to 125" } })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Outleveled reagent$"))
    assert.are.equal("Mining recipes use it up to 125", tt.lines[2].text)
  end)

  it("tells a yellow gray to be saved for the vendor, with the value on one line", function()
    setup()
    local reason, heading = MakeSpace.Verdict.PoorQualityReason(500, true)
    installScanner({ verdict = "yellow", reason = reason, heading = heading })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Save for vendor$"))
    assert.are.equal("Cheapest gray, but worth 5s", plainCoins(tt.lines[2].text))
    assert.are.equal(2, #tt.lines)
  end)

  it("shows only the heading when a yellow has no detail", function()
    setup()
    installScanner({ verdict = "yellow", reason = "Marked by you", heading = { title = "Marked by you" } })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Marked by you$"))
    assert.are.equal(1, #tt.lines)
  end)

  it("names a yellow with no heading of its own by its reason", function()
    setup()
    installScanner({ verdict = "yellow", reason = "Some unlisted hint" })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.is_truthy(tt.lines[1].text:find("Some unlisted hint$"))
    assert.are.equal(1, #tt.lines)
  end)

  it("finds the loot frame several levels up", function()
    setup()
    local calls = installScanner({ verdict = "green", reason = "Quest completed" })

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 3)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(1, #calls.evaluated)
  end)

  it("never mistakes a loot row for a bag slot holding the same item", function()
    setup()
    local calls = installScanner({ verdict = "green", reason = "Quest completed" })
    _G.C_Container.GetContainerItemInfo = function() return { itemID = 2320 } end

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(0, calls.bagLookups)
  end)

  it("shows profession info for loot with no verdict", function()
    setup()
    installScanner({})
    MakeSpace.Data.ReagentProfessions = { [765] = { { "Alchemy", 9, 1, 50 } } }

    local tt = makeLootTooltip("|cff...|Hitem:765:...|h[Silverleaf]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(1, #tt.lines)
    assert.is_truthy(tt.lines[1].text:find("Alchemy %(1%-50%)"))
  end)

  it("shows nothing extra when the game has not loaded the item yet", function()
    setup()
    installScanner(nil)

    local tt = makeLootTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", 1)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(0, #tt.lines)
  end)

  it("does not treat tooltips outside the loot window as loot", function()
    setup()
    local calls = installScanner({ verdict = "green", reason = "x" })
    local tt = makeTooltip("|cff...|Hitem:2320:...|h[Coarse Thread]|h|r", nil)
    MakeSpace.Tooltip.OnTooltipSetItem(tt)
    teardown()

    assert.are.equal(0, #calls.evaluated)
    assert.are.equal(0, #tt.lines)
  end)
end)
