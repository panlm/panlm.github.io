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

- create cluster and delete default aws vpc cni
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

# 确认使用节点 ip 作为出向 nat (natOutgoing=true)
# kubectl get ippool default-ipv4-ippool -o jsonpath='{.spec.natOutgoing}' 

eksctl create nodegroup \
  --cluster ${CLUSTER_NAME} \
  --node-type m5.large \
  --max-pods-per-node 100 \
  --node-private-networking 

```

## 必须使用 hostNetwork 的组件

### CNI 插件本身

- 原因：需要配置节点网络，在网络初始化之前运行
- 实测：需要

```text
NAME                                      READY   STATUS    RESTARTS   AGE    IP                NODE                                            NOMINATED NODE   READINESS GATES
calico-apiserver-565867495-ft8w2          1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
calico-apiserver-565867495-ld47h          1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-kube-controllers-578677b48-b5fgt   1/1     Running   0          2d3h   172.16.28.6       ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-node-d92rg                         1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-node-fxhmc                         1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
calico-typha-68c49cdb58-wwldh             1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
goldmane-65dcd4f69b-cpnwm                 1/1     Running   0          2d3h   172.16.28.1       ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
whisker-785fcbb6fb-d6hm8                  2/2     Running   0          2d3h   172.16.186.65     ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### Kube-proxy 

- 原因：需要管理节点的 iptables/ipvs 规则
- 实测：需要

```text
ubuntu:~$ kubectl get pod -A  -l k8s-app=kube-proxy -o wide
NAMESPACE     NAME               READY   STATUS    RESTARTS   AGE    IP                NODE                                            NOMINATED NODE   READINESS GATES
kube-system   kube-proxy-dxfx5   1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
kube-system   kube-proxy-w9vtm   1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### AWS Load Balancer Controller

- 原因：需要直接访问 AWS API 和 VPC 资源，overlay IP 无法被 AWS 服务识别
- 实测：需要
- [[git/git-mkdocs/EKS/addons/aws-load-balancer-controller#install-|install]] it
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
- install app to [[git/git-mkdocs/EKS/addons/externaldns-for-route53#verify-|verify]] 

### Metrics Server

- 原因: 需要从 kubelet 收集指标，使用 hostNetwork 可以避免网络层问题
- 实测：启用后才能看到 cpu memory 等指标，不启用也没有报错
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

```text
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE   IP                NODE                                            NOMINATED NODE   READINESS GATES
kube-system   metrics-server-5cd97b659b-8mjgj   1/1     Running   0          58s   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
kube-system   metrics-server-5cd97b659b-fbp77   1/1     Running   0          58s   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

## 推荐使用 hostNetwork 的组件:

### Cluster Autoscaler

- 原因: 需要调用 AWS API 管理 Auto Scaling Groups
- 实测：

### Node Problem Detector

- 原因：需要监控节点级别的问题
- 实测：

### CoreDNS 

- 原因：DNS 解析是关键服务，hostNetwork 可以提高可靠性，(可选但推荐)
- 实测：不使用 hostNetwork 也可以成功解析

```text
ubuntu:~$ kubectl get pod -A  -l eks.amazonaws.com/component=coredns -o wide
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE    IP            NODE                                            NOMINATED NODE   READINESS GATES
kube-system   coredns-5449774944-2d4jb   1/1     Running   0          2d4h   172.16.28.5   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
kube-system   coredns-5449774944-dnskk   1/1     Running   0          2d4h   172.16.28.4   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
```

### External DNS

- 原因：需要访问 AWS Route53 API
- 实测：不使用 hostNetwork 也可以成功创建 dns 记录
- refer: [[externaldns-for-route53]] 

```text
ubuntu:~$ kubectl get pod -A  -l "app.kubernetes.io/instance=external-dns,app.kubernetes.io/name=external-dns" -o wide
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE   IP              NODE                                            NOMINATED NODE   READINESS GATES
externaldns   external-dns-596bf4886b-lkg7k   1/1     Running   0          28h   172.16.186.69   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### EBS CSI Driver Node Plugin

- 原因：需要直接访问节点的块设备
- 实测：不使用 hostNetwork 也可以使用
- refer: [[ebs-for-eks]]

```text
ubuntu:~$ kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-ebs-csi-driver,app.kubernetes.io/instance=storage-ebs-csi" -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP              NODE                                            NOMINATED NODE   READINESS GATES
ebs-csi-controller-97758bb7c-gnb45   5/5     Running   0          26m   172.16.186.72   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
ebs-csi-node-255gc                   3/3     Running   0          26m   172.16.28.8     ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
ebs-csi-node-t48tp                   3/3     Running   0          26m   172.16.186.71   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### EFS CSI Driver Node Plugin

- 原因：需要挂载 EFS 到节点
- 实测：不使用 hostNetwork 也可以使用，但是 efs csi node pod 自动使用 hostNetwork
- refer: [[efs-csi]]

```text
ubuntu:~$ kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=storage-efs-csi" -o wide
NAME                                  READY   STATUS    RESTARTS   AGE     IP                NODE                                            NOMINATED NODE   READINESS GATES
efs-csi-controller-784c568b8b-qgrh2   3/3     Running   0          8m46s   172.16.186.74     ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
efs-csi-node-kq96r                    3/3     Running   0          8m46s   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
efs-csi-node-qfrhk                    3/3     Running   0          8m46s   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```



