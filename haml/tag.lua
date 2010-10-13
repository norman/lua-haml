local ext    = require "haml.ext"
local strip  = ext.strip
local unpack = unpack

module "haml.tag"

--- These tags will be auto-closed if the output format is XHTML (the default).
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

--- Whether we should auto close the tag for the current precompiler state.
local function should_auto_close(state)
  return
    auto_closing_tags[state.curr_phrase.tag] and
    state.options.auto_close and
    not state.curr_phrase.inline_content
end

local function should_close_inline(state)
  return state.curr_phrase.inline_content or
    state.curr_phrase.inline_code or
    not state.next_phrase or
    state.next_phrase.space <= state.curr_phrase.space
end

-- Precompile an (X)HTML tag for the current precompiler state.
function tag_for(state)

  local c = state.curr_phrase

  -- close any open tags if need be
  state:close_tags()

  -- set whitespace removal is modifier set
  if c.inner_whitespace_modifier then
    state.show_whitespace = false
  end

  -- open the tag
  state.buffer:string(state:indents() .. '<' .. c.tag)

  -- add any attributes
  if c.attributes or c.css then
    state.buffer:code(state.adapter.format_attributes(c.css or {}, unpack(c.attributes or {})))
  end

  -- complete the opening tag
  if  should_auto_close(state) then
    if state.options.format == "xhtml" then
      state.buffer:string(' />')
    else
      state.buffer:string('>')
    end
  else
    state.buffer:string('>')
    state.endings:push(("</%s>"):format(c.tag))
    if should_close_inline(state) then
      if c.inline_content then
        state.buffer:string(strip(c.inline_content), {interpolate = true})
      elseif c.inline_code then
        state.buffer:code('r:b(r:interp(' .. c.inline_code .. '))')
      end
      state.buffer:string(state.endings:pop())
    end
  end
  if state.options.preserve[c.tag] then
    state.indenting = false
  else
    if state.show_whitespace then
      state.buffer:newline()
    end
  end
end
