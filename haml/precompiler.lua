--- Haml precompiler
module("haml.precompiler", package.seeall)
require "haml.precompiler.headers"
require "haml.precompiler.tags"

--- Default precompiler options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
default_options = {
  format     = 'xhtml',
  encoding   = 'utf-8',
  newline    = "\n",
  indent     = "  ",
  auto_close = true
}

--- A simple string buffer object.
-- This is used by the precompiler to hold the generated (X)HTML markup.
-- @param options Possible values are "newline" and "space". They default to "\n" and " ".
local function string_buffer(options)

  local options = merge_tables(options, {
    newline = '"\n"',
    space   = " "
  })

  local string_buffer = {
    buffer = {}
  }

  function string_buffer:code(value)
    table.insert(self.buffer, value)
  end

  function string_buffer:space(length)
    if length == 0 then return end
    table.insert(self.buffer, string.format('%' .. length .. 's', options.space))
  end

  function string_buffer:newline()
    table.insert(self.buffer, string.format("print \"\\n\""))
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
    if self.buffer[#self.buffer] == 'print "\\n"' then
      table.remove(self.buffer)
    end
    return string.ltrim(table.concat(self.buffer, "\n"))
  end

  return string_buffer

end

--- Precompile Haml into Lua code.
-- @param phrases A table of parsed phrases produced by the lexer.
-- @param options Precompiler options.
function precompile(phrases, options)

  local options = merge_tables(default_options, options)
  local state      = {
    buffer         = string_buffer(options),
    options        = options,
    endstack       = {},
    curr_phrase    = {},
    next_phrase    = {},
    prev_phrase    = {},
    space_sequence = nil
  }

  function state:indent_level()
    if not self.space_sequence then
      return 0
    else
      return string.len(self.curr_phrase.space)  / string.len(self.space_sequence)
    end
  end

  function state:indent_diff()
    if not self.space_sequence then return 0 end
    return self:indent_level() - string.len(self.prev_phrase.space)  / string.len(self.space_sequence)
  end

  function state:indents()
    return string.rep(options.indent, self:indent_level())
  end

  local function detect_whitespace_format()
    if state.space_sequence then return end
    if string.len(state.curr_phrase.space or '') > 0 and not state.space_sequence then
      state.space_sequence = state.curr_phrase.space
      log("debug", string.format("Setting '%s' as leading whitespace sequence", state.space_sequence))
    end
  end

  local function validate_whitespace()
    if not state.space_sequence then return end
    if state.curr_phrase.space == "" then return end
    if string.len(state.curr_phrase.space) <= string.len(state.prev_phrase.space) then return end
    if state.curr_phrase.space == (state.prev_phrase.space .. state.space_sequence) then return end
    do_error(state.curr_phrase.chunk,
      string.format(
        "Bad indentation, current line = %d, previous = %d",
        string.len(state.curr_phrase.space),
        string.len(state.prev_phrase.space)
      )
    )
  end

  -- TODO put these functions in a table and just access them by name
  local function handle_current_phrase()
    if state.curr_phrase.operator == "header" then
      header_for(state)
    elseif state.curr_phrase.tag then
      tag_for(state)
    end
  end

  -- main precompiling loop
  for index, phrase in ipairs(phrases) do
    state.next_phrase = phrases[index + 1]
    state.prev_phrase = phrases[index - 1]
    state.curr_phrase = phrase
    detect_whitespace_format()
    validate_whitespace()
    handle_current_phrase()
  end

  -- close all open tags
  while #state.endstack ~= 0 do
    state.buffer:string(
      string.rep(state.options.indent, #state.endstack - 1) ..
      table.remove(state.endstack), true)
  end
  return state.buffer:cat()

end