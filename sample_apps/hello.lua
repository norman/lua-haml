require "luarocks.require"
require "orbit"
require "haml"
module("hello", package.seeall, orbit.new)

local views = {}

views.index = [[
!!! XML
!!! Strict
%html(xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en")
  %head
    %meta(http-equiv="Content-Type" content="text/html" charset="utf-8")
    %title Haml time!
  %body
    %h1 Lua Haml
      %p
        This is the first web page ever rendered with Lua Haml.
      %p= "The time is currently " .. os.date()
]]

function render_haml(str)
  return haml.render(str)
end

function index(web)
  content = views.index
  return render_haml(views.index)
end

hello:dispatch_get(index, "/", "/index")
return _M
