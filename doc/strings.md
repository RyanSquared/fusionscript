# FusionScript &mdash; String Library

Strings on the Lua VM automatically have a metatable set tot hem which is
accessible using `getmetatable("");`. This metatable allows for adding a
universal metamethod to all strings. This allows adding additional operators
to strings, which is done using this library.

### _metamethod_ string % string _input_

Returns the string formatted with _input_. Similar to using `string.format`.

### _metamethod_ string % table _input_

Returns the string formatted with the unpacked variables of _input_. Similar to
`string:format(unpack(input));`