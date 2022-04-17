---
title: Expressions
---

This section describes the semantics of Austral expressions.

## Nil Constant

The expression:

```austral
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

[TODO]

## Variable Expression

An identifier that's not the nil or boolean constants is a local variable or
global constant, whose type is determined from the lexical environment.

## Arithmetic Expression

If `a` and `b` are two expressions of the same integer or floating point type
`N`, then:

```austral
a+b
a-b
a*b
a/b
```

are all expressions of type `N`.

In the case of division, two rules apply:

- If `b` is zero: the program aborts due to a division-by-zero error.
- If `N` is a signed integer type, and `a` is the minimum value that fits in
  that integer type, and `b` is -1: the program aborts due to a signed integer
  overflow error.

## Function Call

If $$\text{f}$$ is the name of a function with parameters $$\{\text{p}_1:
\tau_1, \dots, \text{p}_n: \tau_n\}$$ and return type $$\tau_r$$, and we have a
set of expressions $$\{e_1: \tau_1, \dots, e_n: \tau_n\}$$, then:

\\[
\text{f}(e_1, \dots, e_n)
\\]

and:

\\[
\text{f}(\text{p}_1 \Rightarrow e_1, \dots, \text{p}_n \Rightarrow e_n)
\\]

are identical function call expression whose type is $$\tau_r$$.

## Method Call

Let $$\text{m}$$ be the name of a method in a typeclass $$\text{t}$$. After
[instance resolution](/spec/type-classes#instance-resolution) the method has
parameters $$\{\text{p}_1: \tau_1, \dots, \text{p}_n: \tau_n\}$$ and return type
$$\tau_r$$. Given a set of expressions $$\{e_1: \tau_1, \dots, e_n: \tau_n\}$$,
then:

\\[
\text{m}(e_1, \dots, e_n)
\\]

and:

\\[
\text{m}(\text{p}_1 \Rightarrow e_1, \dots, \text{p}_n \Rightarrow e_n)
\\]

are identical method call expression whose type is $$\tau_r$$.

## Record Constructor

If $$\text{r}$$ is the name of a record type with slots $$\{\text{s}_1: \tau_1,
\dots, \text{s}_n: \tau_n\}$$, and we have a set of expressions $$\{e_1: \tau_1,
\dots, e_n: \tau_n\}$$, then:

\\[
\text{r}(\text{s}_1 \Rightarrow e_1, \dots, \text{s}_n \Rightarrow e_n)
\\]

is a record constructor expression which evaluates to an instance of
$$\text{r}$$ containing the given values.

## Union Constructor

Let $$\text{u}$$ be a union type, with a case named $$\text{c}$$ with slots
$$\{\text{s}_1: \tau_1, \dots, \text{s}_n: \tau_n\}$$, and we have a set of
expressions $$\{e_1: \tau_1, \dots, e_n: \tau_n\}$$, then:

\\[
\text{c}(\text{s}_1 \Rightarrow e_1, \dots, \text{s}_n \Rightarrow e_n)
\\]

is a union constructor expression which evaluates to an instance of $$\text{u}$$
with case $$\text{c}$$ and the given values.

As a shorthand, if the slot set has a single value, $$\{\text{s}: \tau\}$$, and
the set of expressions also has a single value $$\{e\}$$, then a simplified form
is possible:

\\[
\text{c}(\text{s})
\\]

is equivalent to:

\\[
\text{c}(\text{s} \Rightarrow e)
\\]

## Type Alias Constructor

If $$\text{t}$$ is the name of a type alias with definition $$\tau$$, and $$e$$
is an expression of type $$\tau$$, then:

\\[
\text{t}(e)
\\]

evaluates to an instance of $$\text{t}$$ containing the value $$e$$.

## Cast Expression

The cast expression has four uses:

1. Clarifying the type of integer and floating point constants.

2. Converting between different integer and floating point types (otherwise, you
   get a combinatorial explosion of typeclasses).

3. Converting write references to read references.

4. Clarifying the type of return type polymorphic functions.

If $$e$$ is an expression and $$\tau$$ is a type, then:

\\[
e : \tau
\\]

is the expression that tries to cast $$e$$ to $$\tau$$, and it evaluates to a
value of type $$\tau$$.

Semantics:

1. If $$e$$ is an integer constant that fits in $$\tau$$ (e.g.: $$e$$ can't be a
   negative integer constant if $$\tau$$ is `Natural8`) then $$e : \tau$$ is
   valid.

2. If $$e$$ is an integer or floating point type, and $$\tau$$ is an integer or
   floating point type, then $$e : \tau$$ is valid.

3. If $$e: WriteReference[T, R]$$ and $$\tau$$ is $$Reference[T, R]$$, then $$e:
   \tau$$ is valid and downgrades the write reference to a read reference.

4. If $$e$$ is a call to a return type-polymorphic function or method, and
   $$\tau$$ can clarify the return type of $$e$$, then $$e : \tau$$ is a valid
   expression.

## Comparison Expression

If $$a$$ and $$b$$ are both expressions of Boolean type, then:

\\[
\begin{align}
a &=    b \newline
a &\neq   b \newline
a &\lt  b \newline
a &\leq b \newline
a &\gt  b \newline
a &\geq b
\end{align}
\\]

are comparison expressions with type `Boolean`.

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

If `c` is a Boolean-typed expression, and `t` and `f` are expressions of the
same type `T`, then:

```austral
if c then t else f
```

is an `if` expression. `c` is evaluated first, if is `true`, `t` is evaluated
and its value is returned. Otherwise, `f` is evaluated and its value is
returend. The result has type `T`.

## Path Expression

The syntax of a path is: an expression called the *head* followed by a non-empty
list of *path elements*, each of which is one of:

1. A *slot accessor* of the form `.s` where `s` is the name of a record slot.
2. A *pointer slot accessor* of the form `->s` where `s` is the name of a record
   slot.
3. An *array indexing element* of the form `[i]` where `i` is a value of type
   `Index`.

Path expressions are used for:

1. Accessing the contents of slots and arrays.

2. Transforming references to records and arrays into references to their contents.

Semantics:

1. All paths must end in a path in the `Free` universe. That is, if `x[23]->y.z`
   is a linear type, the compiler will complain.

2. A path that starts in a reference is a reference. For example, if `x` is of
   type `Reference[T, R]`, then the path `x->y->z` (assuming `z` is a record
   slot with type `U`) is of type `Reference[U, R]`.

Examples:

```austral
pos.x
star->pos.ra
stars[23]->distance
```

## Dereference Expression

If `e` is a reference to a value of type `T`, then:

```austral
!e
```

is a dereferencing expression that evaluates to the referenced value of type `T`.

## Sizeof Expression

If `T` is a type specifier, then:

```austral
sizeof(T)
```

is an expression of type `Index` that evaluates to the size of the type in bytes.
