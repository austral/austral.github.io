---
title: Declarations
---

## Constants

If `C` is an identifier, `T` is a type specifier, and `V` is a constant value,
then:

```
constant C : T := V;
```

Defines a constant named `C` of type `T` with a value of `V`.

## Renamed Types

If `T` is an identifier, and `S` is a type specifier, then:

```
type T = S;
```

Defines a type `T` that is the same as `S`. Note that this does not work like
type aliases in ML or Haskell: `T` and `S` are distinct types.

To create an instance of `T` from a value `v : S`, we have to use a `let`
statement:

```
let t : T := v;
```

This will work if:

1. The type `T` is defined in the current module.
2. The type `T` is public (not opaque) and was imported from another module.

This provides encapsulation. If `T` is an opaque type, modules that import it
cannot create instances of `T` through the `let` statement because they don't
know the definition of `T`.

## Records

A record is an unordered collection of values, called fields, which are
addressed by name.

If $R$ is an identifier, $\{R_0, ..., R_n\}$ is a set of identifiers, and
$\{T_0, ..., T_n\}$ is a set of type specifiers, then:

```
record R is
  R_0 : T_0;
  R_1 : T_1;
  ...
  R_n : T_n;
end
```

Defines the record `R`.

Unlike C, records in Austral are unordered, and the compiler is free to choose
how the records will be ordered and laid out in memory. The compiler must select
a single layout for every instance of a given record type.

The layout can be customized using a layout specification. For example:

```
record R is
  a : Natural16;
  b : Int8;
  c : FLoat32;

  pragma Layout(
     Field(b, 8),
     Padding(8),
     Field(a, 16),
     Field(c, 32)
  );
end
```

Will define a record `R` with the following layout:

```
| b (8 bits) | padding (8 bits) | a ( 16 bits) | c (32 bits) |
```

and a total size of 64 bits.

Record construction:

Given the record:

```
record Vector3 is
    x : Float32;
    y : Float32;
    z : Float 32
end
```

We can construct an instance of `Vector3` in two ways:

```
let V1 : Vector3 := Vector3(0.0, 0.0, 0.0);
let V2 : Vector3 := Vector3(
    x => 0.0,
    y => 0.0,
    z => 0.0
);
```

## Unions

Unions are like datatypes in ML and Haskell. They have constructors and,
optionally, constructors have values associated to them.

When a constructor has associated values, it's either:

1. A single unnamed value.
2. A set of named values, as in a record.

For example, the definition of the `Optional` type is:

```
union Optional[T : Type] is
  case Some(T);
  case None;
end
```

```
union Color is
  case RGB(red: Nat8, green: Nat8, blue: Nat8);
  case Greyscale(Nat8);
end
```

Union creation:

```
let O2 : Optional[Int32] := None();
let O2 : Optional[Int32] := Some(10);
let C1 : Color := RGB(10, 12, 3);
let C2 : Color := RGB(
    red => 1,
    green => 2,
    blue => 3
);
let C3 : Color := Greyscale(50);
```

## Functions

Examples:

```
function Fib(n: Natural): Natural is
    if n <= 2 then
        return n;
    else
        return Fib(n-1) + Fib(n-2);
    end if;
end
```

## Generic Functions

Examples:

```
forall (t : Type)
function Identity(x: T): T is
    return x;
end
```

## Type Classes

Examples:

```
typeclass Printable(T : Type) is
    method Print(value: T): Unit;
end
```

## Type Class Instances

Examples:

```
typeclass Printable(T : Type) is
    method Print(value: T): Unit;
end

instance Printable(Int32) is
    method Print(value: Int32): Unit is
        printInt(value);
    end
end
```
