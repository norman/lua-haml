require "socket"
require "haml"

local n = 5000

local template = [=[
!!! html
%html
  %head
    %title Test
  %body
    %h1 simple markup
    %div#content
    %ul
      - for _, letter in ipairs({"a", "b", "c", "d", "e", "f", "g"}) do
        %li= letter
]=]

local start = socket.gettime()
for i = 1,n do
  local engine = haml.new()
  local html = engine:render(template)
end
local done = socket.gettime()

print "Uncached:"
print(("%s seconds"):format(done - start))

local start = socket.gettime()

local engine        = haml.new()
local phrases       = engine:parse(template)
local compiled      = engine:compile(phrases)
local haml_renderer = require "haml.renderer"
local renderer      = haml_renderer.new(compiled)

for i = 1,n do
  renderer:render(compiled)
end
local done = socket.gettime()

print "Cached:"
print(("%s seconds"):format(done - start))
