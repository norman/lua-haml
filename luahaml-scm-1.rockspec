package = "luahaml"
version = "scm-1"
source = {
   url = "git://github.com/norman/lua-haml.git",
}
description = {
   summary = "An implementation of the Haml markup language for Lua.",
   detailed = [[
      Lua Haml is an in-progress implementation of the Haml markup language for Lua.
   ]],
   license = "MIT/X11",
   homepage = "http://github.com/norman/lua-haml"
}
dependencies = {
   "lua >= 5.1"
}

build = {
  type = "none",
  install = {
    lua = {
      "haml.lua",
      ["haml.ext"]         = "haml/ext.lua",
      ["haml.parser"]      = "haml/parser.lua",
      ["haml.precompiler"] = "haml/precompiler.lua",
      ["haml.renderer"]    = "haml/renderer.lua",
      ["haml.tag"]         = "haml/tag.lua",
      ["haml.header"]      = "haml/header.lua",
      ["haml.code"]        = "haml/code.lua"
      ["haml.filter"]      = "haml/filter.lua"
    },
    bin = {
      ["luahaml"] = "bin/luahaml"
    }
  }
}
