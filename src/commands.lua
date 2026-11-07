-- Bagwise: slash command handlers
-- Wired up in Bagwise.lua; helpers live here to keep the entry point small.

Bagwise = Bagwise or {}
Bagwise.Commands = {}

local PREFIX = "|cff66bb6a[Bagwise]|r "

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
    print("  /bagwise help           - Show this message")
    print("  [item] can be a shift-clicked link, an item ID or an item name.")
  end,
  status = function()
    say("v" .. Bagwise.Commands.Version() .. " on WoW " .. (gameBuild() or "?"))
    local bagUIs = Bagwise.Overlay.DetectedBagAddons()
    print("  Bag UIs painted: " .. (#bagUIs > 0 and table.concat(bagUIs, ", ") or "none found"))
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
    print("  Your lists: " .. size(BagwiseDB.keepList) .. " kept, "
      .. size(BagwiseDB.flagList) .. " flagged")
  end,
  dump = function()
    local snapshot = Bagwise.Scanner.CollectInventory()
    local text = Bagwise.Dump.Format(snapshot,
      { version = Bagwise.Commands.Version(), build = gameBuild() })
    Bagwise.Dump.Show(text)
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

function Bagwise.Commands.Init()
  SLASH_BAGWISE1 = "/bagwise"
  SlashCmdList["BAGWISE"] = function(msg)
    local text = strtrim and strtrim(msg or "") or (msg or ""):match("^%s*(.-)%s*$")
    -- Split on the first space; keep the argument's original case (item names).
    local word, argument = text:match("^(%S*)%s*(.-)$")
    local cmd = word:lower()
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
