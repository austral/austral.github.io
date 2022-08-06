.PHONY: default
default: all

#
# Spec resources
#

assets/spec/file-api.png: assets/spec/file-api.dot
	dot -Tpng $< -o $@

assets/spec/file-api-errors.png: assets/spec/file-api-errors.dot
	dot -Tpng $< -o $@

assets/spec/file-api-without-leaks.png: assets/spec/file-api-without-leaks.dot
	dot -Tpng $< -o $@

assets/spec/file-api-without-leaks-and-double-close.png: assets/spec/file-api-without-leaks-and-double-close.dot
	dot -Tpng $< -o $@

assets/spec/file-api.svg: assets/spec/file-api.dot
	dot -Tsvg $< -o $@

assets/spec/file-api-errors.svg: assets/spec/file-api-errors.dot
	dot -Tsvg $< -o $@

assets/spec/file-api-without-leaks.svg: assets/spec/file-api-without-leaks.dot
	dot -Tsvg $< -o $@

assets/spec/file-api-without-leaks-and-double-close.svg: assets/spec/file-api-without-leaks-and-double-close.dot
	dot -Tsvg $< -o $@

#
# Spec
#

PANDOC_FLAGS := --table-of-contents --toc-depth=2 --resource-path=. --standalone

SPEC_SRC := _spec/intro.md \
            _spec/goals.md \
			_spec/rationale.md \
			_spec/rationale-syntax.md \
			_spec/rationale-linear-types.md \
			_spec/rationale-error-handling.md \
			_spec/rationale-capabilities.md \
			_spec/syntax.md \
			_spec/modules.md \
			_spec/types.md \
			_spec/type-classes.md \
			_spec/declarations.md \
			_spec/statements.md \
			_spec/expressions.md \
			_spec/linearity.md \
			_spec/builtins.md \
			_spec/austral-memory.md \
			_spec/austral-pervasive.md \
			_spec/ffi.md \
			_spec/c-ffi.md \
			_spec/style-guide.md \
            _spec/appendix-a.md

SPEC_PDF  := spec/spec.pdf
SPEC_HTML := spec/spec.html

$(SPEC_PDF): $(SPEC_SRC)
	pandoc -t latex \
		   -f markdown \
		   --pdf-engine=xelatex \
		   $(PANDOC_FLAGS) \
		   $(SPEC_SRC) \
		   -o $(SPEC_PDF)

$(SPEC_HTML): $(SPEC_SRC) _spec/template.html
	pandoc -t html5 \
		   -f markdown \
		   --template=_spec/template.html \
		   $(PANDOC_FLAGS) \
		   --mathjax \
		   $(SPEC_SRC) \
		   -o $(SPEC_HTML)

#
# Code Examples
#

EXDIR := _includes/examples

EXAMPLE_SRC := $(EXDIR)/*/*.aum $(EXDIR)/*/*.sh

EXAMPLE_OUT := $(EXDIR)/hello-world/output.txt \
               $(EXDIR)/fib/output.txt

$(EXAMPLE_OUT): $(EXAMPLE_SRC)
	( cd $(EXDIR)/; ./build.sh )

#
# Start targets
#

TARGETS := assets/spec/file-api.png \
		   assets/spec/file-api-errors.png \
		   assets/spec/file-api-without-leaks.png \
		   assets/spec/file-api-without-leaks-and-double-close.png \
		   assets/spec/file-api.svg \
		   assets/spec/file-api-errors.svg \
		   assets/spec/file-api-without-leaks.svg \
		   assets/spec/file-api-without-leaks-and-double-close.svg \
		   $(SPEC_HTML) \
       $(EXAMPLE_OUT)

all: $(TARGETS)

clean:
	rm $(TARGETS)
