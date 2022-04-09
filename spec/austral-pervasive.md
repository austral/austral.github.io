---
title: Austral.Pervasive Module
---

The `Austral.Pervasive` module exports declarations which are imported by every module.

## `Option` Type

Definition:

```
union Option[T: Type]: Type is
    case None;
    case Some is
        value: T;
end;
```

Description:

The `Option` is used to represent values that might be empty, for example, the
return type of a function that retrieves a value from a dictionary by key might
return `None` if the key does not exist and `Some` otherwise.

## `Either` Type

Definition:

```
union Either[L: Type, R: Type]: Type is
    case Left is
        left: L;
    case Right is
        right: R;
end;
```

Description:

The `Either` type is used to represent values which may have one of two distinct
possibilities. For example, a function might return a value of type
`Either[Error, Result]`.

## `Deref` Function

Declaration:

```
generic [T: Free, R: Region]
function Deref(ref: Reference[T, R]): T;
```

Description:

The `Deref` function loads the value pointed to by a read reference.

## `Deref_Write` Function

Declaration:

```
generic [T: Free, R: Region]
function Deref_Write(ref: WriteReference[T, R]): T;
```

Description:

The `Deref_Write` function loads the value pointed to by a write reference.

## `Fixed_Array_Size` Function

Declaration:

```
generic [T: Type]
function Fixed_Array_Size(arr: Fixed_Array[T]): Natural_64;
```

Description:

The `Fixed_Array_Size` function returns the size of a fixed array.

## `Abort` Function

Declaration:

```
function Abort(message: Fixed_Array[Natural_8]): Unit;
```

Description:

The `Abort` function prints the given message to standard error and aborts the
program.

## `Root_Capability` Type

Declaration:

```
type Root_Capability : Linear;
```

Description:

The `Root_Capability` type is meant to be the root of the capability hierarchy.

The entrypoint function of an Austral program takes a single value of type
`Root_Capability`. This is the highest permission level, available only at the
start of the program.

## Integer Bound Constants

Declarations:

```
constant Maximum_Natural_8: Natural_8;
constant Maximum_Natural_16: Natural_16;
constant Maximum_Natural_32: Natural_32;
constant Maximum_Natural_64: Natural_64;

constant Minimum_Integer_8: Integer_8;
constant Maximum_Integer_8: Integer_8;

constant Minimum_Integer_16: Integer_16;
constant Maximum_Integer_16: Integer_16;

constant Minimum_Integer_32: Integer_32;
constant Maximum_Integer_32: Integer_32;

constant Minimum_Integer_64: Integer_64;
constant Maximum_Integer_64: Integer_64;
```

Description:

These constants define the minimum and maximum values that can be stored in
different integer types.

## `Trapping_Arithmetic` Typeclass

Definition:

```
interface Trapping_Arithmetic(T: Type) is
    method Trapping_Add(lhs: T, rhs: T): T;
    method Trapping_Subtract(lhs: T, rhs: T): T;
    method Trapping_Multiply(lhs: T, rhs: T): T;
    method Trapping_Divide(lhs: T, rhs: T): T;
end;
```

Description:

The `Trapping_Arithmetic` typeclass defines methods for performing arithmetic
that aborts on overflow errors.

## `Modular_Arithmetic` Typeclass

Definition:

```
interface Modular_Arithmetic(T: Type) is
    method Modular_Add(lhs: T, rhs: T): T;
    method Modular_Subtract(lhs: T, rhs: T): T;
    method Modular_Multiply(lhs: T, rhs: T): T;
    method Modular_Divide(lhs: T, rhs: T): T;
end;
```

Description:

The `Modular_Arithmetic` typeclass defines methods for performing arithmetic
that wraps around without abort on overflow errors.

## Typeclass Instances

Declarations:

```
implementation Trapping_Arithmetic(Natural_8);
implementation Trapping_Arithmetic(Integer_8);
implementation Trapping_Arithmetic(Natural_16);
implementation Trapping_Arithmetic(Integer_16);
implementation Trapping_Arithmetic(Natural_32);
implementation Trapping_Arithmetic(Integer_32);
implementation Trapping_Arithmetic(Natural_64);
implementation Trapping_Arithmetic(Integer_64);
implementation Trapping_Arithmetic(Double_Float);

implementation Modular_Arithmetic(Natural_8);
implementation Modular_Arithmetic(Integer_8);
implementation Modular_Arithmetic(Natural_16);
implementation Modular_Arithmetic(Integer_16);
implementation Modular_Arithmetic(Natural_32);
implementation Modular_Arithmetic(Integer_32);
implementation Modular_Arithmetic(Natural_64);
implementation Modular_Arithmetic(Integer_64);
```

Description:

These are the built-in instances of the `Trapping_Arithmetic` and
`Modular_Arithmetic` typeclasses.
