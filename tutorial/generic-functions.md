---
title: Generic Functions
---

Generic functions are defined by adding a `generic` clause with a list of type
parameters. For example:

```austral
generic [T: Type]
function identity(x: T): T is
    return x;
end;
```

Or:

```austral
generic [R: Region]
function bufferLength(ref: &[ByteBuffer, R]): Index;
```

# Return-Type Polymorphism

Austral doesn't have type inference: type information flows in one direction,
from the innermost expressions to the outermost.

For most generic functions, where the type parameters that appear in the
parameter list are the same as those that appear in the return type, this isn't
a problem: the return type can be inferred from the types of the parameters.

But there are cases where you have a type parameter that appears only in the
return type, and not in the value parameters. This typically happens with type
classes. Consider a typeclass:

```austral
typeclass Bounded(T: Type) is
    method smallestValue(): T;
    method largestValue(): T;
end;
```

And we have instances defined for all the basic integer types. Then, an
expression like:

```austral
print(smallestValue());
```

Is ill-typed. What is the return type of `smallestValue()`?

Functions and methods that have type parameters that appear in the return type
but not in the parameters are said to be _return-type polymorphic_. Calls to
these functions have to be disambiguated. There are two ways to do this. One is
to use the type casting operator:

```austral
print(smallestValue() : Int32);
```

This tells the compiler that the type of `smallestValue()` is `Int32`. By
asserting the return type, the compiler can figure out which typeclass instance
to use.

The other way is with the `let` statement:

```austral
let min: Int32 := smallestValue();
```

Here we're doing the same thing: asserting the return type.
