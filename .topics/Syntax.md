# FusionScript &mdash; Syntax

**Note:** FusionScript is a language built off C-like syntax running on the Lua
VM. As such, FusionScript could be seen as a variation of Lua with syntax made
to look like C. Eventually, syntax could be added in to make the language less
like Lua and (possibly) more like C or other languages.

**Note:** This document is not meant to act as a tutorial and will probably be
very difficult to understand unless you have at least moderate knowledge in Lua
and know the basic syntax of Lua, C, and Python.

## Literals

There are seven literals - excluding functions - in FusionScript: Numbers,
strings, booleans, `nil`, tables, ranges, and patterns.

### Numbers

Numbers are either a float or an integer and can be written in either base10 or
base16. In base10, they should be preceded with a `-` if they are negative. In
base16, they should be preceded with a `-` if negative, followed by a `0x` to
signal that the number is in base16. Base10 numbers can be written using
scientific notation, with an `E` or `e` followed by optionally a `-` or `+`,
then followed by the power. Because numeric expressions are evaluated during
compilation, `1000` is directly equivalent to `1E+4`. Base16 is written in
the same way, using `P` and `p` instead of `E` and `e`. There is no difference
in case for the scientific notation character.

### Strings

There are two kinds of strings in FusionScript. The first kind is a quotation
mark (`"`) bound string. These strings can include escape codes (`\n`, `\t`,
`\"`, et cetera). The second kind of string is bound with apostrophes (`'`) and
can't include escape codes, including `\'`. Literal strings followed by another
literal string are automatically concatenated onto each other. For example,
`"hello" 'wor\ld'` produces a string `"hello wor\\ld"`.

If string interpolation is **not** used with literal-string concatenation, the
compiler will automatically compile the strings. Otherwise, the compiler tries
it's best to compile as many "full" strings as possible. For instance, when
trying to compile `"#{hello} Wor" 'ld!'`, the compiler may produce instructions
to interpolate the variable `hello`, then the string `"World!"`. 

### Booleans

Booleans are either true or false. They have literal representations of `true`
and `false`. `true` by itself will pass a conditional state or expression while
`false` will not. Booleans can be negated using the `!` operator and any value
(including nil) can be converted to a boolean using `!!value`.

### nil

Nil is considered a value to be used when no other compatible value exists; it
is the value that represents the lack of value. Along with `false`, it is one
of two values that will not pass a conditional statement or expression.

### Tables

Tables are the native data structure that all data structures in FusionScript
can be built off of. Tables are implemented via a hashmap and can use any value
excluding nil as an index. They are implemented using a sequence of comma
delimited assignment fields between curly brackets. Fields can be any of three
things &mdash; an expression; a square-bracket-bound expression, `=`, and an
expression; or a variable name, `=`, and an expression.

```fuse
{
    5,
    [true] = 7,
    asdf = "peanut butter"
}
```

### Ranges

Ranges are a quick way to make an iterator, like a numeric `for` loop. They
don't exist in Lua and require the `using itr;` statement somewhere before the
range is constructed to be used. The syntax for ranges is simple: a _start_, a
_stop_, and optionally a _step_ separated with two semicolons.

```fuse
using itr;
for (i in 1::10::2)
    print(i); -- odds from 1 to 10
```

### Patterns

Patterns use the LPeg `re` module to provide a quick way to make LPeg patterns
without having to manually type out `re.compile()`. They're not like "normal"
regex (see [here](www.inf.puc-rio.br/~roberto/lpeg/re.html) for more info on
why) but still provide a powerful interface to matching text. Similar to the
range syntax, patterns require a `using re;` statement.

```fuse
using re;
print(/{[A-Za-z]+}/:match("test"))
```

## Expressions

Expressions are written using Lisp-like polish notation:

```fuse
a = (+ 1 2);
print((== a 12));
```

Expressions can take either one or two values and (possibly) produces a result
from the values. Unary expressions take one variable with an operator to the
left; binary expressions take two variables with an operator in the middle of
the two.

All bitwise operators automatically convert all values to integers before
evaluating and therefore return an integer.

### Unary Expressions

* `!` &mdash; Boolean not: Any truthy value becomes false, any falsy
value becomes true
* `#` &mdash; Length operator: Returns the length of a string or highest set
index of a table
* `-` &mdash; Unary decimal negation: Equivalent to `-1 * value`
* `~` &mdash; Unary bitwise not

### Binary Expressions

**Arithmetic Operators**

* `+` &mdash; Addition
* `-` &mdash; Subtraction
* `*` &mdash; Multiplication
* `/` &mdash; Division
* `//` &mdash; Floor division
* `%` &mdash; Modulo
* `^` &mdash; Exponent / Power

**Bitwise Operators**

* `&` &mdash; Bitwise and
* `|` &mdash; Bitwise or
* `~` &mdash; Bitwise exclusive or
* `>>` &mdash; Right shift
* `<<` &mdash; Left shift

**Relational Operators**

* `==` &mdash; Equality
* `!=` &mdash; Inequality
* `<` &mdash; Less than
* `<=` &mdash; Less than or equal to
* `>` &mdash; Greater than
* `>=` &mdash; Greater than or equal to

**Logical Operators**

* `&&` &mdash; And: Return true if left side and right side are truthy
* `||` &mdash; Or: Return true if left side or right side are truthy

**Concatenation**

* `..` &mdash; Concat: Append the right side string to the left side string
  - **Note:** Numbers will be converted to a string if either operator is
  a string.

### Ternary Expression

The `?:` operator is the only operator that can currently be used in with a
ternary expression; it works like it would in C but requires a `using ternary;`
statement before the line.

## Names

Names are how you access a variable. You can use any name that starts with an
alphabetical character or an underscore (`_`), then optionally followed by
additional alpha**numeric** characters or underscores. In the context of a
class, it is acceptable to use `@` at the start of a variable to access the
attribute stored in that class with that variable name. For example, `@value`
translates to `self.value`.

You can also index names (as seen above with `self.value`) by providing either
a literal string, in the case of `name.attribute`, or by using variable index
with brackets (`name["attribute"]`, `name[1]`, or `name[print]`). You can use
any non-nil and non-NaN value as an index for a table. Additionally, you can
chain indexing (`name["value"]["valuetoo"]`).

**Note:** Literal indexing is the same as variable indexing in the case of
strings. For example, `name["value"]` is equivalent to `name.value`. However,
`name.value` is **NOT** equivalent to `name[value]`, as `value` might not
equal `"value"`.

## Comments

Comments are started with `--` and end at the end of the line. They do not act
as a statement and therefore can be used inside of a statement.

## Inline Statements

FusionScript is a language based off statements. There are two kinds of
statements used in FusionScript &mdash; block statements and inline statements.
Inline statements must be suffixed with a semicolon (`;`), as with many other
programming languages. Logical blocks will be covered later in the document.

### `using`

The `using` keyword will import a module from the standard library (assuming
FusionScript is installed with the standard library) that can extend the
functionality of the language. Some examples:

- `using class;`: Import the `class` stdlib module as a local variable; this
can be used with the [`class`](#class-definitions) keyword.
- `using fnl;`: Import the `functional` stdlib as `fnl`; adds support for
the iterators `map` and `filter` as well as functions such as `reduce`.
- `using itr;`: Does the same thing as `using fnl;` but with the `iterable`
library (localized as `itr`).
- `using *;`: Load all available syntax extensions.

### Function Calls

Function calls can be one of the simplest statements. Functions consist of a
name which accesses a variable, followed by an opening parenthesis, an
expression list, and a closing parenthesis. The function call must be followed
by a semicolon (`;`).

```fuse
print("Hello World!");
io["write"]("Hello World!\n");
```

### Assignment and Destructuring

#### Valid Names

Valid names for assignment are any alphabetical character or a _, followed by
a sequence of any alphanumeric character or a _. Variable names must **NOT** be
the same as a keyword unless the case is not the same.

Variables used in classes may also be prepended with `@` to access either the
class itself (if the function is called using the class instead of an instance)
or the current instance of the class.

---

Assignment is done by assigning a list of values to a list of names. There can
be any number of names or values. Functions can be defined as local to the
current scope by preceding them with the word `local`. Because functions are
first-class values, a variable can hold them as a value.

```fuse
x = 5;
y = true;
z, a = x, y;
b = print;
local asdf = b;
```

---

Destructuring is a quick way to take items from a table and assign them to
either the local or environment scope. Destructuring can allow importing
functions from a module or table to allow bypassing indexing the module every
time the function is needed.

```fuse
local {print, write} = io.stdout;
print("Hello World!");
```

---

### return and break

`return` and `break` are keywords that act as a standalone statement. The
return statement is used to either return a value from a function or return a
value from a module in the event the file is being used as a module. The break
statement is used to escape a loop, such as a `while` loop or a `for` loop.

### yield

The `yield` keyword acts similar to `return` except it only works when using
[asynchronous functions](#asynchronous-functions). It also doesn't completely
stop the function - unlike `return` - but instead continues as if nothing had
changed when the coroutine is resumed.

## Block Statements

Block statements are any statements that can but might not be forced to include
a list of statements at least once in the form of a block. Blocks are bound
using curly brackets and exist as a statement by themselves. If a block only
consists of one statement, it is optionally acceptable to remove the braces
surrounding the statement, as shown in below examples.

```fuse
{
    local x = 5;
    print(x); -- 5
}
print(x); -- nil, locals don't exist out of a block
```

### Loops

Two kinds of loops are allowed in FusionScript: while loops and for loops.
`while` loops run as long as a condition is met and `for` loops run as long
as an item exists to be examined.

While loops require an expression and a statement in order to run. The loop
runs as long as the expression evaluates to true. The expression is written
using the Lisp-like polish notation ([see above](#expressions)).

```fuse
local x = 0;
while (< x 5) {
    x = (+ x 0.5);
    print(x);
}
```

The first kind of for loop, the numerically based for loop, runs as long as
there is a number that is not at or above the requirement. This is one of few
statements that don't follow the polish notation due to the different syntax.

```fuse
for (i=1, 5)
    print(i);
for (i=5, 1, -1)
    print(i);
```

In the above example, curly brackets were not used because there was only one
statement and not a statement list used for the loops.

The second kind of for loop uses an iterator to set values and, as long as
those values are set, the loop will continue to run. The values are set by
calling an iterator function and can be any amount of values &mdash; only the
first value needs to be set for the loop to continue.

This loop also does not use the polish notation format.

```fuse
for (line in io.lines("example.txt"))
    print(line);
```

For loops can also be written inside of a function call, as a way to iterate
over a set of objects and constantly call the same function with the output
of the iterator.

```fuse
print(line in io.lines());
```

In addition, you can assign a name to the input. This allows you to perform
operations on the returned values from the iterator.

```fuse
print(line:match("%d+") for line in io.lines());
```

This syntax can also be used to create "arrays" based off of an iterator:

```fuse
local array = {_G[k] for k in pairs(_G)}
local array_too = {v for k, v in pairs(_G)}
```

You can also assign manual indexes to values created from the generator
by using a syntax similar to non-generative table creation.

```fuse
local table = {[k] = v for k, v in pairs(_G)}
```

### If and Else statements

Code can be executed based on statements &mdash; FusionScript offers a C-like
`if` and `else` statement that can be used to evaluate code based on if a
condition is met.

```fuse
local x = 5
if (== x 5)
    print("This should work");
else
    print("We should -never- get here");
```

`if` statements can be chained to create a list of conditional tests; this was
implemented by having `else` accept a single statement and `if` itself be a
statement.

```fuse
local x = 2
if (== x 5)
    print("Logical error 1");
else if (== x 2)
    print("Yay, logic rules!");
else
    print("This shouldn't evaluate, ever.");
```

## Function Declaration

Function declarations are done by giving a parenthesis-bound list of arguments
which may or may not be pre-evaluated to a value (using `argument = value`)
followed by either `->` or `=>` and either a statement or a statement list.

```fuse
asdf(gh = "Hello World!")->
    print(gh); -- Hello World!
```

Using fat arrows (`=>`) gives access to a `self` operator - this operator is
used with object-oriented circumstances where a function (in the case of an
object, a method) might need access to the object which was indexed to call the
function.

```fuse
asdf()=>
    print(@text); -- whatever self.text is
```

### Asynchronous Functions

Functions can be made "asynchronous" by appending the function declaration
with the keyword `async`. This means that the function, when it is called,
will return a "wrapped" coroutine (see the Lua manual for more about how
coroutines work in general, and what a wrapped coroutine is). In short,
this means that - after the function is called once - it returns another
function (which can make the original function considered a "factory").
The new, returned function can then be called repeatedly as long as there
are `yield` statements - which can optionally take an expression to be
returned when calling the function produced by the factory.

```fuse
async madeIntoACoroutine()->
    for (i=1, 5)
        yield i;
x = madeIntoACoroutine();
while (true)
    print(x()); -- 1 | 2 | 3 | 4 | 5 | error
```

If a wrapped coroutine reaches the end of it's state and is called again,
the function will produce an error. When using a wrapped coroutine, it is
good practice to return something to "signal" the end of the coroutine.
The variable `nil`, to use the example of iterating, would be a good
variable as it is the default value if no value is signalled from `return`
inside of the function.

When using `nil` as the final `return` value - or not specifying any value -
this means that the function can be used as an iterator. The function
produced by the wrapped coroutine factory can be used in a `for` loop as long
as values are yielded.

```fuse
async madeIntoACoroutine()->
    for (i=1, 5)
        yield i;
-- use a `for` loop and not using return allows avoiding errors
for (i in madeIntoACoroutine())
    print(i); -- 1 | 2 | 3 | 4 | 5
```

## Class Definitions

Class definitions are a specific kind of statement that is like a table but
uses a different form of assignment. Assignment using names can be done like
traditional tables but function declaration can also be done. Classes start
with the word "class", optionally a name for the class, optionally "extends"
followed by a class to extend, and an opening curly bracket.

While inside of a class, methods can make use of the fat arrow operator to
access items and methods inside either the object or the class itself. In the
example, x and y are set to "hello" and "world" respectively and are then
accessed in the `print()` statement.

```fuse
{Object} = require("core");
class ExampleClass extends Object {
    x = "hello";
    y = "world";
    print()=> print("%s %s" % {@x, @y})
}
local example = ExampleClass();
example:print(); -- hello world
```

Classes and instances of the class themselves can include information about
the class or instance. For instance, when compiled with debug information,
accessing the `@class` variable should print out the name of the class, the
arguments for the constructor, the file the class was defined in, and the
line in the file the class was defined on. There's also `@__tostring` for
most class instances (where `__tostring()` is not defined).

```fuse
class ExampleClass extends Object {
    print()=>
        print("<%s>() => %s" % {ExampleClass, @})
}
(ExampleClass()):print() -- <ExampleClass(){example.fuse#1}> => ExampleClass()
```

If a certain method is needed somewhere in the inheritance chain, it can be
accessed before the method call by using angle brackets surrounding the class
for which to call the method. If there is only one instance of the method, it
is not required to use this format to call the method.

```fuse
class ExampleClass extends Object {
    example_method()=> print("hi!")
}
class ExampleClassToo extends ExampleClass {
    example_method()=> print("hello!");
}
(ExampleClassToo()):example_method<ExampleClass>(); -- hi!
```

### Interfaces

Interfaces are a basic extension onto classes that essentially ensure that a
class has a certain method or value. If the class is not generated with any
value at all of the names in the interface, the class will fail to generate and
an error will be thrown.

```fuse
lfs = require("lfs");

interface IScope { descope; }

class UseDir implements IScope {
    __init(dir)=> {
        @old_dir = assert(os.getenv("PWD"), "missing directory");
        lfs.chdir(dir)
    }
    close()=> lfs.chdir(@old_dir);
}
```

Classes extended upon another class will still be able to use the method of the
previous class when using an interface. The methods do not have to be added
again to avoid errors.

```fuse
class UseDirAndPrint extends UseDir implements IScope {
    __init(dir)=> {
        self:__init<UseDir>(self); -- initialize in extended class
        print(dir);
    }
}
```
