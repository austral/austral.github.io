---
title: Type Classes
---

Austral doesn't have operator overloading. That is, you can't write:

```austral
function foo(x: Int32): Unit;

function foo(x: Buffer): Int32;
```

Because the compiler will complain that there are two functions with the same
name. But suppose we want to print things. Normally, we'd have to define a
`printT` function for each type `T`. This works, it's not too verbose, but it
doesn't let you reason about interfaces: to know if a type is printable, you
have to manually look for a function called something like `printFoo` for the
type.

_Type classes_ let us have operator overloading in a way that is principled and
allows us to reason about interfaces.

A _type class_ is an interface that types can implement, equivalently, it
defines the set of types that implement that interface. Type classes have
_instances_: an instance is the implementation of a type class for a particular
type.

For example, you could have a type class for types that can be printed:

```austral
typeclass Printable(T: Type) is
    generic [R: Region]
    method printRef(ref: &[T, R]): Unit;
end;
```

And here's how you would define an instance for the `Int64` type:

```austral
instance Printable(Int64) is
    generic [R: Region]
    method printRef(ref: &[Int64, R]): Unit is
        -- ...
    end;
end;
```

### Navigation

- [Back](/tutorial/generic-functions)
- [Forward](/tutorial/type-constraints)
