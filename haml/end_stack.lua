module("haml.end_stack", package.seeall)

function new()
  local es = {
    endings = {},
    indents = 0
  }
  setmetatable(es, {__index = _M})
  return es
end


function haml.end_stack:push(ending)
  table.insert(self.endings, ending)
  if ending:match '^<' then
    self.indents = self.indents + 1
  end
end

function haml.end_stack:pop()
  if #self.endings == 0 then return nil end
  local ending = table.remove(self.endings)
  if ending:match '^<' then
    self.indents = self.indents - 1
  end
  return ending
end

function haml.end_stack:last()
  return self.endings[#self.endings]
end

function haml.end_stack:indent_level()
  return self.indents
end

function haml.end_stack:size()
  return #self.endings
end
