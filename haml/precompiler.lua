--- Haml precompiler
module("haml.precompiler", package.seeall)

require "haml.markup.headers"

local function ws(level)
  return string.format('%' .. level .. 's', '')
end

-- TODO make this publically inaccessible
function println(space, str)
  return string.format("print '%s%s'", ws(space), string.gsub(str, "'", "\\'"))
end

function precompile(haml_string, options)

  local phrases = haml.lexer.tokenize(haml_string)
  local state = {
    options = {
      format   = 'xhtml',
      encoding = 'utf-8'
    },
    tagstack     = {},
    buffer       = {},
    curr_phrase  = {},
    next_phrase  = {},
    prev_phrase  = {}
  }
  
  local function handle_current_phrase()
    if state.curr_phrase.operator == "header" then
      haml.markup.headers.header_for(state)
    end
  end

  for index, phrase in ipairs(phrases) do
    state.next_phrase = phrases[index + 1]
    state.prev_phrase = current_phrase
    state.curr_phrase = phrase
    handle_current_phrase()
  end
  
  return table.concat(state.buffer, "\n")

end