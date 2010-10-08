local ext = require "haml.ext"

module("haml.renderer", package.seeall)

local function render_attributes(options)
  return function(attr)
    local buffer = {""}
    for k, v in ext.sorted_pairs(attr) do
      if type(v) == "table" then
        if k == "class" then
          table.sort(v)
          table.insert(buffer, string.format("%s='%s'", k, table.concat(v, ' ')))
        elseif k == "id" then
          table.insert(buffer, string.format("%s='%s'", k, table.concat(v, '_')))
        end
      elseif type(v) == "boolean" then
        if options.format == "xhtml" then
          table.insert(buffer, string.format("%s='%s'", k, k))
        else
          table.insert(buffer, k)
        end
      else
        table.insert(buffer, string.format("%s='%s'", k, tostring(v)))
      end
    end
    return table.concat(buffer, " ")
  end
end

local function interpolate(env)
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

local function partial(options, __buffer, env)
  return function(file, locals)
    local locals = locals or {}
    setmetatable(locals, {__index = env})
    return haml.render_file(string.format("%s.haml", file), options, locals):gsub(
      -- if we're in a partial, by definition the last entry added to the buffer
      -- will be the current spaces
      "\n", "\n" .. __buffer[#__buffer])
  end
end

local function yield(__buffer)
  return function(content)
    return ext.strip(content:gsub("\n", "\n" .. __buffer[#__buffer]))
  end
end


function render(precompiled, options, locals)
  local current_line = 0
  local current_file = "<unknown>"
  local __buffer = {}
  local locals = locals or {}
  local options = ext.merge_tables(haml.default_options, options)
  local env = {}
  setmetatable(env, {__index = function(t, key)
    return locals[key] or _M[key] or _G[key]
  end})
  env.buffer = function(str)
    table.insert(__buffer, str)
  end
  env.yield             = yield(__buffer)
  env.partial           = partial(options, __buffer, env)
  env.interpolate       = interpolate(env)
  env.escape_html       = ext.escape_html
  env.render_attributes = render_attributes(options)
  env.at                = function(line) current_line = line end
  env.file              = function(file) current_file = file end

  local func = assert(loadstring(precompiled))
  setfenv(func, env)
  local succeeded, err = pcall(func)
  if not succeeded then
    error(string.format("\nError in %s at line %d:", current_file, current_line) ..
      err:gsub('%[.*:', ''))
  end
  return ext.strip(table.concat(__buffer, ""))
end
