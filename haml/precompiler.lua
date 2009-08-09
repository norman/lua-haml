--- Haml precompiler
module("haml.precompiler", package.seeall)

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

auto_closing_tags = {
  area  = true,
  base  = true,
  br    = true,
  col   = true,
  hr    = true,
  img   = true,
  input = true,
  link  = true,
  meta  = true,
  param = true
}

xhtml_doctypes = {
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
  MOBILE   = '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">',
  BASIC    = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
}

html4_doctypes = {
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
}

local function prolog_for(state)
  local charset = state.curr_phrase.charset or state.options.encoding
  state.buffer:string(string.format("<?xml version='1.0' encoding='%s' ?>", charset), true)
end

local function doctype_for(state)

  if state.options.format == 'html5' then
    return state.buffer:string('<!DOCTYPE html>', true)

  elseif state.curr_phrase.version == "1.1" then
    return state.buffer:string('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">', true)

  elseif state.options.format == 'xhtml' then
    local doctype = xhtml_doctypes[state.curr_phrase.doctype] or xhtml_doctypes.DEFAULT
    return state.buffer:string(doctype, true)

  elseif state.options.format == 'html4' then
    local doctype = html4_doctypes[state.curr_phrase.doctype] or html4_doctypes.DEFAULT
    return state.buffer:string(doctype, true)

  else
    error(string.format('Don\'t understand doctype "%s"', state.curr_phrase.doctype))
  end

end

local function header_for(state)

  if (string.len(state.next_phrase.space) or 0) > 0 then
    error("Syntax error: you can not nest within a doctype declaration or XML prolog.")
  end

  if state.curr_phrase.prolog then
    return prolog_for(state)
  else
    return doctype_for(state)
  end

end

local function format_attributes(...)
  local buffer = {}
  for k, v in pairs(merge_tables(...)) do
    table.insert(buffer, string.format('["%s"] = %s', k, v))
  end
  return 'print(render_attributes({' .. table.concat(buffer, ", ") .. '}))'
end

local function should_auto_close(state)
  return state.options.format == 'xhtml' and
    auto_closing_tags[state.curr_phrase.tag] and
    state.options.auto_close and
    not state.curr_phrase.inline_content
end

function tag_for(state)

  local c = state.curr_phrase
  
  -- if the current indent level is less than the previous phrase's, close
  -- endings from the ending stack
  if state:indent_diff() < 0 then
    local i = state:indent_diff()
    repeat
      state.buffer:string(
        string.rep(state.options.indent, #state.endstack - 1) ..
        table.remove(state.endstack),
        true
      )
      i = i + 1
    until i == 0
  end
  
  -- open the tag
  state.buffer:string(state:indents() .. '<' .. c.tag)

  -- add any attributes
  if c.attributes or c.css then
    local attributes = merge_tables(c.css, unpack(c.attributes or {}))
    state.buffer:code(format_attributes(attributes))
  end

  -- complete the opening tag
  if  should_auto_close(state) then
    state.buffer:string('/>')
  else
    state.buffer:string('>')
    table.insert(state.endstack, string.format("</%s>", c.tag))
    if c.inline_content then
      state.buffer:string(strip(c.inline_content))
      state.buffer:string(table.remove(state.endstack))
      state.endstack[c.space] = nil
    end
  end
  state.buffer:newline()
end

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