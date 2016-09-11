# FusionScript &mdash; Array Classes

Arrays are implemented by replacing the `__index` and `__newindex` metamethods
of a table with respective methods to help improve or restrict the input
allowed into a table.

## Array Classes

```
Array
\- LimitedArray
Queue
|- FIFO (First In, First Out)
\- FILO (First In, Last Out)
```

### _class_ Array() -> _object_

Creates an array which can only use integer-based indexes but is not based on a
sequence like an FIFO or queue would be.

### _method_ Array:insert(integer _key_, _value_)

Put _value_ in the array at position _key_. If _key_ is currently filled in,
the element at position _key_ will be moved down and _key_ will be replaced
with _value_.

### _method_ Array:remove(integer _key_) -> value

Remove the value at position _key_. If any items are above _key_, they will be
shifted downwards to fill _key_. If any value existed at _key_, the value will
be returned from the function.

### _method_ Array:append(_value_)

Add _value_ to the end of Array. Similar to `Array:insert(@size + 1, value);`.

### _method_ Array:prepend(_value_)

Prepend _value_ to the array. Similar to `Array:insert(1, value);`.

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

### _class_ Queue(integer _direction_) -> _object_

Returns a base class that implements a sequence-like structure; objects in the
data structure must be directly followed by another object with no "gaps".

### _table_ Queue.direction

* "fifo": 0x0; First in, first out.
* "filo": 0x1; First in, last out.

### _method_ Queue:peek(index) -> _value_

Checks the item at position _index_ in the array without having to remove the
item. This is similar to Queue[index] but offers a more "functional" format.

### _method_ Queue:push(value)

Appends a value _value_ to the end of the queue.

### _method_ Queue:pop() -> _value_

If _@direction_ is set to Queue.direction.fifo (0x0) then `Queue:pop()` will
return a value from the front of the queue. If _direction_ is set to
Queue.direction.filo (0x1) then `Queue:pop()` will return a value from the
end of the queue. If no values exist in the queue then no value will be
returned.

### _class_ FIFO() :: Queue -> _object_

Creates a Queue with the direction set to Queue.direction.fifo.

### _class_ FILO() :: Queue -> _object_

Creates a Queue with the direction set to Queue.direction.filo. 