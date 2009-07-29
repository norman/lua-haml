--- Haml precompiler
module("haml.precompiler", package.seeall)
require "std"

local function handle_doctype(phrase, state, buffer)
  local output
  if phrase["unparsed"] == "XML" then
    output = "print '" .. '<?xml version="1.0" encoding="utf-8" ?>' .. "'"
  else
    output = "print '" .. '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' .. "'"
  end
  table.insert(buffer, output)
  state.space = phrase.space
  state.current = "doctype"
end

local function ws(level)
  return string.format('%' .. level .. 's', '')
end

local function close_tags(level, state, buffer)
  for i = 0, level do
    if #state.tagstack == 0  then break end
    local tag = string.format("</%s>", table.remove(state.tagstack))
    table.insert(buffer, "print '" .. ws((#state.tagstack) * 2) .. tag .. "'")
  end
end

local function handle_tag(phrase, state, buffer)
  if (phrase.space <= state.space) and state.space > 0  then
    close_tags((state.space - phrase.space) / 2, state, buffer)
  end
  local output
  output = string.format("<%s>", phrase.markup_tag)
  table.insert(buffer, "print '" .. ws(phrase.space) .. output .. "'")
  table.insert(state.tagstack, phrase.markup_tag)
  state.current = "tag"
end

local function handle_unparsed(phrase, state, buffer)
  table.insert(buffer, "print '" .. ws(phrase.space) .. string.trim(phrase.unparsed) .. "'")
  state.space = phrase.space
  state.current = "unparsed"
end

function precompile(haml_string)
  local phrases = haml.lexer.tokenize(haml_string)
  local buffer = {}
  local state = {current = "init", space = 0, tagstack = {}}
  for _, phrase in pairs(phrases) do
    local op
    if phrase.operator == "doctype" then
      handle_doctype(phrase, state, buffer)
    elseif phrase.operator == "tag" then
      handle_tag(phrase, state, buffer)
    elseif phrase.unparsed then
      handle_unparsed(phrase, state, buffer)
    end
  end
  state.space = 0
  close_tags(#state.tagstack, state, buffer)
  print(table.concat(buffer, "\n"))
end