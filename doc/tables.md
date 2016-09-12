# FusionScript &mdash; Table Library

The table library in the core VM isn't up to par with what most people expect
out of a standard library so some common functions have been added in a library
located at `core.table`; this library is a direct copy of the traditional table
library with some functions added on.

### _function_ table.join(table _native_, table _input_) -> _table_

Copy all values from the _input_ and replace the value at the respective index
in _native_ with the value from _input_. If no value currently exists at the
index in _native_, the value is put in without replacement.

### _function_ table.copy(table _input_) -> _table_

Create and return a shallow copy of the table _input_. Metatables are not
copied over.