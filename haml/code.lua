module "haml.code"

local function ending_for(state)
  return state.adapter.ending_for(state.curr_phrase.code)
end

local function should_preserve(state)
  return state.curr_phrase.operator == "preserved_script"
end

local function should_escape(state)
  if state.curr_phrase.operator ~= "unescaped_script" then
    return state.curr_phrase.operator == "escaped_script" or state.options.escape_html
  end
end

function code_for(state)

  state.adapter.close_tags(state)

  if state.options.suppress_eval then
    return state.buffer:newline()
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
    elseif should_preserve(state) then
      state.buffer:code(('r:b(r:preserve_html(%s))'):format(state.curr_phrase.code))
    else
      state.buffer:code(('r:b(%s)'):format(state.curr_phrase.code))
    end
    state.buffer:newline()
  end
end