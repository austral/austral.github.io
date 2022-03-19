---
title: Austral.Pervasive Module
---

The `Austral.Pervasive` module exports declarations which are imported by every module.

### `Option` Type

Definition:

```
union Option[T: Type]: Type is
    case None;
    case Some is
        value: T;
end;
```

### `Either` Type

Definition:

```
union Either[L: Type, R: Type]: Type is
    case Left is
        left: L;
    case Right is
        right: R;
end;
```

### `Deref` Function

Declaration:

```
generic [T: Free, R: Region]
function Deref(ref: Reference[T, R]): T;
```

### `Deref_Write` Function

Declaration:

```
generic [T: Free, R: Region]
function Deref_Write(ref: WriteReference[T, R]): T;
```

### `Fixed_Array_Size` Function

Declaration:

```
generic [T: Type]
function Fixed_Array_Size(arr: Fixed_Array[T]): Natural_64;
```

### `Abort` Function

Declaration:

```
function Abort(message: Fixed_Array[Natural_8]): Unit;
```

### `Root_Capability` Type

Declaration:

```
type Root_Capability : Linear;
```

### Integer Bound Constant

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

### `Trapping_Arithmetic` Typeclass

Definition:

```
interface Trapping_Arithmetic(T: Type) is
    method Trapping_Add(lhs: T, rhs: T): T;
    method Trapping_Subtract(lhs: T, rhs: T): T;
    method Trapping_Multiply(lhs: T, rhs: T): T;
    method Trapping_Divide(lhs: T, rhs: T): T;
end;
```

### `Modular_Arithmetic` Typeclass

Definition:

```
interface Modular_Arithmetic(T: Type) is
    method Modular_Add(lhs: T, rhs: T): T;
    method Modular_Subtract(lhs: T, rhs: T): T;
    method Modular_Multiply(lhs: T, rhs: T): T;
    method Modular_Divide(lhs: T, rhs: T): T;
end;
```

### Typeclass Instances

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
