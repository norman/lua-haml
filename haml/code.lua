module("haml.code", package.seeall)

local function ending_for(code)
  if string.match(code, "do%s*$") or string.match(code, "then%s*$") then
    return "end"
  end
  return nil
end

function code_for(state)
  if state.curr_phrase.operator == "silent_script" then
    state.buffer:code(state.curr_phrase.code)
    local ending = ending_for(state.curr_phrase.code)
    if ending then
      state.endings:push(ending)
    end
  elseif state.curr_phrase.operator == "script" then
    state.buffer:string(string.rep(state.options.indent, state.endings:indent_level()))
    state.buffer:code(string.format('print(%s)', state.curr_phrase.code))
    state.buffer:newline()
  end
end
