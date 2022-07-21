---
title: Fibonacci Example
---

{% capture source %}{% include examples/fib/fib.aum %}{% endcapture %}
{% capture compile %}{% include examples/fib/compile.sh %}{% endcapture %}
{% capture output %}{% include examples/fib/output.txt %}{% endcapture %}

Calculates the _n_-th [Fibonacci number][fib].

Code:

```austral
{{ source }}
```

Compile:

```bash
{{ compile | strip }}
```

Output:

```
{{ output | strip }}
```

[fib]: https://en.wikipedia.org/wiki/Fibonacci_number
