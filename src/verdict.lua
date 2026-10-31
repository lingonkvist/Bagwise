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
    local label = nil

    if item.reqLevel and item.reqLevel > 0 then
      compareLevel = item.reqLevel
      label = "Required level"
    elseif item.itemLevel and item.itemLevel > 0 then
      compareLevel = item.itemLevel
      label = "Item level"
    end

    if compareLevel then
      local gap = state.level - compareLevel
      if gap >= 20 then
        return "green", label .. " " .. compareLevel .. ", you are " .. state.level
      elseif gap >= 10 then
        return "yellow", label .. " " .. compareLevel .. ", you are " .. state.level
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
        return "green", "Vendor reagent, not needed by your professions"
      end
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
