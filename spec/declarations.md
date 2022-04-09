---
title: Declarations
---

This section describes the kind of declarations that can appear in Austral
modules.

## Opaque Constant {#opaque-constant}

If `C` is an identifier, `T` is a type specifier, then:

```
constant C : T;
```

is an opaque constant declaration.

These can only appear in the module interface file, and must be accompanied by a
matching constant declaration in the module body file.

Example:

```
module Example is
    -- Defines a public constant `Pi`, which can be imported
    -- and used by other modules.
    constant Pi : DoubleFloat;
end module.

module body Example is
    -- An opaque constant declaration needs a matching constant
    -- definition in the module body.
    constant Pi : DoubleFloat := 3.14;
end module body.
```

## Constant Definition {#constant-definition}

If `C` is an identifier, `T` is a type specifier, and `E` is a constant
expression of type `T`, then:

```
constant C : T := V;
```

Defines a constant named `C` of type `T` with a value of `V`.

Constant definitions can only appear in the module body file.

If the module interface file has a corresponding opaque constant declaration,
then the constant is public and can be imported by other modules. Otherwise, it
is private.

Example:

```
module body Example is
    -- If there is no corresponding opaque constant declaration
    -- in the module interface file, then this constant is private
    -- and can't be used by other modules.
    constant Pi : DoubleFloat := 3.14;
end module body.
```

## Opaque Type Alias {#opaque-type-alias}

If `T` is an identifier, `{P_1: K_1, ..., P_n: K_n}` is a set of type
parameters, and `U` is a universe, then:

```
type T[P_1: K_1, ..., P_n: K_n]: U;
```

is an opaque type alias declaration.

Opaque type alias declarations can only appear in the module interface
file. They tell us that the module will define a type with a given name, type
parameter set, and universe, and this type name can be imported and used by
other modules, but they don't tell us the definition of the type, which remains
opaque. Consequently: client modules cannot directly construct, or extract
information from, an opaque type.

Opaque type alias declarations are useful when we want to define a type whose
contents are obscure or which is correct by construction.

For example, suppose we want to define a type of usernames for a forum
software. A username is a string, but most strings are not usernames: the
complete works of Shakespeare are a string, but should decidedly not be a valid
username.

To make things type-safe, we can define a module which exports three things:

- An opaque `Username` type.
- A function that takes a string, checks that it is a valid username, and
  returns a `Username` value that contains that string on success.
- A function that takes a `Username` and returns the underlying string.

The module interface would look like this:

```
module App.Username is
    type Username: Linear;

    function makeUsername(name: String): Option[Username];

    function usernameToString(username: Username): String;
end module.
```

Since `Username` is opaque, the only way for a client module to create an
instance of `Username` is to go through the `makeUsername` function, which
should validate that the input string satisfies a username regex. This is
correctness-by-construction: we are guaranteed that an instance of `Username`
contains a string that has satisfied the regex.

The module body would look something like this:

```
module body App.Username is
    record Username: Linear is
        name: String;
    end;

    function makeUsername(name: String): Option[Username] is
        if (validUsername(&name)) then
            return Some(Username(name => name));
        else
            return None();
        end if;
    end;

    function usernameToString(username: Username): String is
        return username.name;
    end;
end module.
```

## Type Alias Definition {#type-alias-definition}

If `T` is an identifier, and `S` is a type specifier, then:

```
type T = S;
```

Defines a type `T` that is the same as `S`. Note that this does not work like
type aliases in ML or Haskell: `T` and `S` are distinct types.

To create an instance of `T` from a value `v : S`, we have to use a `let`
statement:

```
let t : T := v;
```

This will work if:

1. The type `T` is defined in the current module.
2. The type `T` is public (not opaque) and was imported from another module.

This provides encapsulation. If `T` is an opaque type, modules that import it
cannot create instances of `T` through the `let` statement because they don't
know the definition of `T`.

## Record Definition {#record-definition}

A record is an unordered collection of values, called fields, which are
addressed by name.

If $R$ is an identifier, $\{R_0, ..., R_n\}$ is a set of identifiers, and
$\{T_0, ..., T_n\}$ is a set of type specifiers, then:

```
record R is
  R_0 : T_0;
  R_1 : T_1;
  ...
  R_n : T_n;
end
```

Defines the record `R`.

Unlike C, records in Austral are unordered, and the compiler is free to choose
how the records will be ordered and laid out in memory. The compiler must select
a single layout for every instance of a given record type.

The layout can be customized using a layout specification. For example:

```
record R is
  a : Natural16;
  b : Int8;
  c : FLoat32;

  pragma Layout(
     Field(b, 8),
     Padding(8),
     Field(a, 16),
     Field(c, 32)
  );
end
```

Will define a record `R` with the following layout:

```
| b (8 bits) | padding (8 bits) | a ( 16 bits) | c (32 bits) |
```

and a total size of 64 bits.

Record construction:

Given the record:

```
record Vector3 is
    x : Float32;
    y : Float32;
    z : Float32;
end
```

We can construct an instance of `Vector3` in two ways:

```
let V1 : Vector3 := Vector3(0.0, 0.0, 0.0);
let V2 : Vector3 := Vector3(
    x => 0.0,
    y => 0.0,
    z => 0.0
);
```

## Union Definition {#union-definition}

Unions are like datatypes in ML and Haskell. They have constructors and,
optionally, constructors have values associated to them.

When a constructor has associated values, it's either:

1. A single unnamed value.
2. A set of named values, as in a record.

For example, the definition of the `Optional` type is:

```
union Optional[T : Type] is
  case Some(T);
  case None;
end
```

```
union Color is
  case RGB(red: Nat8, green: Nat8, blue: Nat8);
  case Greyscale(Nat8);
end
```

Union creation:

```
let O2 : Optional[Int32] := None();
let O2 : Optional[Int32] := Some(10);
let C1 : Color := RGB(10, 12, 3);
let C2 : Color := RGB(
    red => 1,
    green => 2,
    blue => 3
);
let C3 : Color := Greyscale(50);
```

## Function Declaration {#function-declaration}

Let $$\text{f}$$ be an identifier, $$\{\text{p}_1: \tau_1, \dots, \text{p}_n:
\tau_n\}$$ be a set of value parameters, and $$\tau_r$$ be a type. Then:

\\[
\text{function} ~ \text{f} \(
\text{p}_1: \tau_1,
\dots,
\text{p}_n: \tau_n
\): \tau_r
;
\\]

defines a _concrete function_ $$\text{f}$$ with the given value parameter set
and return type $$\tau_r$$.

More generally, given a set of type parameter $$\{\text{tp}_1: k_1, \dots,
\text{tp}_n: k_n\}$$, then:

\\[
\begin{align\*}
& \text{generic} ~
\[
\text{tp}_1: k_1, \dots, \text{tp}_n: k_n
\] \\newline
& \text{function} ~ \text{f} \(
\text{p}_1: \tau_1,
\dots,
\text{p}_n: \tau_n
\): \tau_r
;
\end{align\*}
\\]

defines a _generic function_ $$\text{f}$$ with the given type parameter set,
value parameter set, and return type $$\tau_r$$.

There must be a corresponding function definition in the module body file that
has the same signature.

Function declarations can only appear in the module interface file.

Examples:

1. The following declares the identity function, a generic function with a
   single type parameter and a single value parameter:

   ```
   generic (t : Type)
   function Identity(x: T): T is
       return x;
   end
   ```

## Function Definition {#function-definition}

Examples:

```
function Fib(n: Natural): Natural is
    if n <= 2 then
        return n;
    else
        return Fib(n-1) + Fib(n-2);
    end if;
end
```

## Typeclass Definition {#typeclass-definition}

[TODO]

Examples:

```
typeclass Printable(T : Type) is
    method Print(value: T): Unit;
end
```

## Instance Declaration {#instance-declaration}

[TODO]

## Instance Definition {#instance-definition}

[TODO]

Examples:

```
typeclass Printable(T : Type) is
    method Print(value: T): Unit;
end

instance Printable(Int32) is
    method Print(value: Int32): Unit is
        printInt(value);
    end
end
```
