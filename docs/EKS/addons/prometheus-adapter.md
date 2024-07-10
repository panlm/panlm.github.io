---
title: prometheus-adapter
description: 
created: 2024-05-27 09:00:14.525
last_modified: 2024-07-27
tags:
  - kubernetes
---

# prometheus-adapter

## install
- https://github.com/kubernetes-sigs/prometheus-adapter
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prom-adapter prometheus-community/prometheus-adapter -n kube-system

```


## alternative
- [[metrics-server]]
