module("haml.lua_adapter", package.seeall)

local function serialize_table(t, opts)
  local buffer = {}
  local opts = opts or {}

  local function kv(k, v)
    if type(k) == "number" then
      return string.format('%s, ', v)
    elseif type(k) == "string" and opts.interpolate then
      return string.format('["%s"] = interpolate(%s), ', k, v)
    else
      return string.format('["%s"] = %s, ', k, v)
    end
  end

  table.insert(buffer, "{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      table.insert(buffer, kv(k, serialize_table(v, opts)))
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
    return 'buffer "\\n"'
  end

  function adapter.code(value)
    return value
  end

  function adapter.string(value, opts)
    local code = "buffer(%s)"
    if opts.interpolate then code = "buffer(interpolate(%s))" end
    return code:format(string.format("%q", value))
  end

  --- Format tables into tag attributes.
  function adapter.format_attributes(...)
    return 'buffer(render_attributes(' .. serialize_table(ext.join_tables(...), {interpolate = true}) .. '))'
  end

  function adapter.ending_for(code)
    if code:match "do%s*$" or code:match "then%s*$" then
      return "end"
    end
    return nil
  end

  return adapter

end
