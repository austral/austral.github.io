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

#
# Spec
#

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

SPEC_PDF  := _spec/spec.pdf
SPEC_HTML := _spec/spec.html

$(SPEC_PDF): $(SPEC_SRC)
	pandoc -t latex \
		   -f markdown \
		   --pdf-engine=xelatex \
		   --table-of-contents \
		   --toc-depth=2 \
		   --resource-path=assets/spec \
		   $(SPEC_SRC) \
		   -o $(SPEC_PDF)

#
# Start targets
#

all: assets/spec/file-api.png \
     assets/spec/file-api-errors.png \
     assets/spec/file-api-without-leaks.png \
     assets/spec/file-api-without-leaks-and-double-close.png \
     $(SPEC_PDF)

clean:
	rm assets/spec/file-api.png
	rm assets/spec/file-api-errors.png
	rm assets/spec/file-api-without-leaks.png
	rm assets/spec/file-api-without-leaks-and-double-close.png
