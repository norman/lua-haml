# Lua Haml #

## About ##

Lua Haml is an in-progress implementation of the [Haml](http://haml-lang.com) markup language for Lua.

A Haml language reference can be found [here](http://haml-lang.com/docs/yardoc/HAML_REFERENCE.md.html).

Lua Haml currently supports the main features of Ruby's Haml, and can be used for real work. However, many of the finer details of the language, some of them important, are still being implemented.

### Working features ###

The following features of Ruby's Haml are working in Lua Haml:

* Options: format, autoclose, encoding
* Plain text
* Escapes
* HTML elements
* HTML-style attributes
* Classes and id's (. and #)
* Implicit div elements
* Self-closing tags
* Doctypes and XML prologs
* Haml comments
* Code evaluation
* Running Lua
* Lua blocks
* Whitespace preservation (via filter)
* Filters: plain, javascript, preserve, custom

### To do ###

The following feautes of Ruby's Haml are not yet working in Lua Haml:

* Options: escape\_html, suppress\_eval, attr\_wrapper, preserve
* Ruby-style attributes
* Attribute methods
* Boolean attributes
* Whitespace removal
* Object reference
* HTML comments
* Conditional comments
* Whitespace preservation (implicit)
* Code interpolation
* Escaping HTML
* Unescaping HTML
* Filters: cdata, escaped, lua, markdown
* Multiline content
* Helpers

To see an example of what you can do with the currently supported features, view the "currently supported language" template in the spec directory.

I probably won't implement Sass for a while yet, possibly never. However if I do implement it, it will definitely be as a separate project.

### Project goals ###

* Support the same Haml language as Ruby Haml with no unecessary changes. Lua Haml should just be Haml, with no embracing and extending.
* Allow some tiny changes to make Haml more comfortable for Lua; i.e., "--" for comments in addition to "#", and Lua tables as attributes.
* Include a cache for compiled templates.
* Help with and contribute to other Haml implementations.
* Since Lua is designed to be embeddded, develop with an architecture that allows for reasonably easy support for using Haml with other languages (Ruby, PHP, Perl, Python, etc.).

## Playing around with it ##

The command line utility in `bin/luahaml` can be used to exercise most of the functionality of Luahaml. To get it running, you need to install Luahaml's dependencies, which are:

* Lua 5.1
* Luarocks
* LPeg

## Author ##

[Norman Clarke](mailto://norman@njclarke.com)

## Attributions ##

Some of the sample files in test/samples were taken from [Ruby's Haml](http://github.com/nex3/haml/).

## License ##

The MIT License

Copyright (c) 2009 Norman Clarke

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
