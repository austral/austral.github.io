---
title: Error Handling
---

On July 3, 1940, as part of Operation Catapult, Royal Air Force pilots bombed
the ships of the French Navy stationed off Mers-el-Kébir to prevent them falling
into the hands of the Third Reich.

This is Austral's approach to error handling: scuttle the ship without delay.

In software terms: programs should crash at the slightest contract violation,
because recovery efforts can become attack vectors. You must assume, when the
program enters an invalid state, that there is an adversary in the system. For
_failures_ --- as opposed to _errors_ --- you should use `Option` and `Result`
types.

This section describes the rationale for Austral's approach to error
handling. We begin by describing what an error is, then we survey different
error handling strategies. Then we explain how those strategies impinge upon a
linear type system.

## Categorizing Errors

"Error" is a broad term. Following [Sutter][sutter] and the [Midori error
model][midori], we divide errors into the following categories:

1. **Physical Failure:** Pulling the power cord, destroying part of the
   hardware.

2. **Abstract Machine Corruption:** A stack overflow.

3. **Contract Violations:** Due to a mistake the code, the program enters an
   invalid state. This includes:

    1. An arithmetic operation leads to integer overflow or underflow (the
       contract here is that operands should be such that the operation does not
       overflow).

	2. Integer division by zero (the contract is the divisor should be non zero).

	3. Attempting to access an array with an index outside the array's bounds
       (the contract is that the index should be within the length of the
       array).

	4. Any violation of a programmer-defined precondition, postcondition,
	   assertion or invariant.

	These errors are bugs in the program. They are unpredictable, often happen
	very rarely, and can open the door to security vulnerabilities.

4. **Memory Allocation Failure:** `malloc` returns `null`, essentially. This
   gets its own category because allocation is pervasive, especially in
   higher-level code, and allocation failure is rarely modeled at the type
   level.

5. **Failure Conditions**. "File not found", "connection failed", "directory is
   not empty", "timeout exceeded".

We can pare down what we have to care about:

1. **Physical Failure:** Nothing can be done. Although it is possible to write
   software that persists data in a way that survives e.g. power
   failure. Databases are often implemented in this way.

2. **Abstract Machine Corruption**. The program should terminate. At this point
   the program is in a highly problematic state and any attempt at recovery is
   likely counterproductive and possibly enables security vulnerabilities.

3. **Memory Allocation Failure:** Programs written in a functional style often
   rely on memory allocation at arbitrary points in the program
   execution. Allocation failure in a deeply nested function thus presents a
   problem from an error-handling perspective: if we're using values to
   represent failures, then every function that allocates has to return an
   `Optional` type or equivalent, and this propagates up through every client of
   that function.

   Nevertheless, returning an `Optional` type (or equivalent) on memory
   allocation is sufficient. It places a minor burden on the programmer, who has
   to explicitly handle and propagate these failures, but this burden can be
   eased by refactoring the program so that most allocations happen in the same
   area in time and space.

   This type of refactoring can improve performance, as putting allocations
   together will make it clear when there is an opportunity to replace $$n$$
   allocations of an object of size $$k$$ bytes with a single allocation of an
   array of $$n \times k$$ bytes.

   A common misconception is that checking for allocation failure is pointless,
   since a program might be terminated by the OS if memory is exhausted, or
   because platforms that implement memory overcommit (such as Linux) will
   always return a pointer as though allocation had succeeded, and crash when
   writing to that pointer. This is a misconception for the following reasons:

   1. Memory overcommit on Linux can be turned off.

   2. Linux is not the only platform.

   3. Memory exhaustion is _not_ the only situation where allocation might fail:
      if memory is sufficiently fragmented that a chunk of the requested size is
      not available, allocation will fail.

4. **Failure Conditions**. These errors are recoverable, in the sense that we
   want to catch them and do something about them, rather than crash. Often this
   involves prompting the user for corrected information, or otherwise informing
   the user of failure, e.g. if trying to open a file on a user-provided path,
   or trying to connect to a server with a user-provided host and port.

   Consequently, these conditions should be represented as values, and error
   handling should be done using standard control flow.

   Values that represent failure should not be confused with "error codes" in
   languages like C. "Error codes or exceptions" is a false dichotomy. Firstly,
   strongly-typed result values are better than brittle integer error
   codes. Secondly, an appropriate type system lets us have e.g. `Optional` or
   `Result` types to better represent the result of fallible
   computations. Thirdly, a linear type system can force the programmer to check
   result codes, so the argument that error codes are bad because programmers
   might forget to check them is obviated.

That takes care of four of five categories. There's one left: what do we do
about contract violations? How we choose to handle this is a critical question
in the design of any programming language.

## Error Handling for Contract Violations

There are essentially three approaches, from most to least brutal:

1. **Terminate Program:** When a contract violation is detected, terminate the
   entire program.  No cleanup code is executed. Henceforth "TPOE" for
   "terminate program on error".

2. **Terminate Thread:** When a contract violation is detected, terminate the
   current thread or task.  No cleanup code is executed, but the parent thread
   will observe the failure, and can decide what to do about it. Henceforth
   "TTOE" for "terminate thread/task on error".

3. **Traditional Exception Handling:** Raise an exception/panic/abort (pick your
   preferred terminology), unwind the stack while calling destructors. This is
   the approach offered by C++ and Rust, and it integrates with RAII. Henceforth
   "REOE" for "raise exception on error".

### Terminate Program

The benefit of this approach is simplicity and security: from the perspective of
security vulnerabilities, terminating a program outright is the best thing to
do,

If the program is the target of an attacker, cleanup or error handling code
might inadvertently allow an attacker to gain access to the program. Terminating
the program without executing any cleanup code at all will prevent this.

The key benefit here besides security is simplicty. There is nothing simpler
than calling `_exit(-1)`. The language is simpler and easier to understand. The
language also becomes simpler to implement. The runtime is simpler. Code written
in the language is simpler to understand and reason about: there are no implicit
function calls, no surprise control flow, no complicated unwinding schemes.

There are, however, a number of problems:

1. **Resource Leaks:** Depending on the program and the operating system, doing
   this might leak resources.

   If the program only allocates memory and acquires file and/or socket handles,
   then the operating system will likely be able to garbage-collect all of this
   on program termination. If the program uses more exotic resources, such as
   locks that survive program termination, then the system as a whole might
   enter an unusable state where the program cannot be restarted (since the
   relevant objects are still locked), and human intervention is needed to
   delete those surviving resources.

   For example, consider a build. The program might use a linear type to
   represent the lifecycle of the directory that stores build output. A `create`
   function creates the directory if it does not already exist, a corresponding
   `destroy` function deletes the directory and its contents.

   If the program is terminated before the `destroy` function is called, running
   the program again will fail in the call to `create` because the directory
   already exists.

   Additionally, in embedded systems without an operating system, allocated
   resources that are not cleaned up by the program will not be reclaimed by
   anything.

2. **Testing:** In a testing framework, we often want to test that a function
   will not fail on certain inputs, or that it will definitely fail on certain
   others. For example, we may want to test that a function correctly aborts on
   values that don't satisfy some precondition.

   [JUnit][junit], for example, provides [`assertThrows`][assert-throws] for
   this purpose.

   If contract violations terminate the program, then the only way to write an
   `assertAborts` function is to fork the process, run the function in the child
   process, and have the parent process observe whether or not it crashes. This
   is expensive. And if we don't implement this, a contract violation will crash
   the entire unit testing process.

   This is a problem because, while we are implicitly "testing" for contract
   violations whenever a function is called, it is still good to have explicit
   unit tests that we can point to in order to prove that a function does indeed
   reject certain kinds of values.

3. **Exporting Code:** When exporting code through the FFI, terminating the
   program on contract violations is less than polite.

   If we write a library and export its functionality through the FFI so it is
   accessible from other languages, terminating the process from that library
   will crash everything else in the address space. All the code that uses our
   library can potentially crash on certain obscure error conditions, a
   situation that would be extremely difficult to debug due to its crossing
   language boundaries.

   The option of forking the process, in this context, is prohibitively
   expensive.

### Terminate Thread on Error

Terminating the thread where the contract violation happened, rather than the
entire process, gives us a bit more recoverability and error reporting ability,
at the cost of safety and resource leaks.

The benefit is that calling a potentially-failing function safely "only"
requires spawning a new thread. While expensive (and
not feasible in a function that might be called thousands of times a second)
this is significantly cheaper than forking the process.

A unit testing library could plausibly do this to implement assertions that a
program does or does not violate any conditions.  Condition failures could then
be reported within the unit testing framework as just another failing test,
without crashing the entire process or requiring expensive forking of the
process.

If we split programs into communicating threads, the failure of one thread could
be detected by its parent, and reported to the user before the program is
terminated.

This is important: _the program should still be terminated_. Terminating the
thread, rather than the entire program, is inteded to allow more user-friendly
and complete reporting of failures, not as a general purpose error recovery
mechanism.

For example, in the context of a webserver, we would _not_ want to restart
failed server threads. Since cleanup code is not executed on thread termination,
a long running process which restarts failing threads will eventually run out of
memory or file handles or other resources.

An attacker that knows the server does this could execute a denial of service
attack by forcing a previously undetected contract violation.

### Raise Exception on Error

This is traditional exception handling with exception values, stack unwinding,
and destructors. C++ calls this throwing an exception. Rust and Go call it
panicking. The only technical difference between C++ exception handling and
Go/Rust panics is that C++ exceptions can be arbitrarily sized objects (and
consequently throwing requires a memory allocation) while in Go and Rust panics
can at most carry an error message. Ada works similarly: an exception is a type
tag plus an error message string.

When a contract violation is detected, an exception is raised and stack
unwinding begins. The stack unwinding process calls destructors.  If an
appropriate handler is reached, control transfers to that handler after stack
unwinding. If no handler is reached, the thread is terminated, and the parent
thread receives the exception object.

Implementing exception handling requires a number of things:

[TODO]

The benefits of this approach are:

1. **Resource Safety:** Contract violations will unwind the stack and cause
   destructors to be called, which allows us to safely deallocate resources
   (with some caveats, see below).

   We can write servers where specific worker threads can occasionally tip over,
   but the file/socket handles are safely closed, and the entire server does not
   crash.

   When the parent thread of a failing thread receives an exception, it can
   decide whether to restart the thread, or simply rethrow the exception. In the
   latter case, its own stack would be unwound and its own resources
   deallocated. Transitively, an exception that is not caught anywhere and
   reaches the top of the stack will terminate the program only after all
   resources have been safely deallocated.

2. **Testing:** Contract violations can be caught during test execution and
   reported appropriately, without needing to spawn a new thread or a new
   process.

3. **Exporting Code:** Code that is built to be exported through the C ABI can
   catch all exceptions, convert them to values, and return appropriate error
   values through the FFI boundary. Rust libraries that export Rust code through
   the FFI use [`catch_unwind`][catch-unwind] to do this.

There are, however, significant downsides to exception handling:

1. **Complexity:** Exceptions are among the most complex language features. This
   complexity is reflected in the semantics, which makes the language harder to
   describe, harder to formalize, harder to learn, and harder to
   implement. Consequently the code is harder to reason about, since exceptions
   introduce surprise control flow at literally every program point.

2. **Pessimization:** When exceptions are part of the language semantics, and
   any function can throw, many compiler optimizations become unavailable.

3. **Code Size:** Exception handling support, even so called "zero cost
   exception handling", requires sizeable cleanup code to be written. This has a
   cost in the size of the resulting binaries. Larger binaries can result in a
   severe performance penalty if the code does not fit in the instruction cache.

4. **Hidden Function Calls:** Calls to destructors are inserted by the compiler,
   both on normal exit from a scope and on cleanup. This makes destructors an
   invisible cost.

   This is worsened by the fact that destructors are often recursive: destroying
   a record requires destroying every field, destroying an array requires
   destroying every element.

5. **No Checking:** exceptions bypass the type system. Solutions like checked
   exceptions in Java exist, but are unused, because they provide little benefit
   in exchange for onerous restrictions. The introduction of checked exceptions
   is also no small matter: it affects the specification of function signatures
   and generic functions, since you need a way to do "throwingness polymorphism"
   (really, effect polymorphism). Any function that takes a function as an
   argument has to annotate not just the function's type signature but its
   permitted exception signature.

6. **Pervasive Failure:** If contract violations can throw, then essentially
   every function can throw, because every function has to perform arithmetic,
   either directly or transitively. So there is little point to a `throws`
   annotation like what Herb Sutter suggests or Swift provides, let alone full
   blown checked exceptions, since every function would have to be annotated
   with `throws (Overflow_Error)`.

7. **Double Throw Problem:** What do we do when the destructor throws? This
   problem affects every language that has RAII.

   In C++ and Rust, throwing in the destructor causes the program to abort. This
   an unsatisfactory solution: we're paying the semantic and runtime cost of
   exceptions, stack unwinding, and destructors, but a bug in the destructor
   invalidates all of this. If we're throwing on a contract violation, it is
   because we expect the code has bugs in it and we want to recover gracefully
   from those bugs. Therefore, it is unreasonable to expect that destructors
   will be bug-free.

   Ada works differently in that raising an exception in a finalizer throws an
   entirely new exception (discarding the original one).

   Double throw is not necessarily a pathological edge case either: the `fclose`
   function from the C standard library returns a result code. What should the
   destructor of a file object do when `fclose` returns an error code?

   In Rust, according to the documentation of the `std::fs::File` object: "Files
   are automatically closed when they go out of scope. Errors detected on
   closing are ignored by the implementation of Drop.  Use the method `sync_all`
   if these errors must be manually handled."

   A solution would be to store a flag in the file object that records the state
   of the file handle: either `closed` or `open`. Then, we can have a function
   `close : File -> ReturnCode` that calls `fclose`, sets the flag to `closed`,
   and returns the return code for the client to handle. The destructor would
   then check that flag: if the flag is `open`, it calls `fclose`, ignoring the
   return code (or aborting if `fclose` reports an error), and if the flag is
   `closed`, the destructor does nothing.

   But this is a non-solution.

   1. With affine types and RAII, we cannot force the programmer to call the
      `close` function. If a file object is silently discarded, the compiler
      will insert a call to the destructor, which as we've seen makes fewer
      safety guarantees. So we have a type system to manage resources, but it
      doesn't force us to handle them properly.

   2. We're paying a cost, in space and time, in having a flag that records the
      file handle state and which needs to be set and checked at runtime. The
      whole point of resource management type systems is _the flag exists at
      compile time_. Otherwise we might as well have reference counting.

8. **Compile Time:** Compilers anecdotally spend a lot of time compiling
   landingpads.

9. **Non-determinism:** Time and space cost of exceptions is completely unknown
   and not amenable to static analysis.

10. **Platform-Specific Runtime Support:** Exceptions need support from the
    runtime, usually involving the generation of DWARF metadata and platform
    specific assembly. This is the case with Itanium ABI "zero-cost exceptions"
    for C++, which LLVM implements.

11. **Corruption:** Unwinding deallocates resources, but this is not all we
    need. Data structures can be left in a broken, inconsistent state, the use
    of which would trigger further contract violations when their invariants are
    violated.

    This can be mitigated somewhat by not allowing the catching of exceptions
	except at thread boundaries, beyond which the internal broken data
	structures cannot be observed. Thus threads act as a kind of censor of
	broken data.  Providing the strong exception guarantee requires either
	transactional memory semantics (and their implied runtime cost in both time,
	space, and implementation complexity) or carefully writing every data
	structure to handle unwinding gracefully.

	However, making it impossible to catch errors not at thread boundaries makes
	it impossible to safely export code through the C FFI without spawning a new
	thread. Rust started out with this restriction, whereby panics can only be
	caught by parent threads of a failing thread. The restriction was removed
	with the implementation of [`catch_unwind`][catch-unwind].

    Furthermore, carefully writing every data structure to implement strong
    exception safety is pointless when a compiler toggle can disable exception
    handling. Doubly so when writing a library, since control of whether or not
    to use exceptions falls on the client of that library (see below:
    **Libraries Cannot Rely on Destructors**).

12. **Misuse of Exceptions:** If catching an exception is possible, people will
    use it to implement a general `try/catch` mechanism, no matter how
    discouraged that is.

    For example, Rust's [`catch_unwind`][catch-unwind] is used in web
    servers. For example, in the [docs.rs][docs.rs] project, see [here][hn1] and
    [here][hn2].

13. **Minimum Common Denominator:** Destructors are a minimum common denominator
    interface: a destructor is a function that takes an object and returns
    nothing, `A -> ()`.

	Destructors force all resource-closing operations to conform to this
	interface, even if they can't.  The prototypical example has already been
	mentioned: `fclose` can return failure. How do languages with destructors
	deal with this?

    Again, in C++, closing a file object will explicitly forget that error,
	since throwing an exception would cause the program to abort. You are
	supposed to close the file manually, and protect that close function call
	from unwinding.

    Again, in Rust, closing a file will also ignore errors, because Rust works
	like C++ in that throwing from a destructor will abort the program. You can
	call `sync_all` before the destructor runs to ensure the buffer is flushed
	to disk. But, again: the compiler will not force you to call `sync_all` or
	to manually close the file.

    More generally, affine type systems _cannot_ force the programmer to do
    anything: resources that are silently discarded will be destroyed by the
    compiler inserting a call to the destructor. Rust gets around this by
    implementing a `cfg(must_use)` annotation on functions, which essentially
    tells the compiler to force programmers to use the result code of that
    function.

14. **Libraries Cannot Rely on Destructors:** In C++, compilers often provide
	non-standard functionality to turn off exception handling. In this mode,
	`throw` is an abort and the body of a `catch` statement is dead code. Rust
	works similarly: a panic can cause stack unwinding (and concurrent
	destruction of stack objects) or a program abort, and this is configurable
	in the compiler. Unlike C++, this option is explicitly welcome in Rust.

	In both languages, the decision of whether or not to use exception handling
	takes place at the root of the dependency tree: at the application. This
	makes sense: the alternative is a model whereby a library that relies on
	unwinding will pass this requirement to other packages that depend on it,
	"infecting" dependents transitively up to the final application.

	For this reason, libraries written in either language cannot rely on
    unwinding for exception safety.

    It is not uncommon, however, for libraries to effectively rely on unwinding
    to occur in order to properly free resources. For example, the documentation
    for the [`easycurses`][easycurses] library says:

    >The library can only perform proper automatic cleanup if Rust is allowed to
    >run the `Drop` implementation. This happens during normal usage, and during
    >an unwinding panic, but if you ever abort the program (either because you
    >compiled with `panic=abort` or because you panic during an unwind) you lose
    >the cleanup safety. That is why this library specifies `panic="unwind"` for
    >all build modes, and you should too.

    This is not a problem with the library, or with Rust. It's just what it is.

15. **Code in General Cannot Rely on Destructors:** A double throw will abort, a
	stack overflow can abort, and a SIGABRT can abort the program, and, finally,
	the power cord can be pulled. In all of these cases, destructors will not be
	called.

	In the presence of exogeneous program termination, the only way to write
	completely safe code is to use side effects with atomic/transactional
	semantics.

## Linear Types and Exceptions

Linear types are incompatible with exception handling. It's easy to see why.

A linear type system guarantees all resources allocated by a terminating program
will be freed, and none will be used after being freed. This guarantee is lost
with the introduction of exceptions: we can throw an exception before the
consumer of a linear resource is called, thus leaking the resource. In this
section we go through different strategies for reconciling linear types and
exceptions.

### Motivating Example

If you're convinced that linear types and exceptions don't work together, skip
this section. Otherwise, consider:

```c
try {
  let f = open("/etc/config");
  // `write` consumes `f`, and returns a new linear file object
  let f' = write(f, "Hello, world!");
  throw Exception("Nope");
  close(f');
} catch Exception {
  puts("Leak!");
}
```

A linear type system will accept this program: `f` and `f'` are both used
once. But this program has a resource leak: an exception is thrown before `f'`
is consumed.

If variables defined in a `try` block can be used in the scope of the associated
`catch` block, we could attempt a fix:

```c
try {
  let f = open("/etc/config");
  let f' = write(f, "Hello, world!");
  throw Exception("Nope");
  close(f');
} catch Exception {
  close(f');
}
```

But the type system wouldn't accept this: `f'` is potentially being consumed
twice, if the exception is thrown from inside `close`.

Can we implement exception handling in a linearly-typed language in a way that
preserves linearity guarantees? In the next three sections, we look at the possible approaches.

### Solution A: Values, not Exceptions

We could try having exception handling only as syntactic sugar over returning
values. Instead of implementing a complex exception handling scheme, all
potentially-throwing operations return union types. This can be made less
onerous through syntactic sugar. The function:

```c
T nth(array<T> arr, size_t index) throws OutOfBounds {
  return arr[index];
}
```

Can be desugared to (in a vaguely Rust-ish syntax):

```c
Result<T, OutOfBounds> nth(array<T> arr, size_t index) {
  case arr[index] {
    Some(elem: T) => {
      return Result::ok(elem);
    }
    None => {
      return Result::error(OutOfBounds());
    }
  }
}
```

This is appealing because much of the hassle of pattern matching `Result` types
can be simplified by the compiler. But this approach is immensely limiting,
because as stated above, many fundamental operations have failure modes that
have to be handled explicitly:

```
add : (Int, Int) -> Result<Int, Overflow>
sub : (Int, Int) -> Result<Int, Overflow>
mul : (Int, Int) -> Result<Int, Overflow>
div : (Int, Int) -> Result<Int, Overflow | DivisionByZero>

nth : (Array<T>, Nat) -> Result<T, OutOfBounds>
```

As an example, consider a data structure implementation that uses arrays under
the hood. The implementation has been thoroughly tested and you can easily
convince yourself that it never accesses an array with an invalid index. But if
the array indexing primitive returns an option type to indicate out-of-bounds
access, the implementation has to handle this explicitly, and the option type
will "leak" into client code, up an arbitrarily deep call stack.

The problem is that an ML-style type system considers all cases in a union type
to be equiprobable, the normal path and the abnormal path have to be given equal
consideration in the code. Exception handling systems let us conveniently
differentiate between normal and abnormal cases.

### Solution B: Use Integrated Theorem Provers

Instead of implementing exception handling for contract violations, we can use
an integrated theorem prover and SMT solver to prove that integer division by
zero, integer overflow, array index out of bounds errors, etc. never happen.

A full treatment of [abstract interpretation][absint] is beyond the scope of
this article. The usual tradeoff applies: the tractable static analysis methods
prohibit many ordinary constructions, while the methods sophisticated enough to
prove most code correct are extremely difficult to implement completely and
correctly. Z3 is 300,000 lines of code.

### Solution C: Capturing the Linear Environment

To our knowledge, this is the only sound approach to doing exception handling in
a linearly-typed language that doesn't involve fanciful constructs using
delimited continuations.

[PacLang][paclang] is an imperative linearly-typed programming language
specifically designed to write packet-processing algorithms for [network
procesors][np]. The paper is worth reading.

Its authors describe the language as:

>a simple, first order, call by value language, intended for constructing
>network packet processing programs. It resembles and behaves like C in most
>respects. The distinctive feature of PacLang is its type system, treating the
>datatypes that correspond to network packets within the program as linear
>types. The target platforms are application-specific network processor (NP)
>architectures such as the Intel IXP range and the IBM PowerNP.

The type system is straightforward: `bool`, `int`, and a linear `packet` type. A
limited form of borrowing is supported, with the usual semantics:

>In PacLang, the only linear reference is a `packet`. An _alias_ to a reference
>of this type, a `!packet`, can be created in a limited scope, by casting a
>`packet` into a `!packet` if used as a function argument whose signature
>requires a `!packet`. An alias may never exist without an owning reference, and
>cannot be created from scratch. In the scope of that function, and other
>functions applied to the same `!packet`, the alias can behave as a normal
>non-linear value, but is not allowed to co-exist in the same scope as the
>owning reference `packet`. This is enforced with constraints in the type
>system:
>
>- A `!packet` may not be returned from a function, as otherwise it would be
> possible for it to co-exist inscope with the owning `packet`
>
>- A `!packet` may not be passed into a function as an argument where the
> owning `packet` is also being used as an argument, for the same reason
>
>Any function taking a `!packet` cannot presume to "own" the value it aliases,
>so is not permitted to deallocate it or pass it to another a thread; this is
>enforced by the signatures of the relevant primitive functions. The constraints
>on the `packet` and `!packet` reference types combined with the primitives for
>inter-thread communication give a _uniqueness guarantee_ that only one thread
>will ever have reference to a packet.

An interesting restriction is that much of the language has to be written in
[A-normal form][anf] to simplify type checking. This is sound: extending a
linear type system to implement convenience features like borrowing is made
simpler by working with variables rather than arbitrary expressions, and it's a
restriction Austral shares.

The original language has no exception handling system. PacLang++, a successor
with exception handling support, is introduced in the paper _Memory safety with
exceptions and linear types_. The paper is difficult to find, so I will quote
from it often. The authors first describe their motivation in adding exception
handling:

>In our experience of practical PacLang programming, an issue commonly arising
>is that of functions returning error values. The usual solution has been to
>return an unused integer value (C libraries commonly use -1 for this practice)
>where the function returns an integer, or to add a boolean to the return tuple
>signalling the presence of an error or other unusual situation. This quickly
>becomes awkward and ugly, especially when the error condition needs to be
>passed up several levels in the call graph. Additionally, it is far easier for
>a programmer to unintentionally ignore errors using this method, resulting in
>less obvious errors later in the program, for example a programmer takes the
>return value as valid data, complacently ignoring the possibility of an error,
>and using that error value where valid data is expected later in the program.

The linear type system of PacLang:

>A linearly typed reference (in PacLang this is known as the owning reference,
>though other kinds of non-linear packet references will be covered later) is
>one that can be used _only once_ along each execution path, making subsequent
>uses a type error; the type system supports this by removing a reference
>(_consuming_ it) from the environment after use. As copying a linear reference
>_consumes_ it, only one reference (the _owning_ reference) to the packet may
>exist at any point in the program’s runtime. Furthermore, a linear reference
>_must_ be used once and only once, guaranteeing that any linearly referenced
>value in a type safe program that halts will be consumed eventually.

The authors first discuss the exceptions as values approach, discarding it
because it doesn't support intra-function exception handling, and requires all
functions to deallocate live linear values before throwing. The second attempt
is described by the authors:

>At the time an exception is raised, any packets in scope must be consumed
>through being used as an argument to the exception constructor, being "carried"
>by the exception and coming into the scope of the block that catches the
>exception.

This is also rejected, because:

>this method does not account for live packets that are not in scope at the time
>an exception is raised. An exception can pass arbitrarily far up the call graph
>through multiple scopes that may contain live packets until it is caught.

The third and final approach:

>We create an enhanced version of the original PacLang type system, which brings
>linear references into the environment implicitly wherever an exception is
>caught. Our type system ensures that the environment starting a catch block
>will contain a set of references (that are in the scope of the exception
>handling block) to the _exact same_ linear references that were live at the
>instant the exception was thrown.

To illustrate I adapted the following example from the paper, adding a few more
comments:

```c
packet x = recv();
packet y = recv();

// At this point, the environment is {x, y}

try {
  consume(x);
  // At this point, the environment is just {y}
  if (check(!y)) {
    consume(y);
    // Here, the environment is {}
  } else {
    throw Error; // Consumes y implicitly
    // Here, the environment is {}
  }
  // Both branches end with the same environment
} catch Error(packet y) {
  log_error();
  consume(y);
}
```

The authors go on to explain a limitation of this scheme: if two different
`throw` sites have a different environment, the program won't type check. For
example:

```c
packet x = recv();

// Environment is {x}
if (check(!x)) {
  packet y = recv();

  // Environment is {x, y}
  if (checkBoth(!x, !y)) {
    consume(x);
    consume(y);
    // Environment is {}
  } else {
    throw Error; // Consumes x and y
    // Environment is {}
  }
} else {
  throw Error; // Consumes x
  // Enviroment is {}
}
```

While the code is locally sound, one `throw` site captures `x` alone while one
captures `x` and `y`.

Suppose the language we're working with requires functions to be annotated with
an exception signature, along the lines of [checked exceptions][checked]. Then,
if all throw sites in a function `f` implicitly capture a single linear packet
variable, we can annotate the function this way:

```c
void f() throws Error(packet x)
```

But in the above code example, the exception annotation is ambiguous, because
different throw sites capture different environments:

```c
void f() throws Error(packet x)
// Or
void f() throws Error(packet x, packet y)
```

Choosing the former leaks `y`, and choosing the latter means the value of `y`
will be undefined in some cases.

This can be fixed with the use of option types: because environments form a
partially ordered set, we can use option types to represent bindings which are
not available at every `throw` site. In the code example above, we have:

```
{} < {x} < {x, y}
```

So the signature for this function is simply:

```c
void f() throws Error(packet x, option<packet> y)
```

In short: we can do it, but it really is just extra semantics and complexity for
what is essentially using a `Result` type.

## Affine Types and Exceptions

Affine types are a weakening of linear types, essentially linear types with
implicit destructors. In a linear type system, values of a linear type must be
used exactly once. In an affine type system, values of an affine type can be
used at most once. If they are unused, the compiler automatically inserts a
destructor call.

[Rust][rust] does this, and there are good reasons to prefer affine types over
linear types:

1. Less typing, since there is no need to explicitly call destructors.

2. Often, compilation fails because programmers make trivial mistakes, such as
   forgetting a semicolon. A similar mistake is forgetting to insert destructor
   calls. This isn't possible with affine types, where the compiler handles
   object destruction for the programmer.

3. Destruction order is consistent and well-defined.

4. Most linear types have a single natural destructor function: pointers are
   deallocated, file handles are closed, database connections are closed,
   etc. Affine types formalize this practice: instead of having a constellation
   of ad-hoc destructor functions (`deallocate`, `closeFile`, `closeDatabase`,
   `hangUp`), all destructors are presented behind a uniform interface: a
   generic function of type `T! -> Unit`.

The drawbacks of affine types are the same as those of destructors in languages
like C++ and [Ada][finalization], that is:

1. The use of destructors requires compiler insertion of implicit function
   calls, which have an invisible cost in runtime and code size, whereas linear
   types make this cost visible.

2. Destruction order has to be well-specified. For stack-allocated variables,
   this is straghtforward: destructors are called in inverse declaration
   order. For temporaries, this is complicated.

Additionally, destroying values we don't do anything with could lead to bugs if
the programmer simply forgets about a value they were supposed to use, and
instead of warning them, the compiler cleans it up.

But there is a benefit to using affine types with destructors: exception
handling integrates perfectly well. Again, Rust does this: [`panic`][rustpanic]
and [`catch_unwind`][catch-unwind] are similar to `try` and `catch`, and
destructors are called by unwinding the stack and calling `drop` on every affine
object. The result is that exceptions are safe: in the happy path, destructors
are called by the compiler. In the throwing path, the compiler ensures the
destructors are called anyways.

The implementation strategy is simple:

1. When the compiler sees a `throw` expression, it emits calls to the destructor
   of every (live) affine variable in the environment before emitting the
   unwinding code.

   That is, given an expression `throw(...)`, where the affine environment up to
   that expression is `{x, y, z}`, the expression is transformed into:

   ```
   free(x);
   free(y);
   free(z);
   throw(...);
   ```

2. When the compiler sees a call to a potentially-throwing function (as
   determined by an [effect system][effect]), it emits a `try`/`catch` block:
   normal excecution proceeds normally, but if an exception is caught, the the
   destructors of all live affine variables are called, and the exception is
   re-thrown.

   Suppose we have a function call `f()`, where the affine environment up to the
   point of that call is `{x, y}`. If the function potentially throws an
   exception, the function call gets rewritten to something like this:

   ```
   let result = try {
     f();
   } catch Exception as e {
     free(x);
     free(y);
     throw(e);
   }
   ```

For a more complete example, a program like this:

```c
void f() throws {
  let x: string* = allocate("A fresh affine variable");
  // Environment is {x}
  g(x); // Environment is {}
}

void g(string* ptr) throws {
  let y: string* = allocate("Another heap-allocated string");
  // Environment is {ptr, y}
  h(ptr); // Environment is {y}
}

void h(string* ptr) throws {
  let z = allocate(1234);
  if (randBool()) {
    throw "Halt";
  }
}
```

Would transform to something like this:

```c
void f() {
  let x: string* = _allocate_str("A fresh affine variable");
  try {
    g(x);
  } catch {
    rethrow;
  }
}

void g(string* ptr) {
  let y: string* = _allocate_str("Another heap-allocated string");
  try {
    h(ptr);
  } catch {
    _free_str(y);
    rethrow;
  }
  _free_str(y);
}

void h(string* ptr) {
  let z = allocate(1234);
  if (randBool()) {
    _free_intptr(z);
    _free_str(ptr);
    throw "Halt";
  }
  _free_intptr(z);
  _free_str(ptr);
}
```

## Prior Art

In Swift, contract violations terminate the program.

Under Herb Sutter's proposal, contract violations terminate the program.

In Ada, contract violations will throw an exception.

In Rust, contract violations can panic. Panic can unwind or abort, depending on
a compiler switch.  This is a pragmatic strategy: the application developer,
rather than the library developer, chooses whether to unwind or abort.

In the specific case of overflow, Rust checks overflow on Debug builds, but uses
two's complement modular arithmetic semantics on Release builds for
performance. This is questionable.

## Conclusion

So, to summarise, language designers that want to integrate resource management
into their type system have a choice:

1. Contract violations terminate the application or thread. This gives us a
   simpler type system having linear types, no hidden destructor calls, no
   hidden function calls, no hidden unwind/cleanup tables, no hidden control
   flow, and all the nice properties of exception-free systems.

2. Contract violations raise an exception, which unwinds the stack, calling
   destructors.  We need affine types, destructors, compiler logic to build the
   destructor functions, insertion of destructor calls for normal exit as well
   as unwinding. We have to figure out what to do in the case of throwing from
   the destructor, and, as mentioned, code cannot actually rely on unwinding
   happening because roughly half of your users will turn off exception handling
   and because of the double throw problem.

Having weighed the benefits and problems of both approaches, we decided to
implement a simple linear type system, and an error handling strategy where
contract violations result in a crash.

[sutter]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0709r4.pdf
[midori]: http://joeduffyblog.com/2016/02/07/the-error-model/
[junit]: https://en.wikipedia.org/wiki/JUnit
[assert-throws]: https://junit.org/junit5/docs/5.0.1/api/org/junit/jupiter/api/Assertions.html#assertThrows-java.lang.Class-org.junit.jupiter.api.function.Executable-
[easycurses]: https://docs.rs/easycurses/latest/easycurses/
[catch-unwind]: https://doc.rust-lang.org/std/panic/fn.catch_unwind.html
[docs.rs]: https://docs.rs/
[hn1]: https://news.ycombinator.com/item?id=22940836
[hn2]: https://news.ycombinator.com/item?id=22938712
[absint]: https://en.wikipedia.org/wiki/Abstract_interpretation
[paclang]: https://link.springer.com/chapter/10.1007/978-3-540-24725-8_15
[np]: https://en.wikipedia.org/wiki/Network_processor
[anf]: https://en.wikipedia.org/wiki/A-normal_form
[rust]: https://www.rust-lang.org/
[finalization]: https://www.adaic.org/resources/add_content/docs/95style/html/sec_9/9-2-3.html
[rustpanic]: https://doc.rust-lang.org/std/macro.panic.html
[effect]: https://en.wikipedia.org/wiki/Effect_system
