# Lua Haml

## About

Lua Haml is an implementation of the [Haml](http://haml.info) markup
language for Lua.

A Haml language reference can be found
[here](http://haml.info/docs/yardoc/file.HAML_REFERENCE.html).

Lua Haml implements almost 100% of Ruby Haml, and attempts to be as compatible
as possible with it, with the following exceptions:

* Your script blocks are in Lua rather than Ruby, obviously.
* A few Ruby-specific filters are not implemented, namely `:maruku`, `:ruby` and `:sass`.
* No attribute methods. This feature would have to be added to Ruby-style
  attributes which are discouraged in Lua-Haml, or the creation of a
  Lua-specific attribute format, which I don't want to add.
* No object reference. This feature is idiomatic to the Rails framework and
  doesn't really apply to Lua.
* No ugly mode. Because of how Lua Haml is designed, there's no performance
  penalty for outputting indented code, so there's no reason to implement this
  option.

Here's a [Haml
template](http://github.com/norman/lua-haml/tree/master/sample.haml) that uses
most of Lua Haml's features.

## TODO

Lua Haml is now feature complete, but is still considered beta quality. That
said, I am using it for a production website, and will work quickly to fix any
bugs that are reported.  So please feel free to use it for serious work - just
not the Space Shuttle, ok?


## Getting it

The easiest way to install is via LuaRocks:

    luarocks install luahaml

You can also always install the latest master branch from Git via Luarocks:

    luarocks install luahaml --from=http://luarocks.org/repositories/rocks-cvs

## Installing without Luarocks

If you do not wish to use Luarocks, just put `haml.lua` and the `haml` directories
somewhere on your package path, and place `luahaml` somewhere in your execution
path.

Here's one of many ways you could do this:

    git clone git://github.com/norman/lua-haml.git
    cd lua-haml
    cp bin/luahaml ~/bin
    cp -rp haml haml.lua /usr/local/my_lua_libs_dir
    export LUA_PATH=";;/usr/local/my_lua_libs_dir/?.lua"

Note that you can also download a .zip or .tar.gz from Github if you do not use
Git.


## Using it in your application

Here's a simple usage example:

    -- in file.haml
    %p= "Hello, " .. name .. "!"

    -- in your application
    local haml         = require "haml"
    local haml_options = {format = "html5"}
    local engine       = haml.new(options)
    local locals       = {name = "Joe"}
    local rendered     = engine:render_file("file.haml", locals)

    -- output
    <p>Hello, Joe!</p>

## Hacking it

The [Github repository](http://github.com/norman/lua-haml) is located at:

    git://github.com/norman/lua-haml.git

To run the specs, you should also install Telescope:

    luarocks install telescope

You can then run them using [Tlua](http://github.com/norman/tlua), or do

    tsc `find . -name '*_spec.lua'`

## Bug reports

Please report them on the [Github issue tracker](http://github.com/norman/lua-haml/issues).

## Author

[Norman Clarke](mailto://norman@njclarke.com)

## Thanks

To Hampton Caitlin, Nathan Weizenbaum and Chris Eppstein for their work on the
original Haml. Thanks also to Daniele Alessandri for being LuaHaml's earliest
"real" user, and a source of constant encouragement.

## License

The MIT License

Copyright (c) 2009-2010 Norman Clarke

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
