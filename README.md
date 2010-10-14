# Lua Haml

## About

Lua Haml is an implementation of the [Haml](http://haml-lang.com) markup
language for Lua.

A Haml language reference can be found
[here](http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html).

Lua Haml currently supports **all** features of Ruby's Haml other than attribute
methods and multiline content.

### The following features of Ruby's Haml are supported in Lua Haml:

* Options: escape\_html, format, autoclose, encoding, suppress_eval, attribute\_wrapper
* Plain text
* Escapes
* HTML elements
* Emulated Ruby-style attributes
* HTML-style attributes
* Classes and id's (. and #)
* Implicit div elements
* Self-closing tags
* Doctypes and XML prologs
* Haml comments
* Code evaluation
* Emulated Ruby-style string interpolation ("#{var}")
* Running Lua
* Lua blocks
* Whitespace preservation (via filter)
* Filters: plain, javascript, preserve, escaped, lua, markdown, css, custom, cdata
* Partial templates. Lua Haml provides a simple default partial implementation,
  which can be overridden by frameworks as they see fit.
* HTML comments
* Conditional comments
* Escaping HTML
* Unescaping HTML
* Boolean attributes
* Whitespace removal
* Whitespace preservation (implicit for pre/textarea)

### To do

* Multiline content is the only feature left on my TODO list. I'll probably
  finish it later tonight.

The following features of Ruby's Haml may eventually be implemented but are low
priority:

* Attribute methods - This feature significantly complicates the already
  complicated task of parsing tag attributes. Also, it would have to be added to
  Ruby-style attributes which are discouraged in Lua-Haml, or the creation of a
  Lua-specific attribute format, which I don't want to add.
* Helpers - Since Lua has functions as first-class values, you can add functions
  to the locals table. In this case Lua the language provides something missing
  from Ruby, so there's no real need to add anything specific to Lua-Haml.
* Object reference - This feature is idiomatic to the Rails framework and
  doesn't really apply to Lua.
* Ugly mode - Because of how Lua Haml is designed, there's no performance
  penalty for outputting indented code. So there's no reason to implement
  this option.
* Encoding comment declarations - This is Ruby 1.9 specific and not needed for
  Lua.

To see an example of what you can do with the currently supported features, view
the "currently supported language" template in the spec directory.

## Getting it

Install using LuaRocks:

    luarocks install luahaml --from=http://luarocks.org/repositories/rocks-cvs/

Don't be put off by the "CVS" in the URL, this will install the latest Lua Haml
from the stable branch on Github.


## Hacking it

The [Github repository](http://github.com/norman/lua-haml) is located at:

    git://github.com/norman/lua-haml.git

To run the specs, you should also install Telescope:

    luarocks install telescope --from=http://luarocks.org/repositories/rocks-cvs/

You can then run them using [Tlua](http://github.com/norman/tlua), or do

    tsc `find . -name '*_spec.lua'`

## Bug reports

Please report them on the [Github issue tracker](http://github.com/norman/lua-haml/issues).

## Author

[Norman Clarke](mailto://norman@njclarke.com)

## Attributions

Some of the sample files in test/samples were taken from [Ruby's
Haml](http://github.com/nex3/haml/).

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
