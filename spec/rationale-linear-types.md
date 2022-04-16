---
title: Linear Types
---

Resource-aware type systems can remove large categories of errors that have
caused endless security vulnerabilities in a simple way. This section describes
the options.

## Linear Types

A _linear type_ is a type whose values can only be used once. This restriction
is not as useless or restrictive as it may appear.

Linear types give us the following benefits:

1. Manual memory management without memory leaks, use-after-`free`, double
   `free` errors, garbage collection, or any runtime overhead in either time or
   space other than having an allocator available.

2. More generally, we can manage _any_ resources (file handles, socket handles,
   etc.) that has a lifecycle in a way that prevents:

   1. Forgetting to dispose of that resource (e.g.: leaving a file handle open).
   2. Disposing of the resource twice (e.g.: trying to delete a file twice).
   3. Using that resource after it has been disposed of (e.g.: reading from a
      closed socket).

  All of these errors are prevented _statically_, again without runtime
  overhead.

3. In-place optimization. We can write code in a functional style, as if we were
   creating new copies of objects, while doing extensive mutations under the
   hood. This gives us the benefits of functional programming (referential
   transparency and equational reasoning) with the performance of imperative
   code that mutates data wildly.

4. Safe concurrency. A value of a linear type, by definition, has only one
   owner: we cannot duplicate it because we can only use it once. So imperative
   mutation is safe, since we know that no other thread can write to our linear
   value while we work with it.

5. Safe imperative side effects. With linear types, we can have functions that
   cause side effects (e.g. printing to the console) in a purely-functional,
   referentially-transparent programming language. Conceptually, a
   side-effectful function is one that takes a linear value representing "the
   state of the world at present", and returns a linear value of the same type,
   representing "the state of the world after this function executed".

### Examples

To see how linear types provide these benefits, we now consider concrete
examples. Examples in this section are in pseudocode. Two things to note: first,
a type name that is suffixed by an exclamation mark denotes a linear
type. Second, we use tuple destructuring, e.g. `let (a: A, b: B) := f(x);` is
equivalent to

```
let tuple := f(x);
let a: A := tuple[0];
let b: B := tuple[1];
```

Here is a simple linear program:

```
let x: T! = f();
dispose(x);
```

The function `f` returns a linear value of a linear type `T!`, which we bind to
the variable `x`. Then we pass `x` to `dispose` to free its underlying
resources. When we pass a value of a linear type to an expression (e.g. a
function), we say that it is `consumed`.

The program is trivially correct: we (and the compiler) can plainly see the
value is used once. Similarly, this program is trivialy incorrect:

```
let x: T! = f();
```

`x` is never consumed by any expression, so this is a compiler error. Let's try
to leak `x`. What if, instead of calling `dispose`, we call another function:

```
let x: T! = f();
do_something(x);
```

Here, `do_something` returns void. Now, if a function consumes a value of a linear type, it has basically three options:

1. Call the destructor of that value, e.g. `free` for a pointer, `fclose` for a
   file etc.
2. Return the value unchanged (e.g. the identity function, which is obviously
   linear).
3. Return a new value that results from transforming the linear value it
   consumed.

Since `do_something` returns void, we're guaranteed that at some point, either
directly or transitively, `x` is disposed of and cannot leak.

How can we get around the "use once" restriction? By returning the values we
pass.

Consider the following API:

```
File! openFile(String path);
File! writeString(File! file, String content);
void closeFile(File! file);
```

The `openFile` function takes a string and returns a linear file object. The
`writeString` function takes a file object and a string, and returns a file
object. The `closeFile` function takes a file object and returns nothing. If
possible, ignore the implementation.

You can use this API as follows:

```
File! file = openFile("hello.txt");
File! file' = writeString(file, "Linear types can change the world!");
closeFile(file');
```

This respects the use-once restriction of linearity: `file` is used once in
`writeString`, which returns a "new" file object called `file'`. Then `file'` is
used once in `closeFile`.

You might be asking: how does `writeString` respect linearity, clearly it is
consuming a file object, and then returning it. The answer involves the concept
of a _trust boundary_: inside the `File!` type is a plain old fashioned
(unrestricted, non-linear) pointer, underneath `closeFile` is plain old C
`fclose`. Clients of this API cannot access the pointer since this would allow
for duplication. But `writeString` can unwrap the `File!` object to access the
pointer within. Then it writes the string to it, and returns the pointer inside
a new `File!` object. From the compiler's perspective, these are distinct
values.

So, the interior of the trust boundary contains a light amount of unsafe FFI
code (which must be thoroughly tested). However, the interface is linear, and
clients of this interface can only use it correctly.

Programmers intuitively understand the inteded usage pattern: we open a file, we
write to it zero or more times, and then we close it. Graphically, this data
flow can be represented like this:

[]

But note how most programming languages _do not_ enforce this contract. In a
language without linear types, the data flow graph looks like this:

[]

That is: we can close a file after closing it, or we can write to a file after
closing the file handle. These types of errors have to be checked at runtime,
and are often dealt with by throwing an exception. Linear types allow us to
prevent all of these errors at compile time: they enforce _when_ and _how many
times_ you can use data. In a sense, they are "temporal contracts".

To prove this, let's try to break the above code. Let's try to close the file
twice, analogous to "double free" vulnerabilities:

```
closeFile(file');
closeFile(file');
```

The compiler will object that we are using a variable of a linear type multiple
times. Similarly, if we try to write to the file after closing it:

```
closeFile(file');
writeString(file', "I am not allowed to be!");
```

The compiler will point out that `file'` has already been consumed.

### Conclusion

Despite these obvious benefits, adoption of linear types has been slow because
the "use once" restriction is very onerous. Many schemes have been proposed to
simplify or ease this restriction. The Rust programming languages (which does
not have linear types, but a more sophisticated ownership tracking system)
implements a _borrowing scheme_ that can be used in a type system with linear
types to greatly improve programmer ergonomics.

There are a number of ways to implement a linear type system:

1. **Linearity via arrows**, as in the linear types extension of the GHC
   compiler for Haskell. This is the closest to Girard's linear logic.

2. **Linearity via kinds**, which involves partitioning the universe of types
   into two: a universe of unrestricted values which can be copied freely, such
   as integers, and a universe of restricted or linear types.

3. **Rust's approach**, which involves which is a sophisticated, fine-grained
   ownership tracking scheme.

In my opinion, linearity via arrows is best suited to an ML family language with
single-parameter functions.

Rust's ownership tracking scheme allows programmers to write code that looks
quite ordinary, frequently using values multiple times, while retaining
"linear-like" properties. Ordinarily the restrictions show up when compilation
fails.

The Rust approach prioritizes programmer ergonomics, but it has a downside: the
ownership tracking scheme is not a fixed algorithm that is set in stone in a
standards document, which programmers are expected to read in order to write
code. Rather, it is a collection of rules, which evolve with the language,
generally in the direction of removing onerous restrictions and allowing
programmers to focus on the problem at hand rather than bending the code to fit
the ownership scheme. Consequently, Rust programmers often describe a learning
curve with a period of "fighting the borrow checker" until the program compiles,
until they become used to the rules.

Compare this with type checking algorithms: type checking is a simple, inductive
process, so much so that programmers effectively run the algorithm while reading
code to understand how it behaves. It often does not need documenting because it
is obvious whether or not two types are equal or compatible, and the "warts" are
generally in the area of implicit integer or float type conversions in
arithmetic.

Austral takes the approach that a language should be _simple enough that it can
be understood entirely by a single person reading the
specification_. Consequently, a programmer should be able to read a brief set of
linearity checker rules, and afterwards be able to write code without fighting
the system, or failing to understand how or why some code compiles.

In short: we sacrifice terseness and programmer ergonomics for
simplicity. Simple to learn, simple to understand, simple to reason about.

To do this, we choose linearity via kinds, because it provides the simplest way
to implement a linear type system. The set of unrestricted types is called the
"free universe" and is denoted `Free` (because `Unrestricted` takes too much
typing) and the set of restricted or linear types is called the "linear
universe" and is denoted `Linear`.

Linearity via kinds interacts with polymorphism and with the definition of
linear types, see section so and so.

## Affine Types

In the presence of error handling, linear types become affine types.
