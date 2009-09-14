module("haml.lua_adapter", package.seeall)

local function serialize_table(t)
  local buffer = {}

  local function kv(k, v)
    if type(k) == "number" then
      return string.format('%s, ', v)
    else
      return string.format('["%s"] = %s, ', k, v)
    end
  end

  table.insert(buffer, "{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      table.insert(buffer, kv(k, serialize_table(v)))
    else
      table.insert(buffer, kv(k, v))
    end
  end
  table.insert(buffer, "}")
  return table.concat(buffer, "")
end


function get_adapter(options)

  local adapter = {}

  function adapter.newline()
    return 'print "\\n"'
  end

  function adapter.code(value)
    return value
  end

  function adapter.string(value, opts)
    local code                    = "print(%s)"
    local str                     = "[=[%s]=]"
    if opts.interpolate then code = "print(interpolate(%s))" end
    return code:format(str:format(value))
  end

  --- Format tables into tag attributes.
  function adapter.format_attributes(...)
    return 'print(render_attributes(' .. serialize_table(join_tables(...)) .. '))'
  end

  return adapter

end
