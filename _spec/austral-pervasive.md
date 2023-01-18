## Austral.Pervasive Module {#austral.pervasive}

The `Austral.Pervasive` module exports declarations which are imported by every module.

### `Option` Type {#austral.pervasive-option}

Definition:

```austral
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

### `Either` Type {#austral.pervasive-either}

Definition:

```austral
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

### `fixedArraySize` Function {#austral.pervasive-fixedarraysize}

Declaration:

```austral
generic [T: Type]
function fixedArraySize(arr: FixedArray[T]): Nat64;
```

Description:

The `fixedArraySize` function returns the size of a fixed array.

### `abort` Function {#austral.pervasive-abort}

Declaration:

```austral
function abort(message: Fixed_Array[Nat8]): Unit;
```

Description:

The `abort` function prints the given message to standard error and aborts the
program.

### `RootCapability` Type {#austral.pervasive-rootcapability}

Declaration:

```austral
type RootCapability : Linear;
```

Description:

The `RootCapability` type is meant to be the root of the capability hierarchy.

The entrypoint function of an Austral program takes a single value of type
`RootCapability`. This is the highest permission level, available only at the
start of the program.

### `surrenderRoot` Function {#austral.pervasive-surrenderroot}

```austral
function surrenderRoot(cap: RootCapability): Unit;
```

The `surrenderRoot` function consumes the root capability. Beyond this point the
program can't do anything effectful, except through unsafe FFI interfaces.

### `ExitCode` Type {#austral.pervasive-exitcode}

```austral
union ExitCode: Free is
    case ExitSuccess;
    case ExitFailure;
end;
```

The `ExitCode` type is the return type of entrypoint functions.

### Integer Bound Constants {#austral.pervasive-integer-bound-constants}

Declarations:

```austral
constant maximum_nat8: Nat8;
constant maximum_nat16: Nat16;
constant maximum_nat32: Nat32;
constant maximum_nat64: Nat64;

constant minimum_int8: Int8;
constant maximum_int8: Int8;

constant minimum_int16: Int16;
constant maximum_int16: Int16;

constant minimum_int32: Int32;
constant maximum_int32: Int32;

constant minimum_int64: Int64;
constant maximum_int64: Int64;
```

Description:

These constants define the minimum and maximum values that can be stored in
different integer types.

### `TrappingArithmetic` Typeclass {#austral.pervasive-trappingarithmetic}

Definition:

```austral
typeclass TrappingArithmetic(T: Type) is
    method trappingAdd(lhs: T, rhs: T): T;
    method trappingSubtract(lhs: T, rhs: T): T;
    method trappingMultiply(lhs: T, rhs: T): T;
    method trappingDivide(lhs: T, rhs: T): T;
end;
```

Description:

The `TrappingArithmetic` typeclass defines methods for performing arithmetic
that aborts on overflow errors.

### `ModularArithmetic` Typeclass {#austral.pervasive-modularithmetic}

Definition:

```austral
typeclass ModularArithmetic(T: Type) is
    method modularAdd(lhs: T, rhs: T): T;
    method modularSubtract(lhs: T, rhs: T): T;
    method modularMultiply(lhs: T, rhs: T): T;
    method modularDivide(lhs: T, rhs: T): T;
end;
```

Description:

The `ModularArithmetic` typeclass defines methods for performing arithmetic that
wraps around without abort on overflow errors.

### Typeclass Instances {#austral.pervasive-typeclass-instances}

Declarations:

```austral
instance TrappingArithmetic(Nat8);
instance TrappingArithmetic(Int8);
instance TrappingArithmetic(Nat16);
instance TrappingArithmetic(Int16);
instance TrappingArithmetic(Nat32);
instance TrappingArithmetic(Int32);
instance TrappingArithmetic(Nat64);
instance TrappingArithmetic(Int64);
instance TrappingArithmetic(Double_Float);

instance ModularArithmetic(Nat8);
instance ModularArithmetic(Int8);
instance ModularArithmetic(Nat16);
instance ModularArithmetic(Int16);
instance ModularArithmetic(Nat32);
instance ModularArithmetic(Int32);
instance ModularArithmetic(Nat64);
instance ModularArithmetic(Int64);
```

Description:

These are the built-in instances of the `TrappingArithmetic` and
`ModularArithmetic` typeclasses.
