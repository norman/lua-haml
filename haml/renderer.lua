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
  -- io.stderr:write(str, "\n", "---", "\n")

  -- match position, then "#" followed by balanced "{}"
  return str:gsub('([\\]*)#()(%b{})', function(a, b, c)

    local function interp()
      -- load stuff between braces, and prepend "return" so that "#{var}" can be printed
      local func = loadstring("return " .. c:sub(2, c:len()-1))
      setfenv(func, getfenv())
      return assert(func)()
    end

    -- if the character before the match is backslash, then don't interpolate
    if a:match "\\" then
      if a:len() == 1 then
        return '#' .. c
      elseif a:len() % 2 == 0 then
        return a:sub(1, a:len() / 2) .. interp()
      else
        -- io.stderr:write("'"..tostring(a).."'", tostring(b), tostring(c), "\n")
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
  local options = merge_tables(options, haml.default_options)
  local env = {}
   for k, v in pairs(_G) do
     env[k] = v
   end
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
  return strip(table.concat(buffer, ""))
end
