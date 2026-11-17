-- MakeSpace: slash command handlers
-- Wired up in MakeSpace.lua; helpers live here to keep the entry point small.

MakeSpace = MakeSpace or {}
MakeSpace.Commands = {}

local PREFIX = "|cff54de7d[Make Space]|r "

local function say(text)
  print(PREFIX .. text)
end

--- Turn the text after a command into an item ID.
-- Accepts a shift-clicked item link, a bare numeric ID, or an item name
-- (names only resolve for items the client has cached, such as bag items).
-- @param argument   string          Text after the command word
-- @param lookupLink function|nil    name -> item link, injected for tests
-- @return number|nil
function MakeSpace.Commands.ParseItemID(argument, lookupLink)
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
function MakeSpace.Commands.Version()
  local version = getAddOnMetadata and getAddOnMetadata("MakeSpace", "Version")
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
  MakeSpace.Scanner.ClearCache()
  MakeSpace.Scanner.ScanAll()
  MakeSpace.Overlay.UpdateAll()
end

local MARK_CONFIRMATIONS = {
  green   = "%s will always get a green dot.",
  yellow  = "%s will always get a yellow dot.",
  none    = "%s will never get a dot.",
  default = "%s is back to the normal rules.",
}

--- Build a handler that sets one mark on the item in the argument.
local function markCommand(usage, mark)
  return function(argument)
    local itemID = MakeSpace.Commands.ParseItemID(argument, lookupItemLinkByName)
    if not itemID then
      say("Usage: " .. usage)
      return
    end
    local name = itemNameOf(itemID)
    MakeSpace.Overrides.Set(itemID, mark, name)
    say(MARK_CONFIRMATIONS[mark or "default"]:format(name))
    refreshDots()
  end
end

-- Facts worth having in a bug report, one "key=value" per line. Each is read
-- on its own so one failure does not lose the rest.
local function reportDetails()
  local details = {}
  local function add(label, read)
    local ok, value = pcall(read)
    details[#details + 1] = label .. "=" .. (ok and tostring(value) or ("error: " .. tostring(value)))
  end
  add("bagUIs", function()
    local found = MakeSpace.Overlay.DetectedBagAddons()
    return #found > 0 and table.concat(found, ",") or "none"
  end)
  add("bagsScanned", function() return "0-" .. MakeSpace.Bags.LastScanned() end)
  add("safetyChecks", function() return table.concat(MakeSpace.Safety.Names(), ",") end)
  add("dots", function()
    local counts = MakeSpace.Scanner.Counts()
    return counts.green .. " green, " .. counts.yellow .. " yellow, " .. counts.items .. " items"
  end)
  add("professions", function() return MakeSpace.Scanner.ProfessionSummary() end)
  add("lastScanError", function() return MakeSpace.Scanner.LastError() or "none" end)
  add("makeRoom", function()
    local plan = MakeSpace.Scanner.MakeRoomSummary()
    return "lootItems " .. plan.lootItems .. ", freeSlots " .. plan.freeSlots
      .. ", junkCandidates " .. plan.junkCandidates
      .. ", active " .. tostring(plan.active)
  end)
  add("marks", function()
    local counts = MakeSpace.Overrides.Counts()
    return counts.green .. " green, " .. counts.yellow .. " yellow, " .. counts.none .. " no dot"
  end)
  return details
end

--- Open the copyable report window. Each step is guarded so a failure says
-- where it broke instead of showing nothing.
local function openReport()
  local ok, snapshot = pcall(MakeSpace.Scanner.CollectInventory)
  if not ok then
    say("report failed while reading your bags: " .. tostring(snapshot))
    return
  end
  local formatted, text = pcall(MakeSpace.Dump.Format, snapshot,
    { version = MakeSpace.Commands.Version(), build = gameBuild(), extra = reportDetails() })
  if not formatted then
    say("report failed while formatting: " .. tostring(text))
    return
  end
  local shown, err = pcall(MakeSpace.Dump.Show, text)
  if not shown then
    say("report failed while opening the window: " .. tostring(err))
    return
  end
  say(#snapshot.rows .. " items listed. Press Ctrl+C in the window to copy, then paste it where you are reporting.")
end

-- The quest data tags a quest "A" or "H" when only one faction can take it.
local FACTION_TAGS = { Alliance = "A", Horde = "H" }

local function otherFaction(questFaction, playerFaction)
  local mine = FACTION_TAGS[playerFaction]
  return questFaction ~= nil and mine ~= nil and questFaction ~= mine
end

--- One line on what the dots in your bags add up to.
-- @param summary table { green, yellow, greenValue }
-- @return string|nil nil when there is nothing marked
function MakeSpace.Commands.SummaryLine(summary)
  local parts = {}
  if summary.green > 0 then
    parts[#parts + 1] = summary.green .. " green (" .. MakeSpace.Verdict.FormatMoney(summary.greenValue)
      .. " at a vendor)"
  end
  if summary.yellow > 0 then parts[#parts + 1] = summary.yellow .. " yellow" end
  if #parts == 0 then return nil end
  return table.concat(parts, ", ")
end

--- Say the summary.
function MakeSpace.Commands.PrintSummary()
  local line = MakeSpace.Commands.SummaryLine(MakeSpace.Scanner.Summary())
  if line then
    say("Your bags: " .. line .. ".")
  else
    say("Nothing marked in your bags.")
  end
end

local COMMAND_HANDLERS = {
  help = function()
    say("commands:")
    print("  /makespace mark green|yellow|none|default [item]")
    print("                            - Set the dot for this item (default: normal rules)")
    print("  /makespace keep [item]    - Same as mark none: never show a dot")
    print("  /makespace flag [item]    - Same as mark yellow")
    print("  /makespace reset [item]   - Same as mark default")
    print("  /makespace list           - Show your marked items")
    print("  Alt-right-click an item in your bags to set its dot from a menu.")
    print("  /makespace autoopen       - Turn on or off opening your bags when loot needs room")
    print("  /makespace summary        - What the dots in your bags add up to")
    print("  /makespace help           - Show this message")
    print("  [item] can be a shift-clicked link, an item ID or an item name.")
    print("Troubleshooting (paste the output when something looks wrong):")
    print("  /makespace report         - Copyable report of your bags, verdicts and setup")
    print("  /makespace why [item]     - Why an item does or doesn't get a dot")
    print("  /makespace loot           - What the make-room plan sees (loot window open)")
    print("  /makespace glow           - Test the delete glow on your first item")
    print("  /makespace status         - Version, bag UI and counts")
    print("  /makespace bank           - What Make Space sees of the bank")
  end,
  summary = function()
    MakeSpace.Commands.PrintSummary()
  end,
  bank = function()
    say("bank:")
    local ok, lines = pcall(MakeSpace.Overlay.BankDiagnostics)
    if not ok then lines = { "Diagnostics failed: " .. tostring(lines) } end
    for _, line in ipairs(lines) do print("  " .. line) end
  end,
  status = function()
    say("v" .. MakeSpace.Commands.Version() .. " on WoW " .. (gameBuild() or "?"))
    local bagUIs = MakeSpace.Overlay.DetectedBagAddons()
    print("  Bag UIs painted: " .. (#bagUIs > 0 and table.concat(bagUIs, ", ") or "none found"))
    print("  Bags scanned: 0-" .. MakeSpace.Bags.LastScanned())
    local professions, summary = pcall(MakeSpace.Scanner.ProfessionSummary)
    print("  Professions: " .. tostring(professions and summary or ("could not be read: " .. tostring(summary))))
    local counts = MakeSpace.Scanner.Counts()
    print("  Scanned items: " .. counts.items .. " (" .. counts.green .. " green, "
      .. counts.yellow .. " yellow)")
    local function size(tbl)
      local n = 0
      for _ in pairs(tbl or {}) do n = n + 1 end
      return n
    end
    print("  Data: " .. size(MakeSpace.Data.QuestItems) .. " quest items, "
      .. size(MakeSpace.Data.ReagentProfessions) .. " recipe reagents")
    local priceDate = MakeSpace.Data.AuctionPricesDate
    if priceDate then
      local age = MakeSpace.Curves.SnapshotAgeDays(priceDate, (_G.time or os.time)())
      local note = age and age > MakeSpace.Curves.REMIND_SNAPSHOT_DAYS and ", update the addon" or ""
      print("  Auction prices: " .. priceDate .. (age and (", " .. age .. " days old") or "") .. note)
    else
      print("  Auction prices: no date in the data")
    end
    local market = MakeSpace.Data.AuctionMarket
    if market then
      print("  Auction market: " .. market)
    elseif MakeSpace.Data.AuctionMarkets then
      print("  Auction market: none for your region and faction, so tradable items get no green")
    end
    print("  Live prices: " .. (MakeSpace.Live.Api()
      and ("Auctionator found, prices seen in the last " .. MakeSpace.Live.MAX_AGE_DAYS .. " days are used")
      or "Auctionator not found, using the price snapshot only"))
    print("  Safety checks: " .. table.concat(MakeSpace.Safety.Names(), ", "))
    local counts = MakeSpace.Overrides.Counts()
    print("  Your marks: " .. counts.green .. " green, " .. counts.yellow .. " yellow, "
      .. counts.none .. " no dot")
  end,
  why = function(argument)
    local itemID = MakeSpace.Commands.ParseItemID(argument, lookupItemLinkByName)
    if not itemID then
      say("Usage: /makespace why [item]")
      return
    end
    local explained = MakeSpace.Scanner.Explain(itemID)
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
          .. " (" .. tostring(entry.reason) .. "), but it was dropped: "
          .. entry.blockedBy)
      end
    end
    for _, line in ipairs(MakeSpace.Verdict.SellAtVendorFacts(item, explained.state)) do
      print("  " .. line)
    end
    print("  " .. MakeSpace.Live.Describe(item))
    if item.link then
      print("  link fields: " .. tostring(item.link:match("item:([^|]*)")))
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
          .. (quest.done and "done" or "not done")
          .. (otherFaction(quest.faction, explained.faction) and ", other faction, ignored" or "")
          .. (MakeSpace.Verdict.IsIgnoredQuest(quest.id) and ", standing turn-in quest, ignored" or "")
          .. (MakeSpace.Verdict.IsLogOnlyQuest(quest.id) and ", crafting writ, counts only while in your log" or "")
          .. (MakeSpace.Verdict.NeedsOtherProfession(quest.id,
                explained.state.professionsKnown ~= false and explained.state.professionSkillLines or nil)
              and ", needs a primary profession you do not have, ignored" or ""))
      end
    end
    print("  recipes: " .. (#explained.recipeProfessions > 0
      and table.concat(explained.recipeProfessions, ", ") or "none"))
    local useFacts = MakeSpace.Verdict.ReagentUseFacts(itemID, explained.state)
    if #useFacts > 0 then
      print("  your professions and this item:")
      for _, line in ipairs(useFacts) do print("    " .. line) end
    end
    if item.classID == 0 and item.subClassID == 7 then
      print("  bandage heal, read from the tooltip: " .. tostring(item.healAmount or "not found")
        .. ", your max health: " .. tostring(explained.state and explained.state.maxHealth or "unknown"))
    end
    if item.classID == 9 and explained.fromBag then
      print("  skill needed, read from the tooltip: " .. tostring(item.requiredSkill or "not found"))
      local ok, summary = pcall(MakeSpace.Scanner.ProfessionSummary)
      print("  your professions: " .. tostring(ok and summary or "could not be read"))
      if MakeSpace.Scanner.TooltipTextOf then
        for _, text in ipairs(MakeSpace.Scanner.TooltipTextOf(item.id) or {}) do
          print("    tooltip: " .. text)
        end
      end
    end
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
  autoopen = function(argument)
    MakeSpaceDB = MakeSpaceDB or {}
    local word = (argument or ""):lower():match("^%s*(%a*)")
    if word == "on" then
      MakeSpaceDB.autoOpenBags = true
    elseif word == "off" then
      MakeSpaceDB.autoOpenBags = false
    else
      MakeSpaceDB.autoOpenBags = MakeSpaceDB.autoOpenBags == false
    end
    say("Opening your bags when loot needs room: " .. (MakeSpaceDB.autoOpenBags and "on" or "off"))
  end,
  loot = function()
    local plan = MakeSpace.Scanner.MakeRoomSummary()
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
    local key = MakeSpace.Scanner.ForceTestGlow()
    if not key then
      say("Your bags are empty, nothing to glow.")
      return
    end
    MakeSpace.Overlay.UpdateAll()
    say("Test glow on bag:slot " .. key .. " until your bags next change.")
    print("  Seen it: the glow draws fine, so the make-room plan is not starting. Open a loot window and run /makespace loot.")
    print("  Not seen: the glow itself cannot draw on your bag UI. Tell me which bag addon you use.")
  end,
  report = function() openReport() end,
  dump = function() openReport() end,
  mark = function(argument)
    local word, rest = (argument or ""):match("^(%a+)%s*(.-)$")
    word = word and word:lower() or ""
    if word ~= "green" and word ~= "yellow" and word ~= "none" and word ~= "default" then
      say("Usage: /makespace mark green|yellow|none|default [item]")
      return
    end
    markCommand("/makespace mark " .. word .. " [item]", word ~= "default" and word or nil)(rest)
  end,
  keep = markCommand("/makespace keep [item]", "none"),
  flag = markCommand("/makespace flag [item]", "yellow"),
  reset = markCommand("/makespace reset [item]", nil),
  list = function()
    local groups = {
      { mark = "green", title = "Safe to delete" },
      { mark = "yellow", title = "Worth a glance" },
      { mark = "none", title = "No dot" },
    }
    local all = MakeSpace.Overrides.All()
    for _, group in ipairs(groups) do
      local lines = {}
      for _, entry in ipairs(all) do
        if entry.mark == group.mark then
          lines[#lines + 1] = entry.name or itemNameOf(entry.itemID)
        end
      end
      table.sort(lines)
      say(group.title .. " (" .. #lines .. ")")
      for i = 1, #lines do print("  " .. lines[i]) end
    end
  end,
}

--- Split what was typed after /makespace into a command word and its argument.
-- The command is the leading letters only, so an item shift-clicked straight
-- after the word ("why|cnIQ1:|Hitem:...") still splits where the link starts.
-- The argument keeps its original case (item names).
-- @return string, string  lower-case command ("" if none), argument
function MakeSpace.Commands.SplitInput(msg)
  local text = (msg or ""):match("^%s*(.-)%s*$")
  local word, argument = text:match("^(%a*)%s*(.-)$")
  return word:lower(), argument
end

function MakeSpace.Commands.Init()
  SLASH_MAKESPACE1 = "/makespace"
  SLASH_MAKESPACE2 = "/bagwise"
  SlashCmdList["MAKESPACE"] = function(msg)
    local cmd, argument = MakeSpace.Commands.SplitInput(msg)
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
