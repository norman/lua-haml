require "benchmark"
require "haml"

n = 5000

haml = '!!! html
%html
  %head
    %title Test
  %body
    %h1 simple markup
    %div#content
    %ul
    - ["a", "b", "c", "d", "e", "f", "g"].each do |letter|
      %li= letter'

compiled = Haml::Engine.new(haml, :format => :html5, :ugly => true)


Benchmark.bmbm do |bench|
  bench.report("haml #{Haml::VERSION} - compile & render") do
    for i in 0..n do
      Haml::Engine.new(haml, :format => :html5, :ugly => true).render
    end
  end
  bench.report("haml #{Haml::VERSION} - render") do
    for i in 0..n do
      compiled.render
    end
  end
end