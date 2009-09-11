module("haml.renderer", package.seeall)

local function render_attributes(attr)
  local buffer = {""}
  for k, v in sorted_pairs(attr) do
    if type(v) == "table" then
      if k == "class" then
        table.sort(v)
        table.insert(buffer, string.format("%s='%s'", k, table.concat(v, ' ')))
      elseif k == "id" then
        table.insert(buffer, string.format("%s='%s'", k, table.concat(v, '_')))
      end
    else
      table.insert(buffer, string.format("%s='%s'", k, v))
    end
  end
  return table.concat(buffer, " ")
end

local function interpolate(str)
  -- match position, then "#" followed by balanced "{}"
  return str:gsub('()#(%b{})', function(a, b)
    -- if the character before the match is backslash, then don't interpolate
    if str:sub(a-1, a-1) == "\\" then return b end
    -- load stuff between braces, and prepend "return" so that "#{var}" can be printed
    local func = loadstring("return " .. b:sub(2, b:len()-1))
    setfenv(func, getfenv())
    return assert(func)()
  end)
end

function render(precompiled, locals)
  local buffer = {}
  local locals = locals or {}
  local env = getfenv()
  -- override the default print function to add lines to a buffer
  env.print = function(str)
    table.insert(__buffer, str)
  end
  env.render_attributes = render_attributes
  env.interpolate = interpolate
  -- assign local variables to the env
  for k, v in pairs(locals) do
    env[k] = v
  end
  env.__buffer = buffer
  local func = loadstring(precompiled)
  setfenv(func, env)
  func()
  return table.concat(buffer, ""):gsub("[%s]*$", "")
end
