# FusionScript &mdash; Error Handling

Error classes themselves will only generate an error if passed to either an
assertion function or error function; those functions can also be called with
most values or no value at all. Error classes can be extended upon to create
further specified errors with more descriptive names and arguments.

## Functions

Functions are defined in the `core.error` module and should be either included
or destructured before using in an application. Unless explicitly stated, these
functions will NOT return.

### _function_ error(_errorObject_)

Generates an error based on the string representation of an object. If the
object fails to produce a string representation (for example, by overwriting
the __tostring metamethod with an erroring version) or an object is not passed,
instead, the string "error();" will be used.

### _function_ assert(_test_, _errorObject_, _..._) -> _test_, _errorObject_, _..._

If _test_ evaluates to a falsy expression, an error is called using the object
passed to the assertion function. If not, all values - including the test, the
second variable, and any other variables - are returned from the function.

## Error Classes

The `error` library (located in `core.error`) contains functions and classes
to assist with error production and handling; for instance, using the generic
class `Error`, as shown in the example below, can produce any error message
the developer wants. However, there's also a way to design your own error
messages based off extending the class, which will also be shown in the example
below.

```fuse
/* ::TODO::
 * The example in this code example is just for testing
 * and will not actually run as of 9/10/2016
 */

local {Error} = require("core.error");
print(Error("Goodbye World!"));

/* Error: "Goodbye World!" */

new ExampleError extends Error {
    __new(message1, message2)=>
        @message1, @message2 = message1, message2;
    __tostring()=>
        return "%s: %q, %q" % {@__name, @message1, @message2};
}

print(ExampleError("Hello", "World"));

/* ExampleError: "Hello", "World" */
```

### Implemented Error Classes

```
Error
\- TypeError
```

### _class_ Error(string _errorMessage_) -> _object_

Base class for all errors; you can use this class if you want to provide a
simple, generic error that takes an optional string as a descriptive argument.

### _class_ TypeError(string _expected_, _actual_) :: Error -> _object_

Error used when an improper type is given to a function or operation.