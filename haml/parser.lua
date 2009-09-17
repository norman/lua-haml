--- Haml parser
module("haml.parser", package.seeall)

-- Lua Haml's parser uses the Lua Parsing Expression Grammar. For more
-- information see: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
require "lpeg"

local P, S, R, C, Cg, Ct, Cb, Cmt, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct, lpeg.Cb, lpeg.Cmt, lpeg.V

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
  conditional_comment = "/[",
  escape              = "\\",
  filter              = ":",
  header              = "!!!",
  markup_comment      = "/",
  script              = "=",
  silent_comment      = P"-#" + "--",
  silent_script       = "-",
  tag                 = "%"
}

-- This builds a table of capture patterns that return the operator name rather
-- than the literal operator string.
local operators = {}
for k, v in pairs(operator_symbols) do
  operators[k] = Cg(P(v) / function() return k end, "operator")
end

-- (X)HTML Doctype or XML prolog
local header =  {
  "header";
  prolog             = Cg(P"XML" + P"xml" / string.upper, "prolog"),
  charset            = Cg((R("az", "AZ", "09") + S"-")^1, "charset"),
  version            = Cg(P"1.1" + "1.0", "version"),
  doctype            = Cg(R("az", "AZ")^1 / string.upper, "doctype"),
  prolog_and_charset = (V"prolog" * (inline_whitespace^1 * V"charset"^1)^0),
  doctype_or_version = V"doctype" + V"version",
  header             = operators.header * (inline_whitespace * (V"prolog_and_charset" + V"doctype_or_version"))^0
}

-- Modifiers that follow Haml markup tags
local modifiers = {
  self_closing     = Cg(P"/", "self_closing_modifier"),
  inner_whitespace = Cg(P"<", "inner_whitespace_modifier"),
  outer_whitespace = Cg(P">", "outer_whitespace_modifier")
}

-- Markup attributes
function parse_html_style_attributes(a)
  local name   = C((R("az", "AZ", "09") + S"-:_")^1 )
  local value  = C(quoted_string + name)
  local sep    = (P" " + eol)^1
  local assign = P'='
  local pair   = lpeg.Cg(name * assign * value) * sep^-1
  local list   = S("(") * lpeg.Cf(lpeg.Ct("") * pair^0, rawset) * S(")")
  return lpeg.match(list, a) or error(string.format("Could not parse attributes '%s'", a))
end

function parse_ruby_style_attributes(a)
  local name   = (R("az", "AZ", "09") + P"_")^1
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

local haml_tag = P{
  "haml_tag";
  alnum        = R("az", "AZ", "09"),
  css_name     = S"-_" + V"alnum"^1,
  class        = P"." * Ct(Cg(V"css_name"^1, "class")),
  id           = P"#" * Ct(Cg(V"css_name"^1, "id")),
  css          = (V"class" + V"id") * V"css"^0,
  html_name    = R("az", "AZ", "09") + S":-_",
  explicit_tag = "%" * Cg(V"html_name"^1, "tag"),
  implict_tag  = Cg(-S(1) * #V"css" / function() return default_tag end, "tag"),
  haml_tag     = (V"explicit_tag" + V"implict_tag") * Cg(Ct(V"css") / flatten_ids_and_classes, "css")^0
}
local inline_code = operators.script * inline_whitespace^0 * Cg(unparsed^0 / function(a) return a:gsub("\\", "\\\\") end, "inline_code")
local inline_content = inline_whitespace^0 * Cg(unparsed, "inline_content")
local tag_modifiers = (modifiers.self_closing + (modifiers.inner_whitespace + modifiers.outer_whitespace))

local format_chunk = (function()
  local line = 0
  return function(chunk)
    line = line + 1
    return string.format("%d: %s", line, ext.strip(chunk))
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
  -- Code
  (operators.silent_script + operators.script) * inline_whitespace^1 * Cg(unparsed^0, "code") +
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
