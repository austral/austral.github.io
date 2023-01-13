---
title: Module Structure
---

This section explains Austral's module system.

# What is a module?

A module is the main unit of code organization in Austral. A module is a name
and a set of _declarations_, which can be public (importable by other modules)
or private.

Module names, like in many programming languages, look like this:

- `Standard.Data.Buffer`
- `MyProject.Database.Sql`
- `MyProject.Serialization.Csv.Reader`

Module names are identifiers separated by dots. Module names are _conceptually_
hierarchical: you start with the name of the project or organization, and
subsequent names denote how code is organized. However, modules do not actually
form a hierarchy: the module namespace is flat.

# Declarations

Modules contain declarations, and there are four kinds of declarations:

- Constants.
- Types.
- Functions.
- Typeclasses.
- Typeclass instances.

We'll learn about each of these throughout the tutorial.

# Visibility

Declarations are be either _public_ or _private_. Private declarations are
invisible to the outside world. Public declarations may be imported by other
modules, and imported public declarations act _as if_ they had been defined in
the module that imports them.

Type definitions have a third visibility category: _opaque_. An opaque type is
one that can be imported and referred to by other modules, but its contents are
hidden. Outside the module that defines them, opaque types cannot be
constructed, nor can their contents be accessed.

The usefulness of opaque types is that they can only be created, accessed, and
transformed by the API functions of the module that defines them. This allows
you to define types which are "correct by construction", by having the
constructor and transformation functions enforce certain invariants.

# Interfaces and Implementations

Austral separates modules into a _module interface_ file and a _module body_
file.

The point of separating interfaces and implementations is readability: the
interface describes all the things module's declarations that are public and
importable by other modules. The implementation contains the things that are
private, and the bodies of functions and such. When you're trying to familiarize
yourself with a module in order to use it, you just have to read the
interface.

It should be stressed: unlike C and C++, the separation of modules into
interfaces and implementations is not a hack to enable separate compilation (in
fact, the compiler combines that interface and implementation into a single
module representation as one of the earliest stages of compilation).

# Examples

This section contains examples of the module system.

## Example: Physical Constants

Let's define a module that exports physical constants.

In the interface file, we declare the names of the constants, along with their
types and a docstring, but not their values:

```austral
module Example.PhysicalConstants is
    """
    The speed of light in meters per second.
    """
    constant speed_of_light: Float64;

    """
    The elementary charge in Coulomb.
    """
    constant elementary_charge: Float64;
end module.
```

In the module file, we actually define the values:

```austral
module body Example.PhysicalConstants is
    constant speed_of_light: Float64 := 299792458.0;

    constant elementary_charge: Float64 := 1.602176634e-19;
end module body.
```

### Navigation

- [Back](/tutorial/hello-world)
- [Forward](/tutorial/basic-types)
