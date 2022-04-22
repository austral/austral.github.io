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

[TODO]

## Affine Types and Exceptions

[TODO]

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
