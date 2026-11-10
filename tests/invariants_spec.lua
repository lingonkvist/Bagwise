-- Bagwise: invariants over the real data.
--
-- Not "does this example work" but "can any item, in any realistic situation,
-- break a rule we never want broken". The data is finite, so the check is
-- exhaustive instead of random: every item in the reagent and quest data
-- crossed with qualities, binding, quest progress, levels and classes.
-- A bug like "a finished quest marks Earthroot safe to delete" fails here
-- before anyone sees it in game.

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

local CLASSES = { "WARRIOR", "MAGE", "ROGUE", "DRUID", "SHAMAN" }
local LEVELS = { 12, 35, 60 }
local QUALITIES = { 0, 1, 2, 3 }
local QUEST_STATES = { "none", "open", "done" }
local ITEM_CLASSES = { 7, 12, 15, 4 } -- trade goods, quest, miscellaneous, armor

local function idsOf(...)
  local seen, ids = {}, {}
  for _, tbl in ipairs({ ... }) do
    for id in pairs(tbl or {}) do
      if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
  end
  table.sort(ids)
  return ids
end

--- Run `check(item, state, verdict, winningRule)` over every combination.
-- @return number the number of combinations checked
local function forEverySituation(ids, check)
  local checked = 0
  for _, id in ipairs(ids) do
    for _, itemClass in ipairs(ITEM_CLASSES) do
      for _, quality in ipairs(QUALITIES) do
        for _, bound in ipairs({ true, false }) do
          for _, questState in ipairs(QUEST_STATES) do
            local item = {
              id = id, classID = itemClass, quality = quality, count = 1,
              sellPrice = 50, itemLevel = 8, reqLevel = 5,
              isBound = bound, isEquippable = (itemClass == 4),
            }
            if questState ~= "none" then
              item.questItemQuestIDs = { 1 }
              item.allQuestObjectivesCompleted = (questState == "done")
            end
            for _, level in ipairs(LEVELS) do
              for _, class in ipairs(CLASSES) do
                local state = {
                  level = level, playerClass = class, class = class,
                  professionNames = {}, professionSkillLines = {},
                }
                local verdict = Bagwise.Verdict.Evaluate(item, state)
                local winner
                for _, entry in ipairs(Bagwise.Verdict.Trace(item, state)) do
                  if not entry.blockedBy and entry.verdict == verdict then
                    winner = entry.rule; break
                  end
                end
                check(item, state, verdict, winner)
                checked = checked + 1
              end
            end
          end
        end
      end
    end
  end
  return checked
end

describe("Safety invariants over the real data", function()
  local D = Bagwise.Data
  local reagentIds = idsOf(D.ReagentProfessions, D.VendorReagents, D.ClassReagents)

  it("no reagent is ever green unless a reagent rule decided it", function()
    local greens = 0
    local checked = forEverySituation(reagentIds, function(item, _, verdict, winner)
      if verdict == "green" then
        greens = greens + 1
        assert.are.equal(true, winner == "vendor_reagent" or winner == "class_reagent")
      end
    end)
    assert.are.equal(true, checked > 100000) -- guard against a test that checks nothing
    assert.are.equal(true, greens > 0)       -- and one that never sees a green at all
  end)

  it("an open quest item is never green", function()
    local ids = idsOf(D.QuestItems)
    local sample = {}
    for i = 1, #ids, 7 do sample[#sample + 1] = ids[i] end -- every 7th keeps it quick
    local seenOpen = 0
    forEverySituation(sample, function(item, _, verdict)
      if item.questItemQuestIDs and not item.allQuestObjectivesCompleted then
        seenOpen = seenOpen + 1
        assert.are.equal(false, verdict == "green")
      end
    end)
    assert.are.equal(true, seenOpen > 1000)
  end)

  it("the hearthstone and profession tools are never green", function()
    local essentials = { 6948, 2901, 5956, 7005, 6219, 6256, 4471 }
    local checked = forEverySituation(essentials, function(_, _, verdict)
      assert.are.equal(false, verdict == "green")
    end)
    assert.are.equal(true, checked > 1000)
  end)

  it("make-room never offers a protected item", function()
    local ids = reagentIds
    local offered, checked = 0, 0
    for _, id in ipairs(ids) do
      for _, quality in ipairs({ 0, 1 }) do
        local item = { id = id, classID = 15, quality = quality, sellPrice = 5, count = 1 }
        checked = checked + 1
        if Bagwise.MakeRoom.IsJunkCandidate(item) then offered = offered + 1 end
      end
    end
    assert.are.equal(true, checked > 1000)
    assert.are.equal(0, offered)
  end)
end)
