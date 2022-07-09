---
title: Capability-Based Security
---

Seen from the surface, the Earth's crust appears immense; seen from afar, it is
the thinnest skin of silicon over a cannonball of iron many times its mass.

Analogously with software: we write masses of application code, but it sits on
tens of millions of lines of open source code: the library ecosystem, both
direct and transitive dependencies. This is far too much code for one team to
audit. Avoiding dependencies in commercial software is unrealistic: you can't
write the universe from scratch, and if you do, you will lose out to competitors
closer to the efficient frontier.

The problem is that code is overwhelmingly permissionless. Or, rather: all code
has uniform root permissions. The size of today's software ecosystems has
introduced a new category of security vulnerability: the [supply chain
attack][supply]. An attacker adds malware to an innocent library used
transitively by millions. It is downloaded and run, with the user's permissions,
on the computers of hundreds of thousands of programmers, and afterwards, on
application servers.

The solution is [capability-based security][cap]. Code shoud be permissioned. To
access the console, or the filesystem, or the network, libraries should require
the capability to do so. Then it is evident, from function signatures, what each
library is able to do, and what level of auditing is required.

Furthermore: capabilities can be arbitrarily granular. Beneath the capability to
access the entire filesystem, we can have a capability to access a specific
directory and its contents, or just a specific file, further divided into read,
write, and read-write permissions. For network access, we can have capabilities
to access a specific host, or capabilities to read, write, and read-write to a
socket.

Access to the computer clock, too, [should be restricted][clock], since accurate
timing information can be used by malicious or compromised dependencies to carry
out a [timing attack][timing] or exploit a [side-channel vulnerability][side]
such as [Spectre][spectre].

## Linear Capabilities

A capability is a value that represents an unforgeable proof of the authority to
perform an action. They have the following properties:

1. Capabilities can be destroyed.

2. Capabilities can be surrended by passing them to others.

3. Capabilities cannot be duplicated.

4. Capabilities cannot be acquired out of thin air: they must be passed by the
   client.

Capabilities in Austral are implemented as linear types: they are destroyed by
being consumed, they are surrended by simply passing the value to a function,
they are non-duplicable since linear types cannot be duplicated. The fourth
restriction must be implemented manually by the programmer.

Let's consider some examples.

## Example: File Access

Consider a non-capability-secure filesystem API:

```austral
module Files is
    -- File and directory paths.
    type Path: Linear;

    -- Creating and disposing of paths.
    function makePath(value: String): Path;
    function disposePath(path: Path): Unit;

    -- Reading and writing.
    generic [R: Region]
    function readFile(path: &[Path, R]): String;

    generic [R: Region]
    function writeFile(path: &![Path, R], content: String): Unit;
end module.
```

(Error handling etc. omitted for clarity.)

Here, any client can construct a path from a string, then read the file pointed
to by that path or write to it. A compromised transitive dependency could then
read the contents of `/etc/passwd`, or any file in the filesystem that the
process has access to, like so:

```austral
let p: Path := makePath("/etc/passwd");
let secrets: String := readFile(&p);
-- Send this over the network, using an
-- equally capability-insecure network
-- API.
```


In the context of code running on a programmer's development computer, that
means personal information. In the context of code running on an application
server, that means confidential bussiness information.

What does a capability-secure filesystem API look like? Like this:

```austral
module Files is
    type Path: Linear;

    -- The filesystem access capability.
    type Filesystem: Linear;

    -- Given a filesystem access capability,
    -- get the root directory.
    generic [R: Region]
    function getRoot(fs: &[Filesystem, R]): Path;

    -- Given a directory path, append a directory or
    -- file name at the end.
    function append(path: Path, name: String): Path;

    -- Reading and writing.
    generic [R: Region]
    function readFile(path: &[Path, R]): String;

    generic [R: Region]
    function writeFile(path: &![Path, R], content: String): Unit;
end module.
```

This demonstrates the hieararchical nature of capabilities, and how granular we
can go:

1. If you have a `Filesystem` capability, you can get the `Path` to the root
   directory. This is essentially read/write access to the entire filesystem.

2. If you have a `Path` to a directory, you can get a path to a subdirectory or
   a file, but you can't go _up_ from a directory to its parent.

3. If you have a `Path` to a file, you can read from it or write to it.

Each capability can only be created by providing proof of a higher-level, more
powerful, broader capability.

Then, if you have a logging library that takes a `Path` to the logs directory,
you know it has access to that directory and to that directory only[^fn1]. If a
library doesn't take a `Filesystem` capability, it has no access to the
filesystem.

But: how do we create a `Filesystem` value? The next section explains this.

## The Root Capability

Capabilities cannot be created out of thin air: they can only be created by
proving proof that the client has access to a more powerful capability. This
recursion has to end somewhere.

The root of the capability hierarchy is a value of type `RootCapability`. This
is the first argument to the entrypoint function of an Austral program. For our
capability-secure filesystem API, we'd add a couple of functions:

```austral
-- Acquire the filesystem capability, when the client can
-- provide proof that they have the root capability.
generic [R: Region]
function getFilesystem(root: &[RootCapability, R]): Filesystem;

-- Relinquish the filesystem capability.
function releaseFilesystem(fs: Filesystem): Unit;
```

And we can use it like so:

```austral
import Files (
    Filesystem,
    getFilesystem,
    releaseFilesystem,
    Path,
    getRoot,
    append,
);
import Dependency (
    doSomething
);

function main(root: Root_Capability): Exit)code is
    -- Acquire a filesystem capability.
    let fs: Filesystem := getFilesystem(&root);
    -- Get the root directory.
    let r: Path := getRoot(&fs);
    -- Get the path to the `/var` directory.
    let p: Path := Append(p, "var");
    -- Do something with the path to the `/var`
    -- directory, confident that nothing this
    -- dependency does can go outside `/var`.
    doSomething(p);
    -- Afterwards, relinquish the filesystem
    -- capability.
    releaseFilesystem(fs);
    -- Surrender the root capability. Beyond
    -- this point, the program can't do anything
    -- effectful.
    surrenderRoot(root);
    -- Finally, end the program by returning
    -- the success status code.
    return ExitSuccess();
end;
```

## The FFI Boundary

Ultimately, all guarantees are lost at the FFI boundary. Because foreign
functions are permissionless, we can implement both the capability-free and the
capability-secure APIs in Austral. Does that mean these guarantees are
worthless?

No. To use the FFI, a module has to be marked as [unsafe][unsafe] using the
`Unsafe_Module` pragma.

The idea is that a list of unsafe modules in all dependencies (including
transitive ones) can be collected by the build system. Then, only code at the
FFI boundary needs to be audited, to ensure that it correctly wraps the
capability-insecure outside world under a correct, linear, capability-secure
API.

## Footnotes

[^fn1]:
    Special paths like `..` should be banned, naturally.

[supply]: https://en.wikipedia.org/wiki/Supply_chain_attack
[cap]: https://en.wikipedia.org/wiki/Capability-based_security
[clock]: https://twitter.com/robotlolita/status/1474351603008389122
[timing]: https://en.wikipedia.org/wiki/Timing_attack
[side]: https://en.wikipedia.org/wiki/Side-channel_attack
[spectre]: https://en.wikipedia.org/wiki/Spectre_(security_vulnerability)
[unsafe]: /spec/modules#unsafe-modules
