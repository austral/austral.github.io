#!/usr/bin/env bash

function comp() {
    cd $1;
    bash compile.sh;
    ./$2 > output.txt;
    cd ..
}

comp hello-world hello
comp fib fib
