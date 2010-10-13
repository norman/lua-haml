--- Default Haml options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8. Note that this is merely informative; no recoding is done.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
_G["default_haml_options"] = {
  adapter      = "lua",
  auto_close   = true,
  escape_html  = false,
  encoding     = "utf-8",
  format       = "xhtml",
  indent       = "  ",
  newline      = "\n",
  preserve     = {pre = true, textarea = true},
  space        = "  ",
  html_escapes = {
    ["'"] = '&#039;',
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;'
  }
}

local haml_parser      = require "haml.parser"
local haml_precompiler = require "haml.precompiler"
local haml_renderer    = require "haml.renderer"

local assert = assert
local open   = io.open

--- An implementation of the Haml markup language for Lua.
-- <p>
-- For more information on Haml, please see <a href="http://haml-lang.com">The Haml website</a>
-- and the <a href="http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html">Haml language reference</a>.
-- </p>
module "haml"

--- Render a Haml string.
-- @param haml_string The Haml string
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function render(haml_string, options, locals)
  local phrases     = haml_parser.tokenize(haml_string)
  local precompiler = haml_precompiler.new(options)
  local template    = precompiler:precompile(phrases)
  local renderer    = haml_renderer.new(options, locals)
  return renderer:render(template)
end

--- Render a Haml file.
-- @param haml_string The Haml file
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function render_file(file, options, locals)
  local fh = assert(open(file))
  local haml_string = fh:read '*a'
  fh:close()
  options.file = file
  return render(haml_string, options, locals)
end
