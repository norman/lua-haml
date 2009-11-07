module("haml.renderer", package.seeall)

local function render_attributes(attr)
  local buffer = {""}
  for k, v in ext.sorted_pairs(attr) do
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
  if type(str) ~= "string" then return str end
  -- match position, then "#" followed by balanced "{}"
  return str:gsub('([\\]*)#()(%b{})', function(a, b, c)

    local function interp()
      -- load stuff between braces, and prepend "return" so that "#{var}" can be printed
      local code = c:sub(2, c:len()-1)
      local env = getfenv()
      -- avoid doing an eval if we're simply returning a value that's in scope
      if env[code] then
        return env[code]
      end
      local func = loadstring("return " .. code)
      setfenv(func, env)
      return assert(func)()
    end

    -- if the character before the match is backslash, then don't interpolate
    if a:match "\\" then
      if a:len() == 1 then
        return '#' .. c
      elseif a:len() % 2 == 0 then
        return a:sub(1, a:len() / 2) .. interp()
      else
        local prefix = a:len() == 1 and "" or a:sub(0, a:len() / 2)
        return prefix .. '#' .. c
      end
    end
    return interp()
  end)
end

local function partial(options, buffer)
  return function(file, locals)
    return haml.render_file(string.format("%s.haml", file), options, locals):gsub(
      -- if we're in a partial, by definition the last entry added to the buffer
      -- will be the current spaces
      "\n", "\n" .. buffer[#buffer])
  end
end

function render(precompiled, options, locals)
  local buffer = {}
  local options = ext.merge_tables(options, haml.default_options)
  local env = {}
  setmetatable(env, {__index = _G})
  -- override the default print function to add lines to a buffer
  env.print = function(str)
    table.insert(buffer, str)
  end
  env.render_attributes = render_attributes
  env.interpolate = interpolate
  env.partial = partial(options, buffer)
  -- assign local variables to the env
  for k, v in pairs(locals or {}) do
    env[k] = v
  end
  local func = loadstring(precompiled)
  setfenv(func, env)
  setfenv(interpolate, env)
  func()
  return ext.strip(table.concat(buffer, ""))
end
