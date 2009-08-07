local xhtml_doctypes = {
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
  MOBILE   = '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">',
  BASIC    = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
}

local html4_doctypes = {
  STRICT   = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
  FRAMESET = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
  DEFAULT  = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
}

local function prolog_for(state)
  local charset = state.curr_phrase.charset or state.options.encoding
  state.buffer:string(string.format("<?xml version='1.0' encoding='%s' ?>", charset), true)
end

local function doctype_for(state)

  if state.options.format == 'html5' then
    return state.buffer:string('<!DOCTYPE html>', true)

  elseif state.curr_phrase.version == "1.1" then
    return state.buffer:string('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">', true)

  elseif state.options.format == 'xhtml' then
    local doctype = xhtml_doctypes[state.curr_phrase.doctype] or xhtml_doctypes.DEFAULT
    return state.buffer:string(doctype, true)

  elseif state.options.format == 'html4' then
    local doctype = html4_doctypes[state.curr_phrase.doctype] or html4_doctypes.DEFAULT
    return state.buffer:string(doctype, true)

  else
    error(string.format('Don\'t understand doctype "%s"', state.curr_phrase.doctype))
  end

end

function header_for(state)

  if (string.len(state.next_phrase.space) or 0) > 0 then
    error("Syntax error: you can not nest within a doctype declaration or XML prolog.")
  end

  if state.curr_phrase.prolog then
    return prolog_for(state)
  else
    return doctype_for(state)
  end

end