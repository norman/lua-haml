local ext          = require "haml.ext"

local concat       = table.concat
local insert       = table.insert
local join_tables  = ext.join_tables
local pairs        = pairs
local setmetatable = setmetatable
local type         = type

module "haml.lua_adapter"

local function key_val(k, v, interpolate)
  if type(k) == "number" then
    return ('%s, '):format(v)
  elseif type(k) == "string" and interpolate then
    return ('["%s"] = r:interp(%s), '):format(k, v)
  else
    return ('["%s"] = %s, '):format(k, v)
  end
end

local function serialize_table(t, opts)
  local buffer = {}
  local opts   = opts or {}

  insert(buffer, "{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      insert(buffer, key_val(k, serialize_table(v, opts), opts.interpolate))
    else
      insert(buffer, key_val(k, v, opts.interpolate))
    end
  end
  insert(buffer, "}")
  return concat(buffer, "")
end

local functions = {}

function functions.should_close(code)
  return not (code:match("^%s*else[^%w]*") or code:match("^%s*elseif[^%w]*"))
end

function functions.newline()
  return 'r:b "\\n"'
end

function functions.code(value)
  return value
end

function functions.string(value, opts)
  local code = "r:b(%s)"
  if opts.interpolate then code = "r:b(r:interp(%s))" end
  return code:format(("%q"):format(value))
end

--- Format tables into tag attributes.
function functions.format_attributes(...)
  return 'r:b(r:attr(' .. serialize_table(join_tables(...), {interpolate = true}) .. '))'
end

function functions.ending_for(code)
  if code:match "^%s*elseif[^%w]*" then
    return nil
  elseif code:match "do%s*$" or code:match "then%s*$" then
    return "end"
  end
  return nil
end

function get_adapter(options)
  local adapter = {}
  return setmetatable(adapter, {__index = functions})
end