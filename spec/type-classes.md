---
title: Type Classes
---

Type classes, borrowed from Haskell 98, give us a bounded and sensible form of
ad-hoc polymorphism.

## Instance Uniqueness

In Austral, instances have to be globally unique: you can't have multiple
instances of the same typeclass for the same type, or for overlapping type
parameters. So, the following are prohibited:

```
instance TC(Natural32);
instance TC(Natural32);
```

But also these:

```
generic [T: Type]
instance TC(Pointer[T]);

generic [T: Linear]
instance TC(Pointer[T]);
```

Enforcing uniqueness, however, does not require loading the entire program in
memory. It only requires enforcing these three rules:

1. Within a module, no instances overlap.

2. You are only allowed to define instances for:

    1. Local typeclasses and local types.

    2. Local typeclasses and foreign types.

    3. Foreign typeclasses and local types.

   But you are *not* allowed to define an instance for a foreign typeclass and a
   foreign type.
