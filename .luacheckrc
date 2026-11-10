-- For editors that run luacheck. CI uses tools/check_globals.js instead.
std = "lua51"
max_line_length = false
unused_args = false
exclude_files = { "data/*", "tests/*" }
globals = { "Bagwise", "BagwiseDB", "SLASH_BAGWISE1", "SlashCmdList" }
read_globals = {
  "Baganator", "Bagnon", "C_AddOns", "C_Container", "C_Item", "C_QuestLog", "C_SkillInfo", "C_Timer",
  "ChatFontNormal", "CloseAllBags", "ContainerFrame1", "ContainerFrameCombinedBags", "CreateFrame",
  "EUI_Bags", "EllesmereUI", "Enum", "GameTooltip", "GetAddOnMetadata", "GetBagName", "GetBuildInfo",
  "GetInventoryItemLink", "GetItemInfo", "GetItemInfoInstant", "GetLootSlotInfo", "GetLootSlotLink",
  "GetNumLootItems", "GetNumSkillLines", "GetProfessionInfo", "GetProfessions", "GetRealmName",
  "GetServerTime", "GetSkillLineInfo", "IsAnyBagOpen", "ITEM_OPENABLE", "ITEM_QUALITY_COLORS",
  "LOOTFRAME_NUMBUTTONS", "LootFrame", "LootSlotHasItem", "NUM_BAG_SLOTS", "NUM_CONTAINER_FRAMES",
  "NUM_REAGENTBAG_SLOTS", "OpenAllBags", "TooltipDataProcessor", "UIParent", "UISpecialFrames",
  "UnitClass", "UnitFactionGroup", "UnitLevel", "UnitName", "UnitRace", "hooksecurefunc", "time", "tinsert",
}
