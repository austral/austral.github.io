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

## Imports

Imports are the mechanism through which declarations from other modules are
brought into an Austral module.

Imports appear at the top of both the module interface and module body files,
before the `module` or `module body` keywords.

An import statement has the general form:

\\[
\text{import} ~ m ~ \(
\text{p}_1 ~ \text{as} ~ \text{l}_1,
\dots,
\text{n}_n ~ \text{as} ~ \text{l}_n
\);
\\]

Where:

1. $$m$$ is the name of the module to import the declarations from.
2. $$p$$ is one of:
   1. The name of a declaration in $$m$$.
   2. The name of a union case in a public union in $$m$$.
   3. The name of a method in a public typeclass in $$m$$.
3. $$l$$ is the _local nickname_ of $$p$$: that is, appearances of $$l$$ in the
   file where this import statement appears will be interpreted as though they
   were references to $$p$$.

Note that import nicknames are not mandatory, and without them, the statement
looks like:

\\[
\text{import} ~ m ~ \(
\text{p}_1,
\dots,
\text{p}_n
\);
\\]

If an identifier $$p$$ is imported without a nickname, references to $$p$$ in
the source text will be interpreted as references to that foreign declaration,
union case, or method.

## Import Nicknames

Import nicknames serve a dual purpose:

1. If two modules $$A$$ and $$B$$ define a declaration with the same name $$p$$,
   we can import both of them by assigning one or both of them a nickname, like:

   \\[
   \text{import} ~ A ~ \(\text{p} ~ \text{as} ~ \text{a}\); \\newline
   \text{import} ~ B ~ \(\text{p} ~ \text{as} ~ \text{b}\);
   \\]

2. They allow us to use shorter names for longer identifiers where necessary.

## Instance Imports

When importing from a module $$M$$, all public typeclass instances in $$M$$ are
imported automatically.

## Unsafe Modules

An **unsafe module** is a module that can access FFI features. Specifically, an
unsafe module can:

- Import declarations from the `Austral.Memory` module.
- Use the `External_Name` pragma.

To specify that a module is unsafe, the `Unsafe_Module` pragma must be used in
the module body. For example:

```austral
module body Example is
    pragma Unsafe_Module;

    -- Can import from `Austral.Memory`, etc.
end module body.
```

## Examples

Given the following interface file:

```austral
module Example is
    -- The constant C is importable, but the interface
    -- doesn't know its value.
    constant C : Float32;

    -- Modules that import R can access the fields
    -- x and y directly.
    record R: Free is
        x: Int32,
        y: Int32
    end;

    -- Modules can refer to the type T, but don't know
    -- how it's implemented.
    type T;

    -- Modules that import U know that it's a renaming
    -- of Int32, and can construct U instances accordingly.
    type U = Int32;

    -- Functions can only be declared, not defined, in
    -- interface files.
    function Fact(n: Nat32): Nat32;

    -- Type classes must be defined with the full set of
    -- methods.
    typeclass Class(T: Type) is
        method Foo(x: T): T;
    end;

    -- Instances are simply declared.
    instance Class(Int32);
end.
```

The following is a module definition that satisfies the interface:

```austral
module Example is
    constant C : Float32 := 3.14;

    -- Record R doesn't have to be redefined here,
    -- because it's already defined in the module interface.

    -- Type T, however, has to be defined. In this case
    -- it's a record.
    record T: Free is
        hidden: Bool;
    end;

    -- Function bodies must appear in the module body.
    function Fact(n: Nat32): Nat32 is
        if n = 0 then
            return 1;
        else
            return n * Fact(n-1);
        end if;
    end;

    -- Type class instances must be defined here:
    instance Class(Int32) is
        method Foo(x: Int32): Int32 is
            return x;
        end;
    end;
end.
```
