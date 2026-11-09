-- Bagwise: safety unit tests

dofile("src/bags.lua")
dofile("src/safety.lua")

describe("Safety.Protections", function()
  Bagwise.Data = {
    ReagentProfessions = { [2449] = { { "Alchemy", 9, 20, 175 } } },
    VendorReagents = { [3371] = {} },
    ClassReagents = { [17020] = { classes = { MAGE = true } } },
  }

  it("protects items on the hand-kept known-use list", function()
    Bagwise.Data.ProtectedItems = { [268415] = "Herb seed" }
    assert.are.equal("known_use", Bagwise.Safety.Protections({ id = 268415, classID = 7 })[1])
    Bagwise.Data.ProtectedItems = nil
  end)

  it("lists nothing for an ordinary item", function()
    assert.are.equal(0, #Bagwise.Safety.Protections({ id = 990300, classID = 15 }))
  end)

  it("protects recipe reagents, vendor reagents and spell reagents", function()
    assert.are.equal("recipe_reagent", Bagwise.Safety.Protections({ id = 2449, classID = 7 })[1])
    assert.are.equal("vendor_reagent", Bagwise.Safety.Protections({ id = 3371, classID = 7 })[1])
    assert.are.equal("spell_reagent", Bagwise.Safety.Protections({ id = 17020, classID = 7 })[1])
  end)

  it("protects anything you right-click to open", function()
    assert.are.equal("openable", Bagwise.Safety.Protections({ id = 990310, classID = 7, hasLoot = true })[1])
    assert.are.equal(0, #Bagwise.Safety.Protections({ id = 990310, classID = 7, hasLoot = false }))
  end)

  it("protects the hearthstone, tools, containers and recipes", function()
    assert.are.equal("essential_item", Bagwise.Safety.Protections({ id = 6948, classID = 15 })[1])
    assert.are.equal("essential_item", Bagwise.Safety.Protections({ id = 2901, classID = 2 })[1])
    assert.are.equal("essential_item", Bagwise.Safety.Protections({ id = 990301, classID = 1 })[1])
    assert.are.equal("essential_item", Bagwise.Safety.Protections({ id = 990302, classID = 9 })[1])
  end)

  it("protects quest items until their quests are done", function()
    local open = { id = 990303, classID = 12, questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = false }
    local names = Bagwise.Safety.Protections(open)
    assert.are.equal("quest_item", names[1])
    assert.are.equal("open_quest_item", names[2])

    local done = { id = 990303, classID = 12, questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.are.equal(1, #Bagwise.Safety.Protections(done)) -- only quest_item, which quest rules override
  end)

  it("protects an ordinary item that a quest also uses, even once the quest is done", function()
    local tools = { id = 990305, classID = 15, questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.are.equal("dual_use", Bagwise.Safety.Blocker(tools, { quest_item = true }))
    local real = { id = 990306, classID = 12, questItemQuestIDs = { 1 }, allQuestObjectivesCompleted = true }
    assert.is_nil(Bagwise.Safety.Blocker(real, { quest_item = true }))
  end)

  it("always protects Thieves' Tools", function()
    assert.are.equal("essential_item", Bagwise.Safety.Protections({ id = 5060, classID = 15 })[1])
  end)

  it("protects an item that starts a quest still open", function()
    local starter = { id = 990304, classID = 12, startsQuestID = 5, startsQuestCompleted = false }
    local names = {}
    for _, name in ipairs(Bagwise.Safety.Protections(starter)) do names[name] = true end
    assert.is_truthy(names.open_quest_starter)
  end)
end)

describe("Safety.Blocker", function()
  it("returns the first protection the rule may not override", function()
    local item = { id = 2449, classID = 7 }
    assert.are.equal("recipe_reagent", Bagwise.Safety.Blocker(item, nil))
    assert.are.equal("recipe_reagent", Bagwise.Safety.Blocker(item, { quest_item = true }))
  end)

  it("lets a rule override exactly the protections it names", function()
    local item = { id = 2449, classID = 7 }
    assert.is_nil(Bagwise.Safety.Blocker(item, { recipe_reagent = true }))
  end)
end)
