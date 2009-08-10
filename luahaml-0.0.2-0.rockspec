package = "luahaml"
version = "0.0.2-0"
source = {
   url = "http://github.com/norman/lua-haml/tarball/REL_0_0_2",
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
      ["haml.lexer"]       = "haml/lexer.lua",
      ["haml.precompiler"] = "haml/precompiler.lua",
      ["haml.renderer"]    = "haml/renderer.lua",
      ["haml.tags"]        = "haml/tags.lua",
      ["haml.headers"]     = "haml/headers.lua"
    },
    bin = {
      ["luahaml"] = "bin/luahaml"
    }
  }
}