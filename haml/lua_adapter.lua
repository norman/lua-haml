module("haml.lua_adapter", package.seeall)

local function key_val(k, v, interpolate)
  if type(k) == "number" then
    return ('%s, '):format(v)
  elseif type(k) == "string" and interpolate then
    return ('["%s"] = interpolate(%s), '):format(k, v)
  else
    return ('["%s"] = %s, '):format(k, v)
  end
end

local function serialize_table(t, opts)
  local buffer = {}
  local opts   = opts or {}

  table.insert(buffer, "{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      table.insert(buffer, key_val(k, serialize_table(v, opts), opts.interpolate))
    else
      table.insert(buffer, key_val(k, v, opts.interpolate))
    end
  end
  table.insert(buffer, "}")
  return table.concat(buffer, "")
end

local functions = {}

function functions.should_close(code)
  return not (code:match("^%s*else[^%w]*") or code:match("^%s*elseif[^%w]*"))
end

function functions.newline()
  return 'buffer "\\n"'
end

function functions.code(value)
  return value
end

function functions.string(value, opts)
  local code = "buffer(%s)"
  if opts.interpolate then code = "buffer(interpolate(%s))" end
  return code:format(string.format("%q", value))
end

--- Format tables into tag attributes.
function functions.format_attributes(...)
  return 'buffer(render_attributes(' .. serialize_table(ext.join_tables(...), {interpolate = true}) .. '))'
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