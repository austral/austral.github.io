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

all: assets/spec/file-api.png \
     assets/spec/file-api-errors.png \
     assets/spec/file-api-without-leaks.png \
     assets/spec/file-api-without-leaks-and-double-close.png

clean:
	rm assets/spec/file-api.png
	rm assets/spec/file-api-errors.png
	rm assets/spec/file-api-without-leaks.png
	rm assets/spec/file-api-without-leaks-and-double-close.png
