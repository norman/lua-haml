module("haml.filter", package.seeall)

function shorten_space(str, options)
  local output = str:gsub("^" .. "  ", "")
  output = output:gsub(options.newline .. "  ", options.newline)
  return output
end

function preserve_filter(content, options, indents, indent_level)
  local output = content:gsub("\n", '&#x0A;')
  output = output:gsub("\r", '&#x0D;')
  output = output:gsub(options.newline .. "  ", options.newline)
  return output
end

function javascript_filter(content, options, indents, indent_level)
  local buffer = {}
  table.insert(buffer, "<script type='text/javascript'>")
  if options.format == "xhtml" then
    table.insert(buffer, "  // <![CDATA[")
  end
  table.insert(buffer, shorten_space(content, options))
  if options.format == "xhtml" then
    table.insert(buffer, "  // ]]>")
  end
  table.insert(buffer, "</script>")
  local output = table.concat(buffer, options.newline)
  output = output:gsub("%s*$", "")
  output = output:gsub(options.newline, options.newline .. indents)
  output = output:gsub("^", indents)
  return output
end

function plain_filter(content, options, indents, indent_level)
  return shorten_space(content, options)
end

filters = {
  javascript = javascript_filter,
  plain = plain_filter,
  preserve = preserve_filter,
  test = function() return nil end
}

function filter_for(state)
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
