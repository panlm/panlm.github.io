---
title: Kyverno
description: Kyverno
created: 2023-10-07 21:26:00.639
last_modified: 2023-10-07 21:26:36.720
tags:
  - kubernetes
---

# Kyverno
Kubernetes Native Policy Management

## install
https://kyverno.io/docs/installation/methods/
```sh
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
helm install kyverno-policies kyverno/kyverno-policies -n kyverno
```


## install from nirmata
https://github.com/nirmata/kyverno-notation-aws#install







