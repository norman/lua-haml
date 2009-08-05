--- Haml Lexer
module("haml.lexer", package.seeall)

-- Lua Haml's lexer uses the Lua Parsing Expression Grammar. For more
-- information see: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
require "lpeg"
require "haml.ext"

local P, S, R, C, Cg, Ct, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct, lpeg.V

local leading_whitespace  = Cg(S" "^0 / string.len, "space")
local inline_whitespace   = S" \t"
local eol                 = P"\n" + P"\r\n" + P"\r"
local empty_line          = Cg(P(""), "empty_line")
local unparsed            = Cg((1 - eol)^1, "unparsed")
local default_tag         = "div"
local singlequoted_string = P("'" * ((1 - S "'\r\n\f\\") + (P '\\' * 1))^0 * "'")
local doublequoted_string = P('"' * ((1 - S '"\r\n\f\\') + (P '\\' * 1))^0 * '"')
local quoted_string       = singlequoted_string + doublequoted_string


local operator_symbols = {
  tag            = "%",
  script         = "=",
  escape         = "\\",
  header         = "!!!",
  markup_comment = "/"
}

-- This uilds a table of capture patterns that return the operator name rather
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
  version            = Cg(P"1.1" + P"1.0", "version"),
  doctype            = Cg(R("az", "AZ")^1 / string.upper, "doctype"),
  prolog_and_charset = (V("prolog") * (inline_whitespace^1 * V("charset")^1)^0),
  doctype_or_version = V("doctype") + V("version"),
  header             = operators.header * (inline_whitespace * (V("prolog_and_charset") + V("doctype_or_version")))^0
}

-- Modifiers that follow Haml markup tags
local modifiers = {
  self_closing     = Cg(P"/", "self_closing_modifier"),
  inner_whitespace = Cg(P"<", "inner_whitespace_modifier"),
  outer_whitespace = Cg(P">", "outer_whitespace_modifier")
}

-- Markup attributes
function parse_attributes(a)
  local name   = C((R("az", "AZ", "09") + S"-:_")^1 )
  local value  = C(quoted_string + name)
  local sep    = (P" " + eol)^1
  local assign = P'='
  local pair   = lpeg.Cg(name * assign * value) * sep^-1
  local list   = S("(") * lpeg.Cf(lpeg.Ct("") * pair^0, rawset) * S(")")
  return lpeg.match(list, a) or error(string.format("Could not parse attributes '%s'", a))
end
local html_style_attributes = P{"(" * ((quoted_string + (P(1) - S"()")) + V(1))^0 * ")"}
local any_attributes   = html_style_attributes / parse_attributes
local attributes       = Cg(Ct((any_attributes * any_attributes^0)) / flatten, "attributes")


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
    table.insert(classes, t.class) end
  end
  return {class = table.concat(classes, " "), id = table.remove(ids)}
end

local haml_tag = P{
  "haml_tag";
  alnum        = R("az", "AZ", "09"),
  css_name     = S"-_" + V("alnum")^1,
  class        = P"." * Ct(Cg(V("css_name")^1, "class")),
  id           = P"#" * Ct(Cg(V("css_name")^1, "id")),
  css          = (V("class") + V("id")) * V("css")^0,
  html_name    = R("az", "AZ", "09") + S":-_",
  explicit_tag = "%" * Cg(V("html_name")^1, "tag"),
  implict_tag  = Cg(-S(1) * #V("css") / function() return default_tag end, "tag"),
  haml_tag     = (V("explicit_tag") + V("implict_tag")) * Cg(Ct(V("css")) / flatten_ids_and_classes, "css")^0
}
local tag_modifiers = (modifiers.self_closing + (modifiers.inner_whitespace + modifiers.outer_whitespace))


-- Core Haml grammar
local haml_element = leading_whitespace * (
  -- Haml markup
  (haml_tag * attributes^0 * tag_modifiers^0 * operators.script^0 * unparsed^0) +
  -- doctype or prolog
  (header) +
  -- Markup comment
  (operators.markup_comment * unparsed^0) +
  -- Escaped
  (operators.escape * unparsed^0) +
  -- Unparsed content
  unparsed +
  -- Last resort
  empty_line
)
local grammar = Ct(Ct(haml_element) * (eol * Ct(haml_element))^0)

function tokenize(input)
  return lpeg.match(grammar, input)
end