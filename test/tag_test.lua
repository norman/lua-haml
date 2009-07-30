require "luarocks.require"
require "lunit"
require "haml"
require "std"
module("tag-test", lunit.testcase, package.seeall)

function test_bare_tag()
  local output = haml.render("%li 1")
  assert_equal("<li>1</li>", output)
end

function test_tag_with_id()
  local output = haml.render("%li#myid 1")
  assert_equal("<li id='myid'>1</li>", output)
end