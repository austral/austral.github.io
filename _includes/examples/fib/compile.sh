austral compile --public-module=fib.aum --entrypoint=Fib:main --output=fib.c
gcc fib.c -o fib
