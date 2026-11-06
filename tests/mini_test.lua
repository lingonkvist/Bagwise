-- mini_test.lua: minimal describe/it/assert harness for Bagwise tests

local current_describe = ""
local passed = 0
local failed = 0
local errors = {}

function describe(name, fn)
  current_describe = name
  fn()
end

function it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    local full = current_describe .. " > " .. name
    errors[#errors + 1] = full .. "\n    " .. tostring(err)
    io.write("  FAIL: " .. full .. "\n")
  end
end

-- Wrap the built-in assert so we can add .are.equal / .is_nil / .is_truthy
local builtin_assert = assert
assert = setmetatable({}, {
  __call = function(_, ...)
    return builtin_assert(...)
  end,
})
assert.are = {}
assert.are.equal = function(expected, actual)
  if expected ~= actual then
    error("expected " .. tostring(expected) .. " but got " .. tostring(actual), 2)
  end
end

assert.is_nil = function(val)
  if val ~= nil then
    error("expected nil but got " .. tostring(val), 2)
  end
end

assert.is_truthy = function(val)
  if not val then
    error("expected truthy but got " .. tostring(val), 2)
  end
end

function mini_test_report()
  print("\n" .. passed .. " passed, " .. failed .. " failed")
  if #errors > 0 then
    print("\nFailures:")
    for _, e in ipairs(errors) do
      print("  " .. e)
    end
  end
  return failed
end
