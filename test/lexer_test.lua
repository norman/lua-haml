require("luarocks.require")
require("lunit")
require("haml")
module("haml-lexer-test", lunit.testcase, package.seeall)

function test_css_name_chars()
  local line = "a-CSS_name1"
  local match = lpeg.match(lpeg.C(haml.lexer.css_name_chars^1), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_css_id()
  local line = "#a-CSS_id"
  local match = lpeg.match(lpeg.C(haml.lexer.css_id), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_html_tag()
  local line = "h2"
  local match = lpeg.match(lpeg.C(haml.lexer.html_tag), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_operator()
  local line = "&-\\~=/:"
  local match = lpeg.match(lpeg.C(haml.lexer.operator^1), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_haml_tag()
  local line = "%h1#id.class"
  local match = lpeg.match(lpeg.C(haml.lexer.haml_tag), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_ruby_style_haml_attributes()
  local line = "{:key => 'value'}"
  local match = lpeg.match(lpeg.C(haml.lexer.attributes), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_portable_style_haml_attributes()
  local line = "(key = 'value')"
  local match = lpeg.match(lpeg.C(haml.lexer.attributes), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_haml_line()
  local line = "%p#my_id.my_class('key' = 'value')= my_function()"
  local match = lpeg.match(lpeg.C(haml.lexer.haml_line), line)
  assert_not_nil(match)
  assert_equal(line, match)
end

function test_single_token_lines()
  -- Haml, token, expectation
  local expectations = {
    {"aaa", "subject", "aaa"},
    {"%p", "html_tag", "p"},
    {"!!!", "operator", "!!!"},
    {"#id", "css_id", "#id"},
    {".class1.class2", "css_classes", ".class1.class2"}
  }
  for _, t in pairs(expectations) do
    result = haml.lexer.tokenize_line(t[1])
    assert_not_nil(result, 'Testing "' .. t[1] .. '"')
    assert_equal(result[t[2]], t[3])
  end
end