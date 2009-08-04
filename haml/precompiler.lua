--- Haml precompiler
module("haml.precompiler", package.seeall)

require "haml.markup.headers"

--- Default precompiler options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
default_options = {
  format   = 'xhtml',
  encoding = 'utf-8',
  newline  = "\n",
  space    = " "
}

--- Precompile Haml into Lua code.
-- @param haml_string A Haml string
-- @param options The options.
function precompile(haml_string, options, locals)

  options = apply_defaults(options, default_options)
  local phrases = haml.lexer.tokenize(haml_string)

  local state = {
    buffer       = string_buffer(options),
    options      = options,
    tagstack     = {},
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

  return state.buffer:cat()

end