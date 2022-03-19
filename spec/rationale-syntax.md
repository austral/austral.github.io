---
title: Syntax
---

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

Austral's syntax is from the Wirth tradition: more Ada-like or Pascal-like than
C-like. Concretely, this means:

1. The syntax is statement-oriented rather than expression-oriented.
2. The syntax prefers keywords over symbols, e.g. `begin` and `end` rather than
   `{` and `}`, `bind` over `>>=`, etc.
3. Terminating keywords include the name of the construct they terminate,
   e.g. `end if`, `end for`, etc.

These decisions will be justified individually.

## Statement Orientation

Three kinds of syntax.

Pure expression oriented

Simple, general. Alan Perlis symmetry quote. Simpler to evaluate.

In pure syntaxes, everything feels like its hanging off. Generality is a
problem: deeply nested code, nothing forces you to factor out into separate
functions.

Midpoint

Unprincipled. Textual syntax doesn't match internal AST. Possible to write
'interesting' code: `let x = { let y; }`.

Statement oriented

Two categories of syntax. Lambdas and short functions are very verbose. Does not
allow deep nesting of code, when disablimg unitiliazed variables, forces you to
refactor things into tiny functions.

Historical example: ALGOL W was expression oriented, Pascal was statement
oriented.

## Terseness versus Verbosity

Verbose enough to be readable, terse enough that people will not be discouraged
from factoring code into many small functions and types.

## Keywords over Symbols

Austral syntax uses English-language words in place of symbols. This is because
words are easier to search for, both locally and on a search engine, than a
string of symbols.

Additionally, words are read into sounds, while a string like `>>=` can only be
understood atomically.

Using English-language keywords, however, does not mean we use a natural
language inspired syntax, like Inform7. The problem with programming languages
that use an English-like natural language syntax is that the syntax is a facade:
programming languages are formal languages, sentences in a programming language
have a rigid and ideally unambiguous interpretation.

Programming languages should not hide their formal nature under a "friendly"
facade of natural language syntax.

## Terminating Keywords

In Austral, delimiters include the name of the construct they terminate. This is
after Ada (and the Wirth tradition) and is in contrast to the C traidition. The
reason for this is that it makes it easier to find where one is in the code.

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
                    // Hundreds and hundreds of lines.
                }
            }
        }
    }
}
```

Then, when we scroll to the bottom of the function to add the code, we find this:

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

1. The end of the first `if` statement.
2. The end of the second `for` loop.
3. The end of the first `if` statement.
4. The end of the first `for` loop.
5. The end of the function `f`.

Thus, delimiters which include the name of the construct they terminate involve
more typing, but make code more readable.

However, declarations end with a simple `end`, not including the name of the
declaration construct. This is because declarations are rarely nested, and
including the name of the declaration would be unnecessarily verbose.

## Semicolons

It is a common misconception that semicolons are needed for the compiler to know
where a statement or expression ends. That is, that without semicolons,
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
