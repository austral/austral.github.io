function australMode(hljs) {
    return {
        name: "Austral",
        case_insensitive: false,
        keywords: {
            keyword: [
                "and",
                "or",
                "not",
                "module",
                "body",
                "is",
                "end",
                "import",
                "as",
                "constant",
                "type",
                "record",
                "union",
                "function",
                "typeclass",
                "method",
                "instance",
                "generic",
                "if",
                "then",
                "else",
                "return",
                "case",
                "of",
                "when",
                "let",
                "while",
                "for",
                "from",
                "to",
                "do",
                "skip",
                "Free",
                "Linear",
                "Type",
                "Region",
                "pragma",
                "sizeof"
            ],
            literal: [
                "nil",
                "false",
                "true"
            ]
        },
        contains: [
            hljs.COMMENT('--', '$')
        ],
    };
};

hljs.registerLanguage("austral", australMode);

document.addEventListener('DOMContentLoaded', (event) => {
  document.querySelectorAll('pre code.language-austral').forEach((el) => {
    hljs.highlightElement(el);
  });
})
