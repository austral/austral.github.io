---
title: Austral.Memory Module
---

The `Austral.Memory` module contains types and functions for manipulating pointers and memory.

## `Pointer` Type

Declaration:

```austral
type Pointer[T: Type]: Free;
```

Description:

This is the type of pointers.

## `Allocate` Function

Declaration:

```austral
generic T: Type
function Allocate(value: T): Optional[Pointer[T]]
```

Description:

Allocates enough space for the given value on the heap, returns `Some` with the
pointer if allocation succeeded, `None` otherwise.

## `Load` Function

Declaration:

```austral
generic T: Type
function Load(pointer: Pointer[T]): T
```

Description:

Dereferences a pointer and returns its value.

## `Store` Function

Declaration:

```austral
generic T: Type
function Store(pointer: Pointer[T], value: T): Unit
```

Description:

Stores `value` at the location pointed to by `pointer`.

## `Deallocate` Function

Declaration:

```austral
generic T: Type
function Deallocate(pointer: Pointer[T]): Unit
```

Description:

Deallocates the given pointer.

## `Load_Read_Ref` Function

Declaration:

```austral
generic [T: Free, R: Region]
function Load_Read_Reference(ref: Reference[Pointer[T], R]): Reference[T, R]
```

Description:

Takes a reference to a pointer, and turns it into a reference to the pointed-to
value.

## `Load_Write_Ref` Function

Declaration:

```austral
generic [T: Free, R: Region]
function Load_Write_Reference(ref: WriteReference[Pointer[T], R]): WriteReference[T, R]
```

Description:

Takes a write reference to a pointer, and turns it into a write reference to the
pointed-to value.

## `Allocate_Array` Function

Declaration:

```austral
generic T: Type
function Allocate_Array(size: Natural_64): Optional[Pointer[T]]
```

Description:

Allocates an array with the given number of bytes.

## `Resize_Array` Function

Declaration:

```austral
generic T: Type
function Resize_Array(array: Pointer[T], size: Natural_64): Optional[Pointer[T]]
```

Description:

Resizes the given array, returning `Some` with the new location if allocation
succeeded, and `None` otherwise.

## `memmove` Function

Declaration:

```austral
generic [T: Type, U: Type]
function memmove(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit
```

Description:

Moves the `count` bytes stored at `source` to `destination`.

## `memcpy` Function

Declaration:

```austral
generic [T: Type, U: Type]
function memcpy(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit
```

Description:

Copies the `count` bytes stored at `source` to `destination`.

## `Positive_Offset` Function

Declaration:

```austral
generic T: Type
function Positive_Offset(pointer: Pointer[T], offset: Natural_64): Pointer[T]
```

Description:

Applies a positive offset to a pointer. Essentially this is:

\\[
\text{pointer} + \text{sizeof}(\\tau) \times \text{offset}
\\]

## `Negative_Offset` Function

Declaration:

```austral
generic T: Type
function Negative_Offset(pointer: Pointer[T], offset: Natural_64): Pointer[T]
```

Description:

Applies a negative offset to a pointer. Essentially this is:

\\[
\text{pointer} - \text{sizeof}(\\tau) \times \text{offset}
\\]
