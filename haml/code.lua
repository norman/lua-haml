module "haml.code"

local function ending_for(state)
  return state.adapter.ending_for(state.curr_phrase.code)
end

local function should_escape(state)
  if state.curr_phrase.operator == "unescaped_script" then
    return false
  elseif state.curr_phrase.operator == "escaped_script" then
    return true
  else
    return state.options.escape_html
  end
end

function code_for(state)
  if state.adapter.should_close(state.curr_phrase.code) then
    state:close_tags()
  end

  if state.curr_phrase.operator == "silent_script" then
    state.buffer:code(state.curr_phrase.code)
    local ending = ending_for(state)
    if ending then
      state.endings:push(ending)
    end
  else
    state.buffer:string(state.options.indent:rep(state.endings:indent_level()))
    if should_escape(state) then
      state.buffer:code(('r:b(r:escape_html(%s))'):format(state.curr_phrase.code))
    else
      state.buffer:code(('r:b(%s)'):format(state.curr_phrase.code))
    end
    state.buffer:newline()
  end
end