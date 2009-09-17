#!/usr/bin/env ruby

def interpolate(str)
  str
end

def render_attributes(hash)
  ' ' + hash.collect {|k, v| "#{k}='#{v}'" }.sort.join(" ")
end

eval(ARGF.read)
print "\n"
