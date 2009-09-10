--- Haml precompiler
module("haml.precompiler", package.seeall)
require "haml.code"
require "haml.filter"
require "haml.headers"
require "haml.tags"

--- Default precompiler options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
-- TODO allow an option for tag auto-closing
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

  local options = merge_tables(options, { newline = '"\n"', space   = " " })
  local string_buffer = { buffer = {} }

  function string_buffer:code(value)
    table.insert(self.buffer, value)
  end

  function string_buffer:space(length)
    if length == 0 then return end
    table.insert(self.buffer, options.space:rep(length))
  end

  function string_buffer:newline()
    table.insert(self.buffer, "print \"\\n\"")
  end

  --- Add a string to the buffer, wrapped in a print() statement.
  -- @param value The string to add.
  -- @param opts A table of optiions:
  -- <ul>
  -- <li><tt>add_newline</tt> If true, then append a newline to the buffer after the value.</li>
  -- <li><tt>long</tt> If true, then insert a Lua long string.</li>
  -- <li><tt>interpolate</tt> If true, then allow Ruby-style string interpolation.</li>
  -- </ul>
  function string_buffer:string(value, opts)
    local opts                    = opts or {}
    local code                    = "print(%s)"
    local str                     = "[=[%s]=]"
    if opts.interpolate then code = "print(interpolate(%s))" end
    table.insert(self.buffer, code:format(str:format(value)))
    if opts.newline then self:newline() end
  end

  function string_buffer:cat()
    -- strip trailing newlines
    if self.buffer[#self.buffer] == 'print "\\n"' then
      table.remove(self.buffer)
    end
    return strip(table.concat(self.buffer, "\n"))
  end

  return string_buffer

end

function endstack()

  local stack = {endings = {}, indents = 0}

  function stack:push(ending)
    table.insert(self.endings, ending)
    if ending:match '^<' then
      self.indents = self.indents + 1
    end
  end

  function stack:pop()
    if #self.endings == 0 then return nil end
    local ending = table.remove(self.endings)
    if ending:match '^<' then
      self.indents = self.indents - 1
    end
    return ending
  end

  function stack:indent_level()
    return self.indents
  end

  function stack:size()
    return #self.endings
  end

  return stack

end

--- Precompile Haml into Lua code.
-- @param phrases A table of parsed phrases produced by the parser.
-- @param options Precompiler options.
function precompile(phrases, options)

  local options = merge_tables(default_options, options)
  local state      = {
    buffer         = string_buffer(options),
    options        = options,
    endings        = endstack(),
    curr_phrase    = {},
    next_phrase    = {},
    prev_phrase    = {},
    space_sequence = nil
  }

  function state:indent_level()
    if not self.space_sequence then
      return 0
    else
      return self.curr_phrase.space:len() / self.space_sequence:len()
    end
  end

  function state:indent_diff()
    if not self.space_sequence then return 0 end
    return self:indent_level() - self.prev_phrase.space:len()  / self.space_sequence:len()
  end

  function state:indents()
    return self.options.indent:rep(self.endings:indent_level())
  end

  function state:close_tags()
    -- if the current indent level is less than the previous phrase's, close
    -- endings from the ending stack
    if self:indent_diff() < 0 then
      local i = self:indent_diff()
      repeat
        local ending = self.endings:pop()
        if ending:match "^<" then
          self.buffer:string(self:indents() .. ending, {newline = true})
        else
          self.buffer:code(ending)
        end
        i = i + 1
      until i == 0
    end
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
    local prev_space = ''
    if state.prev_phrase then prev_space = state.prev_phrase.space end
    if state.curr_phrase.space:len() <= prev_space:len() then return end
    if state.curr_phrase.space == (prev_space .. state.space_sequence) then return end
    do_error(state.curr_phrase.chunk,
      string.format(
        "bad indentation, current line = %d, previous = %d",
        state.curr_phrase.space:len(),
        prev_space:len()
      )
    )
  end

  local function handle_current_phrase()
    if state.curr_phrase.operator == "header" then
      haml.headers.header_for(state)
    elseif state.curr_phrase.operator == "filter" then
      haml.filter.filter_for(state)
    elseif state.curr_phrase.operator == "silent_comment" then
      state:close_tags()
    elseif state.curr_phrase.tag then
      haml.tags.tag_for(state)
    elseif state.curr_phrase.code then
      haml.code.code_for(state)
    elseif state.curr_phrase.unparsed then
      state:close_tags()
      state.buffer:string(state:indents() .. state.curr_phrase.unparsed, {newline = true})
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
  while state.endings:size() > 0 do
    local ending = state.endings:pop()
    if ending:match "^<" then
      state.buffer:string(state:indents() .. ending, {newline = true})
    else
      state.buffer:code(ending)
    end
  end

  return state.buffer:cat()

end
