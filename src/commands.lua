-- Bagwise: slash command handlers
-- Wired up in Bagwise.lua; helpers live here to keep the entry point small.

Bagwise = Bagwise or {}
Bagwise.Commands = {}

local COMMAND_HANDLERS = {
  help = function()
    print("|cff66bb6a[Bagwise]|r commands:")
    print("  /bagwise help    - Show this message")
    print("  /bagwise status  - Show addon status")
  end,
  status = function()
    print("|cff66bb6a[Bagwise]|r v0.3.0 running.")
  end,
}

function Bagwise.Commands.Init()
  SLASH_BAGWISE1 = "/bagwise"
  SlashCmdList["BAGWISE"] = function(msg)
    local cmd = (msg or ""):lower():trim()
    if cmd == "" then cmd = "help" end
    local handler = COMMAND_HANDLERS[cmd]
    if handler then
      handler()
    else
      print("|cff66bb6a[Bagwise]|r Unknown command: " .. cmd)
      COMMAND_HANDLERS.help()
    end
  end
end
