---
title: Fibonacci Example
---

Calculates the _n_-th [Fibonacci number][fib].

```austral
module body Example.Fibonacci is
    function Fibonacci(n: Natural_64): Natural_64 is
        if n < 2 then
            return n;
        else
            return Fibonacci(n - 1) + Fibonacci(n - 2);
        end if;
    end;

    function Main(root: Root_Capability): Root_Capability is
        Fibonacci(30);
        return root;
    end;
end module body.
```

[fib]: https://en.wikipedia.org/wiki/Fibonacci_number
