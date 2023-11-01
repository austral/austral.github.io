---
title: 'Getting Started: Linux'
---

You have two options: download a pre-built release of the compiler, or building
it from source.

## Downloading a Release

Run this to download and install the latest release for [Nix][nix]:

```bash
$ curl -o austral -L https://github.com/austral/austral/releases/latest/download/austral-linux
$ sudo install -m 755 austral /usr/local/bin/austral
```

Then you can invoke `austral` from the command line.

## Building from Source

### Building with Nix

If you have [Nix][nix], this will be much simpler. Just:

[nix]: https://nixos.org/

```bash
$ nix-shell
$ make
```

And you're done.

### Building without Nix

Building the `austral` compiler requires `make` and the `dune` build system for
OCaml, and a C compiler for building the resulting output. You should install
OCaml 4.13.0 or above.

First:

```bash
$ git clone git@github.com:austral/austral.git
$ cd austral
```

Next, install [opam][opam]. On Debian/Ubuntu you can just do:

```bash
$ sudo apt-get install opam
$ opam init
```

Then, create an opam switch for austral and install dependencies via opam:

```bash
opam switch create austral 4.13.0
eval $(opam env --switch=austral)
opam install --deps-only -y .
```

Finally:
```bash
make
```

To build the standard library:

```bash
$ cd standard
$ make
```


### Navigation

- [Forward](/tutorial/hello-world)

[opam]: https://opam.ocaml.org/doc/Install.html
