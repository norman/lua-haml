#!/usr/bin/env ruby

=begin
WTF? A Ruby renderer for Lua Haml?

Luahaml's precompiler uses language adapters to output code for different
target languages. Because the output already uses extremely simple code,
it only requires the implementation of a few basic methods, and a simple
renderer.

Note that running LuaHaml output with Ruby is HIGHLY experimental. As in,
I just did this in about an hour. However, language support is a core
feature of LuaHaml, so I will be working to make Ruby, PHP, and perhaps
other languages first-class target platforms just like Lua.

To try it out, you need to clone the Lua Haml repository from

http://github.com/norman/lua-haml

To run LuaHaml on a file, you need to do:

./bin/luahaml --ruby -c spec/samples/ruby_renderer_test.haml | ./bin/ruby_renderer.rb

or run

./bin/rluahaml spec/samples/ruby_renderer_test.haml

=end

def interpolate(str)
  if str.class == Hash then
    str.values.collect { |a| a.to_s }.sort.join(" ")
  else
    str.to_s
  end
end

def render_attributes(hash)
  ' ' + hash.collect {|k, v| k =~ /^\d*$/ ? v : "#{k}='#{v}'" }.sort.join(" ")
end

eval(ARGF.read)
print "\n"
