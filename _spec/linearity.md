# Linearity Checking

This section describes Austral's linearity checking rules.

The rules for linear types:

1. A type is linear if it physically contains a linear type, or is declared to
   be linear (belongs to either the `Linear` or `Type` universes).

2. A variable `x` of a linear type must be used once and exactly once in the
   scope in which it is defined, where "used once" means:

   1. If the scope is a single block with no changes in control flow, a variable
      that appears once anywhere in the block is used once.

   2. If the scope includes an `if` statement, the variable must be used once in
      every branch or it must not appear in the statement.

   3. Analogously, if the scope includes a `case` statement, the variable must
      be used once in every `when` clause, or it must not appear in the
      statement.

   4. If the scope includes a loop, the variable may not appear in the loop body
      or the loop start/end/conditions (because it would be used once for each
      iteration). Linear variables can be _defined_ inside loop bodies, however.

   5. A borrow statement does not count as using the variable.

   6. Neither does a path that ends in a free value (this is the one concession
      to programmer ergonomics).

3. When a variable is used, it is said to be consumed. Afterwards, it is said to
   be in the consumed state.

4. If a variable is never consumed, or is consumed more than once, the compiler
   signals an error.

5. Linear values which are not stored in variables cannot be discarded.

6. You cannot return from a function while there are any unconsumed linear
   values.

7. A borrowed variable cannot appear in the body of the statement that borrows
   it.
