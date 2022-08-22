---
title: Generic Types
---

Austral's types can be generic, so you can write reusable datastructures. Let's
go by example.

Start with this type: a pair of integers.

```austral
record IntPair: Free is
    first: Int32;
    second: Int32;
end;
```

The string `IntPair: Free` means that `IntPair` is a _concrete type_ (that is, a
non-generic type) that belongs to the `Free` universe. We're allowed to do this
since `IntPair` doesn't contain any linear types.

Let's make it generic:

```austral
record FreeIntPair[A: Free, B: Free]: Free is
    first: A;
    second: B;
end;
```

We've added two type parameters, `A` and `B`. Remember that there are two
universes, `Free` and `Linear`, and we have to specify the universe the type
parameters and the type itself belongs to.

But it would be extremely inconvenient if we had to define each generic type
twice, one version for `Free` types and another for `Linear` types:

```austral
record FreeIntPair[A: Free, B: Free]: Free is
    first: A;
    second: B;
end;

record LinearIntPair[A: Linear, B: Linear]: Linear is
    first: A;
    second: B;
end;
```

So Austral provides a convenience feature: instead of `Free` or `Linear` we
write `Type`:

```
record Pair[A: Type, B: Type]: Type is
    first: A;
    second: B;
end;
```

When a type parameter is marked as `Type`, it means "accept any type in either
universe". When the type's universe (after the colon after the list) is `Type`,
it means "decide the universe on the basis of what is passed in".

So, if we have `Pair[Int32, Float64]`, this type will belong to `Free` because
both `Int32` and `Float64` are `Free`. But if we have `Pair[Bool, ByteBuffer]`
(where `ByteBuffer` is some imaginary linear type), then that type will belong
to the `Linear` universe, because _at least_ one of its type parameters is
linear.

# Type Parameter Syntax

A type is a _name_ `n` and a _kind_ `K`, and is denoted: `n: K`.

The following kinds are defined:

- `Free`: accept any type in the `Free` universe.
- `Linear`: accept any type in the `Linear` universe.
- `Type`: accept any type, but values of this type are treated as if `Linear`
  since that's the lowest common denominator behaviour.
- `Region`: accept a region.
