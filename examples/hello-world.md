---
title: Hello, world!
---

{% capture source %}{% include examples/hello-world/hello.aum %}{% endcapture %}
{% capture compile %}{% include examples/hello-world/compile.sh %}{% endcapture %}
{% capture output %}{% include examples/hello-world/output.txt %}{% endcapture %}


Code:

```austral
{{ source }}
```

Compile:

```bash
{{ compile | strip }}
```

Output:

```
{{ output | strip }}
```
