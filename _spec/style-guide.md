# Style Guide

This section describes acceptable Austral code style.

## Case

The case conventions are:

1. Modules: `Ada_Case.With.Dot.Separators`. Examples:
   1. `MyApp.Core.Storage.SQL_Storage`
   2. `MyLib.Parsers.CSV.CSV_Types`
2. Constants: `snake_case`. Examples:
   1. `minimum_nat8`
   2, `pi`
3. Types: `PascalCase`. Examples:
   1. `Nat8`
   2. `RootCapability`
   3. `CsvReader`
4. Functions and methods: `camelCase`. Examples:
   1. `fib`
   2. `getByTitle`
   3. `parseHtmlString`
5. Type classes: `PascalCase`: Examples:
   1. `Printable`
   2. `TrappingArithmetic`
6. Variables: `snake_case`. Examples:
   1. `x`
   2. `leading_wavefront_velocity`
