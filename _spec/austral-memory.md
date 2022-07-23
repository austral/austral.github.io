## Austral.Memory Module {#austral.memory}

The `Austral.Memory` module contains types and functions for manipulating pointers and memory.

### `Pointer` Type {#austral.memory-pointer}

Declaration:

```austral
type Pointer[T: Type]: Free;
```

Description:

This is the type of nullable pointers.

### `nullPointer` Function {#austral.memory-nullpointer}

```austral
generic [T: Type]
function nullPointer(): Pointer[T];
```

Description:

Returns the null pointer for a given type.

### `allocate` Function {#austral.memory-allocate}

Declaration:

```austral
generic [T: Type]
function allocate(size: Natural_64): Pointer[T];
```

Description:

Allocates the given amount of memory in bytes.

### `load` Function {#austral.memory-load}

Declaration:

```austral
generic [T: Type]
function load(pointer: Pointer[T]): T;
```

Description:

Dereferences a pointer and returns its value.

### `store` Function {#austral.memory-store}

Declaration:

```austral
generic [T: Type]
function store(pointer: Pointer[T], value: T): Unit;
```

Description:

Stores `value` at the location pointed to by `pointer`.

### `deallocate` Function {#austral.memory-deallocate}

Declaration:

```austral
generic [T: Type]
function deallocate(pointer: Pointer[T]): Unit;
```

Description:

Deallocates the given pointer.

### `loadRead` Function {#austral.memory-loadread}

Declaration:

```austral
generic [T: Type, R: Region]
function loadRead(ref: &[Pointer[T], R]): Reference[T, R];
```

Description:

Takes a reference to a pointer, and turns it into a reference to the pointed-to
value.

### `loadWrite` Function {#austral.memory-loadwrite}

Declaration:

```austral
generic [T: Type, R: Region]
function loadWrite(ref: &![Pointer[T], R]): WriteReference[T, R];
```

Description:

Takes a write reference to a pointer, and turns it into a write reference to the
pointed-to value.

### `resizeArray` Function {#austral.memory-resizearray}

Declaration:

```austral
generic [T: Type]
function resizeArray(array: Pointer[T], size: Natural_64): Pointer[T];
```

Description:

Resizes the given array, returning `Some` with the new location if allocation
succeeded, and `None` otherwise.

### `memmove` Function {#austral.memory-memmove}

Declaration:

```austral
generic [T: Type, U: Type]
function memmove(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit;
```

Description:

Moves the `count` bytes stored at `source` to `destination`.

### `memcpy` Function {#austral.memory-memcpy}

Declaration:

```austral
generic [T: Type, U: Type]
function memcpy(source: Pointer[T], destination: Pointer[U], count: Natural_64): Unit;
```

Description:

Copies the `count` bytes stored at `source` to `destination`.

### `positiveOffset` Function {#austral.memory-positiveoffset}

Declaration:

```austral
generic [T: Type]
function positiveOffset(pointer: Pointer[T], offset: Natural_64): Pointer[T];
```

Description:

Applies a positive offset to a pointer. Essentially this is:

$$
\text{pointer} + \text{sizeof}(\tau) \times \text{offset}
$$

### `negativeOffset` Function {#austral.memory-negativeoffset}

Declaration:

```austral
generic [T: Type]
function negativeOffset(pointer: Pointer[T], offset: Natural_64): Pointer[T];
```

Description:

Applies a negative offset to a pointer. Essentially this is:

$$
\text{pointer} - \text{sizeof}(\tau) \times \text{offset}
$$
