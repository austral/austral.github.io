## Austral.Memory Module

The `Austral.Memory` module contains types and functions for manipulating pointers and memory.

### `Pointer` Type

Declaration:

```austral
type Pointer[T: Type]: Free;
```

Description:

This is the type of nullable pointers.

### `nullPointer` Function

```austral
generic [T: Type]
function nullPointer(): Pointer[T];
```

Description:

Returns the null pointer for a given type.

### `allocate` Function

Declaration:

```austral
generic [T: Type]
function allocate(size: Natural_64): Pointer[T];
```

Description:

Allocates the given amount of memory in bytes.

### `load` Function

Declaration:

```austral
generic [T: Type]
function load(pointer: Pointer[T]): T;
```

Description:

Dereferences a pointer and returns its value.

### `store` Function

Declaration:

```austral
generic [T: Type]
function store(pointer: Pointer[T], value: T): Unit;
```

Description:

Stores `value` at the location pointed to by `pointer`.

### `deallocate` Function

Declaration:

```austral
generic [T: Type]
function deallocate(pointer: Pointer[T]): Unit;
```

Description:

Deallocates the given pointer.

### `loadRead` Function

Declaration:

```austral
generic [T: Type, R: Region]
function loadRead(ref: &[Pointer[T], R]): Reference[T, R];
```

Description:

Takes a reference to a pointer, and turns it into a reference to the pointed-to
value.

### `loadWrite` Function

Declaration:

```austral
generic [T: Type, R: Region]
function loadWrite(ref: &![Pointer[T], R]): WriteReference[T, R];
```

Description:

Takes a write reference to a pointer, and turns it into a write reference to the
pointed-to value.

### `resizeArray` Function

Declaration:

```austral
generic [T: Type]
function resizeArray(array: Pointer[T], size: Natural_64): Pointer[T];
```

Description:

Resizes the given array, returning `Some` with the new location if allocation
succeeded, and `None` otherwise.

### `memmove` Function

Declaration:

```austral
generic [T: Type, U: Type]
function memmove(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit;
```

Description:

Moves the `count` bytes stored at `source` to `destination`.

### `memcpy` Function

Declaration:

```austral
generic [T: Type, U: Type]
function memcpy(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit;
```

Description:

Copies the `count` bytes stored at `source` to `destination`.

### `positiveOffset` Function

Declaration:

```austral
generic [T: Type]
function positiveOffset(pointer: Pointer[T], offset: Natural_64): Pointer[T];
```

Description:

Applies a positive offset to a pointer. Essentially this is:

\\[
\text{pointer} + \text{sizeof}(\\tau) \times \text{offset}
\\]

### `negativeOffset` Function

Declaration:

```austral
generic [T: Type]
function negativeOffset(pointer: Pointer[T], offset: Natural_64): Pointer[T];
```

Description:

Applies a negative offset to a pointer. Essentially this is:

\\[
\text{pointer} - \text{sizeof}(\\tau) \times \text{offset}
\\]
