--- An implementation of the Haml markup language for Lua.
-- <p>
-- For more information on Haml, please see <a href="http://haml-lang.com">The Haml website</a>
-- and the <a href="http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html">Haml language reference</a>.
-- </p>
module("haml", package.seeall)
require "std"
require "haml.lexer"
require "haml.precompiler"
require "haml.ext"

--- Render a Haml string.
-- @param haml The Haml string
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function render(haml, options, locals)
  local buffer = {}
  local output = precompiler.precompile(haml, options, locals)
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