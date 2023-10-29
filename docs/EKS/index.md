---
last_modified: 2023-10-29 13:17:53.056
number headings: first-level 2, max 3, 1.1, auto
---

[!WARNING] This is a github note

```ad-attention
title: This is a github note
[!WARNING] This is a github note
```

# EKS

## 1 infra

### 1.1 cluster

```expander
(path:git/git-mkdocs/eks/infra/cluster file:.md)
-  [[$filename]]: $frontmatter:description
```
-  [[eks-public-access-cluster]]: 创建公有访问的 eks 集群
-  [[eks-public-access-cluster-in-china-region]]: 在中国区域，创建共有访问的 eks 集群
-  [[eks-private-access-cluster]]: 在已有 vpc 中创建私有访问的 eks 集群
-  [[eks-terraform-cluster]]: 使用 terraform 创建 eks 集群
<-->

### 1.2 compute

```expander
(path:git/git-mkdocs/eks/infra/compute file:.md)
- [[$filename]]: $frontmatter:description
```
- [[eks-fargate-lab]]: 在 eks 集群中使用 fargate
<-->

### 1.3 network

```expander
(path:git/git-mkdocs/eks/infra/network file:.md)
- [[$filename]]: $frontmatter:description
```
- [[appmesh-workshop-eks]]: appmesh workshop
- [[automated-canary-deployment-using-flagger]]: 自动化 canary 部署
- [[aws-load-balancer-controller]]: 使用 aws 负载均衡控制器
- [[self-signed-certificates]]: 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
- [[externaldns-for-route53]]: 使用 externaldns 组件
- [[enable-sg-on-pod]]: 启用 pod 安全组
- [[nginx-ingress-controller-community-ver]]: 使用 nginx ingress
- [[eks-custom-network]]: custom network 可以解决子网地址段耗尽的问题
- [[build-colorapp]]: 创建 color 应用
<-->

### 1.4 storage

```expander
(path:git/git-mkdocs/eks/infra/storage file:.md)
- [[$filename]]: $frontmatter:description
```
- [[efs-for-eks]]: 使用 efs 作为 pod 持久化存储
- [[ebs-for-eks]]: 使用 ebs 作为 pod 持久化存储 
<-->

## 2 operation
### 2.1 gitops

```expander
(path:git/git-mkdocs/eks/operation/gitops file:.md)
- [[$filename]]: $frontmatter:description
```
- [[argocd-lab]]: argocd
- [[flux-lab]]: flux
<-->

### 2.2 logging

```expander
(path:git/git-mkdocs/eks/operation/logging file:.md)
- [[$filename]]: $frontmatter:description
```
- [[stream-k8s-control-panel-logs-to-s3]]: 目前eks控制平面日志只支持发送到cloudwatch，且在同一个log group中有5种类型6种前缀的log stream的日志，不利于统一查询。且只有audit日志是json格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [[export-cloudwatch-log-group-to-s3]]: 导出 cloudwatch 日志到 s3
- [[cloudwatch-to-firehose-python]]: 在 firehose 上，处理从 cloudwatch 发送来的日志
<-->

### 2.3 monitor

```expander
(path:git/git-mkdocs/eks/operation/monitor file:.md)
- [[$filename]]: $frontmatter:description
```
- [[install-grafana-lab]]: 在 EC2 / beanstalk / EKS 上安装 grafana 
- [[eks-container-insights]]: 启用 EKS 的 container insight 功能
- [[metrics-server]]: EKS 集群中安装 metrics server
- [[install-prometheus-grafana]]: 安装 grafana 和 prometheus
- [[enable-prometheus-in-cloudwatch]]: 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [[cluster-autoscaler]]: EKS 集群中安装 Cluster Autoscaler
<-->

### 2.4 upgrade

```expander
(path:git/git-mkdocs/eks/operation/upgrade file:.md)
- [[$filename]]: $frontmatter:description
```
- [[aws-for-fluent-bit]]: 
- [[eks-addons-coredns]]: eks-addons-coredns
- [[cert-manager]]: cert-manager
- [[eks-addons-kube-proxy]]: eks-addons-kube-proxy
- [[eks-addons-vpc-cni]]: eks-addons-vpc-cni
- [[eks-upgrade-procedure]]: eks 集群升级
- [[pluto]]: pluto
- [[nginx-ingress-controller]]: nginx-ingress-controller
- [[nginx-ingress-controller-nginx-ver]]: nginx-ingress-controller-nginx-ver
- [[kube-state-metrics]]: kube-state-metrics
- [[kube-no-trouble]]: kube-no-trouble
- [[eksup]]: eksup
- [[eks-cluster-addons-list]]: EKS 常用插件清单
- [[cni-metrics-helper]]: cni-metrics-helper
<-->
