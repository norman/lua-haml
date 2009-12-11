require "haml"

describe("The LuaHaml Precompiler:", function()

  describe("the endstack", function()

    local es
    before(function()
      es = haml.end_stack.new()
    end)

    it("should have an initial indent level of 0", function()
      assert_equal(es:indent_level(), 0)
    end)

    it("should add an HTML tag and increase the indent level", function()
      es:push("</p>")
      assert_equal(es:indent_level(), 1)
    end)

    it("should not increase the indent level for code endings", function()
      es:push("end")
      assert_equal(es:indent_level(), 0)
    end)

    it("should pop an HTML tag an decrease the indent level", function()
      es:push("</html>")
      es:push("</body>")
      assert_equal(es:indent_level(), 2)
      es:pop()
      assert_equal(es:indent_level(), 1)
    end)

    it("should not decrease indent level when popping code endings", function()
      es:push("</html>")
      es:push("end")
      assert_equal(es:indent_level(), 1)
      es:pop()
      assert_equal(es:indent_level(), 1)
    end)

    it("should return nil when popping an empty stack", function()
      assert_equal(es:pop(), nil)
    end)

  end)
end)
