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
  function dot:SetColorTexture() end
  function dot:SetAllPoints() end
  function dot:SetWidth() end
  function dot:SetHeight() end
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
    -- dot 1 is the verdict dot; the rest are the glow layers (rings, wash, frame)
    assert.is_truthy(#button.dots >= 8)
    for i = 2, #button.dots do
      assert.is_truthy(button.dots[i].shown)
      assert.is_truthy(button.dots[i].group.playing)
    end

    installScanner({ ["0:3"] = { verdict = "yellow" } })
    Bagwise.Overlay.UpdateAll()
    for i = 2, #button.dots do
      assert.are.equal(false, button.dots[i].shown)
      assert.are.equal(false, button.dots[i].group.playing)
    end
    _G.EllesmereUI = nil
  end)

  it("hides the glow when the marked slot is emptied and the bag addon never redraws it", function()
    local button = makeButton(0, 3)
    installEllesmere({ button })
    installScanner({ ["0:3"] = { verdict = "green", glow = true } })
    Bagwise.Overlay.UpdateAll()
    assert.is_truthy(button.dots[2].shown)

    -- The junk is deleted: the slot has no result, and the addon does not paint it.
    installEllesmere({})
    installScanner({})
    Bagwise.Overlay.UpdateAll()
    for i = 2, #button.dots do
      assert.are.equal(false, button.dots[i].shown)
      assert.are.equal(false, button.dots[i].group.playing)
    end
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

  it("creates no dot for hidden buttons, bags out of range or silent items", function()
    local hidden = makeButton(0, 1, false)
    local bankBag = makeButton(99, 1)
    local silent = makeButton(0, 2)
    installEllesmere({ hidden, bankBag, silent })
    installScanner({
      ["0:1"] = { verdict = "green" },
      ["99:1"] = { verdict = "green" },
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


describe("Bank bags", function()
  it("paints a bank bag slot when the scanner has a result for it", function()
    local bank = makeButton(6, 2)
    local empty = makeButton(7, 1)
    installEllesmere({ bank, empty })
    installScanner({ ["6:2"] = { verdict = "yellow" } })

    Bagwise.Overlay.UpdateAll()
    _G.EllesmereUI = nil

    assert.are.equal(1, #bank.dots)
    assert.is_truthy(bank.dots[1].shown)
    assert.are.equal(0, #empty.dots)
  end)
end)


describe("Blizzard tabbed bank (Forever)", function()
  -- A bank button knows its own tab and slot; its parent frame carries no bag ID.
  local realIsScanned = Bagwise.Bags.IsScanned
  local function teardown()
    Bagwise.Bags.IsScanned = realIsScanned
    _G.BankFrame, _G.hooksecurefunc = nil, nil
  end
  local function makeBankButton(tabID, slotID)
    local button = makeButton(0, 99)
    function button:GetBankTabID() return tabID end
    function button:GetContainerSlotID() return slotID end
    return button
  end

  -- poolStyle: the real bank panel yields (button, true) from its object pool.
  local function installBankPanel(buttons, poolStyle)
    local panel = { visible = true, hooks = {} }
    function panel:IsVisible() return self.visible end
    function panel:EnumerateValidItems()
      local index = 0
      return function()
        index = index + 1
        if buttons[index] then
          if poolStyle then return buttons[index], true end
          return index, buttons[index]
        end
      end
    end
    function panel:GenerateItemSlotsForSelectedTab() end
    _G.BankFrame = { BankPanel = panel }
    _G.hooksecurefunc = function(target, name, fn)
      local original = target[name]
      target[name] = function(...) original(...) fn(...) end
      panel.hooks[#panel.hooks + 1] = name
    end
    return panel
  end

  it("paints a bank slot from the button's own tab and slot", function()
    local first = makeBankButton(6, 4)
    installBankPanel({ first })
    installScanner({ ["6:4"] = { verdict = "yellow" } })
    Bagwise.Bags.IsScanned = function() return true end
    Bagwise.Overlay.UpdateAll()
    assert.are.equal(1, #first.dots)
    assert.is_truthy(first.dots[1].shown)
    teardown()
  end)

  it("reads the bank panel's button pool, which yields (button, true)", function()
    local first = makeBankButton(6, 4)
    installBankPanel({ first }, true)
    installScanner({ ["6:4"] = { verdict = "green" } })
    Bagwise.Bags.IsScanned = function() return true end
    Bagwise.Overlay.UpdateAll()
    assert.are.equal(1, #first.dots)
    assert.is_truthy(first.dots[1].shown)
    for _, line in ipairs(Bagwise.Overlay.BankDiagnostics()) do
      assert.is_truthy(not line:find("failed"))
    end
    teardown()
  end)

  it("repaints after the panel redraws a tab", function()
    local button = makeBankButton(7, 2)
    local panel = installBankPanel({ button })
    installScanner({ ["7:2"] = { verdict = "green" } })
    Bagwise.Bags.IsScanned = function() return true end
    Bagwise.Overlay.UpdateAll()
    button.dots[1].shown = false
    panel:GenerateItemSlotsForSelectedTab()
    assert.is_truthy(button.dots[1].shown)
    teardown()
  end)

  it("finds a bank panel that is only a child of BankFrame", function()
    local button = makeBankButton(6, 1)
    local panel = installBankPanel({ button })
    _G.BankFrame = { GetChildren = function() return panel end }
    installScanner({ ["6:1"] = { verdict = "green" } })
    Bagwise.Bags.IsScanned = function() return true end
    Bagwise.Overlay.UpdateAll()
    assert.are.equal(1, #button.dots)
    teardown()
  end)

  it("falls back to the panel's child frames when it cannot list its buttons", function()
    local button = makeBankButton(6, 5)
    local other = makeButton(0, 1) -- a child that is not an item button
    local panel = { IsVisible = function() return true end,
                    GetChildren = function() return other, button end }
    _G.BankPanel = panel
    installScanner({ ["6:5"] = { verdict = "green" } })
    Bagwise.Bags.IsScanned = function() return true end
    Bagwise.Overlay.UpdateAll()
    _G.BankPanel = nil
    assert.are.equal(1, #button.dots)
    assert.are.equal(0, #other.dots)
    teardown()
  end)

  it("reports what it sees of the bank for /bagwise bank", function()
    local button = makeBankButton(6, 2)
    installBankPanel({ button })
    installScanner({ ["6:2"] = { verdict = "yellow" } })
    Bagwise.Bags.IsScanned = function() return true end
    local text = table.concat(Bagwise.Overlay.BankDiagnostics(), "\n")
    assert.is_truthy(text:find("Bank panels with item buttons: 1", 1, true))
    assert.is_truthy(text:find("tab 6 slot 2 scanned verdict yellow", 1, true))
    teardown()
  end)

  it("lists the bank among the painted bag UIs", function()
    installBankPanel({})
    local found = table.concat(Bagwise.Overlay.DetectedBagAddons(), ",")
    assert.is_truthy(found:find("Blizzard bank", 1, true))
    teardown()
  end)
end)

describe("Bagnon adapter", function()
  -- A fake Bagnon: Item.UpdateSecondary is what Bagnon calls after each slot refresh.
  local function installBagnon()
    _G.hooksecurefunc = function(target, name, hook)
      local original = target[name]
      target[name] = function(...)
        if original then original(...) end
        hook(...)
      end
    end
    _G.CreateFrame = function()
      return { RegisterEvent = function() end, SetScript = function() end }
    end
    _G.Bagnon = { Item = { UpdateSecondary = function() end } }
  end

  local function makeBagnonButton(bagID, slotID, options)
    options = options or {}
    local button = makeButton(bagID, slotID)
    function button:GetBag() return bagID end
    if options.container ~= false then function button:UpdateCooldown() end end
    if options.cached ~= nil then function button:IsCached() return options.cached end end
    return button
  end

  local function refresh(button)
    Bagnon.Item.UpdateSecondary(button)
  end

  local function tearDown()
    _G.Bagnon = nil
    _G.hooksecurefunc = nil
    _G.CreateFrame = nil
  end

  it("paints a live bag slot when Bagnon refreshes it", function()
    installBagnon()
    installScanner({ ["0:3"] = { verdict = "green" } })
    Bagwise.Overlay.Init()
    local button = makeBagnonButton(0, 3, { cached = false })

    refresh(button)

    assert.are.equal(1, #button.dots)
    assert.is_truthy(button.dots[1].shown)
    assert.is_truthy(button.dots[1].texture:find("dot_green$"))
    tearDown()
  end)

  it("never paints another character's cached slot, even with a matching bag and slot", function()
    installBagnon()
    installScanner({ ["0:3"] = { verdict = "green" } })
    Bagwise.Overlay.Init()
    local cached = makeBagnonButton(0, 3, { cached = true })

    refresh(cached)

    assert.are.equal(0, #cached.dots)
    tearDown()
  end)

  it("clears a dot left on a button that now shows cached items", function()
    installBagnon()
    installScanner({ ["0:3"] = { verdict = "green" } })
    Bagwise.Overlay.Init()
    local button = makeBagnonButton(0, 3, { cached = false })
    refresh(button)
    assert.is_truthy(button.dots[1].shown)

    function button:IsCached() return true end
    refresh(button)

    assert.is_truthy(not button.dots[1].shown)
    tearDown()
  end)

  it("ignores guild bank and void storage buttons", function()
    installBagnon()
    installScanner({ ["1:1"] = { verdict = "green" } })
    Bagwise.Overlay.Init()
    local guild = makeBagnonButton(1, 1, { container = false })

    refresh(guild)

    assert.are.equal(0, #guild.dots)
    tearDown()
  end)

  it("repaints remembered buttons when a scan finishes after Bagnon drew them", function()
    installBagnon()
    installScanner({})
    Bagwise.Overlay.Init()
    local button = makeBagnonButton(0, 3, { cached = false })
    refresh(button)
    assert.are.equal(0, #button.dots)

    installScanner({ ["0:3"] = { verdict = "yellow" } })
    Bagwise.Overlay.UpdateAll()

    assert.is_truthy(button.dots[1].shown)
    assert.is_truthy(button.dots[1].texture:find("dot_yellow$"))
    tearDown()
  end)

  it("does nothing, and does not error, when Bagnon is not installed", function()
    _G.Bagnon = nil
    _G.CreateFrame = function()
      return { RegisterEvent = function() end, SetScript = function() end }
    end
    installScanner({})
    Bagwise.Overlay.Init()
    Bagwise.Overlay.UpdateAll()
    _G.CreateFrame = nil
  end)
end)


describe("Baganator adapter", function()
  local onUpdate

  local function installBaganator()
    onUpdate = nil
    _G.Baganator = { API = { RegisterCornerWidget = function(_, _, update) onUpdate = update end } }
    _G.C_Container = { GetContainerItemID = function(bag, slot) return bag == 0 and slot == 3 and 111 or nil end }
    _G.C_Item = { GetItemInfoInstant = function(link) return tonumber(link:match("item:(%d+)")) end }
    installScanner({ ["0:3"] = { verdict = "green" } })
    Bagwise.Overlay.Init()
  end

  local function paint(details)
    local dot = makeDotTexture()
    return onUpdate(dot, details), dot
  end

  local function tearDown()
    _G.Baganator, _G.C_Container, _G.C_Item = nil, nil, nil
  end

  it("paints a live slot whose item matches the one Baganator shows", function()
    installBaganator()
    local painted, dot = paint({ itemLocation = { bagID = 0, slotIndex = 3 }, itemLink = "item:111" })
    assert.is_truthy(painted)
    assert.is_truthy(dot.shown)
    tearDown()
  end)

  it("never paints a remembered item that shares a live slot's number", function()
    installBaganator()
    local painted, dot = paint({ itemLocation = { bagID = 0, slotIndex = 3 }, itemLink = "item:222" })
    assert.is_truthy(not painted)
    assert.is_truthy(not dot.shown)
    tearDown()
  end)

  it("does not paint a slot that is empty in the real bags", function()
    installBaganator()
    local painted = paint({ itemLocation = { bagID = 0, slotIndex = 4 }, itemLink = "item:111" })
    assert.is_truthy(not painted)
    tearDown()
  end)

  it("keeps painting when Baganator gives no item link to compare", function()
    installBaganator()
    local painted = paint({ itemLocation = { bagID = 0, slotIndex = 3 } })
    assert.is_truthy(painted)
    tearDown()
  end)

  it("skips an item with no location, such as another character's", function()
    installBaganator()
    assert.is_truthy(not paint({ itemLink = "item:111" }))
    tearDown()
  end)

  it("takes a delete glow off a button that now shows an empty or foreign slot", function()
    installBaganator()
    installScanner({ ["0:3"] = { verdict = "green", glow = true } })
    local button = makeButton(0, 3)
    local function dotOf(button_)
      local dot = makeDotTexture()
      dot.GetParent = function() return button_ end
      return dot
    end
    onUpdate(dotOf(button), { itemLocation = { bagID = 0, slotIndex = 3 }, itemLink = "item:111" })
    assert.is_truthy(button.dots[1].shown) -- glow layers were made on the button

    -- The slot is emptied: Baganator redraws the button with a link the real slot does not hold.
    onUpdate(dotOf(button), { itemLocation = { bagID = 0, slotIndex = 4 }, itemLink = "item:111" })
    for i = 1, #button.dots do
      assert.are.equal(false, button.dots[i].shown)
    end
    tearDown()
  end)
end)


describe("Loot banner", function()
  local sharedBanner
  local function fakeFrame()
    local frame = { shown = false, points = {} }
    function frame:SetFrameStrata() end
    function frame:SetSize() end
    function frame:SetHeight() end
    function frame:CreateTexture()
      local texture = makeDotTexture()
      function texture:SetAllPoints() end
      function texture:SetColorTexture() end
      return texture
    end
    function frame:CreateFontString()
      local text = { value = nil }
      function text:SetPoint() end
      function text:SetWidth() end
      function text:SetText(value) self.value = value end
      function text:GetStringHeight() return 14 end
      return text
    end
    function frame:ClearAllPoints() end
    function frame:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    return frame
  end

  local function install(summary)
    dofile("src/makeroom.lua")
    -- The overlay keeps its banner for the whole session, so one fake frame serves every test.
    sharedBanner = sharedBanner or fakeFrame()
    _G.UIParent = {}
    _G.CreateFrame = function() return sharedBanner end
    Bagwise.Scanner = { MakeRoomSummary = function() return summary end }
    return function() return sharedBanner end
  end

  local function tearDown()
    _G.CreateFrame, _G.UIParent, _G.LootFrame = nil, nil, nil
  end

  it("shows what to do while bags are full", function()
    local frame = install({ active = true, deletes = 1, leaving = 0 })
    Bagwise.Overlay.UpdateBanner()
    assert.is_truthy(frame().shown)
    assert.is_truthy(frame().text.value:find("delete the glowing item", 1, true))
    tearDown()
  end)

  it("hides again once the plan is over", function()
    local frame = install({ active = true, deletes = 1, leaving = 0 })
    Bagwise.Overlay.UpdateBanner()
    Bagwise.Scanner = { MakeRoomSummary = function() return { active = false, deletes = 0 } end }
    Bagwise.Overlay.UpdateBanner()
    assert.is_truthy(not frame().shown)
    tearDown()
  end)

  it("sits above the loot window when it is open", function()
    local frame = install({ active = true, deletes = 1, leaving = 0 })
    _G.LootFrame = { IsShown = function() return true end }
    frame().points = {}
    Bagwise.Overlay.UpdateBanner()
    assert.are.equal("BOTTOM", frame().points[1][1])
    tearDown()
  end)
end)
