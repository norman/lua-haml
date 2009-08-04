--- Works exactly like pairs() but iterators over sorted table keys.
-- @param t The table to iterate over
-- @param func An option sorting function
-- @return The iterator function
-- @return The table
-- @return The index
function sorted_pairs(t, func)
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys, func)
  local iterator, _, index = ipairs(keys)
  return function()
    local _, key = iterator(keys, index)
    index = index + 1
    return key, t[key] 
  end, tab, index
end

--- Set defaults for missing key-value pairs.
-- @param t1 The table to apply the defaults to
-- @param t2 The table with the default values
function apply_defaults(t1, t2)
  if not t1 then t1 = {} end
  for k, v in pairs(t2) do
    if not t1[k] then t1[k] = v end
  end
  return t1
end

--- Flattens a table of tables
function flatten(t)
  local out = {}
  for _, attr in ipairs(t) do
    for k, v in pairs(attr) do
      out[k] = v
    end
  end
  return out
end

--- Create a function which accumulates all values passed to it in a table.
-- Each call to the function appends the value to a table and returns the
-- resulting table.
-- function accumulator()
--   local array = {}
--   return function(value)
--     table.insert(array, value)
--     return array
--   end
-- end

--- A simple string buffer object.
-- This is used by the precompiler to hold the generated (X)HTML markup.
-- @param options Possible values are "newline" and "space". They default to "\n" and " ".
function string_buffer(options)

  local options = apply_defaults(options, {
    newline = "\n",
    space   = " "
  })
  
  local string_buffer = {
    buffer = {}
  }

  function string_buffer:code(value)
    table.insert(self.buffer, string.format("%s", value))
  end
  
  function string_buffer:space(length)
    if length == 0 then return end
    table.insert(self.buffer, string.format('%' .. length .. 's', options.space))
  end

  function string_buffer:newline()
    table.insert(self.buffer, options.newline)
  end

  --- Add a string to the buffer, wrapped in a print() statement.
  -- @param value The string to add.
  -- @param add_newline If true, then append a newline to the buffer after the value.
  function string_buffer:string(value, add_newline)
    table.insert(self.buffer, string.format("print '%s'", string.gsub(value, "'", "\\'")))
    if add_newline then self:newline() end
  end

  function string_buffer:cat()
    -- strip trailing newlines
    while #self.buffer and self.buffer[#self.buffer] == options.newline do
      table.remove(self.buffer)
    end
    return table.concat(self.buffer, "")
  end

  return string_buffer

end