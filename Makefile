.PHONY: default
default: all

assets/spec/file-api.png: assets/spec/file-api.dot
	dot -Tpng $< -o $@

assets/spec/file-api-errors.png: assets/spec/file-api-errors.dot
	dot -Tpng $< -o $@

assets/spec/file-api-without-leaks.png: assets/spec/file-api-without-leaks.dot
	dot -Tpng $< -o $@

assets/spec/file-api-without-leaks-and-double-close.png: assets/spec/file-api-without-leaks-and-double-close.dot
	dot -Tpng $< -o $@

#
# Code Examples
#

EXDIR := _includes/examples

EXAMPLE_SRC := $(EXDIR)/*/*.aum $(EXDIR)/*/*.sh

EXAMPLE_OUT := $(EXDIR)/hello-world/output.txt \
               $(EXDIR)/fib/output.txt

$(EXAMPLE_OUT): $(EXAMPLE_SRC)
	( cd $(EXDIR)/; ./build.sh )

all: assets/spec/file-api.png \
     assets/spec/file-api-errors.png \
     assets/spec/file-api-without-leaks.png \
     assets/spec/file-api-without-leaks-and-double-close.png \
     $(EXAMPLE_OUT)

clean:
	rm assets/spec/file-api.png
	rm assets/spec/file-api-errors.png
	rm assets/spec/file-api-without-leaks.png
	rm assets/spec/file-api-without-leaks-and-double-close.png
	rm $(EXAMPLE_OUT)
