require "haml"

-- This includes only LuaHaml-specific tests. Most other renderer tests
-- are provided by the haml-spec submodule.

local tests = {
  -- Script
  {'%p="hello"', '<p>hello</p>'},
  {"- a = 'b'\n%p=a", "<p>b</p>"},
  {"- for k,v in pairs({a = 'a'}) do\n  %p(class=k)=v", "<p class='a'>a</p>"},
  -- External filters
  {":markdown\n  # a", "<h1>a</h1>"},
}


describe("The LuaHaml Renderer", function()
  local locals = {}
  for _, t in ipairs(tests) do
    test(string.format("should render '%s' as '%s'", string.gsub(t[1], "\n", "\\n"),
        string.gsub(t[2], "\n", "\\n")), function()
        local engine = haml.new()
        assert_equal(t[2], engine:render(t[1], locals))
    end)
  end

  test("should call attribute value if a function", function()
    local locals = {
      get_id = function()
        return "hello"
      end
    }
    local code = "%p(id=get_id)"
    local html = "<p id='hello'></p>"
    local engine = haml.new()
    assert_equal(html, engine:render(code, locals))
  end)

end)