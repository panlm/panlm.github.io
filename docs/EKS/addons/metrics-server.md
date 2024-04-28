---
title: Metrics Server
description: EKS 集群中用于弹性扩展使用的指标服务
created: 2022-07-04 13:54:12.092
last_modified: 2024-03-29
tags:
  - aws/container/eks
  - kubernetes
---

# Metrics Server

Metrics Server is not meant for non-autoscaling purposes. For example, don't use it to forward metrics to monitoring solutions, or as a source of monitoring solution metrics. In such cases please collect metrics from Kubelet `/metrics/resource` endpoint directly.

refer: [[kube-state-metrics]]

## github
- https://github.com/kubernetes-sigs/metrics-server

![[../../git-attachment/metrics-server-png-1.png]]

## install
### from yaml
- https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/metrics-server.html

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get deployment metrics-server -n kube-system
```

### from helm
- https://artifacthub.io/packages/helm/metrics-server/metrics-server

```sh
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
```

## sample
- [[../kubernetes/k8s-hpa-horizontal-pod-autoscaler]]





