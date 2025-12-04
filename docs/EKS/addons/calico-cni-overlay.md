---
title: calico-cni-overlay
description:
created: 2025-12-02 10:48:26.233
last_modified: 2025-12-02
tags:
  - draft
  - kubernetes/calico
---

# calico-cni-overlay

## eks cluster 

```bash

eksctl create cluster --name my-calico-cluster \
  --without-nodegroup \
  --enable-auto-mode=false

```

## calico cni 

```bash

kubectl create namespace tigera-operator
eksctl create nodegroup --cluster my-calico-cluster --node-type m5.large --max-pods-per-node 100

```

refer: https://docs.tigera.io/calico/latest/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-calico-networking

## aws lbc

```bash

kubectl patch deployment aws-load-balancer-controller \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

```




