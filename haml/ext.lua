-- Remove this before releasing
function log(level, v)
  -- io.stderr:write(string.format("%s: %s\n", level, v))
end

function do_error(chunk, message, ...)
  error(string.format(message, ...) .. " around " .. chunk)
end

--- Works exactly like pairs() but iterators over sorted table keys.
-- @param t The table to iterate over
-- @param func An option sorting function
-- @return The iterator function
-- @return The table
-- @return The index
function sorted_pairs(t, func)
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys, func)
  local iterator, _, index = ipairs(keys)
  return function()
    local _, key = iterator(keys, index)
    index = index + 1
    return key, t[key]
  end, tab, index
end

--- Merge two or more tables together.
-- Duplicate keys are overridden left to right, so for example merge(t1, t2)
-- will use key values from t2. If there is only one argument, and that
-- argument, then the table's contents are treated as the function call's
-- arguments, making merge({a = "b"}, {c = "d"}) the same as 
-- merge({{a = "b"}, {c = "d"}}).
-- @return A table containing all the values of all the tables.
function merge_tables(...)
  local numargs = select('#', ...)
  -- if numargs == 1 and type(select(1, ...) == "table") then
  --   return merge_tables(unpack(select(1, ...)))
  -- end
  local out = {}
  for i = 1, numargs do
    local t = select(i, ...)
    if type(t) == "table" then
      for k, v in pairs(t) do
        out[k] = v
      end
    end
  end
  return out
end

--- Strips leading and trailing space from a string
function strip(str)
  -- assign to local because gsub returns two values and we only want one.
  local s = string.gsub(string.gsub(str, "^[%s]*", ""), "[%s]*$", "")
  return s
end

--- Flattens a table of tables
function flatten(...)
  local out = {}
  for _, attr in ipairs(arg) do
    for k, v in pairs(attr) do
      out[k] = v
    end
  end
  return out
end