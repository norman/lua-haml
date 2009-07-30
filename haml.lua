require("std")
module("haml", package.seeall)
require("haml.lexer")
require("haml.precompiler")
require("haml.ext")

function render(haml, options, locals)
  local buffer = {}
  local output = precompiler.precompile(haml)
  local env = getfenv()
  env.print = function(str)
    table.insert(__buffer, str)
  end
  env.__buffer = buffer
  local func = loadstring(output)
  setfenv(func, env)
  func()
  return table.concat(buffer, "\n")
end