# KnightScript
KnightScript is a [Lua](https://lua.org/)-JS hybrid language that was designed to target [Knight](https://github.com/knight-lang). KnightScript using an optimizing compiler to compile directly to Knight. While KnightScript does require Lua for now, it will be self hosted in the future.

# Running
In order to run KnightScript, you must first install Lua. You can find standalone executables on the Lua [download](https://lua.org/download.html) page.

Compile a file named `example.kns`:
```
lua main.lua example.kns -o example.kn
```
For help:
```
lua main.lua -h
```

# Specification
The language specification in its entirety is available in [ebnf format](https://github.com/synt7x/knightscript/blob/main/knightscript.ebnf).

## Constants

KnightScript contains a few variables and functions that cannot be overwritten or monkey patched. These variables and functions consist of:

### Varibles
* `true`
    * Represents a truthy value.
* `false`
    * Represents a falsey value.
* `null`
    * Represents the absence of a value.
    * Is the automatic return value of functions that have no return statement.

### Functions
* **IO**
    * `print`
        * Called using `print(expression, ...)`.
        * Takes an infinite number of arguments and outputs each value in its string form with a trailing newline. If there is more than one parameter, each value is printed with a space inbetween.
        * Internally represents the `OUTPUT` function in Knight.
    * `write`
        * Called using `write(expression)`.
        * Takes one argument and outputs its value in its string form without a trailing newline.
        * Internally represents the `OUTPUT` function in Knight when called with a string ending with `\`.
    * `read`
        * Called using `read()`.
        * Takes no arguments and returns a line from `stdin`.
        * Internally represents the `PROMPT` function in Knight.
    * `prompt`
        * Called using `prompt(expression)`.
        * Takes one argument and outputs its string form without a trailing newline. It then returns the next line read from `stdin`.
        * Internally represents the `PROMPT` function in Knight when combined with an `OUTPUT` call.

        print|write|read|input|prompt|join|ascii|insert
* **Arrays**
    * `join`
        * Called using `join(array, expression)`.
        * Takes two arguments: one being the array to join into a string, and the other being the string value to use as a delimiter between each item.
        * Internally represents the `^` operation when combined with an array and string.
    * `pop`
        * Called using `pop(array)`.
        * Takes one argument and removes and returns it's first item. Directly modifies the array following the pop.
        * Internally represents assigning the array to the `]` operation on the array, and returns the `[` operation on the array.
    * `push`
        * Called using `push(array, value)`.
        * Takes two arguments: one being the array the value is being pushed to the beginning of, the other being the value being pushed into the array.
        * Internally represents the `+` operator with an array being combined into the boxed value.
    * `insert`
        * Called using `insert(array, value)`.
        * Takes two arguments: one being the array the value is being pushed to the end of, the other being the value being pushed into the array.
        * Internally represents the `+` operator with an array.
    * `length`
        * Called using `length(value)`.
        * Takes on argument and returns its length when converted to a string/list.
        * Internally represents the `LENGTH` function in Knight.
* **Other**
    * `random`
        * Called using `random(min, max)`
        * Extends `irandom` and is incomplete.
    * `irandom`
        * Called using `irandom()`.
        * Takes no arguments and returns a random positive integer with a size depending on your Knight implementation.
        * Internally represents the `RANDOM` function in Knight.
    * `ascii`
        * Called using `ascii(value)`.
        * Takes one argument and returns its ascii code if it is a string or its character if it is a number.
        * Internally represents the `ASCII` function in Knight.