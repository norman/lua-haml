local ext = require "haml.ext"
local do_error = ext.do_error

module "haml.header"

--- The HTML4 doctypes; default is 4.01 Transitional.
html_doctypes = {
  ["5"]    = '<!DOCTYPE html>',
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
}

--- The XHTML doctypes; default is 1.0 Transitional.
xhtml_doctypes = {
  ["5"]    = html_doctypes["5"],
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
  MOBILE   = '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">',
  BASIC    = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
}


--- Returns an XML prolog for the precompiler state.
local function prolog_for(state)
  if state.options.format:match("^html") then return nil end
  local charset = state.curr_phrase.charset or state.options.encoding
  state.buffer:string(("<?xml version='1.0' encoding='%s' ?>"):format(charset), {newline = true})
end

--- Returns an (X)HTML doctype for the precompiler state.
local function doctype_for(state)

  if state.options.format == 'html5' then
    return state.buffer:string(html_doctypes["5"], {newline = true})

  elseif state.curr_phrase.version == "1.1" then
    return state.buffer:string('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">', {newline = true})

  elseif state.options.format == 'xhtml' then
    local doctype = xhtml_doctypes[state.curr_phrase.doctype] or xhtml_doctypes.DEFAULT
    return state.buffer:string(doctype, {newline = true})

  elseif state.options.format == 'html4' then
    local doctype = html_doctypes[state.curr_phrase.doctype] or html_doctypes.DEFAULT
    return state.buffer:string(doctype, {newline = true})

  else
    do_error(state.curr_phrase.pos, 'don\'t understand doctype "%s"', state.curr_phrase.doctype)
  end

end

--- Returns an XML prolog or an X(HTML) doctype for the precompiler state.
function header_for(state)
  if state.next_phrase and (#(state.next_phrase.space) or 0) > 0 then
    do_error(state.curr_phrase.pos, "you can not nest within a doctype declaration or XML prolog")
  end

  if state.curr_phrase.prolog then
    return prolog_for(state)
  else
    return doctype_for(state)
  end
end
