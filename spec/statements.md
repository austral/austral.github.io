---
title: Statements
---

This section describes the semantics of Austral statements.

## Skip Statement

The `skip` statement is a no-op;

Example:

```
skip;
```

## Let Statement

If `N` is an identifier, `T` is a type specifier, and `E` is an expression of type `T`, then:

```
let N: T := e;
```

is a `let` statement which defines a variable with name `N`, type `T`, and initial value `E`.

A `let` statement is one of the few places where type information flows forward:
the declared type is used to disambiguate the type of the expression when the
expression is, for example, a call to a return-type polymorphic function.

## Let Destructure Statement

A let destructure statement is used to break apart records, creating a binding
for each field in the record.

The utility of this is: when you have a linear record type, you can't extract
the value of a linear field from it, because it consumes the record as a whole,
and leaves unconsumed any other linear fields in the record. So the record must
be broken up into its constituent values, and then optionally reassembled.

If `R` is an expression of type `T`, and `T` is a record type with field set
`{R_1: T_1, ..., R_n: T_n}`, then:

```
let {R_1: T_1, ..., R_n: T_n} := R;
```

is a let destructure statement.

## Assignment Statement

If `P` is a [path](#paths) of type `T` and `E` is an expression of type `T`, then:

```
P := E;
```

is an assignment statement that stores the value of `E` in the location denoted by `P`.

## If Statement

If `{e_1, ..., e_n}` is a set of expression of boolean type, and `{b_1, ..., b_n, b_else}` is a set of statements, then:

```
if e_1 then
    b_1;
else if e_2 then
    b_2;
...
else if e_n then
    b_n;
else
    b_else;
end if;
```

Is the general form of an `if` statement.

An example `if` statement with a single branch:

```
if test() then
    doSomething();
end if;
```

An example `if` statement with a `true` branch and a `false` branch:

```
if test() then
    doSomething();
else
    doSomethingElse();
end if;
```

An example `if` statement with three conditions and an else branch:

```
if a() then
    doA();
else if b() then
    doB();
else if c() then
    doB()
else
    doElse();
end if;
```

An example `if` statement with two conditions and no else branch:

```
if a() then
    doA();
else if b() then
    doB();
end if;
```

## Case Statement

## While Loop

If `e` is an expression of type `Boolean` and `b` is a statement, then:

```
while e do
    b;
end while;
```

is a while loop that iterates as long as `e` evaluates to `true`.

Examples:

```
-- An infinite loop
while true do
    doForever();
end while;
```

## For Loop

If `i` is an identifier, `s` is an expression of type `Natural64`, `f` is an
expression of type `Natural64`, and `b` is a statement, and `s <= f`, then:

```
for i from s to f do
    b;
end for;
```

is a for loop where `b` is executed once for each value of `i` in the interval
`[s, f]`.

Examples:

```
for i from 0 to n do
    doSomething(i);
end for;
```

## Borrow Statement

## Discarding Statement

If `e` is an expression, then:

```
e;
```

Evaluates that expression and discards its value.

Note that discarding statements are illegal where `e` is of a linear type.

## Return Statement

If `e` is an expression, then:

```
return e;
```

Returns from the function with the value `e`.

Note that `return` statements are illegal where there are unconsumed linear
values.

## Paths {#paths}

[describe the semantics of paths here]
