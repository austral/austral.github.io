---
title: Type System
---

This section describes Austral's type system.

## Type Universes

Every concrete type belongs to a _universe_, which can be considered as the type
of a type.

There are two universes:

1. The universe of unrestricted types, denoted `Free`. Bindings with a type in
   the `Free` universe can be used any number of times.
2. The universe of affine types, denoted `Affine`. These are explained in the
   next section.

## Affine Types

A type `T` is affine if:

1. It contains another affine type. These types are called _structurally
   affine_.
2. Is it declared to be an affine type (see "Declaring Types"). These types are
   called _declared affine_.

To formalize the notion of "containment" in point 1.: a type `T` is said to
contain an affine type `U` (or, equivalently, a type parameter `U` of kind
`Type[Affine]`) if:

1. `T` is a rename of `U`.
3. `T` is a record, where at least one field contains `U`.
3. `T` is a union, where at least one field on one case contains `U`.

## Type Parameters

## Declaring Types

When declaring a type, we must state which universe it belongs to. This is so
that the programmer is aware of type universes, and these are not relegated to
just an implementation detail of the memory management scheme.

The rules around declaring types are:

1. A type that is not structurally affine can be declared to be `Affine`, and
   will be treated as an `Affine` type.
2. A type that is structurally affine _cannot_ be declared as belonging to the
   `Free` universe..

In the case of generic types, we often want to postpone the decision of which
universe the type belongs to. For example:

```
record Singleton[T: Type]: ??? is
    value: T
end;
```

Here, the type parameter `T` can accept types in both the `Free` and `Affine`
universes. If we had to declare a concrete universe for `Singleton`, the only
way to make this type-check would be to declare that `Singleton` is in the
`Affine` universe, since that is the lowest common denominator.

Austral lets us do this:

```
record Singleton[T: Type]: Auto is
    value: T
end;
```

`Auto` is not a universe, rather, it tells the compiler to choose the universe
when a concrete type is instantiated, using the algorithm described in
"Automatic Universe Classification". So `Singleton[Int32]` would be in the
`Free` universe, but `Singleton[U]` (where `U : Affine`) belongs to the `Affine`
universe.

## Built-In Types

The following types are built into austral and available to all code:

- `Unit` is the type of functions that return no useful value. The only value of
  type `Unit` is the constant `nil`.
- `Bool` is the Boolean type.
- The built-in integer types are:

  |   Name  |   Width  | Signedness |
  |   ----  |   -----  | ---------- |
  | `Nat8`  | 8 bits   | Unsigned.  |
  | `Nat16` | 16 bits. | Unsigned.  |
  | `Nat32` | 32 bits. | Unsigned.  |
  | `Nat64` | 64 bits. | Unsigned.  |
  | `Int8`  | 8 bits.  | Signed.    |
  | `Int16` | 16 bits. | Signed.    |
  | `Int32` | 32 bits. | Signed.    |
  | `Int64` | 64 bits. | Signed.    |

- `Float32` is the 32-bit floating-point type, and `Float64` is the 64-bit
  floating point type.
