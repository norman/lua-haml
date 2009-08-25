require 'luarocks.require'
require 'telescope'
require "haml"

local locals = {
  value = "value",
  hello = "hello",
  world = "world",
  first = "a",
  last  = "z"
}

local passing_expectations = {

  -- Headers
  {"!!!", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'},
  {"!!! XML", "<?xml version='1.0' encoding='utf-8' ?>"},
  {"!!! 1.1", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'},
  {"!!! frameset", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'},

  -- Basic Haml tags and CSS
  {"%p", "<p></p>"},
  {"%p.class1", "<p class='class1'></p>"},
  {"%p.class1.class2", "<p class='class1 class2'></p>"},
  {"%p#id1", "<p id='id1'></p>"},
  {"%p#id1#id2", "<p id='id2'></p>"},
  {"%p.class1#id1", "<p class='class1' id='id1'></p>"},
  {"%p#id1.class1", "<p class='class1' id='id1'></p>"},

  -- Base CSS is interpreted as a div
  {"#id1", "<div id='id1'></div>"},
  {".class1", "<div class='class1'></div>"},

  -- Permitted XML/HTML tag characters
  {"%ns:tag", "<ns:tag></ns:tag>"},
  {"%snake_case", "<snake_case></snake_case>"},
  {"%dashed-tag", "<dashed-tag></dashed-tag>"},
  {"%camelCase", "<camelCase></camelCase>"},
  {"%PascalCase", "<PascalCase></PascalCase>"},

  -- Permitted CSS characters; note that Haml allows invalid CSS on purpose
  {".123", "<div class='123'></div>"},
  {".__", "<div class='__'></div>"},
  {".--", "<div class='--'></div>"},

  -- Tags with inline content
  {"%p hello", "<p>hello</p>"},
  {"%p.class1 hello", "<p class='class1'>hello</p>"},

  -- Tags with nested content
  {"%p\n  hello", "<p>\n  hello\n</p>"},

  -- Tags with portable-style attributes
  {"%p(a='b')", "<p a='b'></p>"},
  {"%p(class='class1')", "<p class='class1'></p>"},
  {"%p.class2(class='class1')", "<p class='class1 class2'></p>"},
  {"%p#id(id='1')", "<p id='id_1'></p>"},
  {".hello(class=world)", "<div class='hello world'></div>"},
  {".b(class=last)", "<div class='b z'></div>"},
  {".b(class=first)", "<div class='a b'></div>"},

  -- Inline comments
  {"-# hello\n%p", "<p></p>"},
  {"-- hello\n%p", "<p></p>"},

  -- Script
  {"- a = 'b'\n%p=a", "<p>b</p>"}
}

describe("The LuaHaml Renderer", function()
  describe("When handling Haml tags", function()
    for _, v in ipairs(passing_expectations) do
      it(string.format("should render [%s] as [%s]", string.gsub(v[1], "\n", "\\n"),
          string.gsub(v[2], "\n", "\\n")), function()
        assert_equal(haml.render(v[1], {}, locals), v[2])
      end)
    end
  end)
end)
