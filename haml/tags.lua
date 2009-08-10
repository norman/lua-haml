module("haml.tags", package.seeall)

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

function serialize_table(t)
  local buffer = {}
  
  local function kv(k, v)
    if type(k) == "number" then
      return string.format('%s, ', v)
    else
      return string.format('["%s"] = %s, ', k, v)
    end
  end
  
  table.insert(buffer, "{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      table.insert(buffer, kv(k, serialize_table(v)))
    else
      table.insert(buffer, kv(k, v))
    end
  end
  table.insert(buffer, "}")
  return table.concat(buffer, "")
end


--- Format tables into tag attributes.
local function format_attributes(...)
  -- local buffer = {}
  -- for k, v in pairs(join_tables(...)) do
    -- TODO abstract away Lua-specific precompiler output into an adatper to allow for other languages
    -- table.insert(buffer, string.format('["%s"] = %s', k, v))
  -- end
  return 'print(render_attributes(' .. serialize_table(join_tables(...)) .. '))'
end

--- Whether we should auto close the tag for the current precompiler state.
local function should_auto_close(state)
  return state.options.format == 'xhtml' and
    auto_closing_tags[state.curr_phrase.tag] and
    state.options.auto_close and
    not state.curr_phrase.inline_content
end

local function should_close_inline(state)
  return state.curr_phrase.inline_content or
    not state.next_phrase or
    state.next_phrase.space == state.curr_phrase.space
end

-- Precompile an (X)HTML tag for the current precompiler state.
function tag_for(state)

  local c = state.curr_phrase

  -- if the current indent level is less than the previous phrase's, close
  -- endings from the ending stack
  if state:indent_diff() < 0 then
    local i = state:indent_diff()
    repeat
      state.buffer:string(
        string.rep(state.options.indent, #state.endstack - 1) ..
        table.remove(state.endstack),
        true
      )
      i = i + 1
    until i == 0
  end

  -- open the tag
  state.buffer:string(state:indents() .. '<' .. c.tag)

  -- add any attributes
  if c.attributes or c.css then
    -- local attributes = merge_tables()
    -- -- Include classes set by css and set by attributes hash. i.e.,
    -- -- %p.class1(class='class2')
    -- if c.css and c.css.class and attributes.class ~= c.css.class then
    --   local classes = { dequote(c.css.class), dequote(attributes.class) }
    --   table.sort(classes)
    --   attributes.class = table.concat(classes, " ")
    --   -- require 'std'
    --   -- print(attributes)
    -- end
    -- -- Join id's set by CSS and attributes hashes with underscores.
    -- -- %p.class1(class='class2')
    -- if c.css and c.css.id and attributes.id ~= c.css.id then
    --   attributes.id = string.format("'%s_%s'",
    --     string.gsub(c.css.id, "'", ""),
    --     string.gsub(attributes.id, "'", "")
    --   )
    -- end
    state.buffer:code(format_attributes(c.css or {}, unpack(c.attributes or {})))
  end

  -- complete the opening tag
  if  should_auto_close(state) then
    state.buffer:string('/>')
  else
    state.buffer:string('>')
    table.insert(state.endstack, string.format("</%s>", c.tag))
    if should_close_inline(state) then
      if c.inline_content then
        state.buffer:string(strip(c.inline_content))
      end
      state.buffer:string(table.remove(state.endstack))
      state.endstack[c.space] = nil
    end
  end
  state.buffer:newline()
end
