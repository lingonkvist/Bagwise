-- Bagwise: slash command handlers
-- Wired up in Bagwise.lua; helpers live here to keep the entry point small.

Bagwise = Bagwise or {}
Bagwise.Commands = {}

local PREFIX = "|cff54de7d[Bagwise]|r "

local function say(text)
  print(PREFIX .. text)
end

--- Turn the text after a command into an item ID.
-- Accepts a shift-clicked item link, a bare numeric ID, or an item name
-- (names only resolve for items the client has cached, such as bag items).
-- @param argument   string          Text after the command word
-- @param lookupLink function|nil    name -> item link, injected for tests
-- @return number|nil
function Bagwise.Commands.ParseItemID(argument, lookupLink)
  if not argument or argument == "" then return nil end

  local fromLink = argument:match("item:(%d+)")
  if fromLink then return tonumber(fromLink) end

  local fromNumber = argument:match("^%d+$")
  if fromNumber then return tonumber(fromNumber) end

  if lookupLink then
    local link = lookupLink(argument)
    local fromName = link and link:match("item:(%d+)")
    if fromName then return tonumber(fromName) end
  end

  return nil
end

local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

--- The version from the TOC, so it lives in one place.
function Bagwise.Commands.Version()
  local version = getAddOnMetadata and getAddOnMetadata("Bagwise", "Version")
  return version or "unknown"
end

local function gameBuild()
  if not GetBuildInfo then return nil end
  local version, build = GetBuildInfo()
  return version .. " (" .. tostring(build) .. ")"
end

local function itemNameOf(itemID)
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name = getInfo and getInfo(itemID)
  return name or ("item " .. itemID)
end

local function lookupItemLinkByName(name)
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not getInfo then return nil end
  local _, link = getInfo(name)
  return link
end

local function refreshDots()
  Bagwise.Scanner.ClearCache()
  Bagwise.Scanner.ScanAll()
  Bagwise.Overlay.UpdateAll()
end

--- Build a handler that applies an override action to the item in the argument.
local function overrideCommand(usage, apply, confirmation)
  return function(argument)
    local itemID = Bagwise.Commands.ParseItemID(argument, lookupItemLinkByName)
    if not itemID then
      say("Usage: " .. usage)
      return
    end
    local name = itemNameOf(itemID)
    apply(itemID, name)
    say(confirmation:format(name))
    refreshDots()
  end
end

local COMMAND_HANDLERS = {
  help = function()
    say("commands:")
    print("  /bagwise keep [item]    - Never show a dot on this item")
    print("  /bagwise flag [item]    - Always show a yellow dot on this item")
    print("  /bagwise reset [item]   - Return this item to the normal rules")
    print("  /bagwise list           - Show your kept and flagged items")
    print("  /bagwise status         - Show addon status")
    print("  /bagwise dump           - Copyable list of everything in your bags")
    print("  /bagwise why [item]     - Show why an item does or doesn't get a dot")
    print("  /bagwise loot           - Explain what the make-room plan sees (loot window open)")
    print("  /bagwise glow           - Test the delete glow on your first item")
    print("  /bagwise help           - Show this message")
    print("  [item] can be a shift-clicked link, an item ID or an item name.")
  end,
  status = function()
    say("v" .. Bagwise.Commands.Version() .. " on WoW " .. (gameBuild() or "?"))
    local bagUIs = Bagwise.Overlay.DetectedBagAddons()
    print("  Bag UIs painted: " .. (#bagUIs > 0 and table.concat(bagUIs, ", ") or "none found"))
    print("  Bags scanned: 0-" .. Bagwise.Bags.LastScanned())
    local counts = Bagwise.Scanner.Counts()
    print("  Scanned items: " .. counts.items .. " (" .. counts.green .. " green, "
      .. counts.yellow .. " yellow)")
    local function size(tbl)
      local n = 0
      for _ in pairs(tbl or {}) do n = n + 1 end
      return n
    end
    print("  Data: " .. size(Bagwise.Data.QuestItems) .. " quest items, "
      .. size(Bagwise.Data.ReagentProfessions) .. " recipe reagents")
    print("  Safety checks: " .. table.concat(Bagwise.Safety.Names(), ", "))
    print("  Your lists: " .. size(BagwiseDB.keepList) .. " kept, "
      .. size(BagwiseDB.flagList) .. " flagged")
  end,
  why = function(argument)
    local itemID = Bagwise.Commands.ParseItemID(argument, lookupItemLinkByName)
    if not itemID then
      say("Usage: /bagwise why [item]")
      return
    end
    local explained = Bagwise.Scanner.Explain(itemID)
    if not explained then
      say("item " .. itemID .. " is not loaded by the game yet. Try again in a moment.")
      return
    end
    local item, result = explained.item, explained.result
    say(item.name .. " (item " .. itemID .. ")")
    print("  class " .. tostring(item.classID) .. ", quality " .. tostring(item.quality)
      .. ", your faction " .. tostring(explained.faction))
    print("  verdict: " .. (result.verdict or "none") .. (result.reason and (" - " .. result.reason) or ""))
    -- A green that Safety dropped is the most useful thing to see here.
    for _, entry in ipairs(explained.trace or {}) do
      if entry.blockedBy then
        print("  not used: rule " .. entry.rule .. " said " .. entry.verdict
          .. " (" .. tostring(entry.reason) .. "), but the item is protected: "
          .. entry.blockedBy)
      end
    end
    if #(explained.protections or {}) > 0 then
      print("  protected as: " .. table.concat(explained.protections, ", "))
    end
    if #explained.quests == 0 then
      print("  quests: none use this item")
    else
      print("  quests that use this item:")
      for _, quest in ipairs(explained.quests) do
        print("    " .. quest.id .. " " .. tostring(quest.name)
          .. " [" .. (quest.faction or "both") .. "] "
          .. (quest.done and "done" or "not done"))
      end
    end
    print("  recipes: " .. (#explained.recipeProfessions > 0
      and table.concat(explained.recipeProfessions, ", ") or "none"))
    if explained.fromBag then
      print("  Judged as the stack in your bags (opens for loot: "
        .. tostring(item.hasLoot) .. ").")
    else
      print("  Judged as if looted: you carry none, so soulbound, openable and quest-starter checks are skipped.")
    end
    if explained.professionsKnown == false then
      print("  Your professions could not be fully read (Skills tab collapsed or not loaded), so profession-based greens are held back.")
    end
  end,
  loot = function()
    local plan = Bagwise.Scanner.MakeRoomSummary()
    say("make-room plan")
    print("  Loot items in the window: " .. plan.lootItems
      .. (plan.lootItems == 0 and " (open a loot window first)" or ""))
    print("  Free bag slots: " .. plan.freeSlots)
    print("  Junk candidates in your bags: " .. plan.junkCandidates)
    print("  Plan active: " .. (plan.active and "yes" or "no")
      .. ", take " .. plan.takes .. ", delete " .. plan.deletes)
    if plan.lootItems > 0 and not plan.active then
      print("  Not active because everything fits in your free slots.")
    end
  end,
  glow = function()
    local key = Bagwise.Scanner.ForceTestGlow()
    if not key then
      say("Your bags are empty, nothing to glow.")
      return
    end
    Bagwise.Overlay.UpdateAll()
    say("Test glow on bag:slot " .. key .. " until your bags next change.")
    print("  Seen it: the glow draws fine, so the make-room plan is not starting. Open a loot window and run /bagwise loot.")
    print("  Not seen: the glow itself cannot draw on your bag UI. Tell me which bag addon you use.")
  end,
  dump = function()
    -- Each step is guarded so a failure says where it broke instead of nothing.
    local ok, snapshot = pcall(Bagwise.Scanner.CollectInventory)
    if not ok then
      say("dump failed while reading your bags: " .. tostring(snapshot))
      return
    end
    local formatted, text = pcall(Bagwise.Dump.Format, snapshot,
      { version = Bagwise.Commands.Version(), build = gameBuild() })
    if not formatted then
      say("dump failed while formatting: " .. tostring(text))
      return
    end
    local shown, err = pcall(Bagwise.Dump.Show, text)
    if not shown then
      say("dump failed while opening the window: " .. tostring(err))
      return
    end
    say(#snapshot.rows .. " items listed. Ctrl+C in the window to copy.")
  end,
  keep = overrideCommand("/bagwise keep [item]",
    Bagwise.Overrides.AddKeep, "%s will never get a dot."),
  flag = overrideCommand("/bagwise flag [item]",
    Bagwise.Overrides.AddFlag, "%s will always get a yellow dot."),
  reset = function(argument)
    local itemID = Bagwise.Commands.ParseItemID(argument, lookupItemLinkByName)
    if not itemID then
      say("Usage: /bagwise reset [item]")
      return
    end
    local name = itemNameOf(itemID)
    if Bagwise.Overrides.Remove(itemID) then
      say(name .. " is back to the normal rules.")
      refreshDots()
    else
      say(name .. " was not on either list.")
    end
  end,
  list = function()
    local function printList(title, entries)
      local lines = {}
      for itemID, stored in pairs(entries) do
        local name = type(stored) == "string" and stored or itemNameOf(itemID)
        lines[#lines + 1] = name
      end
      table.sort(lines)
      say(title .. " (" .. #lines .. ")")
      for i = 1, #lines do print("  " .. lines[i]) end
    end
    printList("Kept", BagwiseDB.keepList)
    printList("Flagged", BagwiseDB.flagList)
  end,
}

--- Split what was typed after /bagwise into a command word and its argument.
-- The command is the leading letters only, so an item shift-clicked straight
-- after the word ("why|cnIQ1:|Hitem:...") still splits where the link starts.
-- The argument keeps its original case (item names).
-- @return string, string  lower-case command ("" if none), argument
function Bagwise.Commands.SplitInput(msg)
  local text = (msg or ""):match("^%s*(.-)%s*$")
  local word, argument = text:match("^(%a*)%s*(.-)$")
  return word:lower(), argument
end

function Bagwise.Commands.Init()
  SLASH_BAGWISE1 = "/bagwise"
  SlashCmdList["BAGWISE"] = function(msg)
    local cmd, argument = Bagwise.Commands.SplitInput(msg)
    if cmd == "" then cmd = "help" end
    local handler = COMMAND_HANDLERS[cmd]
    if handler then
      handler(argument)
    else
      say("Unknown command: " .. cmd)
      COMMAND_HANDLERS.help()
    end
  end
end
