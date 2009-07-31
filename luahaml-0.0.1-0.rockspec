package = "luahaml"
version = "0.0.1-0"
source = {
   url = "http://github.com/norman/lua-haml/tarball/REL_0_0_1",
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
   "lua >= 5.1",
   "stdlib >= 8-1"
}
build = {
  type = "none",
  install = {
    lua = {
      "haml.lua",
      "haml/ext.lua",
      "haml/lexer.lua",
      "haml/precompiler.lua",
      "haml/markup/tags.lua",
    },
    bin = {
      ["luahaml"] = "bin/luahaml"
    }
  }
}