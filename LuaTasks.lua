local function spec()
  local params = tlua.get_params()
  if params[1] == "-f" then
    os.execute("tsc -f `find . -name '*_spec.lua'`")
  else
    os.execute("tsc `find . -name '*_spec.lua'`")
  end
end

local function autospec()
  require 'luarocks.require'
  require 'lfs'
  require 'telescope'

  local watchfiles = {
    "haml.lua",
    "haml/comment.lua",
    "haml/ext.lua",
    "haml/header.lua",
    "haml/parser.lua",
    "haml/precompiler.lua",
    "haml/renderer.lua",
    "haml/tag.lua",
    "haml/code.lua",
    "haml/filter.lua",
    "spec/parser_spec.lua",
    "spec/renderer_spec.lua",
    "spec/precompiler_spec.lua",
    "spec/haml-spec/tests.json"
  }

  local timestamps = {}
  for _, file in pairs(watchfiles) do
    timestamps[file] = 0
  end

  while(true) do
    pcall(function()
      local run_specs = false
      for _, file in pairs(watchfiles) do
        local attr = lfs.attributes(file)
        if attr.modification > timestamps[file] then
          run_specs = true
        end
        timestamps[file] = attr.modification
      end
      if run_specs then
        local f = assert(io.popen("tsc `find . -name '*_spec.lua'`", 'r'))
        local s = assert(f:read('*a'))
        print(s)
        f:close()
        local image = (s:match("0 fail") and s:match("0 err")) and "pass" or "fail"
        os.execute(string.format("echo '%s' | growlnotify --name Telescope --image ~/.autotest_images/%s.png", s:gsub("\n.*", ""), image))
        run_specs = false
      end
      os.execute("sleep 1")
    end)
  end
end

tlua.task("spec", "Run specs", spec)
tlua.task("autospec", "Run specs automatically as files are changed", autospec)
tlua.default_task = "spec"
