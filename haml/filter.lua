module("haml.filter", package.seeall)

function escape_html(str, escapes)
  return str:gsub("([\"'&<>])", function(a)
    return escapes[a]
  end)
end

function change_indents(str, len, options)
  local output = str:gsub("^" .. options.space, options.space:rep(len))
  output = output:gsub(options.newline .. options.space, options.newline .. options.space:rep(len))
  return output
end

local function preserve_filter(state)
  local output = change_indents(
    state.curr_phrase.content,
    state:indent_level() - 1,
    state.options):gsub(
      "\n", '&#x000A;'):gsub(
      "\r", '&#x000D;'
  )
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function escaped_filter(state)
  local output = change_indents(
    escape_html(
      state.curr_phrase.content,
      state.options.html_escapes
    ),
    state:indent_level() - 1,
    state.options
  ):gsub("[%s]*$", "")
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function javascript_filter(state)
  local content = state.curr_phrase.content
  local options = state.options
  local indent_level = state:indent_level()
  local buffer = {}
  table.insert(buffer, state:indents() .. "<script type='text/javascript'>")
  table.insert(buffer, change_indents(content:gsub(options.newline .. '*$', ''), 2, options))
  table.insert(buffer, state:indents() .. "</script>")
  if options.format == "xhtml" then
    table.insert(buffer, 2, state:indents(1) .. "//<![CDATA[")
    table.insert(buffer, #buffer, state:indents(1) .. "//]]>")
  end
  local output = table.concat(buffer, options.newline)
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function plain_filter(state)
  local output = change_indents(
    state.curr_phrase.content,
    state:indent_level() - 1,
    state.options
  )
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

filters = {
  escaped = escaped_filter,
  javascript = javascript_filter,
  plain = plain_filter,
  preserve = preserve_filter,
}

function filter_for(state)
  state:close_tags()
  local func
  if filters[state.curr_phrase.filter] then
    func = filters[state.curr_phrase.filter]
  else
    do_error(state.curr_phrase.chunk, "No such filter \"%s\"", state.curr_phrase.filter)
  end
  return func(state)
end
