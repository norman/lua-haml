local insert       = table.insert
local remove       = table.remove
local setmetatable = setmetatable

module "haml.end_stack"

local methods = {}

function methods:push(ending)
  insert(self.endings, ending)
  if ending:match '^<' then
    self.indents = self.indents + 1
  end
end

function methods:pop()
  if #self.endings == 0 then return nil end
  local ending = remove(self.endings)
  if ending:match '^<' then
    self.indents = self.indents - 1
  end
  return ending
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
  local endstack = {endings = {}, indents = 0}
  return setmetatable(endstack, {__index = methods})
end