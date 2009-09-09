require "haml"

local locals = {
  value = "value",
  hello = "hello",
  world = "world",
  first = "a",
  last  = "z"
}

local passing_expectations = {
  { "headers",
      {"!!!", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'},
      {"!!! XML", "<?xml version='1.0' encoding='utf-8' ?>"},
      {"!!! 1.1", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'},
      {"!!! frameset", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'}
  },
  { "basic Haml tags and CSS",
      {"%p", "<p></p>"},
      {"#id1", "<div id='id1'></div>"},
      {".class1", "<div class='class1'></div>"},
      {"%p.class1", "<p class='class1'></p>"},
      {"%p.class1.class2", "<p class='class1 class2'></p>"},
      {"%p#id1", "<p id='id1'></p>"},
      {"%p#id1#id2", "<p id='id2'></p>"},
      {"%p.class1#id1", "<p class='class1' id='id1'></p>"},
      {"%p#id1.class1", "<p class='class1' id='id1'></p>"}
  },
  { "tags with unusual HTML characters",
      {"%ns:tag", "<ns:tag></ns:tag>"},
      {"%snake_case", "<snake_case></snake_case>"},
      {"%dashed-tag", "<dashed-tag></dashed-tag>"},
      {"%camelCase", "<camelCase></camelCase>"},
      {"%PascalCase", "<PascalCase></PascalCase>"}
  },
  { "tags with unusual CSS identifiers",
      {".123", "<div class='123'></div>"},
      {".__", "<div class='__'></div>"},
      {".--", "<div class='--'></div>"}
  },
  { "tags with inline content",
      {"%p hello", "<p>hello</p>"},
      {"%p.class1 hello", "<p class='class1'>hello</p>"}
  },
  { "tags with nested content",
      {"%p\n  hello", "<p>\n  hello\n</p>"}
  },
  { "tags with portable-style attributes",
      {"%p(a='b')", "<p a='b'></p>"},
      {"%p(class='class1')", "<p class='class1'></p>"},
      {"%p.class2(class='class1')", "<p class='class1 class2'></p>"},
      {"%p#id(id='1')", "<p id='id_1'></p>"},
      {".hello(class=world)", "<div class='hello world'></div>"},
      {".b(class=last)", "<div class='b z'></div>"},
      {".b(class=first)", "<div class='a b'></div>"}
  },
  { "inline comments",
      {"-# hello\n%p", "<p></p>"},
      {"-- hello\n%p", "<p></p>"},
  },
  { "script",
      {"- a = 'b'\n%p=a", "<p>b</p>"}
  },

  { "filters",
      {":preserve\n  hello\n\n%p", "  hello&#x0A;\n<p></p>"},
      {":plain\n  hello\n\n%p", "  hello\n\n<p></p>"},
      {":javascript\n  a();\n%p", "<script type='text/javascript'>\n  // <![CDATA[\na();\n  // ]]>\n</script>\n<p></p>"}
  }

}


describe("The LuaHaml Renderer", function()
  for _, v in ipairs(passing_expectations) do
    describe("when handling " .. v[1], function()
      local i = 1
      while i < #v do
        i = i + 1
        it(string.format("should render '%s' as '%s'", string.gsub(v[i][1], "\n", "\\n"),
            string.gsub(v[i][2], "\n", "\\n")), function()
            assert_equal(haml.render(v[i][1], {}, locals), v[i][2])
        end)
      end
    end)
  end
end)
