---
title: Austral.Memory Module
---

The `Austral.Memory` module contains types and functions for manipulating pointers and memory.

### `Pointer` Type

Declaration:

```
type Pointer[T: Type]: Free;
```

### `Allocate` Function

Declaration:

```
generic T: Type
function Allocate(value: T): Optional[Pointer[T]]
```

### `Load` Function

Declaration:

```
generic T: Type
function Load(pointer: Pointer[T]): T
```

### `Store` Function

Declaration:

```
generic T: Type
function Store(pointer: Pointer[T], value: T): Unit
```

### `Deallocate` Function

Declaration:

```
generic T: Type
function Deallocate(pointer: Pointer[T]): Unit
```

### `Load_Read_Ref` Function

Declaration:

```
generic [T: Free, R: Region]
function Load_Read_Reference(ref: Reference[Pointer[T], R]): Reference[T, R]
```

### `Load_Write_Ref` Function

Declaration:

```
generic [T: Free, R: Region]
function Load_Write_Reference(ref: WriteReference[Pointer[T], R]): WriteReference[T, R]
```

### `Allocate_Array` Function

Declaration:

```
generic T: Type
function Allocate_Array(size: Natural_64): Optional[Pointer[T]]
```

### `Resize_Array` Function

Declaration:

```
generic T: Type
function Resize_Array(array: Pointer[T], size: Natural_64): Optional[Pointer[T]]
```

### `memmove` Function

Declaration:

```
generic [T: Type, U: Type]
function memmove(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit
```

### `memcpy` Function

Declaration:

```
generic [T: Type, U: Type]
function memcpy(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit
```

### `Positive_Offset` Function

Declaration:

```
generic T: Type
function Positive_Offset(pointer: Pointer[T], offset: Natural_64): Pointer[T]
```

### `Negative_Offset` Function

Declaration:

```
generic T: Type
function Negative_Offset(pointer: Pointer[T], offset: Natural_64): Pointer[T]
```
