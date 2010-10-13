local code                 = require "haml.code"
local comment              = require "haml.comment"
local end_stack            = require "haml.end_stack"
local ext                  = require "haml.ext"
local filter               = require "haml.filter"
local header               = require "haml.header"
local string_buffer        = require "haml.string_buffer"
local tag                  = require "haml.tag"

local default_haml_options = _G["default_haml_options"]
local ipairs               = ipairs
local require              = require
local setmetatable         = setmetatable

--- Haml precompiler
module "haml.precompiler"

local methods = {}

--- Precompile Haml into Lua code.
-- @param phrases A table of parsed phrases produced by the parser.
function methods:precompile(phrases)

  self.buffer         = string_buffer.new(self.adapter)
  self.endings        = end_stack.new()
  self.curr_phrase    = {}
  self.next_phrase    = {}
  self.prev_phrase    = {}
  self.space_sequence = nil

  if self.options.file then
    self.buffer:code(("r:f(%q)"):format(self.options.file))
  end

  for index, phrase in ipairs(phrases) do
    self.next_phrase = phrases[index + 1]
    self.prev_phrase = phrases[index - 1]
    self.curr_phrase = phrase
    self:__detect_whitespace_format()
    self:__validate_whitespace()
    self.buffer:code(("r:at(%s)"):format(phrase.chunk[1]))
    self:__handle_current_phrase()
  end

  self:__close_open_tags()

  return self.buffer:cat()
end

function methods:indent_level()
  if not self.space_sequence then
    return 0
  else
    return self.curr_phrase.space:len() / self.space_sequence:len()
  end
end

function methods:indent_diff()
  if not self.space_sequence then return 0 end
  return self:indent_level() - self.prev_phrase.space:len()  / self.space_sequence:len()
end

function methods:indents(n)
  local l = self.endings:indent_level()
  return self.options.indent:rep(n and n + l or l)
end

-- You can pass in a function to check the last end tag and return
-- after a certain level. For example, you can use it to close all
-- open HTML tags and then bail when we reach an "end". This is useful
-- for closing tags around "else" and "elseif".
function methods:close_tags(func)
  if self:indent_diff() < 0 then
    local i = self:indent_diff()
    repeat
      if func and func(self.endings:last()) then return end
        self:close_current()
      i = i + 1
    until i == 0
  end
end

function methods:close_current()
  -- reset some per-tag state settings for each chunk.
  if self.buffer.suppress_whitespace then
    self.buffer:chomp()
    self.buffer.suppress_whitespace = false
  end

  local ending = self.endings:pop()
  if not ending then return end
  if ending:match "^<" then
    self.buffer:string(self:indents() .. ending, {newline = true})
  else
    self.buffer:code(ending)
  end
end

function methods:__close_open_tags()
  while self.endings:size() > 0 do
    self:close_current()
  end
end

function methods:__detect_whitespace_format()
  if self.space_sequence then return end
  if #(self.curr_phrase.space or '') > 0 and not self.space_sequence then
    self.space_sequence = self.curr_phrase.space
  end
end

function methods:__validate_whitespace()
  if not self.space_sequence then return end
  if self.curr_phrase.space == "" then return end
  local prev_space = ''
  if self.prev_phrase then prev_space = self.prev_phrase.space end
  if self.curr_phrase.space:len() <= prev_space:len() then return end
  if self.curr_phrase.space == (prev_space .. self.space_sequence) then return end
  ext.do_error(self.curr_phrase.chunk[2], "bad indentation")
end

function methods:__handle_current_phrase()
  if self.curr_phrase.operator == "header" then
    header.header_for(self)
  elseif self.curr_phrase.operator == "filter" then
    filter.filter_for(self)
  elseif self.curr_phrase.operator == "silent_comment" then
    self:close_tags()
  elseif self.curr_phrase.operator == "markup_comment" then
    comment.comment_for(self)
  elseif self.curr_phrase.operator == "conditional_comment" then
    comment.comment_for(self)
  elseif self.curr_phrase.tag then
    tag.tag_for(self)
  elseif self.curr_phrase.code then
    code.code_for(self)
  elseif self.curr_phrase.unparsed then
    self:close_tags()
    self.buffer:string(self:indents() .. self.curr_phrase.unparsed)
    self.buffer:newline(true)
  end
end

--- Create a new Haml precompiler
-- @param options Precompiler options.
function new(options)
  options = ext.merge_tables(default_haml_options, options)
  local precompiler = {
    options         = options,
    adapter         = require(("haml.%s_adapter"):format(options.adapter)).get_adapter(options)
  }
  return setmetatable(precompiler, {__index = methods})
end
