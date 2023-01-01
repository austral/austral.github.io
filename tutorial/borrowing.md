---
title: Borrowing
---

In the previous chapter we were introduced to linear types. Most of the uses of
linear types we saw involved functions that take (and consume) linear values and
return them again for later use.

But returning records from every, function and threading linear values through
the code, is very verbose and inconvenient. It is also often a violation of the
principle of least privilege: linear values, in a sense, have "root
permissions". If you have a linear value, you can destroy it. And we don't
necessarily want every function that takes a linear value to be able to destroy
it.

What we want is a way to treat linear values as though they were free values,
within a delineated scope, and we want to do this in a way where we don't lose
the safety guarantees of linear types.

# References

A **reference** is a `Free` pointer to a `Linear` or `Free` value. References
have a number of restrictions that preserve the linearity guarantees. There are
two kinds of references:

- **Read references** allow you to read data from a linear value.
- **Read-write** or **mutable** references allow you to read from and write to a
  linear value.

The type "read reference to a value of type `T`" is denoted `&[T, R]`, where `R`
is the **region**, which we will discuss below. The type "mutable reference to a
value of type `T`" is denoted `&![T, R]`

# The Simple Case

Suppose you have a linear `ByteBuffer` type and you want a function to get its
length. You could have something like:

```austral
function length(buf: ByteBuffer): Pair[Index, ByteBuffer];
```

And use it like so:

```austral
let { first as length: Index, second as buf2: ByteBuffer } := length(buf);
```

But this is horribly inconvenient. Additionally, it gives the `length` function
too much power. Internally, it could deallocate `buf` and allocate a new,
entirely different buffer to return. We wouldn't expect that to happen, but the
point is to be defensive and prevent wrong programs from being written in the
first place.

With references, we can simplify the API to this:

```austral
generic [R: Region]
function length(buf: &[ByteBuffer, R]): Index;
```

Instead of consuming the linear `ByteBuffer` value, we take a reference to a
`ByteBuffer` in the region `R`, which is a type parameter of the function.

We can use this like this:

```
let length: Index := length(&buf);
```

The syntax borrow expression matches the syntax of the reference type: `&x`
creates a `&[T, R]` read-reference, `&!` creates a `&![T, R]` mutable reference.

Suppose we had something like:

```austral
let buf: ByteBuffer := allocateBuffer(100, 'a');
let len: Index := length(&buf);
destroyBuffer(buf);
```

This code would compile because the reference expression `&buf` happens after
`buf` is defined but before `buf` is consumed.

But if we tried to do this:

```austral
let buf: ByteBuffer := allocateBuffer(100, 'a');
destroyBuffer(buf);
let len: Index := length(&buf);
```

This would not work. You can't take a reference to a value has that been consumed.

# Under the Hood

How is the above function implemented under the hood? Suppose the definition of
`ByteBuffer` is something like:

```austral
record ByteBuffer: Linear is
    size: Index;
    capacity: Index;
    buffer: Pointer[Nat8];
end;
```

Then, we can define `length` like this:

```austral
generic [R: Region]
function length(buf: &[ByteBuffer, R]): Index is
    return !(buf->size);
end;
```

The `!` operator is the dereferencing operator. This takes a reference (read
reference or mutable reference) to a Free value, and returns that value. So if
we have `x: &[T, R]`, the expression `!x` has type `T`.

# Transforming References

If you have a reference to a value, you can transform that into a reference to
one of its constituents. Consider the following types:

```austral
record SolarSystem is
    sun: Star;
    mercury: Planet;
    venus: Planet;
    ...
end;

record Star: Linear is
    pos: CartesianCoord;
end;

record CartesianCoord: Free is
    x: Float32;
    y: Float32;
    z: Float32;
end;
```

Then suppose we have a reference `ref` of type `&[SolarSystem, R]`. Path
operations will give us references to its constituents:

- The expression `ref->sun` has type `&[Star, R]`.
- The expression `ref->sun->pos` has type `&[CartesianCoord, R]`.
- The expression `ref->sun->pos->x` has type `&[Float32, R]`.

Note that the region is the same as references are transformed.

# Dereferencing

Dereferencing takes a reference and returns the value it points to. You can't
dereference a reference to a linear value, because, since references are free
types, you could do this repeatedly, and make multiple copies of the linear
value. But you can dereference free values.

In the above example, `ref->sun->pos->x` is a reference to a `Float32` value,
which is `Free`, so we can derefence it:

```
let f: Float32 := !(ref->sun->pos->x);
```

# The General Case

But what if we want to save the reference for later use? If we do this:

```
let bufref: &[ByteBuffer, R] := &buf;
```

The compiler will complain that it doens't know any type named `R`.

When you need to know the name of the region---generally, when a reference
outlives a single statement---you need to use the `borrow` statement:

```austral
borrow buf as bufref in Reg do
    -- For the duration of this block, the value `buf` is
    -- unusable, since it has been borrowed, and `bufref`
    -- has type `&[ByteBuffer, Reg].
end borrow;
```

What's different about the borrow statement? Here we're defining the name of
the region `Reg`. You can think of this as a lexically-scoped, type-level
tag. Within the scope of the region statement, `R` is defined. Outside the
block, it isn't. That means you can't leak references. You can't write:

```
let ref: &[T, Reg] := ...;
borrow x as xref in Reg do
    ref := xref;
end borrow;
```

Because `Reg` is not known to the compiler outside the `borrow` statement.

Regions are not values: they are types, which exist only within a scope, and are
used to tag reference types so they can't escape. The reason we use the `borrow`
statement in this case is it makes it completely explicit, in the source code,
how long the reference lives.

As with reference expressions, you can't do this:

```
let buf: ByteBuffer := allocateBuffer(100, 'a');
destroyBuffer(buf);
borrow buf ...
```

Because the value has already been deallocated, and therefore cannot be
borrowed.

### Navigation

- [Back](/tutorial/linear-types)
- [Forward](/tutorial/generic-types)
