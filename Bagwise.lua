-- Bagwise: entry point
-- Registers events, initialises saved variables, wires up slash commands.

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName ~= "Bagwise" then return end

    -- Initialise per-character saved variables
    if not BagwiseDB then
      BagwiseDB = {
        keepList = {},         -- item IDs the player never wants flagged
        flagList = {},         -- item IDs the player always wants yellow
        version  = 1,
      }
    end

    self:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    -- Now that the player is in-world, listen for bag changes
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    self:RegisterEvent("QUEST_TURNED_IN")

    -- Hook bag frame Show/Hide so dots appear/disappear with bags.
    -- Frame pool is shared (NUM_CONTAINER_FRAMES = 13), and any
    -- frame can hold any bag, so hook them all.
    local maxFrames = NUM_CONTAINER_FRAMES or 13
    for i = 1, maxFrames do
      local bagFrame = _G["ContainerFrame" .. i]
      if bagFrame then
        bagFrame:HookScript("OnShow", function()
          Bagwise.Scanner.ScanAll()
          Bagwise.Overlay.UpdateAll()
        end)
      end
    end

    print("|cff66bb6a[Bagwise]|r v0.1.0 loaded. Type /bagwise help for commands.")
  elseif event == "BAG_UPDATE_DELAYED" then
    -- Bag contents changed: re-scan and repaint dots
    Bagwise.Scanner.ScanAll()
    Bagwise.Overlay.UpdateAll()
  elseif event == "PLAYER_LEVEL_UP" then
    -- Level changed, so level-gap verdicts may be stale
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
    Bagwise.Overlay.UpdateAll()
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    -- An item the client didn't have cached is now available.
    -- Re-scan so items we skipped earlier get their verdicts.
    Bagwise.Scanner.ScanAll()
    Bagwise.Overlay.UpdateAll()
  elseif event == "QUEST_TURNED_IN" then
    -- A quest was just completed. Quest-starter items for that quest
    -- should now show green dots, so clear the cache (quest completion
    -- status is part of the cache key) and rescan.
    Bagwise.Scanner.ClearCache()
    Bagwise.Scanner.ScanAll()
    Bagwise.Overlay.UpdateAll()
  end
end)

-- Slash commands
SLASH_BAGWISE1 = "/bagwise"
SlashCmdList["BAGWISE"] = function(msg)
  local cmd = strtrim(msg):lower()

  if cmd == "" or cmd == "help" then
    print("|cff66bb6a[Bagwise]|r commands:")
    print("  /bagwise help   - show this list")
    print("  /bagwise status - show addon state")
    -- Future commands will go here:
    -- /bagwise keep [shift-click item]
    -- /bagwise flag [shift-click item]
  elseif cmd == "status" then
    local keepCount = 0
    local flagCount = 0
    for _ in pairs(BagwiseDB.keepList) do keepCount = keepCount + 1 end
    for _ in pairs(BagwiseDB.flagList) do flagCount = flagCount + 1 end
    print("|cff66bb6a[Bagwise]|r status:")
    print("  Keep list: " .. keepCount .. " items")
    print("  Flag list: " .. flagCount .. " items")
    print("  DB version: " .. (BagwiseDB.version or "?"))
  else
    print("|cff66bb6a[Bagwise]|r unknown command: " .. cmd)
    print("  Type /bagwise help for a list of commands.")
  end
end
