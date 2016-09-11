# FusionScript &mdash; Array Classes

Arrays are implemented by replacing the `__index` and `__newindex` metamethods
of a table with respective methods to help improve or restrict the input
allowed into a table.

## Array Classes

```
Array
\- LimitedArray
Queue ::TODO::
|- FIFO (First In, First Out)
\- FILO (First In, Last Out)
```

### _class_ Array() -> _object_

Creates an array which can only use integer-based indexes but is not based on a
sequence like an FIFO or queue would be.

::TODO:: implement append, prepend, insert, remove

### _class_ LimitedArray(integer _limit_ = 500) :: Array -> _object_

Creates an array like `Array()`, but after reaching _limit_ * 110%, remove 10%
of the entries from the beginning to make roomf or new entries. _limit_, if not
given, will be set to 500.

Because LimitedArray removes items from the beginning, in this case, the items
entered will automatically be put into a sequence; if the index used when
making a new index is greater than the current highest index, the index will
instead be set to the current highest index, plus one.

### **user-defined** _method_ LimitedArray:handle_output(_item_)

This is a user defined function to handle the output of a LimitedArray when the
sequence is higher than 110% the defined limit. Each item starting from the
beginning will be passed to this function as the first parameter (_item_).