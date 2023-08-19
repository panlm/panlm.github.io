---
title: "metrics-server"
description: "EKS 集群中安装 metrics server"
chapter: true
weight: 1
created: 2022-07-04 13:54:12.092
last_modified: 2022-07-04 13:54:12.092
tags: 
- aws/container/eks 
- kubernetes 
---

```ad-attention
title: This is a github note

```

{{% notice note %}}
this note covered by flux-lab
{{% /notice %}}

# metrics-server

- [github](#github)
- [install](#install)
	- [from yaml](#from-yaml)
	- [from helm](#from-helm)
- [sample](#sample)

## github
- [link](https://github.com/kubernetes-sigs/metrics-server)

![[install-metric-server-png-1.png]]

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

helm upgrade --install metrics-server metrics-server/metrics-server
```

## sample
- [[hpa-horizontal-pod-autoscaler]]





