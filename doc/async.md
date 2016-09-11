# FusionScript &mdash; Asynchronization

The Async library allows users to run coroutines that support the async
library as well as the cqueues library, which the library is built off of, at
almost the same time. When waiting on input, a coroutine yields to let other
coroutines process input if available. This can be useful for networking or
timed tasks.

**template** _class_ Async

This class is **not** to be used to return objects but should instead be used
to extend upon. The class itself has only one method and no values. Classes
extended upon this class should not be used as a constructor for objects and
instead should call the one method &mdash; `self:run()`.

_method_ Async:run() -> _LimitedArray(500)_

This method, when used in a class extended from `Async`, will take all methods
inside of the class, treating them as values, and wrap them as a coroutine
inside of a queue and then attempt to process all the functions until complete.
It is possible this function generates an infinite loop and might not return.

**user-defined** _method_ Async:handler(_error_)

This method is called whenever an error is found inside an asynchronous
function. The method will only be called when using the `run()` function.