module("haml.filter", package.seeall)

local function change_indents(str, len, options)
  local output = str:gsub("^" .. options.space, options.space:rep(len))
  output = output:gsub(options.newline .. options.space, options.newline .. options.space:rep(len))
  return output
end

local function preserve_filter(content, options, indents, indent_level)
  local output = change_indents(content, indent_level - 1, options)
  output = output:gsub("\n", '&#x000A;'):gsub("\r", '&#x000D;')
  return output
end

local function javascript_filter(content, options, indents, indent_level)
  local buffer = {}
  table.insert(buffer, options.space:rep(indent_level) .. "<script type='text/javascript'>")
  table.insert(buffer, change_indents(content:gsub(options.newline .. '*$', ''), 2, options))
  table.insert(buffer, options.space:rep(indent_level) .. "</script>")
  if options.format == "xhtml" then
    table.insert(buffer, 2, options.space:rep(indent_level + 1) .. "//<![CDATA[")
    table.insert(buffer, #buffer, options.space:rep(indent_level + 1) .. "//]]>")
  end
  local output = table.concat(buffer, options.newline)
  return output
end

local function plain_filter(content, options, indents, indent_level)
  return change_indents(content, indent_level - 1, options)
end

filters = {
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
  local content = func(state.curr_phrase.content, state.options, state:indents(), state:indent_level())
  if content then
    state.buffer:string(content, {long = true, interpolate = true})
    state.buffer:newline()
  end
end
