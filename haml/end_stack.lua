module("EndStack", package.seeall)

function new()
  local es = {
    endings = {},
    indents = 0
  }
  setmetatable(es, {__index = EndStack})
  return es
end


function EndStack:push(ending)
  table.insert(self.endings, ending)
  if ending:match '^<' then
    self.indents = self.indents + 1
  end
end

function EndStack:pop()
  if #self.endings == 0 then return nil end
  local ending = table.remove(self.endings)
  if ending:match '^<' then
    self.indents = self.indents - 1
  end
  return ending
end

function EndStack:last()
  return self.endings[#self.endings]
end

function EndStack:indent_level()
  return self.indents
end

function EndStack:size()
  return #self.endings
end
