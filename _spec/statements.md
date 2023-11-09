# Statements {#stmt}

This section describes the semantics of Austral statements.

## Skip Statement {#stmt-skip}

The `skip` statement is a no-op;

Example:

```austral
skip;
```

## Let Statement {#stmt-let}

If `N` is an identifier, `T` is a type specifier, and `E` is an expression of
type `T`, then:

```austral
let N: T := e;
```

is a `let` statement which defines a variable with name `N`, type `T`, and
initial value `E`.

A `let` statement is one of the few places where type information flows forward:
the declared type is used to disambiguate the type of the expression when the
expression is, for example, a call to a return-type polymorphic function.

## Let-destructure Statement {#stmt-let-destructure}

A let-destructure statement is used to break apart records, creating a binding
for each field in the record.

The utility of this is: when you have a linear record type, you can't extract
the value of a linear field from it, because it consumes the record as a whole,
and leaves unconsumed any other linear fields in the record. So the record must
be broken up into its constituent values, and then optionally reassembled.

If `R` is an expression of type `T`, and `T` is a record type with field set
`{R_1: T_1, ..., R_n: T_n}`, then:

```austral
let {R_1: T_1, ..., R_n: T_n} := R;
```

is a let-destructure statement.

Since there are likely to be collisions between record field names and existing
variable names, let-destructure statements optionally support binding to a
different name.

If `R` is an expression of type `T`, and `T` is a record type with field set
`{R_1: T_1, ..., R_n: T_n}`, and `N_i` is an identifier, then:

```austral
let {..., R_i as N_i: T_i, ...} := R;
```

is a let-destructure statement with renaming. None, some, or all of the
bindings may be renamed.

An example of a let-destructure statement with no renaming:

```austral
let { symbol: String, Z: Nat8, A: Nat8 } := isotope;
```

An example of a let-destructure statement with some bindings renamed:

```austral
let { symbol: String, Z as atomic_number: Nat8, A as mass_number: Nat8 } := isotope;
```

## Assignment Statement {#stmt-assign}

If `P` is an lvalue of type `T` and `E` is an expression of type `T`, then:

```austral
P := E;
```

is an assignment statement that stores the value of `E` in the location denoted by `P`.

[TODO: describe the semantics of lvalues]

## If Statement {#stmt-if}

If `{e_1, ..., e_n}` is a set of expression of boolean type, and `{b_1, ...,
b_n, b_else}` is a set of statements, then:

```austral
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

```austral
if test() then
    doSomething();
end if;
```

An example `if` statement with a `true` branch and a `false` branch:

```austral
if test() then
    doSomething();
else
    doSomethingElse();
end if;
```

An example `if` statement with three conditions and an else branch:

```austral
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

```austral
if a() then
    doA();
else if b() then
    doB();
end if;
```

## Case Statement {#stmt-case}

If `E` is an expression of a union type with cases `{C_1, ..., C_n}` and each
case has slots `C_i = {S_i1: T_i1, ..., S_in T_im}`, and `{B_1, ..., B_n}` is a
set of statements, then:

```austral
case E of
    when C_1(S_11: T_11, S_12: T_12, ..., S_1m: T_1m) do
        B_1;
    ...
    when C_n(S_n1: T_n1, S_n2: T_n2, ..., S_nm: T_nm) do
        B_n;
end case;
```

is a `case` statement.

Case statements are used to break apart unions. For each case in a union, there
must be a corresponding `when` clause in the `case` statement. Analogously: for
each slot in a union case, the corresponding `when` clause must have a binding
for that slot.

An example of using the `case` statement on a union whose cases have no slots:

```austral
union Color: Free is
    case Red;
    case Green;
    case Blue;
end;

let C : Color := Red();
case C of
    when Red do
        ...;
    when Green do
        ...;
    when Blue do
        ...;
end case;
```

An example of using the `Option` type:

```austral
let o: Option[Int32] := Some(10);
case o of
    when Some(value: Integer_32) do
        -- Do something with `value`.
    when None do
        -- Handle the empty case.
end case;
```

An example of using the `Either` type:

```austral
let e: Either[Bool, Int32] := Right(right => 10);
case e of
    when Left(left: Bool) do
        -- Do something with `left`.
    when Right(right: Int32) do
        -- Do something with `right`.
end case;
```

Since there are likely to be collisions between union case slot names and existing
variable names, case statements optionally support binding to a
different name.

If `E` is an expression of a union type with cases `{C_1, ..., C_n}` and each
case has slots `C_i = {S_i1: T_i1, ..., S_in T_im}`, and `{B_1, ..., B_n}` is a
set of statements, and `N_ij` is an identifier, then:

```austral
case E of
    ...
    when C_i(..., S_ij as N_ij: T_ij, ...) do
        B_i;
    ...
end case;
```

is a `case` statement with renaming. None, some, or all of the bindings may be
renamed.

An example of a case statement with a renamed binding:

```austral
case response of
    when Some(value as payload: String) do
        -- do something with the response payload
    when None do
        -- handle the failure case
end case;
```

## While Loop {#stmt-while}

If `e` is an expression of type `Bool` and `b` is a statement, then:

```austral
while e do
    b;
end while;
```

is a while loop that iterates as long as `e` evaluates to `true`.

Examples:

```austral
-- An infinite loop
while true do
    doForever();
end while;
```

## For Loop {#stmt-for}

If `i` is an identifier, `s` is an expression of type `Nat64`, `f` is an
expression of type `Nat64`, and `b` is a statement, and `s <= f`, then:

```austral
for i from s to f do
    b;
end for;
```

is a for loop where `b` is executed once for each value of `i` in the interval
`[s, f]`.

Examples:

```austral
for i from 0 to n do
    doSomething(i);
end for;
```

## Borrow Statement {#stmt-borrow}

If `X` is a variable of a linear type `T`, `X'` is an identifier, `R` is an
identifier, and `B` is a statement, then:

```austral
borrow X as X' in R do
  B;
end;
```

Is a borrow statement that borrows the variable `X` as a reference `X'` with
type `&[T, R]` in a new region named `R`.

The variable `X'` is usable only in `B`, dually, the variable `X` cannot be used
in `B`, i.e. while it is borrowed.

The mutable form of the borrow statement is:

```austral
borrow! X as X' in R do
  B;
end;
```

The only difference is that the type of `X'` is `&![R, T]`.

## Discarding Statement {#stmt-discard}

If `e` is an expression, then:

```austral
e;
```

Evaluates that expression and discards its value.

Note that discarding statements are illegal where `e` is of a linear type.

## Return Statement {#stmt-return}

If `e` is an expression, then:

```austral
return e;
```

Returns from the function with the value `e`.

Note that `return` statements are illegal where there are unconsumed linear
values.
