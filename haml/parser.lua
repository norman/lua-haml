--- Haml parser
module("haml.parser", package.seeall)
require "lpeg"

-- import lpeg feature functions into current module
for k, v in pairs(lpeg) do
  if string.len(k) <= 3 then
    _M[k] = v
  end
end

local alnum               = R("az", "AZ", "09")
local leading_whitespace  = Cg(S" \t"^0, "space")
local inline_whitespace   = S" \t"
local eol                 = P"\n" + "\r\n" + "\r"
local empty_line          = Cg(P"", "empty_line")
local unparsed            = Cg((1 - eol)^1, "unparsed")
local default_tag         = "div"
local singlequoted_string = P("'" * ((1 - S "'\r\n\f\\") + (P'\\' * 1))^0 * "'")
local doublequoted_string = P('"' * ((1 - S '"\r\n\f\\') + (P'\\' * 1))^0 * '"')
local quoted_string       = singlequoted_string + doublequoted_string

local operator_symbols = {
  conditional_comment = P"/[",
  escape              = P"\\",
  filter              = P":",
  header              = P"!!!",
  markup_comment      = P"/",
  script              = P"=",
  silent_comment      = P"-#" + "--",
  silent_script       = P"-",
  tag                 = P"%",
  escaped_script      = P"&=",
  unescaped_script    = P"!="
}

-- This builds a table of capture patterns that return the operator name rather
-- than the literal operator string.
local operators = {}
for k, v in pairs(operator_symbols) do
  operators[k] = Cg(v / function() return k end, "operator")
end

local script_operator = P(
  operators.silent_script +
  operators.script +
  operators.escaped_script +
  operators.unescaped_script
)

-- (X)HTML Doctype or XML prolog
local  prolog             = Cg(P"XML" + P"xml" / string.upper, "prolog")
local  charset            = Cg((R("az", "AZ", "09") + S"-")^1, "charset")
local  version            = Cg(P"1.1" + "1.0", "version")
local  doctype            = Cg((R("az", "AZ")^1 + "5") / string.upper, "doctype")
local  prolog_and_charset = (prolog * (inline_whitespace^1 * charset^1)^0)
local  doctype_or_version = doctype + version
local header = operators.header * (inline_whitespace * (prolog_and_charset + doctype_or_version))^0

-- Modifiers that follow Haml markup tags
local modifiers = {
  self_closing     = Cg(P"/", "self_closing_modifier"),
  inner_whitespace = Cg(P"<", "inner_whitespace_modifier"),
  outer_whitespace = Cg(P">", "outer_whitespace_modifier")
}

-- Markup attributes
function parse_html_style_attributes(a)
  local name   = C((alnum + S".-:_")^1 )
  local value  = C(quoted_string + name)
  local sep    = (P" " + eol)^1
  local assign = P'='
  local pair   = lpeg.Cg(name * assign * value) * sep^-1
  local list   = S("(") * lpeg.Cf(lpeg.Ct("") * pair^0, rawset) * S(")")
  return lpeg.match(list, a) or error(string.format("Could not parse attributes '%s'", a))
end

function parse_ruby_style_attributes(a)
  local name   = (alnum + P"_")^1
  local key    = (P":" * C(name)) + (P":"^0 * C(quoted_string)) / function(a) local a = a:gsub('[\'"]', ""); return a end
  local value  = C(quoted_string + name)
  local sep    = inline_whitespace^0 * P"," * (P" " + eol)^0
  local assign = P'=>'
  local pair   = lpeg.Cg(key * inline_whitespace^0 * assign * inline_whitespace^0 * value) * sep^-1
  local list   = S("{") * inline_whitespace^0 * lpeg.Cf(lpeg.Ct("") * pair^0, rawset) * inline_whitespace^0 * S("}")
  return lpeg.match(list, a) or error(string.format("Could not parse attributes '%s'", a))
end

local html_style_attributes = P{"(" * ((quoted_string + (P(1) - S"()")) + V(1))^0 * ")"} / parse_html_style_attributes
local ruby_style_attributes = P{"{" * ((quoted_string + (P(1) - S"{}")) + V(1))^0 * "}"} / parse_ruby_style_attributes
local any_attributes   = html_style_attributes + ruby_style_attributes
local attributes       = Cg(Ct((any_attributes * any_attributes^0)) / ext.flatten, "attributes")

-- Haml HTML elements
-- Character sequences for CSS and XML/HTML elements. Note that many invalid
-- names are allowed because of Haml's flexibility.
local function flatten_ids_and_classes(t)
  classes = {}
  ids = {}
  for _, t in pairs(t) do
    if t.id then
      table.insert(ids, t.id)
    else
      table.insert(classes, t.class)
    end
  end
  local out = {}
  if next(ids) then out.id = string.format("'%s'", table.remove(ids)) end
  if next(classes) then out.class = string.format("'%s'", table.concat(classes, " ")) end
  return out
end

local nested_content = Cg((Cmt(Cb("space"), function(subject, index, spaces)
  local buffer = {}
  local num_spaces = tostring(spaces or ""):len()
  local start = subject:sub(index)
  for _, line in ipairs(ext.psplit(start, "\n")) do
    if lpeg.match(P" "^(num_spaces + 1), line) then
      table.insert(buffer, line)
    elseif line == "" then
      table.insert(buffer, line)
    else
      break
    end
  end
  local match = table.concat(buffer, "\n")
  return index + match:len(), match
end)), "content")

local  css_name     = S"-_" + alnum^1
local  class        = P"." * Ct(Cg(css_name^1, "class"))
local  id           = P"#" * Ct(Cg(css_name^1, "id"))
local  css          = P{(class + id) * V(1)^0}
local  html_name    = R("az", "AZ", "09") + S":-_"
local  explicit_tag = "%" * Cg(html_name^1, "tag")
local  implict_tag  = Cg(-S(1) * #css / function() return default_tag end, "tag")
local  haml_tag     = (explicit_tag + implict_tag) * Cg(Ct(css) / flatten_ids_and_classes, "css")^0
local inline_code = operators.script * inline_whitespace^0 * Cg(unparsed^0 / function(a) return a:gsub("\\", "\\\\") end, "inline_code")
local inline_content = inline_whitespace^0 * Cg(unparsed, "inline_content")
local tag_modifiers = (modifiers.self_closing + (modifiers.inner_whitespace + modifiers.outer_whitespace))

local format_chunk = (function()
  local line = 0
  return function(chunk)
    line = line + 1
    return {line, ext.strip(chunk)}
  end
end)()
local chunk_capture = #Cg((P(1) - eol)^1 / format_chunk, "chunk")

-- Core Haml grammar
local haml_element = chunk_capture * leading_whitespace * (
  -- Haml markup
  (haml_tag * attributes^0 * tag_modifiers^0 * (inline_code + inline_content)^0) +
  -- Doctype or prolog
  (header) +
  -- Silent comment
  (operators.silent_comment) * inline_whitespace^0 * Cg(unparsed^0, "comment") * nested_content +
  -- Script
  (script_operator) * inline_whitespace^1 * Cg(unparsed^0, "code") +
  -- IE conditional comments
  (operators.conditional_comment * Cg((P(1) - "]")^1, "condition")) * "]" +
  -- Markup comment
  (operators.markup_comment * inline_whitespace^0 * unparsed^0 * eol^0 * nested_content) +
  -- Filtered block
  (operators.filter * Cg((P(1) - eol)^0, "filter") * eol * nested_content) +
  -- Escaped
  (operators.escape * unparsed^0) +
  -- Unparsed content
  unparsed +
  -- Last resort
  empty_line
)
local grammar = Ct(Ct(haml_element) * (eol^1 * Ct(haml_element))^0)

function tokenize(input)
  return lpeg.match(grammar, input)
end
