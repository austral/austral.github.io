---
title: Functions
---

Functions are the unit of code: they take a fixed set of arguments, and return a
value. There are no optional arguments.

# Defining Functions

Functions are defined with a `function` declaration:

```austral
function fib(n: Nat64): Nat64 is
    if n < 2 then
        return n;
    else
        return fib(n - 1) + fib(n - 2);
    end if;
end;
```

All functions have to return a value. When a function returns nothing useful
(the equivalent of a `void` function in C), you can return a value of the `Unit`
type:

```austral
function launchMissiles(): Unit is
    openSilo();
    launch();
    return nil;
end;
```

# Calling Functions

Function call syntax should be familiar, the function `fib` above can be called
with positional arguments:

```austral
fib(30)
```

or with named arguments:

```austral
fib(n => 30)
```
