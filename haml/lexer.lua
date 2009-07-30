--- Haml Lexer
module("haml.lexer", package.seeall)

-- Lua Haml's lexer uses the Lua Parsing Expression Grammar. For more
-- information see: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
require "lpeg"

local P, S, R, C, Cg, Ct, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct, lpeg.V

local leading_whitespace = Cg(S" "^0 / string.len, "space")
local inline_whitespace  = S" \t"
local eol                = P"\n" + P"\r\n" + P"\r"
local empty_line         = Cg(P(""), "empty_line")
local unparsed           = Cg((1 - eol)^1, "unparsed")

local operator_symbols = {
  tag            = "%",
  script         = "=",
  escape         = "\\",
  doctype        = "!!!",
  markup_comment = "/"
}

-- This uilds a table of capture patterns that return the operator name rather
-- than the literal operator string.
local operators = {}
for k, v in pairs(operator_symbols) do
  operators[k] = Cg(P(v) / function() return k end, "operator")
end

-- Modifiers that follow Haml markup tags
local modifiers = {
  self_closing     = Cg(P"/", "self_closing_modifier"),
  inner_whitespace = Cg(P"<", "inner_whitespace_modifier"),
  outer_whitespace = Cg(P">", "outer_whitespace_modifier")
}

-- Character sequences for CSS and XML/HTML elements. Note that many invalid
-- names are allowed because of Haml's flexibility.
local markup_tag  = Cg(R("az", "AZ") * (R("az", "AZ", "09") + S("-:_"))^0, "markup_tag")
local css_ident   = (P"_" + R("az", "AZ", "09"))^1 * (S"-_" + R("az", "AZ", "09"))^0
local css_id      = P"#" * Cg(css_ident^1, "css_id")
local css_classes = P"." * Cg((css_ident + P".")^1, "css_classes")

-- Markup attributes
local function parse_attributes(t)
  if not t then return end
  local function split(str, separator, elements)
    local elem = C(elements^1)
    local p = Ct(elem * (separator * elem)^0)
    return lpeg.match(p, str)
  end

  local function clean_value(str)
    -- @TODO replace these with lpeg, this temporary, end of day code!
    str = string.gsub(str, "^['\"]", "")
    str = string.gsub(str, "['\"]$", "")
    return str
  end

  local function clean_key(str)
    -- @TODO replace these with lpeg, this temporary, end of day code!
    str = string.gsub(str, "^['\"]", "")
    str = string.gsub(str, "['\"]$", "")
    str = string.gsub(str, ":", "")
    return str
  end

  local function clean_str(str)
    str = string.gsub(str, "%s*[{}\(\)]%s*", "")
    str = string.gsub(str, "%s*\n%s*", " ")
    return str
  end

  local bare_element = R("az", "AZ")^1 * (R("az", "AZ", "09") + P"_")^0
  local quoted_element = P{"'" * ((1 - S"'") + V(1))^0 * "'"} + P{'"' * ((1 - S'"') + V(1))^0 * '"'}
  local element = (bare_element + quoted_element)
  local ruby_symbol = P":" * element
  local item_sep = P" "^0 * P"," * P" "^0
  local item_list = (ruby_symbol + element) * P" "^0 * (P"=>" + P"=") * P" "^0 * (element)
  local assignment_sep = P" "^0 * (P"=>" + P"=") * P" "^0
  local assignment_list = (ruby_symbol + element)
  local attributes = {}
  for _, str in pairs(t) do
    local items = split(clean_str(str), item_sep, item_list)
    for _, v in pairs(items) do
      kv = split(v, assignment_sep, assignment_list)
      attributes[clean_key(kv[1])] = clean_value(kv[2])
    end
  end
  return attributes
end

local paren_attributes = P{"(" * ((1 - S"()") + V(1))^0 * ")"}
local brace_attributes = P{"{" * ((1 - S"{}") + V(1))^0 * "}"}
local any_attributes   = Cg(paren_attributes + brace_attributes)
local attributes       = Cg(Ct(any_attributes * any_attributes^0) / parse_attributes, "attributes")

-- Haml HTML elements
local css_id_and_classes = ((css_id^1 * css_classes^0) + (css_classes^1 * css_id^0))
local explicit_tag       = (operators["tag"] * markup_tag * css_id_and_classes^0)
local tag_modifiers      = (modifiers["self_closing"] + (modifiers["inner_whitespace"] + modifiers["outer_whitespace"]))
local haml_tag           = (explicit_tag + css_id_and_classes)

-- Core Haml grammar
local haml_element = leading_whitespace * (
  -- Haml markup
  (haml_tag * attributes^0 * tag_modifiers^-1 * operators["script"]^0 * unparsed^0) +
  -- doctype or prolog
  (operators["doctype"] * (inline_whitespace^1 * unparsed)^0) +
  -- Markup comment
  (operators["markup_comment"] * unparsed^0) +
  -- Escaped
  (operators["escape"] * unparsed^0) +
  -- Unparsed content
  unparsed +
  -- Last resort
  empty_line
)
local grammar = Ct(Ct(haml_element) * (eol * Ct(haml_element))^0)

function tokenize(input)
  return lpeg.match(grammar, input)
end