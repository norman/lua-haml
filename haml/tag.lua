local ext    = require "haml.ext"
local strip  = ext.strip
local unpack = unpack

module "haml.tag"

--- Whether we should auto close the tag for the current precompiler state.
local function should_auto_close(state)
  return
    state.curr_phrase.self_closing_modifier or
    state.options.auto_closing_tags[state.curr_phrase.tag] and
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

  -- Set whitespace removal is modifier set or if tag is configured to
  -- automatically preserve whitespace ("pre" and "textarea" by default).
  if c.inner_whitespace_modifier or state.options.preserve[c.tag] then
    state.buffer.suppress_whitespace = true
  end

  -- Blow away preceding whitespace when we get this modifier attached
  -- to a tag.
  if c.outer_whitespace_modifier then
    state.buffer:rstrip()
  end

  -- open the tag
  state.buffer:string(state:indents() .. '<' .. c.tag)

  -- add any attributes
  if c.attributes or c.css then
    state.buffer:code(state.adapter.format_attributes(c.css or {}, unpack(c.attributes or {})))
  end

  -- complete the opening tag
  if should_auto_close(state) then
    if state.options.format == "xhtml" then
      state.buffer:string(' />')
    else
      state.buffer:string('>')
    end
  else
    state.buffer:string('>')

    local ending = ("</%s>"):format(c.tag)
    if c.outer_whitespace_modifier then
      state.endings:push(ending, function(state)
        state.buffer:rstrip()
      end)
    else
      state.endings:push(ending)
    end

    if should_close_inline(state) then
      if c.inline_content then
        state.buffer:string(strip(c.inline_content), {interpolate = true})
      elseif c.inline_code then
        if not state.options.suppress_eval then
          state.buffer:code('r:b(r:interp(' .. c.inline_code .. '))')
        end
      end
      if c.outer_whitespace_modifier then
        state.buffer.suppress_whitespace = true
      end
      state.buffer:string((state.endings:pop()))
    end
  end
  state.buffer:newline()
end
