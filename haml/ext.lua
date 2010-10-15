local lpeg   = require "lpeg"

local assert               = assert
local concat               = table.concat
local default_haml_options = _G["default_haml_options"]
local error                = error
local insert               = table.insert
local ipairs               = ipairs
local loadstring           = loadstring
local pairs                = pairs
local select               = select
local sort                 = table.sort
local tostring             = tostring
local type                 = type

module "haml.ext"

-- Remove this before releasing
function log(level, v)
  -- io.stderr:write(string.format("%s: %s\n", level, v))
end

function escape_html(str, escapes)
  local chars = {}
  for k, _ in pairs(escapes) do
    insert(chars, k)
  end
  pattern = ("([%s])"):format(concat(chars, ""))
  return (str:gsub(pattern, escapes))
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

function do_error(position, message, ...)
  error(("Haml error: " .. message):format(...) .. " (at position " .. position .. ")")
end

function render_table(t)
  local buffer = {}
  for k, v in pairs(t) do
    if type(v) == "table" then v = render_table(v) end
    insert(buffer, ("%s=%s"):format(tostring(k), tostring(v)))
  end
  return "{" .. concat(buffer, ' ') .. "}"
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
    insert(keys, key)
  end
  sort(keys, func)
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
            insert(out[k], v)
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
  return (str:gsub("^[%s]*", ""):gsub("[%s]*$", ""))
end

function render_attributes(attributes, options)
  local options = options or {}
  local q = options.attribute_wrapper or "'"
  local buffer = {""}
  for k, v in sorted_pairs(attributes) do
    if type(v) == "table" then
      if k == "class" then
        sort(v)
        insert(buffer, ("%s=" .. q .. "%s" .. q):format(k, concat(v, ' ')))
      elseif k == "id" then
        insert(buffer, ("%s=" .. q .. "%s" .. q):format(k, concat(v, '_')))
      end
    elseif type(v) == "function" then
      if not options.suppress_eval then
        insert(buffer, ("%s=" .. q .. "%s" .. q):format(k, tostring(v())))
      end
    elseif type(v) == "boolean" then
      if options.format == "xhtml" then
        insert(buffer, ("%s=" .. q .. "%s" .. q):format(k, k))
      else
        insert(buffer, k)
      end
    else
      insert(buffer, ("%s=" .. q .. "%s" .. q):format(k, tostring(v)))
    end
  end
  return concat(buffer, " ")
end
