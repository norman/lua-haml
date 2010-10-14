require "benchmark"
require "haml"

n = 5000

haml = "!!! html
%html
  %head
    %title Test
  %body
    %h1 simple markup
    %div#content"

Benchmark.bmbm do |bench|
  bench.report("haml (ugly) #{Haml::VERSION}") do
    for i in 0..n do
      Haml::Engine.new(haml, :format => :html5, :ugly => true).render();
    end
  end
  bench.report("haml (ugly) #{Haml::VERSION} (cached)") do
    t = Haml::Engine.new(haml, :format => :html5, :ugly => true)
    for i in 0..n do
      t.render
    end
  end
end
