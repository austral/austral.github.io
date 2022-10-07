---
title: Hello, World!
---

{% capture source %}{% include examples/hello-world/hello.aum %}{% endcapture %}
{% capture compile %}{% include examples/hello-world/compile.sh %}{% endcapture %}
{% capture output %}{% include examples/hello-world/output.txt %}{% endcapture %}

Without further ado:

```austral
{{ source }}
```

Save this to `hello.aum`, then run:

```bash
$ {{ compile | strip }}
$ ./hello
{{ output | strip }}
```

### Navigation

- [Back](/tutorial/getting-started-linux)
- [Forward](/tutorial/modules)
