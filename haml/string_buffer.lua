module("StringBuffer", package.seeall)

function new(adapter)
  local sb = {
    adapter = adapter,
    buffer = {}
  }
  setmetatable(sb, {__index = StringBuffer})
  return sb
end

function StringBuffer:code(value)
  self.buffer[#self.buffer + 1] = self.adapter.code(value)
end

function StringBuffer:newline()
  self.buffer[#self.buffer + 1] = self.adapter.newline()
end

--- Add a string to the buffer, wrapped in a buffer() statement.
-- @param value The string to add.
-- @param opts A table of optiions:
-- <ul>
-- <li><tt>newline</tt> If true, then append a newline to the buffer after the value.</li>
-- <li><tt>interpolate</tt> If true, then invoke string interpolation.</li>
-- </ul>
function StringBuffer:string(value, opts)
  local opts = opts or {}
  self.buffer[#self.buffer + 1] = self.adapter.string(value, opts)
  if opts.newline then self:newline() end
end

function StringBuffer:chomp()
  if self.buffer[#self.buffer] == self.adapter:newline() then
    table.remove(self.buffer)
  end
end

function StringBuffer:cat()
  self:chomp()
  return ext.strip(table.concat(self.buffer, "\n"))
end
