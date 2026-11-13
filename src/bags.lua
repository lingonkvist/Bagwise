-- Bagwise: which bags count
-- One place that knows how far the bag numbering goes, so the scanner, the
-- overlay and the tooltip never disagree.

Bagwise = Bagwise or {}
Bagwise.Bags = {}

--- The highest bag ID Bagwise scans.
-- Backpack is 0 and the equipped bags are 1 to NUM_BAG_SLOTS. Clients that
-- have a reagent bag (Forever, like Mainline) put it right after them.
-- Classic Era has no reagent bag slot, so this stays 4 there.
function Bagwise.Bags.LastScanned()
  local last = NUM_BAG_SLOTS or 4
  local reagentSlots = NUM_REAGENTBAG_SLOTS or 0
  if reagentSlots > 0 then last = last + reagentSlots end
  return last
end

-- The bank. On Forever the character bank is a row of tabs, one bag ID each,
-- followed by the warband bank tabs (6-14 and 15-23 in the Forever client's
-- own API documentation). -1 is the keyring there, not a bank. The IDs come
-- from Enum.BagIndex when the client has it; otherwise any ID in a window
-- past the carried bags that reports slots counts. The bank is only readable
-- while it is open.
local BANK_WINDOW = 20

local function firstBankBag()
  return Bagwise.Bags.LastScanned() + 1
end

local function lastBankBag()
  local index = Enum and Enum.BagIndex
  return (index and index.AccountBankTab_9) or (firstBankBag() + BANK_WINDOW - 1)
end

-- Bank bag IDs learned at run time: from the client's own bank tab data, and
-- from the item buttons the bank window draws. The assumed window above is a
-- guess; these are what the client says.
local learnedBankBags = {}

-- Building the set asks the client for its bank tabs, and IsBank is asked once
-- per button per paint, so the set is kept until a scan (BankBags) or a newly
-- learned tab builds it again.
local bankSet = nil

--- Remember a bank bag ID seen on the client (a bank tab button, say).
-- @return boolean  true when the ID was new, so the bank needs a fresh scan
function Bagwise.Bags.NoteBankBag(bag)
  if type(bag) ~= "number" or Bagwise.Bags.IsCarried(bag) or bag < 0 then return false end
  if learnedBankBags[bag] then return false end
  learnedBankBags[bag] = true
  bankSet = nil
  if Bagwise.Bags.onNewBankBag then Bagwise.Bags.onNewBankBag(bag) end
  return true
end

-- IDs of the purchased bank tabs, character and warband, as the client lists them.
local function clientBankTabIDs()
  local ids = {}
  local bankType = Enum and Enum.BankType
  if not (C_Bank and C_Bank.FetchPurchasedBankTabData and bankType) then return ids end
  for _, kind in ipairs({ bankType.Character, bankType.Account }) do
    local ok, tabs = pcall(C_Bank.FetchPurchasedBankTabData, kind)
    if ok and type(tabs) == "table" then
      for _, tab in ipairs(tabs) do
        if type(tab) == "table" and type(tab.ID) == "number" then ids[#ids + 1] = tab.ID end
      end
    end
  end
  return ids
end

-- Enum.BagIndex entries named like bank tabs (CharacterBankTab_1 and so on).
local function enumBankTabIDs()
  local ids = {}
  local index = Enum and Enum.BagIndex
  if type(index) ~= "table" then return ids end
  for name, id in pairs(index) do
    if type(id) == "number" and tostring(name):find("BankTab") then ids[#ids + 1] = id end
  end
  return ids
end

--- Bag IDs Bagwise treats as bank, whether or not they hold items right now.
-- @return table  set of bag ID -> true
function Bagwise.Bags.BankIDSet()
  if bankSet then return bankSet end
  return Bagwise.Bags.RefreshBankIDs()
end

--- Build the set of bank bag IDs again from what the client says now.
function Bagwise.Bags.RefreshBankIDs()
  local set = {}
  local function add(id)
    if type(id) == "number" and id >= 0 and not Bagwise.Bags.IsCarried(id) then set[id] = true end
  end
  for bag = firstBankBag(), lastBankBag() do add(bag) end
  for id in pairs(learnedBankBags) do add(id) end
  for _, id in ipairs(clientBankTabIDs()) do add(id) end
  for _, id in ipairs(enumBankTabIDs()) do add(id) end
  bankSet = set
  return set
end

--- Bag IDs that currently hold bank slots.
-- @return table  list of bag IDs, in scan order
function Bagwise.Bags.BankBags()
  local ids = {}
  if not (C_Container and C_Container.GetContainerNumSlots) then return ids end
  for bag in pairs(Bagwise.Bags.RefreshBankIDs()) do
    if (C_Container.GetContainerNumSlots(bag) or 0) > 0 then ids[#ids + 1] = bag end
  end
  table.sort(ids)
  return ids
end

--- Is this one of the bags you carry (backpack, bags, reagent bag)?
function Bagwise.Bags.IsCarried(bag)
  return bag ~= nil and bag >= 0 and bag <= Bagwise.Bags.LastScanned()
end

--- Is this a bank bag (a character bank tab or a warband bank tab)?
function Bagwise.Bags.IsBank(bag)
  return bag ~= nil and Bagwise.Bags.BankIDSet()[bag] == true
end

--- Is this a warband bank tab, shared by all your characters?
function Bagwise.Bags.IsWarbandBank(bag)
  local index = Enum and Enum.BagIndex
  local firstTab = index and index.AccountBankTab_1
  return firstTab ~= nil and bag ~= nil and bag >= firstTab and Bagwise.Bags.IsBank(bag)
end

--- Is this a bag Bagwise paints: carried, or a bank bag?
function Bagwise.Bags.IsScanned(bag)
  return Bagwise.Bags.IsCarried(bag) or Bagwise.Bags.IsBank(bag)
end
