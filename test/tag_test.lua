require "luarocks.require"
require "lunit"
require "haml"
require "std"
module("tag-test", lunit.testcase, package.seeall)

function test_bare_tag()
  local output = haml.render("%li 1")
  assert_equal("<li>1</li>", output)
end

function test_id()
  local output = haml.render("%li#myid 1")
  assert_equal("<li id='myid'>1</li>", output)
end

function test_ruby_style_attributes()
  local output = haml.render('%li{:hello => "world"} 1')
  assert_equal("<li hello='world'>1</li>", output)
end

function test_lua_style_attributes()
  local output = haml.render('%li{hello = "world"} 1')
  assert_equal("<li hello='world'>1</li>", output)
end

function test_portable_style_attributes()
  local output = haml.render('%li(hello = "world") 1')
  assert_equal("<li hello='world'>1</li>", output)
end