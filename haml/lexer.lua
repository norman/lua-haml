module("haml.lexer", package.seeall)
require "lpeg"
local P, S, R, C, Cg, Ct = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct

lpeg.locale(lpeg)

operator = Cg(P'!!!' + S"/&~-\\:=", "operator")
css_name_chars = S'-_' + lpeg.alnum
css_id = Cg(P'#' * css_name_chars^1, "css_id")
css_classes = Cg(P'.' * (css_name_chars + P'.')^1, "css_classes")
html_tag = Cg(lpeg.alpha * lpeg.alnum^0, "html_tag")
attributes = Cg(P{ "(" * (1 - S"()")^0 * ")" } + P{ "{" * (1 - S"{}")^0 * "}" }, "attributes")
haml_tag = ((P"%" * html_tag * css_id^0 * css_classes^0) + (css_id^1 * css_classes^0) + (css_classes^1))
subject = Cg(P(1)^1, "subject")
haml_line = (Cg(lpeg.space^0, "leading_whitespace") * ((operator * lpeg.space^0) + (haml_tag * attributes^0)))^0 * operator^0 * subject^0

function tokenize_line(line)
  return lpeg.match(Ct(haml_line), line)
end