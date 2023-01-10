---
title: Unions
---

Unions are for representing values that can be in one of a fixed number of
states: a switch can be on or off; a street light can be red, yellow, or green;
a box can hold _something_ or be empty, etc.

For C programmers: they are like enums and tagged unions. For OCaml/Haskell
programmers: they are sum types.

# Defining Unions

Unions are defined with the `union` declaration:

```austral
union IntBox: Free is
    case Empty;
    case Full is
        value: Int32;
end;
```

Unions have a set of **cases**, each case has a unique name and a (potentially
empty) set of fields like a record. Here, the type `IntBox` represents values
that can either be `Empty` (in which case it holds no data) or `Full` (in which
case it holds a value of type `Int32`).

# Constructing Unions

Unions are constructed using a function call-like syntax, like records, except
you use the name of the particular case:

```austral
let box1: IntBox := Empty();
let box2: IntBox := Full(value => 32);
```

# The Case Statement

Unlike records, the contents of a union can't be accessed using dot
notation. You need the `case` statement:

```austral
let box: IntBox := ...;
case box of
    when Empty do
        -- Do something with an empty box.
        printLn("Box is empty");
    when Full(value: Int32) do
        -- Do something with the value of a full box.
        print("Box has value: ");
        printLn(value);
end case;
```

If `box` is `Empty`, this code will print:

```
Box is empty
```

If `box` was constructed like `Full(value => 123)`, then the above code will print:

```
Box has value: 123
```

When a case has no values, the corresponding `when` clause takes no bindings:

```austral
when Empty do
    ...
```

When a case has values, the corresponding `when` clause needs one binding for
each field in the case:

```austral
when Full(value: Int32) do
    ...
```

You can rename bindings:

```austral
when Full(value as v: Int32) do
    ...
```

### Navigation

- [Back](/tutorial/records)
- [Forward](/tutorial/linear-types)
