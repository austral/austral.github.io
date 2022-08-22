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
it. All of this is enforced at compile time.

# References

There are two kinds of references:

- **Read references** allow you to read data from a linear value.
- **Read-write** or **mutable** references allow you to read from and write to a
  linear value.

The type "read reference to a value of type `T`" is denoted `&[T, R]`, where `R`
is the **region**, which we will discuss below. The type "mutable reference to a
value of type `T`" is denoted `&![T, R]`

# The Simple Case

Suppose you have a linear `ByteBuffer` type and you want a function to get its length. You could have something like:

```austral
function length(buf: ByteBuffer): Pair[Index, ByteBuffer];
```

And use it like so:

```austral
let { first as length: Index, second as buf2: ByteBuffer } := length(buf);
```

But this is horribly inconvenient! Additionally, it gives the `length` function
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

# The General Case

But what if we want to save the reference for later use? If we do this:

```
let bufref: &[ByteBuffer, R] := &buf;
```

The compiler will complain that it doens't know any type named `R`.

When you need to know the name of the region---generally, when a reference
outlives a single statement---you need to use the `borrow` statement:

```austral
borrow buf as bufref in R do
    -- For the duration of this block, the value `buf` is
    -- unusable, since it has been borrowed, and `bufref`
    -- has type `&[ByteBuffer, R].
end borrow;
```

The `borrow` statement defines the name of the **region** to borrow the variable
into. You can think of regions as being like lexically-scoped types. Within the
block, `R` is defined, outside the block, it isn't. That means you can't leak
references. You can't write:

```
let ref: &[T, R] := ...;
borrow x as xref in R do
    ref := xref;
end borrow;
```

Because `R` is not known to the compiler outside the `borrow` statement.
