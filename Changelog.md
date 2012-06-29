## 0.3.0 (NOT RELEASED YET)

* String interpolation now works with local variables.

* Fixed markup comment handling - previously LuaHaml didn't parse Haml inside
  comments, which was incorrect behavior.

* Fixed bug where when the last line of Haml was immediately preceded by a
  markup comment, then the line was not added to the buffer.

## 0.2.0 (2012-06-18)

* Added a __newindex function on to the metatable for Haml environments.
  (Thanks [Ross Andrews](https://github.com/randrews))

* Fix bug with mixed tabs and spaces
  (Thanks [Ross Andrews](https://github.com/randrews))

* Fix bug which prevented if/elseif/else from working properly

* Fall back to renderer's locals if no locals are passed to the `partial` function.

* Various small documentation fixes.


## 0.1.0 (2010-11-23)

First release.
