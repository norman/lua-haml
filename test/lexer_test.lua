require "luarocks.require"
require "lunit"
require "haml"
require "std"
module("haml-lexer-test", lunit.testcase, package.seeall)

local tokenize = haml.lexer.tokenize

function test_doctype()
  local output = tokenize("!!! XML")
  assert_not_nil(output[1]["doctype_operator"])
  assert_equal("XML", output[1]["unparsed"])
end

function test_div_with_id_and_classes()
  local output = tokenize("#my_div.my_classes=")
  assert_equal("my_div", output[1]["css_id"]) 
  assert_equal("my_classes", output[1]["css_classes"])
  assert_not_nil(output[1]["script_operator"])
end

function test_tag_with_whitespace_modifiers()
  local output = tokenize([=[
    %p> hello
    %p< world
  ]=])
  assert_not_nil(output[1]["outer_whitespace_modifier"])
  assert_not_nil(output[2]["inner_whitespace_modifier"])
end

function test_self_closing_tag()
  local output = tokenize("%br/")
  assert_not_nil(output[1]["self_closing_modifier"])
end

function test_basic_attributes()
  local output = tokenize([=[
    %html{lang = en}
      %body(style="color: green")
  ]=])
  assert_equal("{lang = en}", output[1]["attributes"][1])
  assert_equal('(style="color: green")', output[2]["attributes"][1])
end

function test_multiple_attributes()
  local output = tokenize([=[
    %h1(a=b){c=d}
    %h2{e=f}(g=h)
    %h3(1=2){3=4}(5=6)
  ]=])
  assert_equal('(a=b)', output[1]["attributes"][1])
  assert_equal('{c=d}', output[1]["attributes"][2])
  assert_equal('{e=f}', output[2]["attributes"][1])
  assert_equal('(g=h)', output[2]["attributes"][2])
  assert_equal('(5=6)', output[3]["attributes"][3])  
end

function test_multiline_attributes()
  local output = tokenize([=[
    %html{ lang = 'en',
      whatever = 'ok' }
  ]=])
  assert_equal("{ lang = 'en',\n      whatever = 'ok' }", output[1]["attributes"][1])
end
