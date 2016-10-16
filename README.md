# FusionScript
The programming language of ultimate dankliness

**Warning:** This project is considered volatile and should not be used unless
you know what you're doing; also, I have no clue how to write a programming
language so good luck figuring out what the hell I'm doing.

## Examples

### Hello World

```
/* ::TODO::
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

local {stdout} = io;
stdout:write("Hello World!");
```

### Factorial

```
/* ::TODO::
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

local {stdout} = io;

factorial(n)->
    if n == 0
        return 1;
    else
        return n * factorial(n-1);

stdout:write(tostring(factorial(5)));
```

### Account (from Lua Demo)

```
/* ::TODO::
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

new Account {
    __new(balance = 0)=> {
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
/* ::TODO::
 * The example in this code example is just for testing
 * and will not actually run as of 9/9/2016
 */

local {Async} = require("core.async");
local {TCPSocket, TCPServer} = require("core.async.net");

/*
 * The server MUST be started before the asynchronization
 * due to the fact the client can attempt connecting before
 * the server is initialized.
 */

server = TCPServer("localhost", 9999);

new ExampleAsyncApp extends Async {
    client()-> {
        socket = TCPSocket("localhost", 9999);
        socket:send("echo");
        print(socket:recv(4) == "echo");
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
make
```
