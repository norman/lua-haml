# Lua Haml

## About

Lua Haml is an implementation of the [Haml](http://haml-lang.com) markup
language for Lua.

A Haml language reference can be found
[here](http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html).

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

Lua Haml is now feature complete, but has not been formally released. At the
moment, error checking and reporting are a bit weak, so if you have errors in
your Haml template they can be hard to track down.

Once I've had a chance to improve this area of the code, then I'll do a stable
release.

## Getting it

The easiest way to install is from the current Git master using LuaRocks:

    luarocks build http://github.com/norman/lua-haml/raw/master/luahaml-scm-1.rockspec

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
original Haml.

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
