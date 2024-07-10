---
title: helm-cmd
description: 
created: 2024-03-27 20:22:27.977
last_modified: 2024-03-27
tags:
  - kubernetes
---

# helm-cmd

## install
```sh
helm upgrade -i -f prom.yaml prom-0327 prometheus-community/kube-prometheus-stack --namespace monitoring
```

## search chats
```
helm search repo <repo_name>

```

## show value
```sh
# refer defualt value
helm show values prometheus-community/kube-prometheus-stack > values_default.yaml

```




