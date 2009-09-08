#!/usr/bin/env lua
require 'luarocks.require'
require 'lfs'
require 'std'

local watchfiles = {
  "haml.lua",
  "haml/ext.lua",
  "haml/headers.lua",
  "haml/lexer.lua",
  "haml/precompiler.lua",
  "haml/renderer.lua",
  "haml/tags.lua",
  "haml/code.lua",
  "haml/filter.lua"
}

local specs = {
  "spec/lexer_spec.lua",
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
    os.execute("bin/spec")
    run_specs = false
  end
  os.execute("sleep 1")
end

print(timestamps)
