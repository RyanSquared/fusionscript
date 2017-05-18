# FusionScript [![Build Status](https://travis-ci.org/RyanSquared/fusionscript.svg?branch=master)](https://travis-ci.org/RyanSquared/fusionscript)
The programming language of ultimate dankliness

**Warning:** This project is very unstable and possibly has many bugs.  If your
code does not compile, it is *very* likely a problem in the compiler or a
change in the language instead of your code. Please feel free to add an issue
if any errors arise that you believe were caused by the compiler.

## What is FusionScript?

FusionScript is a language that runs on the Lua runtime (currently, by
transpiling to Lua and then using a Lua interpreter) inspired by C++, Python,
and Lua. Eventually, FusionScript will compile to a modified Lua 5.3 bytecode
and run on a modified Lua VM.

FusionScript offers an improved runtime type checking system (that
checks between both native Lua types, as well as instances of a class) by using
the [standard library](/RyanSquared/stdlib)'s `assert.is()` method. Eventually,
runtime type checking may be implemented using syntax similar to Pythonic type
hints and checked using bytecode instructions.

FusionScript also has a class system, with the ability to inherit values from a
superclass as well as an "interface" system that when used (see below) will
ensure that classes implement certain methods. Below is an example that closely
mirrors the standard library's scope module:

```fuse
interface IScope { descope; with; }
class Scope {
	with(fn)=> {
		fn(self);
	}
}

-- Example:

local lfs = require("lfs");

class UseDir extends Scope implements IScope {
	descope()=> lfs.chdir(@old_dir);
	__init(directory)=> {
		@old_dir = lfs.currentdir();
		@dir = directory;
		lfs.chdir(directory);
	}
}

UseDir("/tmp"):with(\=> {
	File("thing.txt"):with(\file-> {
		file:write("Hello World!\n");
	});
});
```

There is also implemented an easier way to use generators / iterators using the
`async` and `yield` functions:

```
async gen_numbers(low = 1, high)->
	for (i=low, high)
		yield i;

for (number in gen_numbers(1, 10))
	print(number);
```

## Commands

### `fusion-ast`: Compile a file into an abstract syntax tree (AST).

This program will load a file and print out a syntax tree for the file. The
program will generate a syntax error and exit with error code `1` if a file has
a syntax error.

### `fusion-pkg`: Install and manage FusionScript packages

The `fusion-pkg` program offers a very simple wrapper around Git that offers
the ability to use Git URLs as well as GitHub repositories to clone a repo and
a simple way to upgrade all locally installed repos. The repos will be placed
in the `vendor` folder, which is automatically searched when `require()` is
invoked. There's two subcommands for `fusion-pkg`:

**`get`** - Clone a GitHub url (pattern `user/repository`) or a Git url,
pattern (`git+<url>`).

**`upgrade`** - Upgrade a locally installed package.

**`remove`** - Remove a locally installed package; url is the repository name.

### `fusion`: Run FusionScript files

The `fusion` program (which at the current time is an alias to `fusion-source`)
can load syntaxes from `.fuse` files, compile them, and run them. As of
02-12-2016, compiled syntax trees are **not** cached. In future releases,
either the syntax trees or the compiled Lua output might be cached to allow
faster responsiveness when loading a program.

### `fusion-source`: Run FusionScript with the Lua VM

The `fusion-source` program compiles FusionScript files at runtime and runs
them using the same Lua VM. This means that running `fusion-source` will NOT
produce the same output as `fusionc-source` then running the generated file
with `lua`.  This could leave undesired side effects from `lpeg`, `fusion`,,
and `luafilesystem` libraries. However, the libraries themselves should not
edit the global state and only remain in the `package` table.

There are two command line flags that can be used with the `fusion-source`
program:

**`--package`** - Load the `main` module of the supplied `package` argument and
exit. This is somewhat similar to the Python `-m` flag.

**`--metadata`** - Load the `metadata` module of the supplied `package`
argument and print out the compatible information. Acceptable fields are
documented [here](https://github.com/ChickenNuggers/FusionScript/wiki/Modules).

The `fusion-source` interpreter also makes it so the `using` keyword isn't
required for loading syntax extensions. If the target audience for a script is
intended to not use `fusionc-source` to compile to Lua, it is suggested to not
use the `using` keyword.

### `fusionc`: Compile FusionScript

The `fusionc` will use whatever alias is currently in place as the compiler.
Use the documentation for the alias instead of this one to learn more about how
the compiler works. The default compiler as of 01-12-2016 is `fusionc-source`.

### `fusionc-source`: Compile FusionScript to Lua

The `fusionc-source` compiler can take FusionScript files and compile them to
formatted Lua source. Because the compilation is from source to source, some
things may look awkwardly formatted when compiled. As of 01-12-2016, there is
no way to automatically compile FusionScript code to Lua bytecode.

There's a single command line flag that allows the output of the parser to be
printed to the standard output, which is `-p`.

## Examples

### Hello World

```
print("Hello World!\n");
```

### Factorial

```
factorial(n)->
    if (== n 0)
        return 1;
    else
        return (* n factorial((- n 1)));

print(tostring(factorial(5)));
```

### Account (from Lua Demo)

```
class Account {
    __new(balance = 0)=> {
        @balance = balance;
    }

    deposit(amount)=> {
        @balance = (+ @balance amount);
        return true;
    }

    withdraw(amount)=> {
        if (> amount @balance)
            return false;
        else {
            @balance = (- @balance amount);
            return true;
        }
    }

    balance()=>
        return @balance;
}

bob = Account(500); -- 500
bob:deposit(600);   -- 1100
bob:withdraw(1000); -- 100
assert(bob:withdraw(math.max)); -- errors
```

### Asynchronous Networking

```
-- ::TODO::
-- The example in this code example is just for testing
-- and will not actually run as of 9/9/2016

local {Async} = require("core.async");
local {TCPSocket, TCPServer} = require("core.async.net");


-- The server MUST be started before the asynchronization
-- due to the fact the client can attempt connecting before
-- the server is initialized.

server = TCPServer("localhost", 9999);

class ExampleAsyncApp extends Async {
    client()-> {
        socket = TCPSocket("localhost", 9999);
        socket:send("echo");
        print((== socket:recv(4) "echo"));
        socket:close();
    }

    server()-> {
        local client = server:accept();
        local input = client:recv(1024);
        client:send(input);
        client:close();
        server:close();
    }

    handler(errorMessage)=>
        error(errorMessage);
}

ExampleAsyncApp:run();
```

### Building

```sh
luarocks make --local
```
