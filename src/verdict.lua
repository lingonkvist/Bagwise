-- Bagwise: verdict engine
-- Pure function: (item, playerState) -> verdict, reason
-- No WoW API calls in this file. Everything comes through arguments,
-- making it testable with busted outside the game client.

Bagwise = Bagwise or {}
Bagwise.Verdict = {}

--- Evaluate a single item and return a verdict.
-- @param item   table  Item data gathered by the scanner
-- @param state  table  Player state (class, race, level, professions, etc.)
-- @return string|nil   "green", "yellow", or nil
-- @return string|nil   Human-readable reason, or nil
function Bagwise.Verdict.Evaluate(item, state)
  -- Stories 1.1 + 1.2: soulbound gear not usable by your character
  -- DISABLED: IsUsableItem() checks right-click usability (potions,
  -- scrolls), NOT whether your class can equip gear. It returns false
  -- for ALL equipment. Proper class restriction detection needs
  -- tooltip scanning or a proficiency lookup table -- a separate story.

  -- Story 1.3: soulbound gear far below my level
  -- Uses reqLevel when available, falls back to itemLevel for quest
  -- rewards and other gear with reqLevel=0. In Classic, ilvl 7-65
  -- roughly follows: reqLevel = ilvl - 5.
  if item.isBound and item.isEquippable then
    local compareLevel = nil
    local isItemLevel = false

    if item.reqLevel and item.reqLevel > 0 then
      compareLevel = item.reqLevel
    elseif item.itemLevel and item.itemLevel > 0 then
      compareLevel = item.itemLevel
      isItemLevel = true
    end

    if compareLevel then
      local gap = state.level - compareLevel
      if gap >= 10 then
        local verdict = gap >= 20 and "green" or "yellow"
        local prefix = verdict == "green" and "Very low" or "Low"
        local kind = isItemLevel and " item level: " or " level: "
        local reason = prefix .. kind .. compareLevel
        return verdict, reason
      end
    end
  end

  -- Story 2.1: quest-starter items for completed quests
  -- The scanner passes startsQuestID, startsQuestCompleted, and
  -- startsQuestName from the WoW API. The verdict just checks data.
  if item.startsQuestID and item.startsQuestCompleted then
    local questName = item.startsQuestName or ("quest " .. item.startsQuestID)
    return "green", "Quest '" .. questName .. "' completed"
  end

  -- Epic 5: vendor-bought profession reagents
  -- Green dot when the player has NONE of the professions that use
  -- this reagent. These are cheap vendor items (vials, thread, flux,
  -- dyes, spices) so green is appropriate -- no AH value to worry about.
  local reagentProfessions = Bagwise.Data.VendorReagents
      and Bagwise.Data.VendorReagents[item.id]
  if reagentProfessions and state.professionSkillLines then
    -- Some classes use vendor reagents for non-profession purposes
    -- (e.g. Rogues need vials for poison crafting). Skip the rule
    -- for those classes so they don't get a false green dot.
    if reagentProfessions.excludeClasses
        and state.playerClass
        and reagentProfessions.excludeClasses[state.playerClass] then
      -- Fall through to later rules
    else
      local playerNeeds = false
      for _, skillLine in ipairs(reagentProfessions) do
        if state.professionSkillLines[skillLine] then
          playerNeeds = true
          break
        end
      end
      if not playerNeeds then
        -- Build profession names from ReagentProfessions data so the
        -- verdict line matches the tooltip info format exactly.
        local profEntries = Bagwise.Data.ReagentProfessions
            and Bagwise.Data.ReagentProfessions[item.id]
        if profEntries then
          local names = {}
          for i = 1, #profEntries do
            names[#names + 1] = profEntries[i][1]
          end
          return "green",
              table.concat(names, ", ") .. " reagent (vendor)"
        end
        return "green", "Vendor reagent"
      end
    end
  end

  -- Gathering professions whose raw materials should not get verdicts.
  -- Ores only list Mining (smelting), herbs list Alchemy not Herbalism,
  -- leather lists Leatherworking not Skinning. So this filter mostly
  -- catches raw ores (Copper Ore, Tin Ore, etc.) that a Miner would
  -- smelt -- tagging those yellow is noise.
  local GATHERING_PROFESSIONS = {
    Mining = true,
    Herbalism = true,
    Skinning = true,
  }

  -- Epic 5.1: crafting reagent not used by the player's professions.
  -- Yellow because non-vendor reagents typically have AH value.
  -- Skips items already handled by the vendor reagent rule above.
  -- Skips raw materials only used by gathering professions.
  -- Only applies to Trade Goods (classID 7). Consumables (classID 0)
  -- like potions and elixirs may appear in ReagentProfessions because
  -- some recipes use them as ingredients, but they have inherent use
  -- value beyond being a reagent and should not get verdict dots.
  local reagentProfs = Bagwise.Data.ReagentProfessions
      and Bagwise.Data.ReagentProfessions[item.id]
  if reagentProfs and state.professionNames and item.classID == 7 then
    -- Skip items used only by gathering professions (raw materials)
    local hasNonGathering = false
    for i = 1, #reagentProfs do
      if not GATHERING_PROFESSIONS[reagentProfs[i][1]] then
        hasNonGathering = true
        break
      end
    end
    if not hasNonGathering then
      return nil, nil
    end
    local playerNeeds = false
    local profNames = {}
    for i = 1, #reagentProfs do
      local profName = reagentProfs[i][1]
      profNames[#profNames + 1] = profName
      if state.professionNames[profName] then
        playerNeeds = true
      end
    end
    if not playerNeeds then
      local text = table.concat(profNames, ", ") .. " reagent"
      -- Single-prof: include skill range to match tooltip info format
      if #reagentProfs == 1 then
        local e = reagentProfs[1]
        local range = e[3] == e[4] and tostring(e[3])
            or (e[3] .. "-" .. e[4])
        text = text .. " (" .. range .. ")"
      end
      return "yellow", text
    end
  end

  -- Class reagent: green or yellow when the player's class cannot use it.
  -- Green for vendor-sold reagents (cheap, replaceable).
  -- Yellow for world-drop reagents (may have AH value).
  local classReagent = Bagwise.Data.ClassReagents
      and Bagwise.Data.ClassReagents[item.id]
  if classReagent then
    if not state.playerClass then
      return nil, nil
    end
    if not classReagent.classes[state.playerClass] then
      local classList = {}
      for class in pairs(classReagent.classes) do
        classList[#classList + 1] = class:sub(1, 1)
            .. class:sub(2):lower()
      end
      table.sort(classList)
      return classReagent.verdict,
          classReagent.name .. " (" .. table.concat(classList, "/") .. " only)"
    end
    return nil, nil
  end

  return nil, nil
end
