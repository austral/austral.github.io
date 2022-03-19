---
title: Design Goals
---

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

2. **Correctness.** This is an intangible, but generally, the measure of how
   much a language enables programmers to write correct code is: if the code
   compiles, it should work. With the caveat that said code should use the
   relevant safety features, since it is possible to write unsafe C in any
   language.

   There is a steep tradeoff curve between correctness and simplicity: simple
   type system features provide 80% of correctness. The remaining 20% consists of things like:

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

[vasa]: https://www.stroustrup.com/P0977-remember-the-vasa.pdf
[lamport]: https://lamport.azurewebsites.net/pubs/future-of-computing.pdf
