local ext   = require "haml.ext"
local strip = ext.strip

module "haml.comment"

function comment_for(state)
  state:close_tags()

  if state.curr_phrase.operator == "markup_comment" then
    if state.curr_phrase.unparsed then
      state.buffer:string(state:indents() .. "<!-- ")
      state.buffer:string(state.curr_phrase.unparsed)
      state.buffer:string(state:indents() .. " -->")
    elseif state.curr_phrase.content then
      state.buffer:string(state:indents() .. "<!--", {newline = true})
      state.buffer:string(state.curr_phrase.content, {newline = true})
      state.buffer:string(state:indents() .. "-->", {newline = true})
    end

  elseif state.curr_phrase.operator == "conditional_comment" then
    state.buffer:string(state:indents() .. ("<!--[%s]>"):format(strip(state.curr_phrase.condition)), {newline = true})
    state.endings:push("<![endif]-->")
  end
end