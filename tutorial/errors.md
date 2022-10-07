---
title: Errors
---

This section of the tutorial describes Austral's approach to error handling.

We begin by describing what an error is, the different categories of errors, and
how Austral handles each of them.

# Categorizing Errors

Following [Sutter][sutter] and [Duffy][duffy], we divide errors into five
categories, from most to least severe:

1. **Physical Failure:** Pulling the power cord, destroying part of the
   hardware.

2. **Abstract Machine Corruption:** A stack overflow.

3. **Contract Violations:** Due to a mistake the code, the program enters an
   invalid state. This includes:

    1. An arithmetic operation leads to integer overflow or underflow (the
       contract here is that operands should be such that the operation does not
       overflow).

	2. Integer division by zero (the contract is the divisor should be non zero).

	3. Attempting to access an array with an index outside the array's bounds
       (the contract is that the index should be within the length of the
       array).

	4. Any violation of a programmer-defined precondition, postcondition,
	   assertion or invariant.

	These errors are bugs in the program. They are unpredictable, often happen
	very rarely, and can open the door to security vulnerabilities.

4. **Memory Allocation Failure:** `malloc` returns `null`, essentially. This
   gets its own category because allocation is pervasive, especially in
   higher-level code, and allocation failure is rarely modeled at the type
   level.

5. **Failure Conditions**. Things that aren't actually errors, but are rather
   situations you would encounter normally and have to be explicitly handled in
   the code. "File not found", "connection failed", "directory is not empty",
   "timeout exceeded".

The different error categories should be approached differently.

For **physical hardware failure**, there is little we can do except write code
that uses operating system APIs that provide ACID guarantees.

For **abstract machine corruption**, the solution is to crash the
program. Attempting to recover from so fundamental a failure provides endless
security vulnerabilities: it is likely that if the stack has overflown it is
because of an attack.

**Allocation failure** and **failure conditions** are not errors. As in Rust and
many modern languages, these should be modeled at the value level, using things
like option types.

Finally, **contract violations**. These are bugs in the program: if there is
unplanned arithmetic overflow, if there is a division by zero inside a data
structure where that shouldn't happen, if arrays are accessed out of bounds,
that's all an error in the program. And, importantly, _bugs are not
recoverable_, because recovery introduces its own security vulnerability
opportunities.

So Austral's solution is to crash the program by _aborting_. The built-in
`abort` function lets you do this in your own custom situations:

```austral
function division(dividend: Int64, divisor: Int64): Int64 is
    if divisor = 0 then
        abort("Division by zero error in division()");
    end if;
    return a / b;
end;
```

# Example: The Option Type

Austral's built-in `Option` type lets you model places where a value can either
be present or not. It is defined like this:

```austral
union Option[T: Type]: Type is
    case None;
    case Some is
        value: T;
    end;
end;
```

For example, imagine you have a linear type `Map[K, V]`. The function that
retrieves a value by key might have this signature:

```austral
generic [K: Free, V: Type, R: Region]
function get(mapref: &[Map[K, V], R], key: K): Option[V];
```

And you could use it like this:

```austral
let opt: Option[Int32] := get(&map, "postCount");
case opt of
    when Some(value: Int32) do
        print("postCount = ");
        printLn(value);
    when None do
        printLn("No value with the key `postCount`.");
end case;
```

# Example: The Either Type

Austral's built-in either type can be used to represent a case where you get
either an error value or a success value. It is defined like this:


```austral
union Either[L: Type, R: Type]: Type is
    case Left is
        left: L;
    case Right is
        right: R;
end;
```

[sutter]: https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0709r1.pdf
[duffy]: http://joeduffyblog.com/2016/02/07/the-error-model/

### Navigation

- [Back](/tutorial/type-constraints)
- [Forward](/tutorial/capability-based-security)
