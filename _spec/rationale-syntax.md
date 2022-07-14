## Syntax

According to Wadler's Law,

>In any language design, the total time spent discussing
>a feature in this list is proportional to two raised to
>the power of its position.
>
>0. Semantics
>1. Syntax
>2. Lexical syntax
>3. Lexical syntax of comments

Therefore, I will begin by justifying the design of Austral's syntax.

Austral's syntax is characterized by:

1. Being statement-oriented rather than expression oriented.

2. Preference over English-language keywords over non-alphanumeric symbols,
   e.g. `begin` and `end` rather than `{` and `}`, `bind` over `>>=`, etc.

3. Delimiters include the name of the construct they terminate, e.g. `end if`
   and `end for`.

4. Verbose names are preferred over inscrutable abbreviations.

5. Statements are terminated by semicolons.

These decisions will be justified individually.

### Statement Orientation

Syntax can be classified into three categories.

1. **Statement-Oriented:** Like C, Pascal, and Ada. Statements and expressions
   form two distinct syntactic categories.

2. **Pure Expression-Oriented Syntax:** Like Lisp, Standard ML, OCaml, and
   Haskell. There are only expressions, and the syntax reflects this directly.

3. **Mixed Syntax:** Many newer languages, like Scala and Rust, fall into this
   category. At the AST level there is only one kind of thing: expressions. But
   the actual written syntax is made to resemble statement-oriented languages to
   make programmers more comfortable.

In _Epigrams in Programming_, Alan Perlis wrote:

> 6. Symmetry is a complexity-reducing concept (co-routines include
>    subroutines); seek it everywhere.

Indeed, expression-oriented syntax is simpler (there is no duplication between
e.g. `if` statements and `if` expressions) and symmetrical (there is only one
syntactic category of code). But it suffers from excess generality in that it is
possible to write things like:

```
let x = (* A gigantic, inscrutable expression
           with multiple levels of `let` blocks. *)
in
    ...
```

In short, nothing forces the programmer to factor things out.

Furthermore, in pure expression-oriented languages of the ML family code has the
ugly appearance of "hanging in the air", there is little in terms of delimiters.

Three kinds of syntax.

Mixed syntaxes are unprincipled because the textual syntax doesn't match the
AST, which makes it possible to abuse the syntax and write "interesting"
code. For example, in Rust, the following:

```
let x = { let y; }
```

is a valid expression. `x` has the Unit type because the block expression ends
in a semicolon, so it is evaluated to the Unit type.

A statement-oriented syntax is less simple, but it forces code to be
structurally simple, especially when combined with the restriction that
uninitialized variables are not allowed. Then, the programmer is forced to
factor out complicated control flow into chains of functions.

Historically, there is one language that moved from an expression-oriented to a
statement-oriented syntax: ALGOL W was expression-orienten; Pascal, its
successor, was statement-oriented.

### Keywords over Symbols

Austral syntax prefers English-language words in place of symbols. This is
because words are easier to search for, both locally and on a search engine,
than a string of symbols.

Additionally, words are read into sounds, which aids in remembering them, while
a string like `>>=` can only be understood as a visual symbol.

Using English-language keywords, however, does not mean we use a natural
language inspired syntax, like Inform7. The problem with programming languages
that use an English-like natural language syntax is that the syntax is a facade:
programming languages are formal languages, sentences in a programming language
have a rigid and ideally unambiguous interpretation.

Programming languages should not hide their formal nature under a "friendly"
facade of natural language syntax.

### Terminating Keywords

In Austral, delimiters include the name of the construct they terminate. This is
after Ada (and the Wirth tradition) and is in contrast to the C tradition. The
reason for this is that it makes it easier to find one's place in the code.

Consider the following code:

```
void f() {
    for (int i = 0; i < N; i++) {
        if (test()) {
            for (int j = 0; j < N; j++) {
                if (test()) {
                    g();
                }
            }
        }
    }
}
```

Suppose we want to add some code after the second for loop. In this case, it's
simple enough:

```
void f() {
    for (int i = 0; i < N; i++) {
        if (test()) {
            for (int j = 0; j < N; j++) {
                if (test()) {
                    g();
                }
            }
            // New code goes here.
        }
    }
}
```

But suppose that instead of a call to `g()` we have multiple pages of
code:

```
void f() {
    for (int i = 0; i < N; i++) {
        if (test()) {
            for (int j = 0; j < N; j++) {
                if (test()) {
                    // Hundreds and hundreds of lines here.
                }
            }
        }
    }
}
```

Then, when we scroll to the bottom of the function to add the code, we find this
train of closing delimiters:

```
                }
            }
        }
    }
}
```

Which one of these corresponds to the second `for` loop? Unless we have an
editor with folding support, we have to find the column where the second `for`
loop begins, scroll down to the closing curly brace at that column position, and
insert the code there. This is manual and error-prone.

Consider the equivalent in an Ada-like syntax:

```
function f() is
    for (int i = 0; i < N; i++) do
        if (test()) then
            for( int j = 0; j < N; j++) do
                if (test()) then
                    g();
                end if;
            end for;
        end if;
    end for;
end f;
```

Then, even if the code spans multiple pages, finding the second `for` loop is easy:

```
                end if;
            end for;
        end if;
    end for;
end f;
```

We have, from top to bottom:

1. The end of the second `if` statement.
2. The end of the second `for` loop.
3. The end of the first `if` statement.
4. The end of the first `for` loop.
5. The end of the function `f`.

Thus, delimiters which include the name of the construct they terminate involve
more typing, but make code more readable.

Note that this is often done in C and HTML code, where one finds things like this:

```
} // access check
```

or,

```
</table> // user data table
```

However, declarations end with a simple `end`, not including the name of the
declaration construct. This is because declarations are rarely nested, and
including the name of the declaration would be unnecessarily verbose.

### Terseness versus Verbosity

The rule is: verbose enough to be readable without context, terse enough that
people will not be discouraged from factoring code into many small functions and
types.

### Semicolons

It is a common misconception that semicolons are needed for the compiler to know
where a statement or expression ends. That is: that without semicolons,
languages would be ambiguous. This obviously depends on the language grammar,
but in the case of Austral it is not true, and the grammar would remain
unambiguous even without semicolons.

The purpose of the semicolon is to provide _redundancy_, which aids both reading
and parser error recovery. For example, in the following code:

```
let x : T := f(a, b, c;
```

The programmer has forgotten the closing parenthesis in a function
call. However, the parser can report the error as soon as it encounters the
semicolon.

For many people, semicolons represent the distinction between an old and crusty
language and a modern one, in which case the semicolon serves a function similar
to the use of Comic Sans by the OpenBSD project.

### Syntax of Type Declarations

The syntax of type declarations it designed to make explicit the analogy between
functions and generic types: that is, generic types are essentially functions
from types to a new type.

Where function declarations look like this:

```
\text{function} ~ \text{f} \( \text{p}_1: \tau_1, \dots, \text{p}_1: \tau_1 \): \tau_r ;
```

A type declaration looks like:

```
\text{type} ~ \tau \[ \text{p}_1: k, \dots, \text{p}_1: k \]: u ;
```

Here, type parameters are analogous to type parameters, kinds are analogous to
types, and the universe is analogous to the return type.
