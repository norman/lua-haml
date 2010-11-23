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
