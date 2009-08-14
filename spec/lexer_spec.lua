require 'luarocks.require'
require 'luaspec'
require "haml"

local tokenize = haml.lexer.tokenize

describe["The LuaHaml Lexer:"] = function()

  describe["When handling Haml tags"] = function()
    it["should parse a bare css class as a div of that class ('.class1')"] = function()
      local output = tokenize(".class1")
      expect(output[1].tag).should_be("div")
      expect(output[1].css.class).should_be("'class1'")
    end

    it["should parse a bare css id as a div with that id ('#id1')"] = function()
      local output = tokenize("#id1")
      expect(output[1].tag).should_be("div")
      expect(output[1].css.id).should_be("'id1'")
    end

    it["should return all css classes ('.class1.class2')"] = function()
      local output = tokenize(".class1.class2")
      expect(output[1].css.class).should_be("'class1 class2'")
    end

    it["should return only the last css id ('#id1#id2')"] = function()
      local output = tokenize("#id1#id2")
      expect(output[1].css.id).should_be("'id2'")
    end

    it["should return both css classes and the id"] = function()
      local output = tokenize("#id1.class1")
      expect(output[1].css.id).should_be("'id1'")
      expect(output[1].css.class).should_be("'class1'")
    end

    it["should parse lines beginning with % as (X)HTML tags"] = function()
      local valid_tags = {"h2", "a", "div", "a:a", "a-a", "1"}
      for _, tag in pairs(valid_tags) do
        local output = tokenize("%" .. tag)
        expect(output[1].tag).should_be(tag)
      end
    end

    it["should parse '<' following a tag as an inner whitespace modifier"] = function()
      local output = tokenize("%p<")
      expect(output[1].inner_whitespace_modifier).should_not_be(nil)
    end

    it["should parse '>' following a tag as an outer whitespace modifier"] = function()
      local output = tokenize("%p>")
      expect(output[1].outer_whitespace_modifier).should_not_be(nil)
    end

    it["should parse '/' following a tag as a self-closing modifier"] = function()
      local output = tokenize("%img/")
      expect(output[1].self_closing_modifier).should_not_be(nil)
    end

    it["should parse '=' following a tag as a script operator"] = function()
      local output = tokenize("%p=a")
      expect(output[1].operator).should_be("script")
    end

    it["should parse content after a script operator as inline code"] = function()
      local output = tokenize("%p=a")
      expect(output[1].inline_code).should_be("a")
    end

  end

  describe["When handling Haml tags with portable-style attributes (a='b')"] = function()

    it["should return a table of key-value pairs"] = function()
      local output = tokenize("%p(a='b')")
      expect(output[1].attributes[1].a).should_be("'b'")
    end

    it["should parse attributes with newlines"] = function()
      local output = tokenize("%p(a='b'\n   c='d')")
      expect(output[1].attributes[1].c).should_be("'d'")
    end

    it["should parse attributes with variables"] = function()
      local output = tokenize("%p(a=b)")
      -- notice that the return value is not wrapped in quotes
      expect(output[1].attributes[1].a).should_be("b")
    end

    it["should parse attributes keys with :, - and _"] = function()
      local output = tokenize("%p(a-:_a='b')")
      expect(output[1].attributes[1]["a-:_a"]).should_be("'b'")
    end

    it["should parse attribute values with quoted parens"] = function()
      local output = tokenize("%p(a='b)')")
      expect(output[1].attributes[1].a).should_be("'b)'")
    end

    it["should not parse attributes separated by spaces"] = function()
      expect(tokenize, "%p(a = 'b')").should_error()
    end

    it["should not parse attributes separated by commas"] = function()
      expect(tokenize, "%p(a='b', c='d')").should_error()
    end

    it["should not parse quoted attribute keys"] = function()
      expect(tokenize, "%p('a' = 'b')").should_error()
    end

  end

  describe["When handling silent script"] = function()
    it["should parse '- ' as the start of script"] = function()
      local output = tokenize("- a")
      expect(output[1].operator).should_be("silent_script")
      expect(output[1].code).should_be("a")
    end
  end

  describe["When handling script"] = function()
    it["should parse '= ' as the start of script"] = function()
      local output = tokenize("= a")
      expect(output[1].operator).should_be("script")
      expect(output[1].code).should_be("a")
    end
  end

  describe["When handling silent comments"] = function()

    it["Should parse '-#' as the start of a silent comment"] = function()
      local output = tokenize("-# a")
      expect(output[1].operator).should_be("silent_comment")
      expect(output[1].comment).should_be("a")
    end

    it["Should parse '--' as the start of a silent comment"] = function()
      local output = tokenize("-- a")
      expect(output[1].operator).should_be("silent_comment")
      expect(output[1].comment).should_be("a")
    end

  end

  describe["When handling header instructions('!!!')"] = function()

    it["should parse '!!! XML' as an XML prolog"] = function()
      local output = tokenize("!!! XML")
      expect(output[1].doctype).should_be(nil)
      expect(output[1].operator).should_be("header")
      expect(output[1].prolog).should_be("XML")
      expect(output[1].version).should_be(nil)
    end

    it["should parse '!!! 1.1' as XHTML 1.1 doctype"] = function()
      local output = tokenize("!!! 1.1")
      expect(output[1].doctype).should_be(nil)
      expect(output[1].operator).should_be("header")
      expect(output[1].prolog).should_be(nil)
      expect(output[1].version).should_be("1.1")
    end

    it["should parse '!!! strict' as an 'XHTML Strict 1.0' doctype"] = function()
      local output = tokenize("!!! strict")
      expect(output[1].operator).should_be("header")
      expect(output[1].doctype).should_be("STRICT")
      expect(output[1].prolog).should_be(nil)
      expect(output[1].version).should_be(nil)
    end

    it["should parse '!!!' as an unspecified doctype"] = function()
      local output = tokenize("!!!")
      expect(output[1].doctype).should_be(nil)
      expect(output[1].operator).should_be("header")
      expect(output[1].prolog).should_be(nil)
      expect(output[1].version).should_be(nil)
    end

  end

end
