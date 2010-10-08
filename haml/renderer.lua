local ext = require "haml.ext"

local _G           = _G
local assert       = assert
local concat       = table.concat
local error        = error
local getfenv      = getfenv
local insert       = table.insert
local loadstring   = loadstring
local pairs        = pairs
local pcall        = pcall
local setfenv      = setfenv
local setmetatable = setmetatable
local sorted_pairs = ext.sorted_pairs

module "haml.renderer"

local methods = {}

local function interpolate_value(str, locals)
  -- load stuff between braces, and prepend "return" so that "#{var}" can be printed
  local code = str:sub(2, str:len()-1)
  -- avoid doing an eval if we're simply returning a value that's in scope
  if locals[code] then return locals[code] end
  local func = loadstring("return " .. code)
  return assert(func)()
end

--- Do Ruby-style string interpolation.
-- e.g.: "#{var}" will be interpreted to the value of `var`.
function methods:interp(str)
  if type(str) ~= "string" then return str end
  -- match position, then "#" followed by balanced "{}"
  return str:gsub('([\\]*)#()(%b{})', function(a, b, c)
    -- if the character before the match is backslash...
    if a:match "\\" then
      -- then don't interpolate...
      if #a == 1 then
        return '#' .. c
      -- unless the backslash is also escaped by another backslash
      elseif #a % 2 == 0 then
        return a:sub(1, #a / 2) .. interpolate_value(c, self.locals)
      -- otherwise remove the escapes before outputting
      else
        local prefix = #a == 1 and "" or a:sub(0, #a / 2)
        return prefix .. '#' .. c
      end
    end
    return interpolate_value(c, self.locals)
  end)
end

function methods:escape_html(...)
  return ext.escape_html(...)
end


function methods:attr(attr)
  return ext.render_attributes(attr, self.options)
end

function methods:at(line)
  self.current_line = line
end

function methods:f(file)
  self.current_file = file
end

function methods:b(string)
  insert(self.buffer, string)
end

function methods:make_partial_func()
  return function(file, locals)
    local haml     = require "haml"
    local rendered = haml.render_file(("%s.haml"):format(file), self.options, locals)
    -- if we're in a partial, by definition the last entry added to the buffer
    -- will be the current spaces
    return rendered:gsub("\n", "\n" .. self.buffer[#self.buffer])
  end
end

function methods:make_yield_func()
  return function(content)
    return ext.strip(content:gsub("\n", "\n" .. self.buffer[#self.buffer]))
  end
end

function methods:render(precompiled)
  local func  = assert(loadstring(precompiled))
  local env   = getfenv()
  -- the renderer object itself
  env.r       = self
  -- set up DSL helper functions
  env.yield   = self:make_yield_func()
  env.partial = self:make_partial_func()

  -- assign locals as env vars
  for k, v in pairs(self.locals) do
    env[k] = v
  end

  -- allow access to globals
  setmetatable(env, {__index = _G})

  setfenv(func, env)

  -- now do the actual rendering
  local succeeded, err = pcall(func)
  if not succeeded then
    error(("\nError in %s at line %d:"):format(self.current_file,
      self.current_line) .. err:gsub('%[.*:', ''))
  end
  return ext.strip(concat(self.buffer, ""))
end

function new(options, locals)
  local renderer = {
    buffer       = {},
    current_file = "<unknown>",
    current_line = 0,
    locals       = locals or {},
    options      = ext.merge_tables(default_haml_options, options)
  }
  return setmetatable(renderer, {__index = methods})
end