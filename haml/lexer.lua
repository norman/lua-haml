--- Haml Lexer
module("haml.lexer", package.seeall)
require "lpeg"

local P, S, R, C, Cg, Ct, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct, lpeg.V

local script_operator = Cg(P"=", "script_operator")
local escape_operator = Cg(P"\\", "escape_operator")
local doctype_operator = Cg(P"!!!", "doctype_operator")
local tag_indicator = P"%"
local self_closing_modifier = Cg(P"/", "self_closing_modifier")
local inner_whitespace_modifier = Cg(P"<", "inner_whitespace_modifier")
local outer_whitespace_modifier = Cg(P">", "outer_whitespace_modifier")
local leading_whitespace = Cg(S" "^0 / string.len, "space")
local inline_whitespace = S" \t"
local eol = S"\n" + S"\r\n" + S"\r"
local markup_tag = Cg(R("az", "AZ") * (R("az", "AZ", "09") + S("-:_"))^0, "markup_tag")
-- note that this is not valid CSS, but Haml allows it
local css_ident = (P"_" + R("az", "AZ", "09"))^1 * (S"-_" + R("az", "AZ", "09"))^0
local css_id = P"#" * Cg(css_ident^1, "css_id")
local css_classes = P"." * Cg((css_ident + P".")^1, "css_classes")
local poratable_style_attributes = P{"(" * ((1 - S"()") + V(1))^0 * ")"}
local lua_style_attributes = P{"{" * ((1 - S"{}") + V(1))^0 * "}"}
local any_attributes = Cg(poratable_style_attributes + lua_style_attributes)
local attributes = Cg(Ct(any_attributes * any_attributes^0), "attributes")

-- Haml HTML elements
local css_id_and_classes = ((css_id^1 * css_classes^0) + (css_classes^1 * css_id^0))
local explicit_tag = (tag_indicator * markup_tag * css_id_and_classes^0)
local tag_modifiers = (
  self_closing_modifier + 
  (inner_whitespace_modifier + outer_whitespace_modifier)
)
local haml_tag = (explicit_tag + css_id_and_classes)
local unparsed = Cg((1 - eol)^1, "unparsed")
local haml_element = leading_whitespace * (
  -- doctype or prolog
  (doctype_operator * (inline_whitespace^1 * unparsed)^0) +
  -- HAML HTML
  (haml_tag * attributes^0 * tag_modifiers^-1 * script_operator^0 * unparsed^0) +
  -- Escaped
  (escape_operator * unparsed^0) +
  -- Last resort: unparsed content
  unparsed
)
local chunk = Ct(haml_element)
local grammar = Ct(chunk * (eol * chunk)^0)

function tokenize(input)
  return lpeg.match(grammar, input)
end