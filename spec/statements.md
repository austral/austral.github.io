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

## Let Destructure Statement

## Assignment Statement

## If Statement

Examples:

```
if test() then
    doSomething();
end if;
```

```
if test() then
    doSomething();
else
    doSomethingElse();
end if;
```

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
