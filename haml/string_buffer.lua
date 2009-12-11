module("haml.string_buffer", package.seeall)

function new(adapter)
  local sb = {
    adapter = adapter,
    buffer = {}
  }
  setmetatable(sb, {__index = _M})
  return sb
end

function haml.string_buffer:code(value)
  self.buffer[#self.buffer + 1] = self.adapter.code(value)
end

function haml.string_buffer:newline()
  self.buffer[#self.buffer + 1] = self.adapter.newline()
end

--- Add a string to the buffer, wrapped in a buffer() statement.
-- @param value The string to add.
-- @param opts A table of optiions:
-- <ul>
-- <li><tt>newline</tt> If true, then append a newline to the buffer after the value.</li>
-- <li><tt>interpolate</tt> If true, then invoke string interpolation.</li>
-- </ul>
function haml.string_buffer:string(value, opts)
  local opts = opts or {}
  self.buffer[#self.buffer + 1] = self.adapter.string(value, opts)
  if opts.newline then self:newline() end
end

function haml.string_buffer:chomp()
  if self.buffer[#self.buffer] == self.adapter:newline() then
    table.remove(self.buffer)
  end
end

function haml.string_buffer:cat()
  self:chomp()
  return ext.strip(table.concat(self.buffer, "\n"))
end
