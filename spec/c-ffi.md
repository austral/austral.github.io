---
title: The C Interface
---

This section decribes Austral's support for calling C code.

## Functions

To call a foreign function, we must declare it. The syntax is the same as that
of ordinary functions, except in the body of the function definition.

For example, consider the C function:

```
double sum(double* array, size_t length);
```

The [declaration](/spec/declarations#function-declaration) of this function
would look like:

```
function Sum(array: Pointer[Float64], length: Index): Float64;
```

Note that, as in regular functions, the declaration is only needed if the
function is to be public in the module in which it is defined.

The definition would look like:

```
function Sum(array: Pointer[Float64], length: Index): Float64 is
    pragma Foreign_Import(External_Name => "sum");
end;
```

That is, instead of a statement, there is only a `Foreign_Import` pragma, which
takes a named argument `External_Name`, which must be a string constant with the
name of the function to import.

Naturally, the function's parameter list and return type must match those of the
foreign function. See the following section for how C types are mapped to
Austral types.

## Mapping Types

In the following table, the C type on the first column corresponds to the
Austral type on the second column.

Only the types in the second column are permitted to appear in the parameter
list and return type of a foreign function.

C Type           | Austral Type
---------------- | ------------
`unsigned char`  | `Bool`
`unsigned char`  | `Nat8`
`signed char`    | `Int8`
`unsigned short` | `Nat16`
`signed short`   | `Int16`
`unsigned int`   | `Nat32`
`signed int`     | `Int32`
`unsigned long`  | `Nat64`
`signed long`    | `Int64`
`float`          | `Float32`
`double`         | `Float64`
`t*`             | `Address[t]`
