.PHONY: default
default: all

hello-world/hello: hello-world/hello.aum hello-world/compile.sh
	(cd hello-world; bash compile.sh )

hello-world/output.txt: hello-world/hello
	./hello-world/hello > hello-world/output.txt

all: hello-world/output.txt

clean:
	rm hello-world/output.txt
