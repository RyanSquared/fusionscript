# FusionScript &mdash; Syntax

**Note:** FusionScript is a language built off C-like syntax running on the Lua
VM. As such, FusionScript could be seen as a variation of Lua with syntax made
to look like C. Eventually, syntax could be added in to make the language less
like Lua and (possibly) more like C or other languages.

## Literals

There are five literals - excluding functions - in FusionScript: Numbers,
strings, booleans, `nil`, and tables.

### Numbers

Numbers are either a float or an integer and can be written using several
formats: `1234`, `12.34`, `.34`, `12e+34`, `0xB00B`.

### Strings

There are two kinds of strings in FusionScript. The first kind is a quotation
mark (`"`) bound string. These strings can include escape codes (`\n`, `\t`,
`\"`, et cetera). The second kind of string is bound with apostrophes (`'`) and
can't include escape codes, including `\'`.

### Booleans

Booleans are either true or false. They have literal representations of `true`
and `false`. `true` by itself will pass a conditional state or expression while
`false` will not.

### nil

Nil is considered a value to be used when no other compatible value exists; it
is the value that represents the lack of value. Along with `false`, it is one
of two values that will not pass a conditional statement or expression.

### Tables

Tables are the native data structure that all data structures in Lua can be
built off of. Tables are implemented via a hashmap and can use any value
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

## Expressions

Expressions can take either one or two values and (possibly) produces a result
from the values. Unary expressions take one variable with an operator to the
left; binary expressions take two variables with an operator in the middle of
the two.

All bitwise operators automatically convert all values to integers before
evaluating and therefore return an integer.

### Precedence

Following Lua semantics, the precedence for operators is as follows, from the
lowest priority to the highest priority:

* `||`
* `&&`
* `<` `>` `<=` `>=` `!=` `==`
* `|`
* `~` (binary)
* `&`
* `<<` `>>`
* `..`
* `+` `-`
* `*` `/` `//` `%`
* `!` `#` `-` `~` (unary)
* `^`

Parenthesis can be used to change precedence of an expression. The `..` and `^`
operators are right associative while all other binary operators are left
associative.

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

## Inline Statements

FusionScript is a language based off statements. There are two kinds of
statements used in FusionScript &mdash; block statements and inline statements.
Inline statements must be suffixed with a semicolon (`;`), as with many other
programming languages. Logical blocks will be covered later in the document.

### Function Calls

Function calls can be one of the simplest statements. Functions consist of a
name which accesses a variable, followed by an opening parenthesis, an
expression list, and a closing parenthesis. The function call must be followed
by a semicolon (`;`).

```fuse
print("Hello World!");
io["write"]("Hello World!\n");
```

### Assignment, Destructuring, and Reassignment

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

Reassignment is a shorthand way to perform an operation on a variable without
using the variable itself. For example, you could increment or double a
variable without having to reference the variable more than once. Reassignment
is done by preceding the assignment sign (`=`) with a binary operator.

```fuse
local x, y = 4, "Hello";
x /= 2;
x *= 5;
y ..= " world!";
```

### return and break

`return` and `break` are keywords that act as a standalone statement. The
return statement is used to either return a value from a function or return a
value from a module in the event the file is being used as a module. The break
statement is used to escape a loop, such as a `while` loop or a `for` loop.

## Block Statements

Block statements are any statements that can but might not be forced to include
a list of statements at least once in the form of a block. Blocks are bound
using curly brackets and exist as a statement by themselves.

```fuse
{
    local x = 5;
    print(x); /* 5 */
}
print(x); /* nil, locals don't exist out of a block */
```

### Loops

Two kinds of loops are allowed in FusionScript: while loops and for loops.
`while` loops run as long as a condition is met and `for` loops run as long
as an item exists to be examined.

While loops require an expression and a statement in order to run. The loop
runs as long as the expression evaluates to true.

```fuse
local x = 0;
while (x < 5) {
    x += 0.5;
    print(x);
}
```

The first kind of for loop, the numerically based for loop, runs as long as
there is a number that is not at or above the requirement.

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

```fuse
for (line in io.lines("example.txt"))
    print(line);
```

Iterator-based for loops can be shortened using **forward assertion** which
is an iterator followed by the symbol `|>`, then followed by a function call.
The example above could be improved using this method.

```fuse
io.lines("example.txt") |> print();
```

### If and Else statements

Code can be executed based on statements &mdash; FusionScript offers a C-like
`if` and `else` statement that can be used to evaluate code based on if a
condition is met.

```fuse
local x = 5
if (x == 5)
    print("This should work");
else
    print("We should -never- get here");
```

`if` statements can be chained to create a list of conditional tests; this was
implemented by having `else` accept a single statement and `if` itself be a
statement.

```fuse
local x = 2
if (x == 5)
    print("Logical error 1");
else if (x == 2)
    print("Yay, logic rules!");
else
    print("This shouldn't evaluate, ever.");
```

## Function Declaration

Function declarations are done by giving a parenthesis-bound list of arguments
which may or may not be pre-evaluated to a value (using `argument = value`)
followed by either `->` or `=>` and either a statement or a statement list.

Using fat arrows (`=>`) gives access to a `self` operator - this operator is
used with object-oriented circumstances where a function (in the case of an
object, a method) might need access to the object which was indexed to call the
function. Fat arrows will be demonstrated in the below section over classes.

```fuse
asdf(gh = "Hello World!")->
    print(gh); /* Hello World! */
```

## Class Definitions

Class definitions are a specific kind of statement that is like a table but
uses a different form of assignment. Assignment using names can be done like
traditional tables but function declaration can also be done. Classes start
with the word "new", optionally a name for the class, optionally "extends"
followed by a class to extend, and an opening curly bracket.

While inside of a class, methods can make use of the fat arrow operator to
access items and methods inside either the object or the class itself. In the
example, x and y are set to "hello" and "world" respectively and are then
accessed in the `print()` statement.

```fuse
{Object} = require("core");
new ExampleClass extends Object {
    x = "hello";
    y = "world";
    print()=>
        print("%s %s" % {@x, @y});
}
local example = ExampleClass();
example:print(); /* hello world */
```