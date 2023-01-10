function australMode(hljs) {
    const TYPE = {
        scope: "type",
        begin: "(?<=: *)(\\w|[&!])+",
        end: "(?=[^A-Za-z0-9_])",
        contains: [
            { begin: "\\[", end: "\\]", }, // Type params
            { begin: "\\(", end: "\\)", }, // Constraints
        ]
    };

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
                "borrow",
                "in",
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
            hljs.COMMENT('--', '$'),
            hljs.QUOTE_STRING_MODE,
            hljs.C_NUMBER_MODE,
            {
                scope: "string",
                begin: "'",
                end: "'",
            },
            {
                scope: "comment",
                begin: "\\.{3}",
                end: "$",
            },
            {
                scope: "type",
                begin: "(?<=type +)",
                end: "(;|(?=:)|$)"
            },
            {
                scope: "type",
                begin: "(?<=instance \\w+\\()",
                end: "\\)"
            },
            {
                scope: "operator",
                begin: "(=>)|(->)"
            },
            {
                scope: "operator",
                begin: "[&!]+(?![!\\[])"
            },
            TYPE,
        ],
    };
};

hljs.registerLanguage("austral", australMode);

document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre code.language-austral').forEach((el) => {
        hljs.highlightElement(el);
    });
})
