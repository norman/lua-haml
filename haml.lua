local parser       = require "haml.parser"
local precompiler  = require "haml.precompiler"
local renderer     = require "haml.renderer"
local ext          = require "haml.ext"

local assert       = assert
local merge_tables = ext.merge_tables
local open         = io.open
local setmetatable = setmetatable
--- An implementation of the Haml markup language for Lua.
-- <p>
-- For more information on Haml, please see <a href="http://haml.info">The Haml website</a>
-- and the <a href="http://haml.info/docs/yardoc/file.HAML_REFERENCE.html">Haml language reference</a>.
-- </p>
module "haml"

--- Default Haml options.
-- @field format The output format. Can be xhtml, html4 or html5. Defaults to xhtml.
-- @field encoding The output encoding. Defaults to utf-8. Note that this is merely informative; no recoding is done.
-- @field newline The string value to use for newlines. Defaults to "\n".
-- @field space The string value to use for spaces. Defaults to " ".
default_haml_options = {
  adapter           = "lua",
  attribute_wrapper = "'",
  auto_close        = true,
  escape_html       = false,
  encoding          = "utf-8",
  format            = "xhtml",
  indent            = "  ",
  newline           = "\n",
  preserve          = {pre = true, textarea = true},
  space             = "  ",
  suppress_eval     = false,
  -- provided for compatiblity; does nothing
  ugly              = false,
  html_escapes      = {
    ["'"] = '&#039;',
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;'
  },
  --- These tags will be auto-closed if the output format is XHTML (the default).
  auto_closing_tags = {
    area  = true,
    base  = true,
    br    = true,
    col   = true,
    hr    = true,
    img   = true,
    input = true,
    link  = true,
    meta  = true,
    param = true
  }
}

local methods = {}

--- Render a Haml string.
-- @param haml_string The Haml string
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function methods:render(haml_string, locals)
  local parsed   = self:parse(haml_string)
  local compiled = self:compile(parsed)
  local rendered = renderer.new(compiled, self.options):render(locals)
  return rendered
end

--- Render a Haml file.
-- @param haml_string The Haml file
-- @param options Options for the precompiler
-- @param locals Local variable values to set for the rendered template
function methods:render_file(file, locals)
  local fh = assert(open(file))
  local haml_string = fh:read '*a'
  fh:close()
  self.options.file = file
  return self:render(haml_string, locals)
end

function methods:parse(haml_string)
  return parser.tokenize(haml_string)
end

function methods:compile(parsed)
  return precompiler.new(self.options):precompile(parsed)
end

function new(options)
  local engine = {}
  engine.options = merge_tables(default_haml_options, options or {})
  return setmetatable(engine, {__index = methods})
end
