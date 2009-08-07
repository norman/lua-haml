local auto_closing_tags = {
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