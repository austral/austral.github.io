---
title: Basic Types
---

This section describes Austral's basic built in types.

# The Unit Type

The `Unit` type is the simplest type: it has a single value, the constant `nil`.

```austral
let unit: Unit := nil;
```

This is the equivalent of C's `void`: functions which don't return anything
useful can return `nil`:

```austral
function foo(): Unit is
    return nil;
end;
```

# Booleans

The built in `Bool` type has two values: the constants `true` and `false`. `if`
and `while` statements require boolean arguments, there are no implicit type
conversions or "truthy" values in Austral.

```austral
let t: Bool := true;
let f: Bool := false;

if t then
    printLn("true!");
else
    printLn("false!");
end if;
```

The `not`, `and`, and `or` operators do what you expect. If `a` and `b` are
expressions of type `Bool`, you can write:

```austral
not a
a and b
a or b
a and (not b)
```

Just as with arithmetic, there is no operator precedence for logical operators
in Austral: any expression beyond one level has to be fully parenthesized:

```austral
-- Not valid:
a and b and c and d
-- Valid:
a and (b and (c and d))
```

# Integers

The following are Austral's built-in integer types:

|  Name   |        Width        | Signedness |
| ------- | ------------------- | ---------- |
| `Nat8`  | 8 bits              | Unsigned.  |
| `Nat16` | 16 bits.            | Unsigned.  |
| `Nat32` | 32 bits.            | Unsigned.  |
| `Nat64` | 64 bits.            | Unsigned.  |
| `Int8`  | 8 bits.             | Signed.    |
| `Int16` | 16 bits.            | Signed.    |
| `Int32` | 32 bits.            | Signed.    |
| `Int64` | 64 bits.            | Signed.    |
| `Index` | Platform-dependent. | Unsigned.  |


`Nat` types are **unsigned**, they are natural numbers: they start at
zero. `Int` types are **signed**, they are integers: they can hold negative and
positive values. The number is the width or size of the integer in bits.

The `Index` type is a special case: it's the type of array indices, and
equivalent to C's `size_t` type.

The minimum and maximum values of each type are:

|  Name   | Minimum                                      | Maximum                                       |
| ------- | -------------------------------------------- | --------------------------------------------- |
| `Nat8`  | 0                                            | 2<sup>8</sup>-1 = 255                         |
| `Nat16` | 0                                            | 2<sup>16</sup>-1 = 65,535                     |
| `Nat32` | 0                                            | 2<sup>32</sup>-1 = 4,294,967,295              |
| `Nat64` | 0                                            | 2<sup>64</sup>-1 = 18,446,744,073,709,551,615 |
| `Int8`  | -2<sup>7</sup> = -128                        | 2<sup>7</sup>-1 = 127                         |
| `Int16` | -2<sup>15</sup> = -32,768                    | 2<sup>15</sup>-1 = 32,767                     |
| `Int32` | -2<sup>31</sup> = -2,147,483,648             | 2<sup>31</sup>-1 = 2,147,483,647              |
| `Int64` | -2<sup>63</sup> = -9,223,372,036,854,775,808 | 2<sup>63</sup>-1 = 9,223,372,036,854,775,807  |
| `Index` | 0                                            | _Platform-dependent._                         |

The usual arithmetic operators are defined. If `a` and `b` are variables of _the same_ integer type, you can write:

```austral
-a
a + b
a - b
a * b
a / d
```

Two notes:

1. First, Austral has no arithmetic precedence: any arithmetic operation (or any
   binary operation, including Boolean and comparison operations) deeper than
   one level has to be fully parenthesized. The following _will not_ parse:

   ```austral
   a - f(b - c/d) / e
   ```

   Instead:

   ```austral
   a - (f(b - (c/d)) / e)
   ```

2. Second, Austral has no implicit type conversions. If you need to do
   arithmetic with types having different sizes and signedness, you have to
   convert them first.

# Note on Overflow

Austral's built-in arithmetic operators abort on overflow. If you want modular
semantics, or you don't want to pay the performance cost of overflow checking
_and_ can prove that overflow won't happen, you can use the modular arithmetic
methods:

```austral
modularAdd(a, b)
modularSubtract(a, b);
modularMultiply(a, b);
modularDivide(a, b);
```

# Floating-Point Numbers

Austral has two built-in floating-point types: `Float32` is equivalent to C's
`float` and `Float64` is equivalent to C's `double`. The arithmetic operators
work on floats as well, but the usual restrictions apply: you can't mix
different float types, or floats and integers, in the same expression, you have
to convert them.

# Fixed Arrays

Fixed arrays are the type of (usually statically allocated) arrays. String
literals are fixed arrays of bytes:

```austral
let str: FixedArray[Nat8] := "Hello, world!";
```

The size of a fixed array can be obtained with the built-in `fixedArraySize`
function, which takes a fixed array and returns a value of type `Index`:

```austral
let size: Index := fixedArraySize("Hello, world!");
```

Array elements can be accessed through the index operator:

```austral
let str: FixedArray[Nat8] := "Hello, world!";
printLn(str[0]);
```

If an array index is out-of-bounds, the program aborts.

### Navigation

- [Back](/tutorial/modules)
- [Forward](/tutorial/functions)
