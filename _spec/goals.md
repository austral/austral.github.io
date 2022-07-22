# Design Goals {#goals}

This section lists the design goals for Austral.

1. **Simplicity.** This is the _sine qua non_: the language must be simple
   enough to fit in a single person's head. We call this "fits-in-head
   simplicity". Notably, many languages fail to clear this bar. C++ is the
   prototypical example, already [its author has warned][vasa] against excess
   complexity (in vain).

   Simplicity is valuable for multiple reasons:

   1. It makes the language easier to implement, which makes it feasible to have
      multiple implementations, reducing vendor lock-in risk.

   2. It makes the language easier to learn, which is good for beginners.

   3. It makes code easier to reason about, because there are fewer overlapping
      language features to consider.

   Simplicity is defined in terms of [Kolmogorov complexity][compl]: a system is
   simple not when it forgives mistakes or is beginner-friendly or is easy to
   use. A system is simple when _it can be described briefly_.

   Two crucial measures of simplicity are:

   1. Language lawyering should be impossible. If people can argue about what
      some code prints out, that's a language failure. If code can be ambiguous
      or obsfuscated, that is not a failure of the programmer but a failure of
      the language.

   2. A programmer should be able to learn the language in its entirety by
      reading this specification.

   Simplicity also means that Austral is a generally low-level language. There
   is no garbage collector, not primarily because of performance concerns, but
   because it would require an arbitrarily complex runtime.

2. **Correctness.** This is an intangible, but generally, the measure of how
   much a language enables programmers to write correct code is: if the code
   compiles, it should work. With the caveat that said code should use the
   relevant safety features, since it is possible to write unsafe C in any
   language.

   There is a steep tradeoff curve between correctness and simplicity: simple
   type system features provide 80% of correctness. The remaining 20% consists
   of things like:

   1. Statically proving that there are no integer overflows.
   2. Proving that all array indexing calls are within array bounds.
   3. More generally: proving that function contracts are upheld.

   Doing this with full generality requires either interactive theorem proving
   or SMT solving, which is a massive increase in implementational complexity
   (Z3 is 300,000 lines of C++). Given that this is an active area of research
   in computer science, we sacrifice absolute safety for implementational
   simplicity.

3. **Security.** It should not be difficult to write secure code. That is:
   ordinary language features should not be strewn with footguns that make
   security impossible.

4. **Readability.** We are not typists, we are programmers. And because code is
   read far more than it is written, we should optimize for readability, perhaps
   at the cost of writability.

5. **Maintainability.** Leslie Lamport [wrote][lamport]:

   >An automobile runs, a program does not. (Computers run, but I’m not
   >discussing them.) An automobile requires mainte- nance, a program does
   >not. A program does not need to have its stack cleaned every 10,000
   >miles. Its if statements do not wear out through use. (Previously undetected
   >errors may need to be corrected, or it might be necessary to write a new but
   >sim- ilar program, but those are different matters.) An automobile is a
   >piece of machinery, a program is some kind of mathematical expression.

   Working programmers know this is far from reality. Bitrot, not permanence, is
   the norm. However, bitrot is avoidable by doing careful design up-front,
   prioritizing stability in the design, and, crucially: saying _no_ to proposed
   language features. The goal is that code written in Austral that depends only
   on the standard library should compile and run without changes decades into
   the future.

6. **Modularity.** Software is built out of hierarchically organized modules,
   accessible through interfaces. Languages have more-or-less explicit support
   for this:

   1. In C, all declarations exist in the same namespace, and textual inclusion
      and the separation of header and implementation files provides a loose
      modularity, enforced only through style guides and programmer discipline.

   2. In Python, modules exist, their names and paths are tied to the
      filesystem, and the accessibility of identifiers is determined by their
      names.

   3. In Rust and Java, visibility modifiers are attached to declarations to
      make them public or private.

   Austral's module system is inspired by those of Ada, Modula-2, and Standard
   ML, with the restriction that there are no generic modules (as in Ada or
   Modula-3) or functors (as in Standard ML or OCaml), that is: all modules are
   first-order.

   Modules are given explicit names are are not tied to any particular file
   system structure. Modules are split in two textual parts (effectively two
   files), a module interface and a module body, with strict separation between
   the two. The declarations in the module interface file are accessible from
   without, and the declarations in the module body file are private.

   Crucially, a module `A` that depends on a module `B` can be typechecked when
   the compiler only has access to the interface file of module `B`. That is:
   modules can be typechecked against each other before being implemented. This
   allows system interfaces to be designed up-front, and implemented in
   parallel.

7. **Strictness.** Gerald Jay Sussman and Hal Abelson [wrote][sicp]:

   >Pascal is for building pyramids --- imposing, breathtaking, static structures
   >built by armies pushing heavy blocks into place. Lisp is for building
   >organisms --- imposing, breathtaking, dynamic structures built by squads
   >fitting fluctuating myriads of simpler organisms into place.

   Austral is decidedly a language for building pyramids. Code written in
   Austral is strict, rigid, crystalline, and _brittle_: minor changes are prone
   to breaking the build. We posit that this is a good thing.

8. **Restraint.** There is a widespread view in software engineering that errors
   are the responsibility of programmers, that "only a bad craftsperson
   complains about their tools", and that the solution to catastrophic security
   vulnerabilities caused by the same underlying mechanisms is to simply write
   fewer bugs.

   We take the view that human error is an inescapable, intrinsic aspect of
   human activity. Human processes such as code review are only as good as the
   discipline of the people running them, who are often tired, burnt out,
   distracted, or otherwise unable to accurately simulate virtual machines (a
   task human brains were not evolved for), or facing business pressure to put
   expedience over correctness. Mechanical processes --- such as type systems,
   type checking, formal verification, design by contract, static assertion
   checking, dynamic assertion checking --- are independent of the skill of the
   programmer.

   Therefore: programmers need all possible mechanical aid to writing good code,
   up to the point where the implemention/semantic complexity exceeds the gains
   in correctness.

   Given the vast empirical evidence that humans are unable to predict the
   failure modes and security vulnerabilities in the code they write, Austral is
   designed to restrain programmer power and minimize footguns.

[vasa]: https://www.stroustrup.com/P0977-remember-the-vasa.pdf
[lamport]: https://lamport.azurewebsites.net/pubs/future-of-computing.pdf
[compl]: https://en.wikipedia.org/wiki/Kolmogorov_complexity
[sicp]: https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book-Z-H-5.html
