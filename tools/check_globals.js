#!/usr/bin/env node
// Lists every global variable the addon's Lua files read or write and fails on
// any that is not on the list below. It catches typos and variables that were
// meant to be local (a missing `local` is a silent bug in WoW addons), which the
// tests only notice on the paths they happen to run.
//
// Usage:  NODE_PATH=<dir with luaparse> node tools/check_globals.js
//         (CI installs luaparse; locally: npm install --prefix /tmp/lp luaparse@0.3.1)

const fs = require("fs");
const path = require("path");
const luaparse = require("luaparse");

const LUA = new Set(("assert collectgarbage error getmetatable ipairs loadstring next pairs pcall print " +
  "rawequal rawget rawset select setmetatable tonumber tostring type unpack xpcall string table math os " +
  "io debug coroutine _G _VERSION").split(" "));

// What the WoW client (or another addon) provides. Read only.
const WOW = new Set(("Baganator Bagnon C_AddOns C_Container C_Item C_QuestLog C_SkillInfo C_Timer " +
  "ChatFontNormal CloseAllBags ContainerFrame1 ContainerFrameCombinedBags CreateFrame EUI_Bags " +
  "EllesmereUI Enum GameTooltip GetAddOnMetadata GetBagName GetBuildInfo GetInventoryItemLink " +
  "GetItemInfo GetItemInfoInstant GetLootSlotInfo GetLootSlotLink GetNumLootItems GetNumSkillLines " +
  "GetProfessionInfo GetProfessions GetCurrentRegion GetNormalizedRealmName GetRealmName GetServerTime GetSkillLineInfo IsAnyBagOpen " +
  "ITEM_OPENABLE ITEM_QUALITY_COLORS LOOTFRAME_NUMBUTTONS LootFrame LootSlotHasItem NUM_BAG_SLOTS " +
  "NUM_CONTAINER_FRAMES NUM_REAGENTBAG_SLOTS OpenAllBags SlashCmdList TooltipDataProcessor UIParent " +
  "UISpecialFrames UnitClass UnitFactionGroup UnitLevel UnitName UnitRace hooksecurefunc time tinsert").split(" "));

// The only globals the addon may create.
const OURS = new Set(["Bagwise", "BagwiseDB", "SLASH_BAGWISE1"]);

const root = path.resolve(__dirname, "..");
const files = fs.readdirSync(path.join(root, "src")).filter(f => f.endsWith(".lua"))
  .map(f => path.join("src", f)).concat(["Bagwise.lua"]);

let problems = 0;
for (const file of files) {
  const ast = luaparse.parse(fs.readFileSync(path.join(root, file), "utf8"),
    { scope: true, luaVersion: "5.1", locations: true });
  const written = new Set();
  (function walk(node) {
    if (!node || typeof node !== "object") return;
    if (Array.isArray(node)) { node.forEach(walk); return; }
    if (node.type === "AssignmentStatement") {
      for (const target of node.variables) {
        if (target.type === "Identifier" && target.isLocal === false) written.add(target);
      }
    }
    if (node.type === "Identifier" && node.isLocal === false) {
      const known = LUA.has(node.name) || WOW.has(node.name) || OURS.has(node.name);
      if (!known) {
        console.log(`${file}:${node.loc.start.line}: unknown global '${node.name}'`);
        problems++;
      } else if (written.has(node) && !OURS.has(node.name) && node.name !== "SlashCmdList") {
        console.log(`${file}:${node.loc.start.line}: writes the global '${node.name}'`);
        problems++;
      }
    }
    for (const key in node) if (key !== "loc" && key !== "range" && key !== "globals") walk(node[key]);
  })(ast);
}
console.log(problems === 0 ? `ok: ${files.length} files` : `${problems} problem(s)`);
process.exit(problems === 0 ? 0 : 1);
