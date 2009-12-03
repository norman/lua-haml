module("haml.renderer", package.seeall)

function render_attributes(attr)
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

function interpolate(env)
  local function f(str)
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
  setfenv(f, env)
  return f
end

local function partial(options, buffer, env)
  return function(file, locals)
    local locals = locals or {}
    setmetatable(locals, {__index = env})
    return haml.render_file(string.format("%s.haml", file), options, locals):gsub(
      -- if we're in a partial, by definition the last entry added to the buffer
      -- will be the current spaces
      "\n", "\n" .. buffer[#buffer])
  end
end

function yield(buffer)
  return function(content)
    return ext.strip(content:gsub("\n", "\n" .. buffer[#buffer]))
  end
end


function render(precompiled, options, locals)
  local buffer = {}
  local locals = locals or {}
  local options = ext.merge_tables(options, haml.default_options)
  local env = {}
  setmetatable(env, {__index = function(t, key)
    return locals[key] or _M[key] or _G[key]
  end})
  env.print = function(str)
    table.insert(buffer, str)
  end
  env.yield = yield(buffer)
  env.partial = partial(options, buffer, env)
  env.interpolate = interpolate(env)
  env.escape_html = ext.escape_html
  local func = assert(loadstring(precompiled))
  setfenv(func, env)
  func()
  return ext.strip(table.concat(buffer, ""))
end
