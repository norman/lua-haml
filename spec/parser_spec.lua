require "haml"

local tokenize = haml.parser.tokenize

describe("The LuaHaml parser", function()

  describe("When handling Haml tags", function()
    it("should parse a bare css class as a div of that class ('.class1')", function()
      local output = tokenize(".class1")
      assert_equal(output[1].tag, "div")
      assert_equal(output[1].css.class, "'class1'")
    end)

    it("should parse a bare css id as a div with that id ('#id1')", function()
      local output = tokenize("#id1")
      assert_equal(output[1].tag, "div")
      assert_equal(output[1].css.id, "'id1'")
    end)

    it("should return all css classes ('.class1.class2')", function()
      local output = tokenize(".class1.class2")
      assert_equal(output[1].css.class, "'class1 class2'")
    end)

    it("should return only the last css id ('#id1#id2')", function()
      local output = tokenize("#id1#id2")
      assert_equal(output[1].css.id, "'id2'")
    end)

    it("should return both css classes and the id", function()
      local output = tokenize("#id1.class1")
      assert_equal(output[1].css.id, "'id1'")
      assert_equal(output[1].css.class, "'class1'")
    end)

    it("should parse lines beginning with % as (X)HTML tags", function()
      local valid_tags = {"h2", "a", "div", "a:a", "a-a", "1"}
      for _, tag in pairs(valid_tags) do
        local output = tokenize("%" .. tag)
        assert_equal(output[1].tag, tag)
      end
    end)

    it("should parse '<' following a tag as an inner whitespace modifier", function()
      local output = tokenize("%p<")
      assert_not_equal(output[1].inner_whitespace_modifier, nil)
    end)

    it("should parse '>' following a tag as an outer whitespace modifier", function()
      local output = tokenize("%p>")
      assert_not_equal(output[1].outer_whitespace_modifier, nil)
    end)

    it("should parse '/' following a tag as a self-closing modifier", function()
      local output = tokenize("%img/")
      assert_not_equal(output[1].self_closing_modifier, nil)
    end)

    it("should parse '=' following a tag as a script operator", function()
      local output = tokenize("%p=a")
      assert_equal(output[1].operator, "script")
    end)

    it("should parse content after a script operator as inline code", function()
      local output = tokenize("%p=a")
      assert_equal(output[1].inline_code, "a")
    end)

  end)

  describe("When handling Haml tags with portable-style attributes (a='b')", function()

    it("should return a table of key-value pairs", function()
      local output = tokenize("%p(a='b')")
      assert_equal(output[1].attributes[1].a, "'b'")
    end)

    it("should parse attributes with newlines", function()
      local output = tokenize("%p(a='b'\n   c='d')")
      assert_equal(output[1].attributes[1].c, "'d'")
    end)

    it("should parse attributes with variables", function()
      local output = tokenize("%p(a=b)")
      -- notice that the return value is not wrapped in quotes
      assert_equal(output[1].attributes[1].a, "b")
    end)

    it("should parse attributes keys with :, - and _", function()
      local output = tokenize("%p(a-:_a='b')")
      assert_equal(output[1].attributes[1]["a-:_a"], "'b'")
    end)

    it("should parse attribute values with quoted parens", function()
      local output = tokenize("%p(a='b)')")
      assert_equal(output[1].attributes[1].a, "'b)'")
    end)

    -- it("should not parse attributes separated by spaces", function()
    --   expect(tokenize, "%p(a = 'b')").should_error()
    -- end)

    -- it("should not parse attributes separated by commas", function()
    --   expect(tokenize, "%p(a='b', c='d')").should_error()
    -- end)

    -- it("should not parse quoted attribute keys", function()
    --   expect(tokenize, "%p('a' = 'b')").should_error()
    -- end)

  end)

  describe("When handling silent script", function()
    it("should parse '- ' as the start of script", function()
      local output = tokenize("- a")
      assert_equal(output[1].operator, "silent_script")
      assert_equal(output[1].code, "a")
    end)
  end)

  describe("When handling script", function()
    it("should parse '= ' as the start of script", function()
      local output = tokenize("= a")
      assert_equal(output[1].operator, "script")
      assert_equal(output[1].code, "a")
    end)
  end)

  describe("When handling silent comments", function()

    it("Should parse '-#' as the start of a silent comment", function()
      local output = tokenize("-# a")
      assert_equal(output[1].operator, "silent_comment")
      assert_equal(output[1].comment, "a")
    end)

    it("Should parse '--' as the start of a silent comment", function()
      local output = tokenize("-- a")
      assert_equal(output[1].operator, "silent_comment")
      assert_equal(output[1].comment, "a")
    end)

  end)

  describe("When handling header instructions('!!!')", function()

    it("should parse '!!! XML' as an XML prolog", function()
      local output = tokenize("!!! XML")
      assert_equal(output[1].doctype, nil)
      assert_equal(output[1].operator, "header")
      assert_equal(output[1].prolog, "XML")
      assert_equal(output[1].version, nil)
    end)

    it("should parse '!!! 1.1' as XHTML 1.1 doctype", function()
      local output = tokenize("!!! 1.1")
      assert_equal(output[1].doctype, nil)
      assert_equal(output[1].operator, "header")
      assert_equal(output[1].prolog, nil)
      assert_equal(output[1].version, "1.1")
    end)

    it("should parse '!!! strict' as an 'XHTML Strict 1.0' doctype", function()
      local output = tokenize("!!! strict")
      assert_equal(output[1].operator, "header")
      assert_equal(output[1].doctype, "STRICT")
      assert_equal(output[1].prolog, nil)
      assert_equal(output[1].version, nil)
    end)

    it("should parse '!!!' as an unspecified doctype", function()
      local output = tokenize("!!!")
      assert_equal(output[1].doctype, nil)
      assert_equal(output[1].operator, "header")
      assert_equal(output[1].prolog, nil)
      assert_equal(output[1].version, nil)
    end)

  end)

  describe("When handling filtered blocks", function()
    it("should return filtered content with 0-level indentation", function()
      local output = tokenize(":javascript\n  alert('hello world!');")
      assert_not_nil(output[1].filter)
      assert_not_nil(output[1].content)
      assert_equal("javascript", output[1].filter)
      assert_equal("  alert('hello world!');", output[1].content)
    end)

    it("should return filtered content with 2-level indentation", function()
      local output = tokenize("    :javascript\n      alert('hello world!');\n    %h2 Hello")
      assert_not_nil(output[1].filter)
      assert_not_nil(output[1].content)
      assert_equal("javascript", output[1].filter)
      assert_equal("      alert('hello world!');", output[1].content)
    end)

  end)

end)
