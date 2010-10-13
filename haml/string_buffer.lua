local ext          = require "haml.ext"
local concat       = table.concat
local remove       = table.remove
local setmetatable = setmetatable
local strip        = ext.strip

module "haml.string_buffer"

local methods = {}

function methods:code(value)
  self.buffer[#self.buffer + 1] = self.adapter.code(value)
end

function methods:newline(force)
  if not force and self.suppress_whitespace then return end
  self.buffer[#self.buffer + 1] = self.adapter.newline()
end

--- Add a string to the buffer, wrapped in a buffer() statement.
-- @param value The string to add.
-- @param opts A table of optiions:
-- <ul>
-- <li><tt>newline</tt> If true, then append a newline to the buffer after the value.</li>
-- <li><tt>interpolate</tt> If true, then invoke string interpolation.</li>
-- </ul>
function methods:string(value, opts)
  local value = value
  if self.suppress_whitespace then
    if value:match("^%s*$") then
      return
    else
      value = value:gsub("^%s*", "")
    end
  end
  local opts = opts or {}
  self.buffer[#self.buffer + 1] = self.adapter.string(value, opts)
  if opts.newline then self:newline() end
end

function methods:chomp()
  if self.buffer[#self.buffer] == self.adapter:newline() then
    remove(self.buffer)
  end
end

function methods:rstrip()
  self:chomp()
  if self.buffer[#self.buffer - 1] == self.adapter:newline() then
    remove(self.buffer, #self.buffer - 1)
  end
end

function methods:cat()
  self:chomp()
  return strip(concat(self.buffer, "\n"))
end

function new(adapter)
  local string_buffer = {
    adapter             = adapter,
    buffer              = {},
    suppress_whitespace = false
  }
  return setmetatable(string_buffer, {__index = methods})
end