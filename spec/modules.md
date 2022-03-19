---
title: Module System
---

Modules are the unit of code organization in Austral. Modules have two parts:
the module interface file and the module body file.

## Module Interfaces

The interface contains declarations that are importable by other modules.

A module interface can have the following declarations:

- [Opaque constant declarations](/spec/declarations#opaque-constant)
- [Opaque type alias declarations](/spec/declarations#opaque-type-alias)
- [Type alias definitions](/spec/declarations#type-alias-definition)
- [Record definitions](/spec/declarations#record-definition)
- [Union definitions](/spec/declarations#union-definition)
- [Function declarations](/spec/declarations#function-declaration)
- [Typeclass definitions](/spec/declarations#typeclass-definition)
- [Instance declarations](/spec/declarations#instance-declaration)

## Module Bodies

The module body contains private declarations (that are not importable by other
modules), as well as declarations that provide the definitions of opaque
declarations in the module interface.

A module body can have the following kinds of declarations:

- [Constant definitions](/spec/declarations#constant-definition)
- [Type alias definitions](/spec/declarations#type-alias-definition)
- [Record definitions](/spec/declarations#record-definition)
- [Union definitions](/spec/declarations#union-definition)
- [Function definitions](/spec/declarations#function-definition)
- [Typeclass definitions](/spec/declarations#typeclass-definition)
- [Instance definitions](/spec/declarations#instance-definitions)

## Unsafe Modules

An **unsafe module** is a module that can access FFI features. Specifically, an
unsafe module can:

- Import declarations from the `Austral.Memory` module.
- Use the `External_Name` pragma.

To specify that a module is unsafe, the `Unsafe_Module` pragma must be used in
the module body. For example:

```
module body Example is
    pragma Unsafe_Module;

    -- Can import from `Austral.Memory`, etc.
end module body.
```

## Examples

Given the following interface file:

```
interface Example is
    -- The constant C is importable, but the interface
    -- doesn't know its value.
    constant C : Float32

    -- Modules that import R can access the fields
    -- x and y directly.
    record R is
        x: Int32,
        y: Int32
    end

    -- Modules can refer to the type T, but don't know
    -- how it's implemented.
    type T

    -- Modules that import U know that it's a renaming
    -- of Int32, and can construct U instances accordingly.
    type U = Int32

    -- Functions can only be declared, not defined, in
    -- interface files.
    function Fact(n: Nat32): Nat32;

    -- Type classes must be defined with the full set of
    -- methods.
    typeclass Class(t: Type) is
        method Foo(t: Type): t
    end

    -- Instances are simply declared.
    instance Class(Int32) is
        method Foo(t: Int32): Int32
    end
end.
```

The following is a module definition that satisfies the interface:

```
module Example is
    constant C : Float32 := 3.14;

    -- Record R doesn't have to be redefined here.
    -- Type T, however, has to be defined. In this case
    -- it's a record.
    record T is
        hidden: Bool;
    end

    -- Function bodies must appear in the module body.
    function Fact(n: Nat32): Nat32 is
        if n = 0 then
            return 1;
        else
            return n * Fact(n-1);
        end if
    end

    -- Type class instances must be defined here:
    instance Class(Int32) is
        method Foo(t: Int32): Int32 is
            return t;
        end
    end
end.
```
