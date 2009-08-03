require "luarocks.require"
require "lunit"
require "haml"
require "std"
module("haml-lexer-test", lunit.testcase, package.seeall)

local tokenize = haml.lexer.tokenize

function test_header()
  local output = tokenize("!!! XML")
  assert_not_nil(output[1]["operator"])
  assert_equal("XML", output[1]["unparsed"])
end

function test_div_with_id_and_classes()
  local output = tokenize("#my_div.my_classes=")
  assert_equal("my_div", output[1]["css_id"]) 
  assert_equal("my_classes", output[1]["css_classes"])
  assert_not_nil(output[1]["operator"])
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
    %html{lang=en}
      %body(style="color: green")
  ]=])
  assert_equal("en", output[1]["attributes"]["lang"])
  assert_equal("color: green", output[2]["attributes"]["style"])
end

function test_multiple_attributes()
  local output = tokenize([=[
    %h1(a=b){c=d}
    %h2{e=f}(g=h)
    %h3(a=b){c=d}(e=f)
  ]=])
  assert_equal('b', output[1]["attributes"]["a"])
  assert_equal('d', output[1]["attributes"]["c"])
  assert_equal('f', output[2]["attributes"]["e"])
  assert_equal('h', output[2]["attributes"]["g"])
  assert_equal('f', output[3]["attributes"]["e"])
end

function test_multiline_attributes()
  local output = tokenize([=[
    %html{ lang = 'en',
      whatever = 'ok' }
  ]=])
  assert_equal("en", output[1]["attributes"]["lang"])
  assert_equal("ok", output[1]["attributes"]["whatever"])
end


function test_attributes_with_commas()
  local output = tokenize("%p{'a,b' => 'c, d'}")
  assert_equal('c, d', output[1]["attributes"]["a,b"])
end

function test_attributes_with_separators()
  local output = tokenize("%p{'a=>b' => 'c => d'}")
  assert_equal('c => d', output[1]["attributes"]["a=>b"])
end

function test_attributes_with_braces()
  local output = tokenize("%p('a' = ')b')")
  assert_equal('}b', output[1]["attributes"]["a"])
end
