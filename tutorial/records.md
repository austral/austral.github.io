---
title: Records
---

Records are a way to wrap multiple values in a single value. A record is a
collection of values that can be addressed by name. They are the equivalent of
`struct` types in C.

# Defining Records

Records are defined by the `record` declaration. The following:

```austral
record Vector3: Free is
    x: Float64;
    y: Float64;
    z: Float64;
end;
```

Is equivalent to this in C:

```c
struct Vector3 {
    double x;
    double y;
    double z;
};
```

Don't worry about the `Free` bit, this has to do with Austral's linear type
system, and will be explained later in the tutorial.

# Constructing Records

Records are constructed using a function call-like syntax:

```austral
Vector3(x => 0.0, y => 0.0, z => 0.0);
```

Note that you _have_ to use named arguments in record constructor expressions.

# Accessing Record Values

Record values can be accessed using dot notation.

For example, the following:

```austral
let vec: Vector3 := Vector3(x => 0.0, y => 1.0, z => 2.0);
printLn(vec.y);
```

Will print `1.000000`.

# Destructuring

Destructuring lets you "explode" a record and turn each field into a
variable. For example, instead of:

```austral
let vec: Vector3 := Vector3(x => 0.0, y => 1.0, z => 2.0);
printLn(vec.x);
printLn(vec.y);
printLn(vec.z);
```

You can write:

```austral
let vec: Vector3 := Vector3(x => 0.0, y => 1.0, z => 2.0);
let { x: Float64, y: Float64, z: Float64 } := vec;
printLn(x);
printLn(y);
printLn(z);
```

If the name of a field would collide with the name of another variable, you can
rename them:

```
let { x as x0: Float64, y as y0: Float64, z as z0: Float64 } := vec;
printLn(x0);
printLn(y0);
printLn(z0);
```
