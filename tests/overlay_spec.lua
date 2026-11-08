-- Bagwise: overlay tests (EllesmereUI Bags adapter and recycled buttons)
-- Run with: python3 -I tests/run_tests.py (from the Bagwise/ root)

_G.Bagwise = nil
dofile("src/bags.lua")
dofile("src/overlay.lua")

local function makeDotTexture()
  local dot = { shown = false }
  function dot:SetSize() end
  function dot:SetBlendMode() end
  function dot:SetTexture(path) self.texture = path end
  function dot:SetPoint() end
  function dot:SetVertexColor(r, g, b) self.color = { r, g, b } end
  function dot:Show() self.shown = true end
  function dot:Hide() self.shown = false end
  function dot:CreateAnimationGroup()
    local group = { playing = false }
    function group:SetLooping() end
    function group:CreateAnimation()
      return { SetOrder = function() end, SetDuration = function() end,
               SetSmoothing = function() end, SetScaleFrom = function() end,
               SetScaleTo = function() end,
               SetFromAlpha = function() end, SetToAlpha = function() end }
    end
    function group:IsPlaying() return self.playing end
    function group:Play() self.playing = true end
    function group:Stop() self.playing = false end
    dot.group = group
    return group
  end
  return dot
end

-- A fake item button: its parent frame carries the bag ID, its own ID is the slot.
local function makeButton(bagID, slotID, visible)
  local parent = { GetID = function() return bagID end }
  local button = { visible = visible ~= false, dots = {} }
  function button:GetID() return slotID end
  function button:GetParent() return parent end
  function button:IsVisible() return self.visible end
  function button:CreateTexture()
    local dot = makeDotTexture()
    self.dots[#self.dots + 1] = dot
    return dot
  end
  return button
end

local function installEllesmere(pool)
  _G.EllesmereUI = {
    _ModuleNS = { EllesmereUIBags = { _bagsInternals = { itemSlots = pool } } },
  }
end

-- results is keyed "bag:slot"
local function installScanner(results)
  Bagwise.Scanner = {
    GetResult = function(bag, slot) return results[bag .. ":" .. slot] end,
  }
end

describe("Ellesmere Bags adapter", function()
  it("paints each visible button from its parent's bag ID and its own slot", function()
    local first = makeButton(0, 3)
    local second = makeButton(2, 5)
    installEllesmere({ first, second })
    installScanner({
      ["0:3"] = { verdict = "green" },
      ["2:5"] = { verdict = "yellow" },
    })

    Bagwise.Overlay.UpdateAll()

    assert.are.equal(1, #first.dots)
    assert.is_truthy(first.dots[1].shown)
    assert.is_truthy(first.dots[1].texture:find("dot_green$"))
    assert.are.equal(1, #second.dots)
    assert.is_truthy(second.dots[1].shown)
    assert.is_truthy(second.dots[1].texture:find("dot_yellow$"))
    _G.EllesmereUI = nil
  end)

  it("glows a slot marked to delete and stops when it is no longer marked", function()
    local button = makeButton(0, 3)
    installEllesmere({ button })
    installScanner({ ["0:3"] = { verdict = "yellow", glow = true } })

    Bagwise.Overlay.UpdateAll()
    local glow = button.dots[#button.dots]
    assert.is_truthy(glow.shown)
    assert.is_truthy(glow.group.playing)

    installScanner({ ["0:3"] = { verdict = "yellow" } })
    Bagwise.Overlay.UpdateAll()
    assert.are.equal(false, glow.shown)
    assert.are.equal(false, glow.group.playing)
    _G.EllesmereUI = nil
  end)

  it("hides a quiet verdict's dot", function()
    local button = makeButton(0, 3)
    installEllesmere({ button })
    installScanner({ ["0:3"] = { verdict = "green", quiet = true } })

    Bagwise.Overlay.UpdateAll()
    assert.are.equal(false, button.dots[1].shown)
    _G.EllesmereUI = nil
  end)

  it("hides the dot when a recycled button no longer has a verdict", function()
    local button = makeButton(1, 7)
    installEllesmere({ button })
    installScanner({ ["1:7"] = { verdict = "green" } })
    Bagwise.Overlay.UpdateAll()
    assert.is_truthy(button.dots[1].shown)

    installScanner({})
    Bagwise.Overlay.UpdateAll()

    assert.are.equal(1, #button.dots)
    assert.is_truthy(not button.dots[1].shown)
    _G.EllesmereUI = nil
  end)

  it("creates no dot for hidden buttons, unscanned bags or silent items", function()
    local hidden = makeButton(0, 1, false)
    local bankBag = makeButton(6, 1)
    local silent = makeButton(0, 2)
    installEllesmere({ hidden, bankBag, silent })
    installScanner({
      ["0:1"] = { verdict = "green" },
      ["6:1"] = { verdict = "green" },
    })

    Bagwise.Overlay.UpdateAll()

    assert.are.equal(0, #hidden.dots)
    assert.are.equal(0, #bankBag.dots)
    assert.are.equal(0, #silent.dots)
    _G.EllesmereUI = nil
  end)

  it("does nothing, and does not error, when EllesmereUI is not installed", function()
    _G.EllesmereUI = nil
    installScanner({})
    Bagwise.Overlay.UpdateAll()
    assert.is_nil(_G.EllesmereUI)
  end)

  it("does nothing when the pool is missing (a renamed internal)", function()
    _G.EllesmereUI = { _ModuleNS = { EllesmereUIBags = { _bagsInternals = {} } } }
    installScanner({})
    Bagwise.Overlay.UpdateAll()
    _G.EllesmereUI = nil
  end)
end)


describe("Reagent bag (Forever)", function()
  it("paints dots in bag 5 only when the client has a reagent bag slot", function()
    local button = makeButton(5, 2)
    installEllesmere({ button })
    installScanner({ ["5:2"] = { verdict = "green" } })

    _G.NUM_REAGENTBAG_SLOTS = nil
    Bagwise.Overlay.UpdateAll()
    local paintedWithout = #button.dots

    _G.NUM_REAGENTBAG_SLOTS = 1
    Bagwise.Overlay.UpdateAll()
    _G.NUM_REAGENTBAG_SLOTS = nil
    _G.EllesmereUI = nil

    assert.are.equal(0, paintedWithout)
    assert.are.equal(1, #button.dots)
    assert.is_truthy(button.dots[1].shown)
  end)
end)
