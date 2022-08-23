---
title: Capability-Based Security
---

As software ecosystems grow larger, an increasingly-common type of security
vulnerability is the [supply chain attack][supply]. Austral solves this problem
using [capability-based security][cap], which adds permission checking to code.

To the filesystem, or the network, or some other privileged resource, code has
to be explicitly passed a linear value, called a capability, representing the
permission to access that resource.

# Linear Capabilities

A capability is a value that represents an unforgeable proof of the authority to
perform an action. They have the following properties:

1. Capabilities can be destroyed.

2. Capabilities can be surrended by passing them to others.

3. Capabilities cannot be duplicated.

4. Capabilities cannot be acquired out of thin air: they must be passed by the
   client.

Capabilities in Austral are implemented as linear types: they are destroyed by
being consumed, they are surrended by simply passing the value to a function,
they are non-duplicable since linear types cannot be duplicated.

# Example: Environment Variables

Consider a non-capability-secure API for accessing and modifying environment
variables:

```austral
module Env is
    function get(name: String): Option[String];
    function put(name: String, value: String): Unit;
end module.
```

Often, sensitive data is stored in the environment. We don't want arbitrary code
to be able to access it. How do we lock this down? Like so:

```austral
module Env is
    type EnvCap: Linear;

    generic [R: Region]
    function acquire(root: &[RootCapability, R]): EnvCap;

    function release(cap: EnvCap): Unit;

    generic [R: Region]
    function get(cap: &[EnvCap, R], name: String): Option[String];

    generic [R: Region]
    function put(cap: &![EnvCap, R], name: String, value: String): Unit;
end module.
```

`EnvCap` is a linear value that represents the ability to access the
environment. Since it is an opaque type, it cannot be created by clients. The
only way to construct an instance of the `EnvCap` type is via the `acquire`
function. Dually, the `release` function consumes the capability.

The `get` and `put` functions have been modified so that they take a reference
to the capability: essentially, the client has to pass proof that they have an
`EnvCap` in order to use these functions.

Here's how you'd use this:

```austral
function main(root: RootCapability): ExitCode is
    -- Acquire the environment capability from
    -- a reference to the root capability.
    let cap: EnvCap := acquire(&root);
    -- Now we can interact with the environment.
    print(get(&cap, "HOME"));
    put(&!cap, "TERM", "xterm");
    -- Release the capability;
    release(cap);
    -- Release the root capability;
    surrenderRoot(root);
    -- Finally, end the program by returning
    -- the success status code.
    return ExitSuccess();
end;
```

# The Root Capability

Capabilities cannot be created out of thin air: they can only be created by
proving proof that the client has access to a more powerful capability. This
recursion has to end somewhere.

The root of the capability hierarchy is the built-in `RootCapability`
type. Values of this type cannot be created by the programmer. A root capability
is the first and only argument to an Austral program's entrypoint function:

```austral
function main(root: RootCapability): ExitCode is
    -- Do something effectful here.
    -- ...
    -- Release the root capability;
    surrenderRoot(root);
    -- End the program.
    return ExitSuccess();
end;
```

[supply]: https://en.wikipedia.org/wiki/Supply_chain_attack
[cap]: https://en.wikipedia.org/wiki/Capability-based_security
