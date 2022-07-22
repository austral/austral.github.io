# Type Classes {#type-classes}

Type classes, borrowed from Haskell 98, give us a bounded and sensible form of
ad-hoc polymorphism.

## Instance Uniqueness {#type-class-uniqueness}

In Austral, instances have to be globally unique: you can't have multiple
instances of the same typeclass for the same type, or for overlapping type
parameters. So, the following are prohibited:

```austral
instance TC(Nat32);
instance TC(Nat32);
```

But also these:

```austral
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

## Instance Resolution {#instance-resolution}

This section describes how an instance is resolved from a method call.

Consider a typeclass:

```austral
typeclass Printable(T: Free) is
    method Print(t: T): Unit;
end;
```

And a set of instances:

```austral
instance Printable(Unit);
instance Printable(Bool);
generic [U: Type]
instance Printable(Pointer[U]);
```

Then, given a call like `Print(true)`, we know `Print` is a method in the
typeclass `Printable`. Then, we match the parameter list `(t: T)` to the
argument list `(true)` and get a set of type parameter bindings `{ T => true
}`. The set will be the singleton set because typeclass definitions can only
have one type parameter.

In this case, `true` is called the _dispatch type_.

Then we iterate over all the visible instances of the type class `Printable`
(i.e.: those that are defined in or imported into the current module), and find
the instance where the instance argument matches the dispatch type.

In the case of a concrete instance that's just comparing the types for equality,
and we'll find the instance of `Printable` for `Boolean`.

Consider a call like `Print(ptr)` where `ptr` has type `Pointer[Nat8]`. Then, we
repeat the process, except we'll find a generic instance of
`Printable`. Matching `Pointer[U]` to `Pointer[Nat8]` produces the bindings set
`{ U => Nat8 }`.
