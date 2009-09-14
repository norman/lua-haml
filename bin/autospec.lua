#!/usr/bin/env lua
require 'luarocks.require'
require 'lfs'
require 'telescope'

local watchfiles = {
  "haml.lua",
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
  "spec/precompiler_spec.lua"
}

local timestamps = {}
for _, file in pairs(watchfiles) do
  timestamps[file] = 0
end

while(true) do
  local run_specs = false
  for _, file in pairs(watchfiles) do
    local attr = lfs.attributes(file)
    if attr.modification > timestamps[file] then
      run_specs = true
    end
    timestamps[file] = attr.modification
  end
  if run_specs then
    result = os.execute("tsc spec/*_spec.lua")
    local image = result == 0 and "pass" or "fail"
    os.execute(string.format("echo '%s' | growlnotify --image ~/.autotest_images/%s.png", image:upper(), image))
    run_specs = false
  end
  os.execute("sleep 1")
end
