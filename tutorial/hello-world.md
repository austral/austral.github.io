---
title: Hello, World!
---

Without further ado:

```
module body Hello is
    function main(): ExitCode is
        printLn("Hello, world!");
        return ExitSuccess();
    end;
end module body.
```

Save this to `hello.aum`, then:

```bash
$ austral compile --public-module=hello.aum --entrypoint=Hello:main --output=hello.c
$ gcc hello.c -o hello
$ ./hello
Hello, world!
```
