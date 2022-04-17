---
title: Linear Types
---

Resource-aware type systems can remove large categories of errors that have
caused endless security vulnerabilities in a simple way. This section describes
the options.

This section begins with the motivation for linear types, then explains what
linear types are and how they provide safety.

## Resources and Lifecycles

Consider a file handling API:

```
type File

File openFile(String path)

File writeString(File file, String content)

void closeFile(File file)
```

An experienced programmer understands the _implicit lifecycle_ of the `File`
object:

1. We create a `File` handle by calling `openFile`.
2. We write to the handle zero or more times.
3. We close the file handle by calling `closeFile`.

We can depict this graphically like this:

![A graph with three nodes labeled 'openFile', 'writeString', and 'close File'. There are four arrows: from 'openFile' to 'writeString', from 'openFile' to 'closeFile', from 'writeString' to itself, and from 'writeString' to 'closeFile'.](/assets/spec/file-api.png)

But, crucially: this lifecycle is _not enforced by the compiler_. There are a
number of erroneous transitions that we don't consider, but which are
technically possible:

![The graph from the previous figure, with a new node labeled 'leak', and with four new arrows in red: one from 'closeFile' to itself labeled 'double close', one from 'closeFile' to 'writeString' labeled 'use after close', one from 'openFile' to 'leak' labeled 'forgot to close', and one from 'writeString' to 'leak' also labeled 'forgot to close'.](/assets/spec/file-api-errors.png)

These fall into two categories:

1. **Leaks:** we can forget to call `closeFile`, e.g.:

    ```
    let file = openFile("hello.txt")
    writeString(file, "Hello, world!")
    // Forgot to close
    ```

2. **Use-After-Close:** and we can call `writeString` on a `File` object that
   has already been closed:

   ```
   closeFile(file)
   writeString(file, "Goodbye, world!");
   ```

   And we can close the file handle after it has been closed:

   ```
   closeFile(file);
   closeFile(file);
   ```

In a short linear program like this, we aren't likely to make these
mistakes. But when handles are stored in data structures and shuffled around,
and the lifecycle calls are separated across time and space, these errors become
more common.

And they don't just apply to files. Consider a database access API:

```
type Db

Db connect(String host)

Rows query(Db db, String query)

void close(Db db)
```

Again: after calling `close` we can still call `query` and `close`. And we can
also forget to call `close` at all.

And --- crucially --- consider this memory management API:

```
type Pointer<T>

Pointer<T> allocate(T value)

T load(Pointer<T> ptr)

void store(Pointer<T> ptr, T value)

void free(Pointer<T> ptr)
```

Here, again, we can forget to call `free` after allocating a pointer, we can
call `free` twice on the same pointer, and, more disastrously, we can call
`load` and `store` on a pointer that has been freed.

Everywhere we have _resources_ --- types with an associated lifecycle, where
they must be created, used, and destroyed, in that order --- we have the same
kind of errors: forgetting to destroy a value, or using a value after it has
been destroyed.

In the context of memory management, pointer lifecycle errors are so disastrous
they have their own names:

1. [Double free errors](https://owasp.org/www-community/vulnerabilities/Doubly_freeing_memory).
2. [Use-after-free errors](https://owasp.org/www-community/vulnerabilities/Using_freed_memory).

Naturally, computer scientists have attempted to attack these problems. The
traditional approach is called _static analysis_: a group of PhD's will write a
program that goes through the source code and performs various checks and finds
places where these errors may occur.

Reams and reams of papers, conference proceedings, university slides, etc. have
been written on the use of static analysis to catch these errors. But the
problem with static analysis is threefold:

1. It is a moving target. While type systems are relatively fixed --- i.e., the
   type checking rules are the same across language versions --- static
   analyzers tend to change with each version, so that in each newer version of
   the software you get more and more sophisticated heuristics.

2. Like unit tests, it can usually show the _presence_ of bugs, but not their
   _absence_. There may be false positives --- code that is perfectly fine but
   that the static analyzer flags as incorrect --- but more dangerous is the
   false negative, where the static analyzer returns an all clear on code that
   has a vulnerability.

3. Static analysis is an opaque pile of heuristics. Because the analyses are
   always changing, the programmer is not expected to develop a mental model of
   the static analyzer, and to write code with that model in mind. Instead, they
   are expected to write the code they usually write, then throw the static
   analyzer at it and hope for the best.

What we want is a way to solve these problems that is _static_ and
_complete_. Static in that it is a fixed set of rules that you can learn once
and remember, like how a type system works. _Complete_ in that is has _no false
negatives_, and _every_ lifecycle error is caught.

And, above all: we want it to be simple, so it can be wholly understood by the
programmer working on it.

So, to summarize our requirements:

1. **Correctness Requirement:** We want a way to ensure that resources are used
   in the correct lifecycle.

2. **Simplicity Requirement:** We want that mechanism to be simple, that is, a
   programmer should be able to hold it in their head. This rules out
   complicated solutions involving theorem proving, SMT solvers, symbolic
   execution, etc.

3. **Staticity Requirement:** We want it to be a fixed set of rules and not an
   ever changing pile of heuristics.

All these goals are achievable: the solution is _linear types_.

## Linear Types

This section describes what linear types are, how they provide the safety
properties we want, and how we can relax some of the more onerous restrictions
so as to increase programmer ergonomics while retaining safety.

A _type_ is a set of values that share some structure. A _linear type_ is a type
whose values can only be used once. This restriction may sound onerous (and
unrelated to the problems we want to solve), but it isn't.

A linear type system can be defined with just two rules:

1. **Linear Universe Rule:** in a linear type system, the set of types is
   divided into two _universes_: the _free_ universe, containing types which can
   be used any number of times (like booleans, machine sized integers, floats,
   structs containing free types, etc.); and the _linear_ universe, containing
   linear types, which usually represent resources (pointers, file handles,
   database handles, etc.).

   Types enter the linear universe in one of two ways:

   1. By fiat: a type can simply be declared linear, even though it only
      contains free types. We'll see later why this is useful.

      ```
      // `LInt` is in the `Linear` universe,
      // even if `Int` is in the `Free` universe.
      type LInt: Linear = Int
      ```

   2. By containment: linear types can be thought of as being "viral". If a type
      contains a value of a linear type, it automatically becomes linear.

      So, if you have a linear type `T`, then a tuple `(a, b, T)` is linear, a struct like:

      ```
      struct Ex {
          a: A;
          b: B;
          c: Pair<T, A>;
      }
      ```

      is linear because the slot `c` contains a type which in turn contains
      `T`. A union or enum where one of the variants contains a linear type is,
      unsurprisingly, linear. You can't sneak a linear type into a free type.

   The virality of linear types ensures that you can't escape linearity by accident.

2. **Use-Once Rule:** a value of a linear type must be used once and only
   once. Not _can_: _must_. It cannot be used zero times. This can be enforced
   entirely at compile time through a very simple set of checks.

   To understand what "using" a linear value means, let's look at some
   examples. Suppose you have a function `f` that returns a value of a linear
   type `L`.

   Then, the following code:

   ```
   {
       let x: L := f();
   }
   ```

   is incorrect. `x` is a variable of a linear type, and it is used zero
   times. The compiler will complain that `x` is being silently discarded.

   Similarly, if you have:

   ```
   {
       f();
   }
   ```

   The compiler will complain that the return value of `f` is being silently
   discarded, which you can't do to a linear type.

   If you have:

   ```
   {
       let x: L := f();
       g(x);
       h(x);
   }
   ```

   The compiler will complain that `x` is being used twice: it is passed into
   `g`, at which point is it said to be _consumed_, but then it is passed into
   `h`, and that's not allowed.

   This code, however, passes: `x` is used once and exactly once:

   ```
   {
       let x: L := f();
       g(x);
   }
   ```

   "Used" does not, however, mean "appears once in the code". Consider how `if`
   statements work. The compiler will complain about the following code, because
   even though `x` appears only once in the source code, it is not being "used
   once", rather it's being used --- how shall I put it? 0.5 times?:

   ```
   {
       let x: L := f();
       if (cond) {
           g(x);
       } else {
           // Do nothing.
       }
   }
   ```

   `x` is consumed in one branch but not the other, and the compiler isn't
   happy. If we change the code to this:

   ```
   {
       let x: L := f();
       if (cond) {
           g(x);
       } else {
           h(x);
       }
   }
   ```

   Then we're good. The rule here is that a variable of a linear type, defined
   outside an `if` statement, must be used either zero times in that statement,
   or exactly once in each branch.

   A similar restriction applies to loops. We can't do this:

   ```
   {
       let x: L := f();
       while (true) {
           g(x);
       }
   }
   ```

   Because even though `x` appears once, it is _used_ more than once: it is used
   once in each iteration. The rule here is that a variable of a linear type,
   defined outside a loop, cannot appear in the body of the loop.

That's it. That's all there is to it. We have a fixed set of rules, and they're
so brief you can learn them in a few minutes. So we're satisfying the simplicity
and staticity requirements listed in the previous section.

But do linear types satisfy the correctness requirement? In the next section,
we'll see how linear types make it possible to enforce that a value should be
used in accordance to a lifecycle.

## Linear Types and Safety

Let's consider a linear file system API. We'll use a vaguely C++ like syntax,
but linear types are denoted by an exclamation mark after their name.

The API looks like this:

```
type File!

File! openFile(String path)

File! writeString(File! file, String content)

void closeFile(File! file)
```

The `openFile` function is fairly normal: takes a path and returns a linear
`File!` object.

`writeString` is where things are different: it takes a linear `File!` object
(and consumes it), and a string, and it returns a "new" linear `File!`
object. "New" is in quotes because it is a fresh linear value only from the
perspective of the type system: it is still a handle to the same file. But don't
think about the implementation too much: we'll look into how this is implemented
later.

`closeFile` is the destructor for the `File!` type, and is the terminus of the
lifecycle graph: a `File!` enters and does not leave, and the object is disposed
of. Let's see how linear types help us write safe code.

Can we leak a `File!` object? No:

```
let file: File! := openFile("sonnets.txt");
// Do nothing.
```

The compiler will complain: the variable `file` is used zero
times. Alternatively:

```
let file: File! := openFile("sonnets.txt");
writeString(file, "Devouring Time, blunt thou the lion’s paws, ...");
```

The return value of `writeString` is a linear `File!` object, and it is being
silently discarded. The compiler will whine at us.

We can strike the "leak" transitions from the lifecycle graph:

![A graph with three nodes labeled 'openFile', 'writeString', and 'close File'. There are four black arrows: from 'openFile' to 'writeString', from 'openFile' to 'closeFile', from 'writeString' to itself, and from 'writeString' to 'closeFile'. There are two red arrows: one from 'closeFile' to 'writeString' labeled 'use after close', and one from 'closeFile' to itself labeled 'double close'.](/assets/spec/file-api-without-leaks.png)

Can we close a file twice? No:

```
let file: File! := openFile("test.txt");
closeFile(file);
closeFile(file);
```

The compiler will complain that you're trying to use a linear variable twice. So
we can strike the "double close" erroneous transition from the lifecycle graph:

![A graph with three nodes labeled 'openFile', 'writeString', and 'close File'. There are four black arrows: from 'openFile' to 'writeString', from 'openFile' to 'closeFile', from 'writeString' to itself, and from 'writeString' to 'closeFile'. There is one red arrow: from 'closeFile' to 'writeString' labeled 'use after close'.](/assets/spec/file-api-without-leaks-and-double-close.png)

And you can see where this is going. Can we write to a file after closing it?
No:

```
let file: File! := openFile("test.txt");
closeFile(file);
let file2: File! := writeString(file, "Doing some mischief.");
```

The compiler will, again, complain that we're consuming `file` twice. So we can strike the "use after close" transition from the lifecycle graph:

![A graph with three nodes labeled 'openFile', 'writeString', and 'close File'. There are four arrows: from 'openFile' to 'writeString', from 'openFile' to 'closeFile', from 'writeString' to itself, and from 'writeString' to 'closeFile'.](/assets/spec/file-api.png)

And we have come full circle: the lifecycle that the compiler enforces is
exactly, one-to-one, the lifecycle that we intended.

There is, ultimately, one and only one way to use this API such that the
compiler doesn't complain:

```
let f: File! := openFile("rilke.txt");
let f_1: File! := writeString(f, "We cannot know his legendary head\n");
let f_2: File! := writeString(f_1, "with eyes like ripening fruit. And yet his torso\n");
...
let f_15: File! := writeString(f_14, "You must change your life.");
closeFile(f_15);
```

Note how the file value is "threaded" through the code, and each linear variable
is used exactly once.

And now we are three for three with the requirements we outlined in the previous
section:

1. **Correctness Requirement:** Is it correct? Yes: linear types allow us to
   define APIs in such a way that the compiler enforces the lifecycle perfectly.

2. **Simplicity Requirement:** Is it simple? Yes: the type system rules fit in a
   napkin. There's no need to use an SMT solver, or to prove theorems about the
   code, or do symbolic execution and explore the state space of the
   program. The linearity checks are simple: we go over the code and count the
   number of times a variable appears, taking care to handle loops and `if`
   statements correctly. And also we ensure that linear values can't be
   discarded silently.

3. **Staticity Requirement:** Is it an ever-growing, ever-changing pile of
   heuristics? No: it is a fixed set of rules. Learn it once and use it forever.

And does this solution generalize? Let's consider a linear database API:

```
type Db!

Db! connect(String host)

Pair<Db!, Rows> query(Db! db, String query)

void close(Db! db)
```

This one's a bit more involved: the `query` function has to return a tuple
containing both the new `Db!` handle, and the result set.

Again: we can't leak a database handle:

```
let db: Db! := connect("localhost");
// Do nothing.
```

Because the compiler will point out that `db` is never consumed. We can't `close` a database handle twice:

```
let db: Db! := connect("localhost");
close(db);
close(db); // error: `db` consumed again.
```

Because `db` is used twice. Analogously, we can't query a database once it's closed:

```
let db: Db! := connect("localhost");
close(db);
let (db1, rows): Pair<Db!, Rows> := query(db, "SELECT ...");
close(db); // error: `db` consumed again.
```

For the same reason. The only way to use the database correctly is:

```
let db: Db! := connect("localhost");
let (db1, rows): Pair<Db!, Rows> := query(db, "SELECT ...");
// Iterate over the rows or some such.
close(db1);
```

What about manual memory management? Can we make it safe? Let's consider a
linear pointer API, but first, we have to introduce some new notation. When you
have a generic type with generic type parameters, in a regular language you
might declare it like:

```
type T<A, B, C>
```

Here, we also have to specify which universe the parameters and the resulting
type belong to. Rember: there are two universes: free and linear. So for example
we can write:

```
type T<A: Free, B: Free>: Free
type U!<A: Linear>: Linear
```

But sometimes we want a generic type to accept type arguments from any
universe. In that case, we use `Type`:

```
type Pair<L: Type, R: Type>: Type;
```

This basically means: the type parameters `L` and `R` can be filled with types
from either universe, and the universe that `Pair` belongs to is determined by
said arguments:

1. If `A` and `B` are both `Free`, then `Pair` is `Free`.
2. If either one of `A` and `B` are `Linear`, then `Pair` is `Linear`.

Now that we're being explicit about universes, we can drop the exclamation mark
notation.

Here's the linear pointer API:

```
type Pointer<T: Type>: Linear;

generic <T: Type>
Pointer<T> allocate(T value)

generic <T: Type>
T deallocate(Pointer!<T> ptr)

generic <T: Free>
Pair<Pointer<T>, T> load(Pointer<T> ptr)

generic <T: Free>
Pointer<T> store(Pointer<T> ptr, T value)
```

This is more involved than previous examples, and uses new notation, so let's
break it down declaration by declaration.

1. First, we declare the `Pointer` type as a generic type that takes a parameter
   from any universe, and belongs to the `Linear` universe by fiat. That is:
   even if `T` is `Free`, `Pointer<T>` will be `Linear`.

   ```
   type Pointer<T: Type>: Linear;
   ```

2. Second, we define a generic function `allocate`, that takes a value from
   either universe, allocates memory for it, and returns a linear pointer to it.

   ```
   generic <T: Type>
   Pointer<T> allocate(T value)
   ```

3. Third, we define a slightly unusual `deallocate` function: rather than
   returning `void`, it takes a pointer, dereferences it, deallocates the
   memory, and returns the dereferenced value:

   ```
   generic <T: Type>
   T deallocate(Pointer!<T> ptr)
   ```

4. Fourth, we define a generic function specifically for pointers that contain
   free values: it takes a pointer, dereferences it, and returns a tuple with
   both the pointer and the dereferenced free value.

   ```
   generic <T: Free>
   (Pointer<T>, T) load(Pointer<T> ptr)
   ```

   Why does `T` have to belong to the `Free` universe? Because otherwise we
   could write code like this:

   ```
   // Suppose that `L` is a linear type.
   let p: Pointer<L> := allocate(...);
   let (p2, val): Pair<Pointer<L>, L> := load(p);
   let (p3, val2): Pair<Pointer<L>, L> := load(p2);
   ```

   Here, we've allocated a pointer to a linear value, but we've loaded it from
   memory twice, effectively duplicating it. This obviously should not be
   allowed. So the type parameter `T` is constrained to take only values of the
   `Free` universe, which can be copied freely any number of times.

5. Fifth, we define a generic function, again for pointers that contain free
   values. It takes a pointer and a free value, and stores that value in the
   memory allocated by the pointer, and returns the pointer again for reuse:

   ```
   generic <T: Free>
   Pointer<T> store(Pointer<T> ptr, T value)
   ```

   Again: why can't this function be defined for linear values? Because then we
   could write:

   ```
   // Suppose `L` is a linear type, and `a` and b`
   // are variables of type `L`.
   let p1: Pointer<L> := allocate(a);
   let p2: Pointer<L> := store(p1, b);
   let l: L := deallocate(p2);
   ```

   What happens to `a`? It is overwritten by `b` and lost. For values in the
   `Free` universe this is no problem: who cares if a byte is overwritten? But
   we can't overwrite linear values -- like database handles and such -- because
   the they would be leaked.

Is it trivial to verify the safety properties. We can't leak memory, we can't
deallocate twice, and we can't read or write from and to a pointer after it has
been deallocated.

## What Linear Types Provide

Linear types give us the following benefits:

1. Manual memory management without memory leaks, use-after-`free`, double
   `free` errors, garbage collection, or any runtime overhead in either time or
   space other than having an allocator available.

2. More generally, we can manage _any_ resource (file handles, socket handles,
   etc.) that has a lifecycle in a way that prevents:

   1. Forgetting to dispose of that resource (e.g.: leaving a file handle open).
   2. Disposing of the resource twice (e.g.: trying to free a pointer twice).
   3. Using that resource after it has been disposed of (e.g.: reading from a
      closed socket).

   All of these errors are prevented _statically_, again without runtime
   overhead.

3. In-place optimization: the APIs we have lookoed at resemble functional
   code. We write coode "as if" we were creating and returning new objects with
   each call, while doing extensive mutations under the hood. This gives us the
   benefits of functional programming (referential transparency and equational
   reasoning) with the performance of imperative code that mutates data wildly.

4. Safe concurrency. A value of a linear type, by definition, has only one
   owner: we cannot duplicate it, therefore, we cannot have multiple owners
   across threads. So imperative mutation is safe, since we know that no other
   thread can write to our linear value while we work with it.

5. Capability-based security: suppose we want to lock down access to the
   terminal. We want there to be only one thread that can write to the terminal
   at a time. Furthermore, code that wants to write to the terminal needs
   permission to do so.

   We can do this with linear types, by having a linear `Terminal` type that
   represents the capability of using the terminal. Functions that read and
   write from and to the terminal need to take a `Terminal` instance and return
   it. We'll discuss capability based security in greater detail in a future
   section.

## The Trust Boundary

So far we have only seen the interfaces of linear APIs. What about the
implementations?

Here's the linear file access API, using the universe notation instead of the
exclamation mark notation to indicate linear types:

```
type File: Linear

File openFile(String path)

File writeString(File file, String content)

void closeFile(File file)
```

How does `writeString` respect linearity? Clearly, it is consuming a `File`
handle, then returning it again. Does it internally close and reopen the file
handle?

The answer involves the concept of a _trust boundary_: inside the `File` type is
a plain old fashioned (unrestricted, non-linear) file handle, like so:

```
struct File: Linear {
  handle: int;
}
```

The `openFile` function looks like this:

```
extern int fopen(char* filename, char* mode)

File openFile(String path) {
    let handle: int = fopen(as_c_string(filename), "r");
    return File(handle => ptr);
}
```

`openFile` calls `fopen`, which returns a file handle as an ordinary, free
integer. Then we wrap it in a nice linear type and return it to the client.

Write string is where the magic happens:

```
extern int fputs(char* string, int fp)

File writeString(File file, String content) {
  let { handle: int } := file;
  fputs(as_c_string(content), handle);
  return File(handle => ptr);
}
```

The `let` statement uses destructuring syntax: it "explodes" a linear struct
into a set of variables.

Why do we need destructuring? Imagine if we had a struct with two linear fields:

```
struct Pair {
  x: L1;
  y: L2;
}
```

And we wanted to write code like:

```
let p: Pair := make_pair();
let x: L1 := p.x;
```

This is a big problem. `p` is being consumed by the `p.x` expression. But what
happens to the `y` field in the `p` struct? It is leaked: we can't afterwards
write `p.y` because `p` has been consumed.

Austral has special rules around accessing the fields of a struct to prevent
this kind of situation. And the destructuring syntax we're using allows us to
take a struct, dismantle it into its constituent fields (linear or otherwise),
then transform the values of those fields and/or put them back together.

This is what we're doing in `openFile`: we break up the `File` value into its
constituent fields (here just `handle`), which consumes it. Then we call `fputs`
on the non-linear handle, then, we construct a new instance of `File` that
contains the unchanged file handle.

From the compiler's perspective, the `File` that goes in is distinct from the
`File` that goes out and linearity is respected. Internally, the non-linear
handle is the same.

Finally, `closeFile` looks like this:

```
extern int fclose(int fp)

void closeFile(File file) {
  let { handle: int } := file;
  fclose(handle);
}
```

The `file` variable is consumed by being destructured. Then we call `fclose` on
the underlying file handle.

And there you have it: linear interface, non-linear interior. Inside the trust
boundary, there is a light amount of unsafe FFI code (ideally, carefully vetted
and tested). Outside, there is a linear interface, which can only be used
correctly.

## Affine Types

Affine types are a "weakening" of linear types. Where linear types are "use
exactly once", affine types are "use _at most_ once". Values can be silently
discarded.

This requires a way to associate destructors to affine types. Then, at the end
of a block, the compiler will look around for unconsumed affine values, and
insert calls to their destructors.

There are two benefits to affine types:

1. First, by using implicit destructors, the code is less verbose.

2. Secondly (and this will be expanded upon in the next section), affine types
   are compatible with traditional (C++ or Java-style) exception handling, while
   linear types are not.

But there are downsides:

1. Sometimes, you _don't_ want values to be silently discarded.

2. There are implicit function calls (destructor calls are inserted by the
   compiler at the end of blocks).

3. Exception handling involves a great deal of complexity, and is not immune to
   e.g. the "double throw" problem.

## Borrowing

Returning tuples from every function and threading linear values through the
code is very verbose.

It is also often a violation of the principle of least privilege: linear values,
in a sense, have "uniform permissions". If you have a linear value, you can
destroy it. Consider the linear pointer API described above: the `load` function
could internally deallocate the pointer and allocate it again.

We wouldn't _expect_ that to happen, but the whole point is to be defensive. We
want the language to give us some guarantees: if a function should only be
allowed to read from a linear value, but not deallocate it or mutate its
interior, we want a way to represent that.

_Borrowing_ is stolen lock, stock, and barrel from Rust. It advanced programming
ergonomics by allowing us to treat a linear value as free within a delineated
context. And it allows us to degrade permissions: we can pass read-only
references to a linear value to functions that should only be able to read from
that value, we can pass mutable references to a linear value to functions that
should only be able to read from, and mutate, that value, without destroying
it. Passing the linear value itself is the highest level of permissions: it
allows the receiving function to do anything whatever with that value, by taking
complete ownership of it.

## The Cutting Room Floor

Universes are not the only way to implement linear types. There are three ways:

1. **Linearity via arrows**, as in the linear types extension of the GHC
   compiler for Haskell. This is the closest to Girard's linear logic.

2. **Linearity via kinds**, which involves partitioning the set of types into
   two universes: a universe of unrestricted values which can be copied freely,
   such as integers, and a universe of restricted or linear types.

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
code. Rather, it is closer to static analysis in that it is a collection of
rules, which evolve with the language, generally in the direction of improving
ergonomics and allowing programmers to focus on the problem at hand rather than
bending the code to fit the ownership scheme. Consequently, Rust programmers
often describe a learning curve with a period of "fighting the borrow checker",
until they become used to the rules.

Compare this with type checking algorithms: type checking is a simple, inductive
process, so much so that programmers effectively run the algorithm while reading
code to understand how it behaves. It often does not need documenting because it
is obvious whether or not two types are equal or compatible, and the "warts" are
generally in the area of implicit integer or float type conversions in
arithmetic, and subtyping where present.

There are many good reasons to prefer the Rust approach:

1. Programmers care a great deal about ergonomics. The [dangling
   else](https://en.wikipedia.org/wiki/Dangling_else) is a feature of C syntax
   that has caused many security vulnerabilities. Try taking this away from
   programmers: they will kick and scream about the six bytes they're saving on
   each `if` statement.

2. Allowing programmers to write code that they're used to helps with onboarding
   new users. It is generally not realistic to tell programmers to "read the
   spec" to learn a new language.

3. By putting the complexity in the language, application code becomes simpler:
   programmers can focus on solving the problem at hand, and the compiler, ever
   helpful, will do its best to "prove around it", that is, the compiler bends
   to the programmer's code and tries to interpret it as best it can, rather
   than the programmer bending to the language's rules.

4. Since destructors are automatically inserted, the code is less verbose.

5. Finally, Rust's approach is compatible with exception handling, which the
   language provides: panics unwind the stack and call destructors
   automatically. Austral, because of its emphasis on implementation simplicty,
   has _much_ more verbose code around error handling.

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

Another feature that was considered and discarded is
[LinearML](https://github.com/pikatchu/LinearML)'s concept of _observer types_,
a lightweight alternative to read-only references that has the benefit of not
requiring regions, but has the drawback that they can't be stored in data
structures.

## Conclusion

In the next section, we explain the rationale for Austral's approach to error
handling, why linear types are incompatible with traditional exception handling,
why affine types are, and how our preferred error handling scheme impacts the
choice of linear types over affine types.

Afterwards, we describe capability-based security, and how linear types allow us
to implement capabilities.
