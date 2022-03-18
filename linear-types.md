---
title: Introduction to Linear Types
breadcrumbs:
  - { title: "Home", url: "/" }
---

In the physical world, an object occupies a single point in space, and objects
can move from one place to the other. Copying an object, however, is
impossible. Computers invert this: copying is the primitive operation. While an
object in memory resides in a single place, _references_ or pointers to that
object can be copied any number of times, and passed around through threads.

This brings a number of security and correctness problems:

1. **Double-Free Errors**: the memory used to store an object can be deallocated
   by calling `free()` on a pointer to the object. The code might try to call
   `free()` on another copy of the pointer elsewhere, leading to a [double-free
   error][2free]. This can cause [security vulnerabilities][2freesec].

2. **Use-After-Free Errors**: when the memory used to store an object has been
   deallocated by a call to `free()`, other code that holds a pointer to the
   same memory might try to read or write to that block of memory, causing a
   crash. This is a [use-after-free error][afterfree], and it can also cause
   [security vulnerabilities][afterfreesec].

3. **Concurrency Errors:** when multiple concurrent threads have references to
   the same block of memory, errors caused by the ordering of reads and writes
   can introduce security vulnerabilities and be impossible to debug.

This generalizes beyond memory: any value that has a strict lifecycle of
"create, use, dispose", such as file handles, database handles, heap-allocated
memory, sockets, is called a _resource_ and is subject to this kind of
errors. For example, in C, calling [`fclose`][fclose] on a file handle that has
already been closed is undefined behaviour.

Linear types fix this. Simply put: a value of a linear type is a value that can
only be used once. This sounds useless, but it isn't. Let's see what a linear
API for database access looks like.

>For the first time in 50 years of computer science, a metaphor of programming
>has been proposed that most people can relate to—objects have true identity,
>and _objects are conserved_. As in the real world, _an object cannot be copied
>or destroyed_ without first filling out a lot of forms, but on the other hand,
>_the transmission of objects is relatively painless_. An object is localized in
>space, and can move from place to place. (Only computer-literate people must be
>told that the transmission of these objects does not create copies.) Linear
>logic finally makes precise the high school notion that a function is like a
>box into which one puts argument values and receives result values, and that a
>truly "functional" box does not remember its previous arguments or results.
>
>— Henry G. Baker, ["Linear Logic and Permutation Stacks—The Forth Shall Be First"][forth]

## Linear Database API

Considering the following C++ declarations for a simple API for sending queries
to an SQL database:

```c++
struct database;
struct result_set;

database connect(string path);

result_set query(database db, string query);

void close(database db);
```

Here's how this API would be used:

```c++
database db = connect("db@localhost:user/pass");
result_set set1 = query(db, "SELECT ...");
result_set set2 = query(db, "INSERT ...");
result_set set3 = query(db, "UPDATE ...");
close(db);
```

Implicitly, we understand that there are certain rules here:

1. We shouldn't be able to call `close` on a database that has already been
   `close`'d.

2. We shouldn't be able to call `query` on a database that has already been
   `close`'d.

3. Multiple threads holding the same copy of a `database` object should not be
   able to call `query` at the same time.

Points 1 and 2 are analogous to double-free and use-after-free errors when
managing memory. While we understand these rules implicitly as programmers, they
are not enforced by the type system at all. Since programming is hard, we want
as much mechanical help as possible: we want a type system that helps us prevent
these errors, while being simple enough to be tractable.

Point 3 is a concurrency error and would typically be addressed with some kind
of exclusive locking scheme. But locks incur a runtime cost and are hard to get
right. It would be preferrable if we could enforce that certain values cannot
cross thread boundaries.

Let's see what a linear version of this API would look like. Say that a type
whose name ends in an exclamation mark is linear -- that is, values of that type
must be used once and only used. Which means they can't be silently discarded or
passed to multiple function calls. Our new API now looks like this:

```c++
struct database!;
struct result_set;

database! connect(string path);

pair<database!, result_set> query(database! db, string query);

void close(database! db);
```

The most important change here is that the `query` function no longer returns a
result: it returns a pair of a "new" database and the query result set. "New" is
in quotes because this database is only new from the perspective of the type
system: in the implementation of this API, the `database!` type would be a
wrapper around an underlying non-linear database handle (maybe a file handle or
a socket). The opaque interface separates a non-linear implementation (which is
needed any time we need to cross the FFI boundary, for example) from a neatly
linear interface.

Here's how this API would be used (using [C++17 destructuring][destr]):

```c++
database! db = connect("db@localhost:user/pass");
auto [db1, set1] = query(db, "SELECT ...");
auto [db2, set2] = query(db1, "INSERT ...");
auto [db3, set3] = query(db2, "UPDATE ...");
close(db3);
```

As you can see, each `database!` value is used once and only once. Let's see how
this addresses the errors.

If we try to close a database handle twice:

```c++
database! db = connect("db@localhost:user/pass");
close(db);
close(db);
```

The compiler will throw an error on the third line, pointing out that `db` has
already been consumed in the second line.

Similarly, we can't otherwise use a database handle that's already been closed:

```c++
database! db = connect("db@localhost:user/pass");
close(db);
query(db, "SELECT ...");
```

Again, the compiler will complain that `db` is consumed twice.

We can send a database handle to another thread, for example:

```c++
database! db = connect("db@localhost:user/pass");
thread thr = spawn_thread(some_function, db);
```

But the main thread cannot use the database handle: it has been consumed by
calling the `spawn_thread` function. So only one thread can acccess the database
at a time, and when multiple threads need to use it, these threads have to pass
the database handle around.

[forth]: https://www.plover.com/~mjd/misc/hbaker-archive/ForthStack.html
[2free]: https://cwe.mitre.org/data/definitions/415.html
[2freesec]: https://owasp.org/www-community/vulnerabilities/Doubly_freeing_memory
[afterfree]: https://cwe.mitre.org/data/definitions/416.html
[afterfreesec]: https://owasp.org/www-community/vulnerabilities/Using_freed_memory
[fclose]: https://man7.org/linux/man-pages/man3/fclose.3.html
[destr]: https://en.cppreference.com/w/cpp/language/structured_binding
