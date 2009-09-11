require "haml"

local locals = {
  value = "value",
  hello = "world",
  first = "a",
  last  = "z"
}

local tests = {}

tests.headers = {
  {"!!! XML", "<?xml version='1.0' encoding='utf-8' ?>"},
  {"!!!", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'},
  {"!!! 1.1", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'},
  {"!!! frameset", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'}
}

tests["basic Haml tags and CSS"] = {
  {"%p", "<p></p>"},
  {"#id1", "<div id='id1'></div>"},
  {".class1", "<div class='class1'></div>"},
  {"%p.class1", "<p class='class1'></p>"},
  {"%p.class1.class2", "<p class='class1 class2'></p>"},
  {"%p#id1", "<p id='id1'></p>"},
  {"%p#id1#id2", "<p id='id2'></p>"},
  {"%p.class1#id1", "<p class='class1' id='id1'></p>"},
  {"%p#id1.class1", "<p class='class1' id='id1'></p>"}
}

tests["tags with unusual HTML characters"] = {
  {"%ns:tag", "<ns:tag></ns:tag>"},
  {"%snake_case", "<snake_case></snake_case>"},
  {"%dashed-tag", "<dashed-tag></dashed-tag>"},
  {"%camelCase", "<camelCase></camelCase>"},
  {"%PascalCase", "<PascalCase></PascalCase>"}
}

tests["tags with unusual CSS identifiers"] = {
  {".123", "<div class='123'></div>"},
  {".__", "<div class='__'></div>"},
  {".--", "<div class='--'></div>"}
}

tests["tags with inline content"] = {
  {"%p hello", "<p>hello</p>"},
  {"%p.class1 hello", "<p class='class1'>hello</p>"}
}

tests["tags with nested content"] = {
  {"%p\n  hello", "<p>\n  hello\n</p>"}
}

tests["tags with portable-style attributes"] = {
  {"%p(a='b')", "<p a='b'></p>"},
  {"%p(class='class1')", "<p class='class1'></p>"},
  {"%p.class2(class='class1')", "<p class='class1 class2'></p>"},
  {"%p#id(id='1')", "<p id='id_1'></p>"},
  {".hello(class=hello)", "<div class='hello world'></div>"},
  {".b(class=last)", "<div class='b z'></div>"},
  {".b(class=first)", "<div class='a b'></div>"}
}

tests["inline comments"] = {
  {"-# hello\n%p", "<p></p>"},
  {"-- hello\n%p", "<p></p>"},
}

tests.script = {
  {"- a = 'b'\n%p=a", "<p>b</p>"}
}

tests.filters = {
  {":preserve\n  hello\n\n%p", "hello&#x000A;\n<p></p>"},
  {":plain\n  hello\n\n%p", "hello\n\n<p></p>"},
  {":javascript\n  a();\n%p", "<script type='text/javascript'>\n  //<![CDATA[\n    a();\n  //]]>\n</script>\n<p></p>"}
}

tests.interpolation = {
  {":plain\n  #{hello} interpolated: #{hello}", "world interpolated: world"}
}


describe("The LuaHaml Renderer", function()
  for context, set in pairs(tests) do
    describe("When handling " .. context, function()
      for _, t in ipairs(set) do
        test(string.format("should render '%s' as '%s'", string.gsub(t[1], "\n", "\\n"),
            string.gsub(t[2], "\n", "\\n")), function()
            assert_equal(haml.render(t[1], {}, locals), t[2])
        end)
      end
    end)
  end
end)
