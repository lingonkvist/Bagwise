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
                keepList = {},   -- item IDs the player never wants flagged
                flagList = {},   -- item IDs the player always wants yellow
                version  = 1,
            }
        end

        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        print("|cff66bb6a[Bagwise]|r v0.1.0 loaded. Type /bagwise help for commands.")
    end
end)

-- Slash commands
SLASH_BAGWISE1 = "/bagwise"
SlashCmdList["BAGWISE"] = function(msg)
    local cmd = strtrim(msg):lower()

    if cmd == "" or cmd == "help" then
        print("|cff66bb6a[Bagwise]|r commands:")
        print("  /bagwise help - show this list")
        print("  /bagwise status - show addon state")

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
