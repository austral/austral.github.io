---
title: Type Constraints
---

Type parameters are, in a sense, "universally quantified". If we have a function:

```austral
generic [T: Type]
function identity(x: T): T is
    return x;
end;
```

We really can't do anything with `x` other than shuffle it around data
structures and return it, since we know nothing about it. We can't write:

```austral
generic [T: Type]
function identity(x: T): T is
    return x + x;
end;
```

Since it might not be a numeric type. Similarly, we can't write:

```austral
generic [T: Type]
function identity(x: T): T is
    print(x);
    return x;
end;
```

Since it might not be printable, the type of the value we pass in might not
implement the `Printable` typeclass.

Type constraints allow us to circumvent this. We can tell the compiler to only
accept types that implement certain type classes.

For example, suppose we have:

```
typeclass Equatable(T: Free) is
    method isEqual(a: T, b: T): Bool;
end;
```

Then we can write a `isNotEqual` function like this:

```austral
generic [T: Free(Equatable)]
function isNotEqual(a: T, b: T): Bool is
    return not isEqual(a, b);
end;
```

The type parameter `T: Free` is modified to `T: Free(Equatable)`. If we try to
call `isNotEqual` with a type that doesn't implement `Equatable`, the compiler
will complain.

Multiple type classes can be specified in a comma-separated list, e.g.:

```
generic [T: Type(TotalEquality, TotalOrder, Printable, Serializable)]
```
