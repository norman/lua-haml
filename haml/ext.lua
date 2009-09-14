-- Remove this before releasing
function log(level, v)
  -- io.stderr:write(string.format("%s: %s\n", level, v))
end

function escape_html(str, escapes)
  return str:gsub("([\"'&<>])", function(a)
    return escapes[a]
  end)
end

function change_indents(str, len, options)
  local output = str:gsub("^" .. options.space, options.space:rep(len))
  output = output:gsub(options.newline .. options.space, options.newline .. options.space:rep(len))
  return output
end

function psplit(s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)
  return lpeg.match(p, s)
end

function do_error(chunk, message, ...)
  error(string.format("Haml error: " .. message, ...) .. " (around line " .. chunk .. ")")
end

function render_table(t)
  local buffer = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      v = render_table(v)
    end
    table.insert(buffer, string.format("%s=%s", k, v))
  end
  return "{" .. table.concat(buffer, ' ') .. "}"
end

_print = print
function print(...)
  local toprint = {}
  for _, v in ipairs({...}) do
    if type(v) == "table" then
      table.insert(toprint, render_table(v))
    else
      table.insert(toprint, tostring(v))
    end
  end
  _print(unpack(toprint))
end

--- Like pairs() but iterates over sorted table keys.
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
-- will use key values from t2.
-- @return A table containing all the values of all the tables.
function merge_tables(...)
  local numargs = select('#', ...)
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

--- Merge two or more tables together.
-- Duplicate keys cause the value to be added as a table containing all the
-- values for the key in every table.
-- @return A table containing all the values of all the tables.
function join_tables(...)
  local numargs = select('#', ...)
  local out = {}
  for i = 1, numargs do
    local t = select(i, ...)
    if type(t) == "table" then
      for k, v in pairs(t) do
        if out[k] then
          if type(out[k]) == "table" then
            table.insert(out[k], v)
          else
            out[k] = {out[k], v}
          end
        else
          out[k] = v
        end
      end
    end
  end
  return out
end

--- Flattens a table of tables.
function flatten(...)
  local out = {}
  for _, attr in ipairs(arg) do
    for k, v in pairs(attr) do
      out[k] = v
    end
  end
  return out
end

--- Strip leading and trailing space from a string.
function strip(str)
  -- assign to local because gsub returns two values and we only want one.
  local s = str:gsub("^[%s]*", ""):gsub("[%s]*$", "")
  return s
end
