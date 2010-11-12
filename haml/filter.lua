local ext            = require "haml.ext"

local change_indents = ext.change_indents
local concat         = table.concat
local escape_html    = ext.escape_html
local insert         = table.insert
local require        = require
local strip          = ext.strip
local do_error       = ext.do_error

module "haml.filter"

local function code_filter(state)
  state.buffer:code(state.curr_phrase.content)
end

local function preserve_filter(state)
  local output = change_indents(
    state.curr_phrase.content,
    state:indent_level() - 1,
    state.options):gsub(
      "\n", '&#x000A;'):gsub(
      "\r", '&#x000D;'
  )
  state.buffer:string(output, {interpolate = true})
  state.buffer:newline()
end

local function escaped_filter(state)
  local output = strip(change_indents(
    escape_html(
      state.curr_phrase.content,
      state.options.html_escapes
    ),
    state:indent_level() - 1,
    state.options
  ))
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function javascript_filter(state)
  local content = state.curr_phrase.content
  local options = state.options
  local indent_level = state:indent_level()
  local buffer = {}
  insert(buffer, state:indents() .. "<script type='text/javascript'>")
  insert(buffer, change_indents(content:gsub(options.newline .. '*$', ''), 2, options))
  insert(buffer, state:indents() .. "</script>")
  if options.format == "xhtml" then
    insert(buffer, 2, state:indents(1) .. "//<![CDATA[")
    insert(buffer, #buffer, state:indents(1) .. "//]]>")
  end
  local output = concat(buffer, options.newline)
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function cdata_filter(state)
  local content = state.curr_phrase.content
  local options = state.options
  local buffer = {}
  insert(buffer, state:indents() .. "<![CDATA[")
  insert(buffer, change_indents(content:gsub(options.newline .. '*$', ''), 2, options))
  insert(buffer, state:indents() .. "]]>")
  local output = concat(buffer, options.newline)
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function markdown_filter(state)
  local markdown = require "markdown"
  local output = state.curr_phrase.content:gsub("^"..state:indents(1), "")
  output = markdown(output:gsub(state.options.newline .. state:indents(1), state.options.newline))
  state.buffer:string(change_indents(strip(output), state:indent_level(), state.options), {long = true, interpolate = true})
  state.buffer:newline()
end

local function plain_filter(state)
  local output = change_indents(
    state.curr_phrase.content:gsub("[%s]*$", ""),
    state:indent_level() - 1,
    state.options
  )
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

local function css_filter(state)
  local content = state.curr_phrase.content
  local options = state.options
  local indent_level = state:indent_level()
  local buffer = {}
  insert(buffer, state:indents() .. "<style type='text/css'>")
  insert(buffer, change_indents(content:gsub(options.newline .. '*$', ''), 2, options))
  insert(buffer, state:indents() .. "</style>")
  if options.format == "xhtml" then
    insert(buffer, 2, state:indents(1) .. "/*<![CDATA[*/")
    insert(buffer, #buffer, state:indents(1) .. "/*]]>*/")
  end
  local output = concat(buffer, options.newline)
  state.buffer:string(output, {long = true, interpolate = true})
  state.buffer:newline()
end

filters = {
  cdata      = cdata_filter,
  css        = css_filter,
  escaped    = escaped_filter,
  javascript = javascript_filter,
  lua        = code_filter,
  markdown   = markdown_filter,
  plain      = plain_filter,
  preserve   = preserve_filter
}

function filter_for(state)
  state:close_tags()
  local func
  if filters[state.curr_phrase.filter] then
    func = filters[state.curr_phrase.filter]
  else
    do_error(state.curr_phrase.pos, "No such filter \"%s\"", state.curr_phrase.filter)
  end
  return func(state)
end
