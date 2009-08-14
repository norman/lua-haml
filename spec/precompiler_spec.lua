require 'luarocks.require'
require 'luaspec'
require "haml"

local endstack = haml.precompiler.endstack

describe["The LuaHaml Precompiler:"] = function()

  describe["the endstack"] = function()

    it["should have an initial indent level of 0"] = function()
      local es = endstack()
      expect(es:indent_level()).should_be(0)
    end

    it["should add an HTML tag and increase the indent level"] = function()
      local es = endstack()
      es:push("</p>")
      expect(es:indent_level()).should_be(1)
    end

    it["should not increase the indent level for code endings"] = function()
      local es = endstack()
      es:push("end")
      expect(es:indent_level()).should_be(0)
    end

    it["should pop an HTML tag an decrease the indent level"] = function()
      local es = endstack()
      es:push("</html>")
      es:push("</body>")
      expect(es:indent_level()).should_be(2)
      es:pop()
      expect(es:indent_level()).should_be(1)
    end

    it["should not decrease indent level when popping code endings"] = function()
      local es = endstack()
      es:push("</html>")
      es:push("end")
      expect(es:indent_level()).should_be(1)
      es:pop()
      expect(es:indent_level()).should_be(1)
    end

    it["should return nil when popping an empty stack"] = function()
      local es = endstack()
      expect(es:pop()).should_be(nil)
    end

  end
end
