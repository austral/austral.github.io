---
title: 'Getting Started: Linux'
---

You have two options: download a pre-built release of the compiler, or building
it from source.

## Downloading a Release

Run this to download and install the latest release:

```bash
$ curl -o austral -L https://github.com/austral/austral/releases/latest/download/austral-linux
$ sudo install -m 755 austral /usr/local/bin/austral
```

Then you can invoke `austral` from the command line.

## Building from Source

First, you need to install [opam][opam], the package manager for OCaml. On
Debian/Ubuntu, this is simply:

```bash
$ sudo apt-get install opam
```

Then, set up the OCaml compiler environment:

```bash
$ opam init
$ opam switch install 4.13.0
```

Then, download and build Austral:

```bash
$ git clone https://github.com/austral/austral.git
$ cd austral
$ ./install-ocaml-deps.sh
$ make
$ sudo make install
```

### Navigation

- [Forward](/tutorial/hello-world)

[opam]: https://opam.ocaml.org/doc/Install.html
