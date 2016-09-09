# FusionScript
The programming language of ultimate dankliness

**Warning:** This project is considered volatile and should not be used unless
you know what you're doing; also, I have no clue how to write a programming
language so good luck figuring out what the hell I'm doing.

## Examples

### Hello World

```
/*
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

local {stdout} = require("core.async.io");
stdout:write("Hello World!");
```

### Factorial

```
/*
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

{stdout} = require("core.async.io");

factorial(n)->
    if n == 0
        return 1;
    else
        return n * factorial(n-1);

stdout:write(tostring(factorial(5)));
```

### Account (from Lua Demo)

```
/*
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

new Account {
    new(balance = 0)=> {
        @balance = balance;
    }

    deposit(amount)=> {
        @balance += amount;
        return true;
    }

    withdraw(amount)=> {
        if (amount > @balance)
            return false;
            /* one-line statement, no brackets */
            /* comments don't count towards lines */
        else {
            @balance -= amount;
            return true;
        }
    }

    balance()=>
        return @balance;
}

bob = Account(500); /* 500  */
bob:deposit(600);   /* 1100 */
bob:withdraw(1000); /* 100  */
assert(bob:withdraw(math.max)); /* errors */
```

### Asynchronous Networking

```
/*
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

local {Async} = require("core.async");
local {TCPSocket, TCPServer} = require("core.async.net");

new ExampleAsyncApp extends Async {
    priority = {"server", "client"};

    client()-> {
        socket = TCPSocket("localhost", 9999);
        socket:send("echo");
        print(socket:recv(4) == "echo");
        socket:close();
    }

    server()-> {
        server = TCPServer("localhost", 9999);
        local client = server:accept();
        local input = client:recv(1024);
        client:send(input);
        client:close();
        server:close();
    }
}

ExampleAsyncApp:run();
```

## Compiling Utilities Library

**Please note** that this method is proven to work on Linux systems only. The
commands used should work fine as long as you have the following programs
installed:

 * cURL (`curl`)
 * GNU Compiler Collection (`gcc`)
 * Linux compatible archiving tool (`tar`)

```sh
curl https://www.lua.org/ftp/lua-5.3.2.tar.gz | tar -xvz && mv lua-5.3.2 lua
```
