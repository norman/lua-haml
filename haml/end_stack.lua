local insert       = table.insert
local remove       = table.remove
local setmetatable = setmetatable
local type         = type

module "haml.end_stack"

local methods = {}

function methods:push(ending, callback)
  if callback then
    insert(self.endings, {ending, callback})
  else
    insert(self.endings, ending)
  end
  if ending:match '^<' then
    self.indents = self.indents + 1
  end
end

function methods:pop()
  local ending = remove(self.endings)
  if not ending then return end
  local callback
  if type(ending) == "table" then
    callback = ending[2]
    ending   = ending[1]
  end
  if ending:match '^<' then
    self.indents = self.indents - 1
  end
  return ending, callback
end

function methods:last()
  return self.endings[#self.endings]
end

function methods:indent_level()
  return self.indents
end

function methods:size()
  return #self.endings
end

function new()
  local endstack = {endings = {}, callbacks = {}, indents = 0}
  return setmetatable(endstack, {__index = methods})
end