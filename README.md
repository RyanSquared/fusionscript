# SunScript
The programming language of ultimate dankliness

**Warning:** This project is considered volatile and should not be used unless
you know what you're doing; also, I have no clue how to write a programming
language so good luck figuring out what the hell I'm doing.

## Compiling Utilities Library

**Please note** that this method is proven to work on Linux systems only. The
commands used should work fine as long as you have the following programs
installed:

 * cURL (`curl`)
 * GNU Compiler Collection (`gcc`)
 * Linux compatible archiving tool (`tar`)

```sh
curl https://www.lua.org/ftp/lua-5.3.2.tar.gz | tar -xvf
gcc -I. -Wall -pedantic -c -fPIC sun/assembler/util.c -o sun/assembler/util.o
gcc `pkg-config lua` -shared -o sun/assembler/util.so sun/assembler/util.o
```
