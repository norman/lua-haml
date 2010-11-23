package = "luahaml"
version = "0.1.0-0"
source = {
   url = "http://cloud.github.com/downloads/norman/lua-haml/lua-haml-0.1.0-0.tar.gz",
   md5 = "a3fb8b0032a08965690a84fe43c8821c"
}
description = {
   summary = "An implementation of the Haml markup language for Lua.",
   detailed = [[
      Lua Haml is an implementation of the Haml markup language for Lua.
   ]],
   license = "MIT/X11",
   homepage = "http://github.com/norman/lua-haml"
}
dependencies = {
   "lua >= 5.1",
   "lpeg"
}

build = {
  type = "none",
  install = {
    lua = {
      "haml.lua",
      ["haml.ext"]           = "haml/ext.lua",
      ["haml.parser"]        = "haml/parser.lua",
      ["haml.precompiler"]   = "haml/precompiler.lua",
      ["haml.renderer"]      = "haml/renderer.lua",
      ["haml.tag"]           = "haml/tag.lua",
      ["haml.header"]        = "haml/header.lua",
      ["haml.code"]          = "haml/code.lua",
      ["haml.filter"]        = "haml/filter.lua",
      ["haml.comment"]       = "haml/comment.lua",
      ["haml.lua_adapter"]   = "haml/lua_adapter.lua",
      ["haml.string_buffer"] = "haml/string_buffer.lua",
      ["haml.end_stack"]     = "haml/end_stack.lua"
    },
    bin = {
      ["luahaml"] = "bin/luahaml"
    }
  }
}
