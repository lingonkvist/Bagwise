-- Bagwise: skill progress bookkeeping (is a profession being leveled?).
_G.Bagwise = nil
dofile("src/progress.lua")

local P = Bagwise.Progress
local DAY = 86400
local HOUR = 3600

describe("Progress", function()
  local store

  local function session(now, ranks)
    P.ResetSession()
    P.Observe(store, ranks, now)
    return P.IdleSet(store, ranks, now)
  end

  it("a new profession is not idle", function()
    store = {}
    assert.is_nil(session(0, { Alchemy = 100 }).Alchemy)
  end)

  it("goes idle when a session half a day later shows no gain", function()
    store = {}
    session(0, { Alchemy = 100 })
    assert.is_truthy(session(13 * HOUR, { Alchemy = 100 }).Alchemy)
  end)

  it("is settling after 7 hours and idle only after 12", function()
    store = {}
    session(0, { Alchemy = 100 })
    P.ResetSession()
    P.Observe(store, { Alchemy = 100 }, 7 * HOUR)
    assert.is_truthy(P.SettlingSet(store, { Alchemy = 100 }, 7 * HOUR).Alchemy)
    assert.is_nil(P.IdleSet(store, { Alchemy = 100 }, 7 * HOUR).Alchemy)
    assert.is_nil(P.SettlingSet(store, { Alchemy = 100 }, 5 * HOUR).Alchemy)
  end)

  it("is not idle after a session only 11 hours later", function()
    store = {}
    session(0, { Alchemy = 100 })
    assert.is_nil(session(11 * HOUR, { Alchemy = 100 }).Alchemy)
  end)

  it("a second session the same day is not enough", function()
    store = {}
    session(0, { Alchemy = 100 })
    assert.is_nil(session(2 * HOUR, { Alchemy = 100 }).Alchemy)
  end)

  it("a skill gain makes it active again", function()
    store = {}
    session(0, { Alchemy = 100 })
    assert.is_truthy(session(DAY, { Alchemy = 100 }).Alchemy)
    P.Observe(store, { Alchemy = 101 }, DAY + 60)
    assert.is_nil(P.IdleSet(store, { Alchemy = 101 }, DAY + 60).Alchemy)
  end)

  it("a relog within half an hour is the same session", function()
    store = {}
    session(0, { Alchemy = 100 })
    for i = 1, 5 do session(i * 60, { Alchemy = 100 }) end
    assert.are.equal(0, store.Alchemy.quiet)
  end)

  it("counts a session once, however often it is scanned", function()
    store = {}
    session(0, { Alchemy = 100 })
    P.ResetSession()
    for i = 1, 10 do P.Observe(store, { Alchemy = 100 }, DAY + i) end
    assert.are.equal(1, store.Alchemy.quiet)
  end)

  it("tracks professions separately", function()
    store = {}
    session(0, { Alchemy = 100, Tailoring = 50 })
    local idle = session(DAY, { Alchemy = 100, Tailoring = 51 })
    assert.is_truthy(idle.Alchemy)
    assert.is_nil(idle.Tailoring)
  end)
end)
