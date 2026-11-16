-- MakeSpace: item menu rows (the frame itself is confirmed in game)

_G.MakeSpace = nil
dofile("src/menu.lua")

local function labels(rows)
  local out = {}
  for _, row in ipairs(rows) do out[#out + 1] = row.label end
  return out
end

local function checkedLabel(rows)
  for _, row in ipairs(rows) do if row.checked then return row.label end end
end

describe("Item menu rows", function()
  it("an item with no dot offers the two dots, and Default says no dot", function()
    local rows = MakeSpace.Menu.Rows(nil, nil)
    assert.are.equal("Default (no dot)", rows[1].label)
    assert.are.equal("Safe to delete", rows[2].label)
    assert.are.equal("Worth a glance", rows[3].label)
    assert.are.equal(3, #rows)
  end)

  it("a green item offers yellow and No dot, never a second green", function()
    local rows = MakeSpace.Menu.Rows("green", nil)
    assert.are.equal("Default (safe to delete)", rows[1].label)
    assert.are.equal("Worth a glance", rows[2].label)
    assert.are.equal("No dot", rows[3].label)
    assert.are.equal(3, #rows)
  end)

  it("a yellow item offers green and No dot", function()
    local rows = MakeSpace.Menu.Rows("yellow", nil)
    assert.are.equal("Default (worth a glance)", rows[1].label)
    assert.are.equal("Safe to delete", rows[2].label)
    assert.are.equal("No dot", rows[3].label)
  end)

  it("always has three rows when nothing is pinned", function()
    for _, default in ipairs({ "green", "yellow", false }) do
      assert.are.equal(3, #MakeSpace.Menu.Rows(default or nil, nil))
    end
  end)

  it("the row for the current choice is checked, Default when there is no mark", function()
    assert.are.equal("Default (no dot)", checkedLabel(MakeSpace.Menu.Rows(nil, nil)))
    assert.are.equal("No dot", checkedLabel(MakeSpace.Menu.Rows("green", "none")))
    assert.are.equal("Safe to delete", checkedLabel(MakeSpace.Menu.Rows(nil, "green")))
  end)

  it("a mark equal to the default still shows, checked, so it is never hidden", function()
    local rows = MakeSpace.Menu.Rows("green", "green")
    assert.are.equal(4, #rows)
    assert.are.equal("Safe to delete", checkedLabel(rows))
    local expected = { "Default (safe to delete)", "Safe to delete", "Worth a glance", "No dot" }
    for i, label in ipairs(labels(rows)) do assert.are.equal(expected[i], label) end
  end)

  it("Default clears the mark, and the dot rows carry their icon", function()
    local rows = MakeSpace.Menu.Rows("yellow", nil)
    assert.is_nil(rows[1].mark)
    assert.are.equal("yellow", rows[1].icon)
    assert.are.equal("green", rows[2].icon)
    assert.is_nil(rows[3].icon)
    assert.are.equal("none", rows[3].mark)
  end)
end)

-- A smoke test of the frame code with stand-in frames: it catches a call on a
-- missing value, which only the game would show otherwise.
describe("Item menu frame", function()
  local function stand_in()
    local frame = { scripts = {}, shown = false }
    return setmetatable(frame, { __index = function(t, key)
      if key == "GetEffectiveScale" then return function() return 1 end end
      if key == "CreateTexture" or key == "CreateFontString" then
        return function() return stand_in() end
      end
      return function(self, ...)
        if key == "SetScript" then local name, fn = ...; self.scripts[name] = fn end
        if key == "SetText" then self.text = ... end
        if key == "Show" then self.shown = true end
        if key == "Hide" then
          self.shown = false
          if self.scripts.OnHide then self.scripts.OnHide() end
        end
      end
    end })
  end

  local GLOBALS = { "CreateFrame", "UIParent", "UISpecialFrames", "tinsert", "GetCursorPosition", "C_Container", "C_Item" }
  local saved = {}
  local function save() for _, name in ipairs(GLOBALS) do saved[name] = _G[name] end end
  local function restore() for _, name in ipairs(GLOBALS) do _G[name] = saved[name] end end

  it("opens for a slot, lists the rows, and a click sets the mark", function()
    save()
    local frames = {}
    _G.CreateFrame = function() local f = stand_in(); frames[#frames + 1] = f; return f end
    _G.UIParent = stand_in()
    _G.UISpecialFrames = {}
    _G.tinsert = table.insert
    _G.GetCursorPosition = function() return 100, 200 end
    _G.C_Container = { GetContainerItemID = function() return 2589 end }
    _G.C_Item = { GetItemInfo = function() return "Linen Cloth" end }
    local set = {}
    MakeSpace.Scanner = { DefaultVerdict = function() return "green" end,
      ClearCache = function() end, ScanAll = function() end }
    MakeSpace.Overlay = { UpdateAll = function() end }
    MakeSpace.Overrides = { Get = function() return nil end,
      Set = function(id, mark, name) set.id, set.mark, set.name = id, mark, name end }

    MakeSpace.Menu.Open(0, 1)

    local clicked
    for _, f in ipairs(frames) do
      if f.scripts.OnClick then clicked = f; break end
    end
    assert.is_truthy(clicked)
    clicked.scripts.OnClick()
    restore()
    assert.are.equal(2589, set.id)
    assert.are.equal("Linen Cloth", set.name)
  end)

  it("does nothing for an empty slot", function()
    save()
    _G.C_Container = { GetContainerItemID = function() return nil end }
    MakeSpace.Menu.Open(0, 1) -- must not raise
    restore()
  end)
end)
