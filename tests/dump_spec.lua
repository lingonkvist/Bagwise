-- Bagwise: inventory dump formatting tests

dofile("src/dump.lua")

local function snapshotWith(rows)
  return {
    player = {
      class = "MAGE", race = "Human", faction = "Alliance", level = 42,
      professions = { "Alchemy", "Tailoring" },
    },
    rows = rows,
    uncached = 0,
  }
end

local function split(line)
  local cells = {}
  for value in (line .. "|"):gmatch("(.-)|") do cells[#cells + 1] = value end
  return cells
end

describe("Dump.Format", function()
  it("starts with player state and a column header", function()
    local text = Bagwise.Dump.Format(snapshotWith({}), { version = "0.3.0", build = "1.15.6 (1)" })

    assert.is_truthy(text:find("# bagwise=0.3.0 wow=1.15.6 (1)", 1, true))
    assert.is_truthy(text:find("# class=MAGE race=Human faction=Alliance level=42", 1, true))
    assert.is_truthy(text:find("# professions=Alchemy,Tailoring", 1, true))
    assert.is_truthy(text:find("# columns: bag|slot|id|name", 1, true))
    assert.is_truthy(text:find("# 0 items", 1, true))
  end)

  it("writes one pipe-separated row per item with the same columns as the header", function()
    local text = Bagwise.Dump.Format(snapshotWith({
      {
        bag = 0, slot = 3, id = 2589, name = "Linen Cloth", count = 20,
        maxStack = 20, quality = 1, classID = 7, subClassID = 5, bindType = 0,
        isBound = false, sellPrice = 13, verdict = "green",
        reason = "Vendor reagent", recipeProfessions = { "Tailoring", "First Aid" },
        quests = { { id = 100, done = true }, { id = 101, done = false, faction = "H" } },
        isVendorReagent = false, isClassReagent = false,
      },
    }), {})

    local lines = {}
    for line in text:gmatch("[^\n]+") do lines[#lines + 1] = line end
    local header = split(lines[5]:gsub("^# columns: ", ""))
    local row = split(lines[6])

    assert.are.equal(#header, #row)
    assert.are.equal("0", row[1])
    assert.are.equal("3", row[2])
    assert.are.equal("Linen Cloth", row[4])
    assert.are.equal("green", row[16])
    assert.are.equal("Tailoring,First Aid", row[20])
    assert.are.equal("100:done,101:open:H", row[21])
  end)

  it("leaves missing values empty and writes booleans as 1 and 0", function()
    local text = Bagwise.Dump.Format(snapshotWith({
      { bag = 1, slot = 1, id = 9, isBound = true, isKept = false },
    }), {})
    local row = split(text:match("\n(1|1|9[^\n]*)"))

    assert.are.equal("", row[4])
    assert.are.equal("1", row[14])
    assert.are.equal("0", row[18])
  end)

  it("keeps a pipe in an item name from breaking the columns", function()
    local text = Bagwise.Dump.Format(snapshotWith({
      { bag = 0, slot = 1, id = 5, name = "Odd|Name" },
    }), {})

    assert.is_truthy(text:find("Odd/Name", 1, true))
  end)

  it("says how many items were not cached yet", function()
    local snapshot = snapshotWith({ { bag = 0, slot = 1, id = 5 } })
    snapshot.uncached = 1

    local text = Bagwise.Dump.Format(snapshot, {})

    assert.is_truthy(text:find("1 not cached yet", 1, true))
  end)
end)
