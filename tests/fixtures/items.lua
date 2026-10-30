-- Bagwise: test item fixtures
-- Fake item data for unit tests. No WoW API needed.

return {
    soulbound_wrong_class = {
        id = 12345,
        name = "Lightforge Breastplate",
        quality = 3,
        soulbound = true,
        classRestriction = "Paladin",
        raceRestriction = nil,
        reqLevel = 40,
        isEquippable = true,
    },
    quest_item_completed = {
        id = 3713,
        name = "Soothing Turtle Bisque",
        quality = 1,
        soulbound = false,
        questItem = true,
        associatedQuests = { 555 },
    },
    reagent_no_recipe = {
        id = 99998,
        name = "Severed Ear",
        quality = 0,
        soulbound = false,
        isReagent = true,
    },
}
