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


function render(precompiled, locals)
  local buffer = {}
  local locals = locals or {}
  local env = getfenv()
  -- override the default print function to add lines to a buffer
  env.print = function(str)
    table.insert(__buffer, str)
  end
  env.render_attributes = render_attributes
  -- assign local variables to the env
  for k, v in pairs(locals) do
    env[k] = v
  end
  env.__buffer = buffer
  local func = loadstring(precompiled)
  setfenv(func, env)
  func()
  return table.concat(buffer, "")
end