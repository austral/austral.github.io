---
title: Expressions
---

This section describes the semantics of Austral expressions.

## Nil Constant

The expression:

```
nil
```

has type `Unit`.

## Boolean Constant

The Boolean constants are the identifiers `true` and `false`.

## Integer Constant

Integer constants have type `Integer32` by default, but to improve programmer
ergonomics, the compiler will try to find a type for an integer constant that
makes the surrounding context work. E.g., if `x` is of type `Natural8`, then an
expression like `x + 3` will work, and the `3` will be interpreted to have type
`Natural8`.

## Float Constant

Floating-point number constants have type `DoubleFloat`.

## String Constant

## Variable Expression

## Arithmetic Expression

## Function Call

## Method Call

## Record Constructor

## Union Constructor

## Type Alias Constructor

If `T` is the name of a type alias with definition `U`, and `e` is an expression of type `U`, then:

```
T(e)
```

evaluates to an instance of `T` containing the value `e`.

## Cast Expression

## Comparison Expression

## Conjunction Expression

If `a` and `b` are Boolean-typed expressions, then `a and b` is the
short-circuiting and operator and evaluates to a Boolean value.

## Disjunction Expression

If `a` and `b` are Boolean-typed expressions, then `a or b` is the
short-circuiting or operator, and evaluates to a Boolean value.

## Negation Expression

If `e` is a Boolean-typed expression, then `not e` evaluates to the negation of
the value of `e`, a Boolean value.

## If Expression

If `c` is a Boolean-typed expression, and `t` and `f` are expressions of the same type `T`, then:

```
if c then t else f
```

is an `if` expression. `c` is evaluated first, if is `true`, `t` is evaluated
and its value is returned. Otherwise, `f` is evaluated and its value is
returend. The result has type `T`.

## Path Expression

[paths]

## Dereference Expression

If `e` is an expression of type `Reference[T, R]` or `WriteReference[T,

## Sizeof Expression

If `T` is a type specifier, then:

```
sizeof(T)
```

is an expression of type `Index` that evaluates to the size of the type in bytes.
