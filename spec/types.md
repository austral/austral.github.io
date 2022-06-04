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
2. The universe of linear types, denoted `Linear`. These are explained in the
   next section.

## Linear Types

A type $$\tau$$ is linear if:

1. It contains another linear type. These types are called _structurally
   linear_.

2. Is it declared to be a linear type (see "Declaring Types"). These types are
   called _declared linear_.

To formalize the notion of "containment" in point 1.: a type $$\tau$$ is said to
contain a linear type $$\upsilon$$ (or, equivalently, a type parameter
$$\upsilon$$ of kinds `Linear` or `Type`) if:

1. $$\tau$$ is a type alias of $$\upsilon$$.
3. $$\tau$$ is a record, where at least one field contains $$\upsilon$$.
3. $$\tau$$ is a union, where at least one case contains a field that contains $$\upsilon$$.

## Type Parameters

A _type parameter_ has the form:

\\[
\text{p}: K
\\]

where $$\text{p}$$ is an identifier and $$K$$ is a _kind_. The set of permitted
kinds is:

- `Free`: a type parameter with kind `Free` accepts types that belong to the
  `Free` universe.

- `Linear`: a type parameter with kind `Linear` accepts types that belong to the
  `Linear` universe.

- `Type`: a type parameter with kind `Type` accepts any kind of type. Values
  with this type are treated as though they were `Linear` (i.e., they can only
  be used once, they can't be silently dropped, etc.) since this is the lowest
  common denomination of behaviour.

- `Region`: a type parameter with kind `Region` accepts regions.

## Declaring Types

When declaring a type, we must state which universe it belongs to. This is so
that the programmer is aware of type universes, and these are not relegated to
just an implementation detail of the memory management scheme.

The rules around declaring types are:

1. A type that is not structurally linear can be declared to be `Linear`, and
   will be treated as an `Linear` type.
2. A type that is structurally linear _cannot_ be declared as belonging to the
   `Free` universe.

In the case of generic types, we often want to postpone the decision of which
universe the type belongs to. For example:

```austral
record Singleton[T: Type]: ??? is
    value: T
end;
```

Here, the type parameter `T` can accept types in both the `Free` and `Linear`
universes. If we had to declare a universe for `Singleton`, the only way to make
this type-check would be to declare that `Singleton` is in the `Linear`
universe, since that is the lowest common denominator.

However, Austral lets us do this:

```austral
record Singleton[T: Type]: Type is
    value: T
end;
```

When `Type` appears as the declared universe of a type, it is not a universe,
but rather, it tells the compiler to choose the universe when a concrete type is
instantiated, using the algorithm described in "Automatic Universe
Classification". So `Singleton[Int32]` would be in the `Free` universe, but
`Singleton[U]` (where `U : Linear`) belongs to the `Linear` universe.

## Built-In Types

The following types are built into austral and available to all code.

### Unit {#unit}

```austral
type Unit: Free;
```

`Unit` is the type of functions that return no useful value. The only value of
type `Unit` is the constant `nil`.

### Boolean {#boolean}

```austral
type Boolean: Free;
```

`Boolean` is the type of logical and comparison operators.

The only `Boolean` values are the constants `true` and `false`.

### Integer Types {#integers}

The following integer types are available:

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

All are in the free universe.

The `Index` type is the type of array indices.

### Floating Point Types {#floats}

```austral
type Float32: Free;
type Float64: Free;
```

The two floating-point types are `Float32` and `Float64`.

### Read-Only Reference {#read-ref}

```austral
type Reference[T: Linear, R: Region]: Free;
```

The type `Reference` is the type of read-only references to linear
values. Values of this type are bound to a region and are acquired by borrowing.

Syntactic sugar is available: `&[T, R]` expands to `Reference[T, R]`.

### Read-Write Reference {#write-ref}

```austral
type WriteReference[T: Linear, R: Region]: Free;
```

The type `WriteReference` is the type of read-write references to linear
values. Values of this type are bound to a region and are acquired by borrowing.

Syntactic sugar is available: `&![T, R]` expands to `WriteReference[T, R]`.

### Root Capability {#root-capability}

```austral
type Root_Capability: Linear;
```

The type `Root_Capability` is the root of the capability hierarchy. It is the
type of the first parameter to the entrypoint function.
