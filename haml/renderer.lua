local ext = require "haml.ext"

local _G           = _G
local assert       = assert
local concat       = table.concat
local error        = error
local getfenv      = getfenv
local insert       = table.insert
local loadstring   = loadstring
local open         = io.open
local pairs        = pairs
local pcall        = pcall
local require      = require
local setfenv      = setfenv
local setmetatable = setmetatable
local sorted_pairs = ext.sorted_pairs
local tostring     = tostring
local type         = type
local rawset       = rawset

module "haml.renderer"

local methods = {}

local function interpolate_value(str, locals)
  local locals = locals or {}
  -- load stuff between braces
  local code = str:sub(2, str:len()-1)
  -- avoid doing an eval if we're simply returning a value that's in scope
  if locals[code] then return locals[code] end
  local func = loadstring("return " .. code)
  local env = getfenv()
  setmetatable(env, {__index = function(table, key)
    return locals[key] or _G[key]
  end})
  setfenv(func, env)
  return assert(func)()
end

--- Does Ruby-style string interpolation.
-- e.g.: in "hello #{var}!"
function methods:interp(str)
  if self.options.suppress_eval then return str end
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
        return a:sub(1, #a / 2) .. interpolate_value(c, self.env.locals)
      -- otherwise remove the escapes before outputting
      else
        local prefix = #a == 1 and "" or a:sub(0, #a / 2)
        return prefix .. '#' .. c
      end
    end
    return interpolate_value(c, self.env.locals)
  end)
end

function methods:escape_html(...)
  return ext.escape_html(..., self.options.html_escapes)
end

local function escape_newlines(a, b, c)
  return a .. b:gsub("\n", "&#x000A;") .. c
end

function methods:preserve_html(string)
  local string  = string
  for tag, _ in pairs(self.options.preserve) do
    string = string:gsub(("(<%s>)(.*)(</%s>)"):format(tag, tag), escape_newlines)
  end
  return string
end

function methods:attr(attr)
  return ext.render_attributes(attr, self.options)
end

function methods:at(pos)
  self.current_pos = pos
end

function methods:f(file)
  self.current_file = file
end

function methods:b(string)
  insert(self.buffer, string)
end

function methods:make_partial_func()
  local renderer = self
  local haml = require "haml"
  return function(file, locals)
    local engine   = haml.new(self.options)
    local rendered = engine:render_file(("%s.haml"):format(file), locals or renderer.env.locals)
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

function methods:render(locals)
  local locals      = locals or {}
  self.buffer       = {}
  self.current_pos  = 0
  self.current_file = nil
  self.env.locals   = locals or {}

  setmetatable(self.env, {__index = function(table, key)
    return locals[key] or _G[key]
  end,
  __newindex = function(table, key, val) rawset(locals, key, val) end
  })

  local succeeded, err = pcall(self.func)
  if not succeeded then

    local line_number

    if self.current_file then
      local file = assert(open(self.current_file, "r"))
      local str = file:read(self.current_pos)
      line_number = #str - #str:gsub("\n", "") + 1
    end

    error(
      ("\nError in %s at line %s (offset %d):"):format(
        self.current_file or "<unknown>",
        line_number or "<unknown>",
        self.current_pos - 1) ..
      tostring(err):gsub('%[.*:', '')
    )
  end
  -- strip trailing spaces
  if #self.buffer > 0 then
    self.buffer[#self.buffer] = self.buffer[#self.buffer]:gsub("%s*$", "")
  end
  return concat(self.buffer, "")

end

function new(precompiled, options)
  local renderer = {
    options = options or {},
    -- TODO: capture compile errors here and determine line number
    func    = assert(loadstring(precompiled)),
    env     = {}
  }
  setmetatable(renderer, {__index = methods})
  renderer.env = {
    r       = renderer,
    yield   = renderer:make_yield_func(),
    partial = renderer:make_partial_func(),
  }
  setfenv(renderer.func, renderer.env)
  return renderer
end
