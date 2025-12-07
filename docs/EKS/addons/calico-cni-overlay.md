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
CLUSTER_NAME=my-calico-cluster

eksctl create cluster --name ${CLUSTER_NAME} \
  --without-nodegroup \
  --enable-auto-mode=false

kubectl delete daemonset -n kube-system aws-node

```

## calico cni 

- refer: [calico doc](https://docs.tigera.io/calico/latest/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-calico-networking) 
```bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update

# install calico using helm
kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.31.2 --namespace tigera-operator
kubectl patch installation default --type='json' -p='[{"op": "replace", "path": "/spec/cni", "value": {"type":"Calico"} }]'

# 确认使用节点 ip 作为出向 nat
# kubectl get ippool default-ipv4-ippool -o jsonpath='{.spec.natOutgoing}' 

eksctl create nodegroup \
  --cluster ${CLUSTER_NAME} \
  --node-type m5.large \
  --max-pods-per-node 100 \
  --node-private-networking 

```

## 必须使用 hostNetwork 的组件
### aws load balancer controller

- 原因: 需要直接访问 AWS API 和 VPC 资源，overlay IP 无法被 AWS 服务识别
- [[git/git-mkdocs/EKS/addons/aws-load-balancer-controller#install-]]
- patch it
```bash

kubectl patch deployment aws-load-balancer-controller \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

# verify
kubectl get deployment aws-load-balancer-controller \
  -n kube-system \
  -o jsonpath='{.spec.template.spec.hostNetwork}' 
  
```
- install external dns for route53 (chapter [[#External DNS]])
- install app to verify ([[git/git-mkdocs/EKS/addons/externaldns-for-route53#verify-]])

### Kube-proxy 

- 原因: 需要管理节点的 iptables/ipvs 规则

### CNI 插件本身 (Calico Node)

- 原因: 需要配置节点网络，在网络初始化之前运行

### Metrics Server

- 原因: 需要从 kubelet 收集指标，使用 hostNetwork 可以避免网络层问题
- 启用后才能看到 cpu memory 等指标
- refer: [[metrics-server]]
```sh

kubectl patch deployment metrics-server \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

# verify
kubectl get deployment metrics-server \
  -n kube-system \
  -o jsonpath='{.spec.template.spec.hostNetwork}' 
  
```


## 推荐使用 hostNetwork 的组件:

### Cluster Autoscaler

- 原因: 需要调用 AWS API 管理 Auto Scaling Groups

### Node Problem Detector

- 原因: 需要监控节点级别的问题

### CoreDNS (可选但推荐)

- 原因: DNS 解析是关键服务，hostNetwork 可以提高可靠性
- 不使用 hostNetwork 也可以成功解析

### External DNS

- 原因: 需要访问 AWS Route53 API
- refer: [[externaldns-for-route53]] 
- 不使用 hostNetwork 也可以成功创建 dns 记录

### EBS CSI Driver Node Plugin

- 原因: 需要直接访问节点的块设备

### EFS CSI Driver Node Plugin

- 原因: 需要挂载 EFS 到节点
