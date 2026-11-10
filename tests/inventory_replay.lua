-- Replays a /bagwise dump through the verdict rules, so a real inventory can
-- be used as a test fixture or as a "what if I were level 40" scenario.
-- Pure: reads a dump file, never touches the game.

Bagwise = nil
dofile("src/bags.lua")
dofile("src/safety.lua")
dofile("src/notes.lua")
dofile("src/verdict.lua")
dofile("src/bank.lua")
dofile("src/makeroom.lua")
for _, file in ipairs({ "reagent_professions", "vendor_reagents", "class_reagents", "quest_items" }) do
  dofile("data/" .. file .. ".lua")
end

local Replay = {}
local NOT_GEAR = { INVTYPE_NON_EQUIP_IGNORE = true, INVTYPE_AMMO = true, INVTYPE_BAG = true,
                   INVTYPE_QUIVER = true, [""] = true }
local FACTION_NAMES = { Alliance = "A", Horde = "H" }

local function split(line)
  local cells = {}
  for value in (line .. ";"):gmatch("(.-);") do cells[#cells + 1] = value end
  return cells
end

--- Read a dump into { player = {...}, rows = { {field = value}, ... } }.
function Replay.Load(path)
  local snapshot = { player = {}, rows = {} }
  local columns
  for line in io.lines(path) do
    if line:sub(1, 1) == "#" then
      local cols = line:match("^# columns: (.+)$")
      if cols then columns = split(cols) end
      for key, value in line:gmatch("(%w+)=(%S+)") do
        snapshot.player[key] = value
      end
      local profs = line:match("^# professions=(.*)$")
      if profs then snapshot.player.professions = profs end
    elseif columns and line ~= "" then
      local cells, row = split(line), {}
      for i, name in ipairs(columns) do row[name] = cells[i] end
      snapshot.rows[#snapshot.rows + 1] = row
    end
  end
  return snapshot
end

local function questsOf(cell, factionCode)
  local ids, allDone = {}, true
  for entry in (cell or ""):gmatch("[^,]+") do
    local id, status, faction = entry:match("^(%d+):(%a+):?(%a*)$")
    if not id then id, status = entry:match("^(%d+):(%a+)$") end
    if id and (faction == nil or faction == "" or faction == factionCode) then
      ids[#ids + 1] = tonumber(id)
      if status ~= "done" then allDone = false end
    end
  end
  if #ids == 0 then return nil, nil end
  return ids, allDone
end

--- Evaluate every row. overrides can change level, class, faction,
-- professions (a list), e.g. { level = 40 }.
-- @return table list of { row, verdict, reason }
function Replay.Evaluate(snapshot, overrides)
  overrides = overrides or {}
  local player = snapshot.player
  local factionName = overrides.faction or player.faction
  local state = {
    level = tonumber(overrides.level or player.level),
    class = overrides.class or player.class,
    playerClass = overrides.class or player.class,
    faction = factionName,
    professions = overrides.professions or {},
  }
  local code = FACTION_NAMES[factionName]
  local results = {}
  for _, row in ipairs(snapshot.rows) do
    local questIDs, allDone = questsOf(row.quests, code)
    local item = {
      id = tonumber(row.id), name = row.name, count = tonumber(row.count),
      quality = tonumber(row.quality), itemLevel = tonumber(row.ilvl),
      reqLevel = tonumber(row.reqLvl), classID = tonumber(row.class),
      subClassID = tonumber(row.subclass),
      isEquippable = not NOT_GEAR[row.equipSlot or ""],
      isBound = row.bound == "1", sellPrice = tonumber(row.sellCopper),
      isKept = row.kept == "1", isFlagged = row.flagged == "1",
      hasLoot = row.lootable == "1",
      questItemQuestIDs = questIDs, allQuestObjectivesCompleted = allDone,
    }
    local verdict, reason = Bagwise.Verdict.Evaluate(item, state)
    results[#results + 1] = { row = row, verdict = verdict, reason = reason }
  end
  return results
end

return Replay
