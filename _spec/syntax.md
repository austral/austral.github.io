# Syntax {#syntax}

This section describes Austral's syntax using EBNF.

_(Note: the most up-to-date description of Austral's syntax is the Menhir syntax
definition [here][menhir]. This section is out of date.)_

[menhir]: https://github.com/austral/austral/blob/master/lib/Parser.mly

## Meta-Language {#syntax-meta}

Quick guide: definition is `=`, definitions are terminated with with
`;`. Concatenation is `,`. Alternation is `|`. Optional is `[...]`. Repetition
(zero or more) is `{...}`.

The syntax has two start symbols: one for interface files, and one for module
body files.

## Modules {#syntax-modules}

```
module interface = [docstring], {import}, "interface", module name, "is"
                   {interface declaration}, "end.";

module body = [docstring], {import}, "module", module name, "is",
              {declaration}, "end.";

import = "import", module name, ["as", identifier], ["(", imported symbols, ")"], ";";

imported symbols = identifier, ",", imported symbols
                 | identifier;

interface declaration = constant declaration
                      | type declaration
                      | opaque type declaration
                      | function declaration


declaration = constant declaration
            | type declaration
            | function declaration
```

## Declarations {#syntax-declarations}

```
constant declaration = "constant", identifier, ":", Type, ":=", expression;

type declaration = ;

opaque type declaration = "type", identifier, ";";

function declaration = ;
```

## Identifiers {#syntax-identifiers}

```
module name = module identifier, ".", module name
            | module identifier;

module identifier = identifier;

identifier = letter, {identifier character};
identifier character = letter | digit;
```

## Comments and Documentation {#syntax-comments}

```
comment = "-- ", {any character}, "\n";

docstring = "\"\"\"\n", { any character - "\"\"\"" } ,"\n\"\"\"";
```

## Literals {#syntax-literals}

```
digits = digit, { digit | "_" };
integer constant = ["+", "-"], digits;
float constant = digits, ".", digits, ["e", ["+", "-"], integer constant];
string constant = '"', { any character - '"' | '\"' }, '"';
```

## Auxiliary Non-Terminals {#syntax-aux}

```
Letter = uppercase | lowercase;
uppercase = "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J"
          | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T"
          | "U" | "V" | "W" | "X" | "Y" | "Z"
lowercase = "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j"
          | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t"
          | "u" | "v" | "w" | "x" | "y" | "z"
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9";
symbol = "$" | "?" | "'"
```
