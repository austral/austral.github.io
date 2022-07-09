---
title: Fibonacci Example
---

Calculates the _n_-th [Fibonacci number][fib].

```austral
module body Fib is
    function fib(n: Nat64): Nat64 is
        if n < 2 then
            return n;
        else
            return fib(n - 1) + fib(n - 2);
        end if;
    end;

    function main(): ExitCode is
        print("fib(10) = ");
        printLn(fib(10));
        return ExitSuccess();
    end;
end module body.
```

[fib]: https://en.wikipedia.org/wiki/Fibonacci_number
