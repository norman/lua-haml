module("haml.code", package.seeall)

local function ending_for(state)
  return state.adapter.ending_for(state.curr_phrase.code)
end

function code_for(state)
  if state.curr_phrase.operator == "silent_script" then
    state.buffer:code(state.curr_phrase.code)
    local ending = ending_for(state)
    if ending then
      state.endings:push(ending)
    end
  elseif state.curr_phrase.operator == "script" then
    state.buffer:string(state.options.indent:rep(state.endings:indent_level()))
    state.buffer:code(string.format('print(%s)', state.curr_phrase.code))
    state.buffer:newline()
  end
end
