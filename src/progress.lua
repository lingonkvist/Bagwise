-- Bagwise: is a profession actually being leveled?
--
-- A recipe a little out of reach is worth keeping while you are working on
-- that profession, and clutter when you are not. This remembers each
-- profession's skill rank, when it last moved, and whether a play session has
-- passed since without it moving.
-- Pure bookkeeping: the caller hands in the saved table and the time.

Bagwise = Bagwise or {}
Bagwise.Progress = {}

-- A profession counts as idle once a later play session has passed with no
-- skill gain and the last gain is at least this old.
Bagwise.Progress.IDLE_SECONDS = 86400
-- Logins closer together than this are one session (relogs, /reload).
Bagwise.Progress.MIN_SESSION_GAP = 1800

local sessionSeen = {} -- profession name -> true once counted this session

--- Record the current ranks.
-- @param store table  saved table, name -> { rank, quiet, seen }
-- @param ranks table  profession name -> current rank (nil ranks skipped)
-- @param now number   seconds, any steady clock
function Bagwise.Progress.Observe(store, ranks, now)
  for name, rank in pairs(ranks) do
    local entry = store[name]
    if not entry then
      store[name] = { rank = rank, quiet = 0, seen = now, gained = now }
      sessionSeen[name] = true
    elseif rank ~= entry.rank then
      entry.rank, entry.quiet, entry.seen, entry.gained = rank, 0, now, now
      sessionSeen[name] = true
    elseif not sessionSeen[name] then
      sessionSeen[name] = true
      if now - entry.seen >= Bagwise.Progress.MIN_SESSION_GAP then
        entry.quiet = entry.quiet + 1
        entry.seen = now
      end
    end
  end
end

--- Professions whose skill has stood still for long enough.
-- @return table  name -> true
function Bagwise.Progress.IdleSet(store, ranks, now)
  local idle = {}
  for name in pairs(ranks) do
    local entry = store[name]
    if entry and entry.quiet >= 1
        and now - (entry.gained or entry.seen) >= Bagwise.Progress.IDLE_SECONDS then
      idle[name] = true
    end
  end
  return idle
end

--- Forget which professions were counted this session (tests).
function Bagwise.Progress.ResetSession() sessionSeen = {} end
