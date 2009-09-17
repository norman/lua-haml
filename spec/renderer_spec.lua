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
  for _, t in ipairs(tests) do
    test(string.format("should render '%s' as '%s'", string.gsub(t[1], "\n", "\\n"),
        string.gsub(t[2], "\n", "\\n")), function()
        assert_equal(haml.render(t[1], {}, locals), t[2])
    end)
  end
end)
