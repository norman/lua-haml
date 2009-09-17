--- An implementation of the Haml markup language for Lua.
-- <p>
-- For more information on Haml, please see <a href="http://haml-lang.com">The Haml website</a>
-- and the <a href="http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html">Haml language reference</a>.
-- </p>
ext = require "haml.ext"
module("haml", package.seeall)
require "haml.parser"
require "haml.precompiler"
require "haml.renderer"

--- Default Haml options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
-- TODO allow an option for tag auto-closing
default_options = {
  adapter    = "lua",
  auto_close = true,
  encoding   = 'utf-8',
  format     = 'xhtml',
  indent     = "  ",
  newline    = "\n",
  space      = "  ",
  html_escapes = {
    ["'"] = '&#039;',
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;'
  }
}

--- Render a Haml string.
-- @param haml_string The Haml string
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function render(haml_string, options, locals)
  local phrases = haml.parser.tokenize(haml_string)
  local template = precompiler.precompile(phrases, options)
  return haml.renderer.render(template, options, locals)
end

--- Render a Haml file.
-- @param haml_string The Haml file
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function render_file(file, options, locals)
  local fh = assert(io.open(file))
  local haml_string = fh:read '*a'
  fh:close()
  return render(haml_string, options, locals)
end
