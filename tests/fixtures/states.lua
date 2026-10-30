-- Bagwise: test player state fixtures

return {
    warrior_30 = {
        class = "Warrior",
        race = "Human",
        level = 30,
        faction = "Alliance",
        professions = {
            { name = "Mining", skill = 150 },
            { name = "Blacksmithing", skill = 120 },
        },
        completedQuests = {},
        activeQuests = {},
    },
    mage_60 = {
        class = "Mage",
        race = "Gnome",
        level = 60,
        faction = "Alliance",
        professions = {
            { name = "Tailoring", skill = 300 },
            { name = "Enchanting", skill = 280 },
        },
        completedQuests = { 555, 1200 },
        activeQuests = {},
    },
}
