---
last_modified: 2023-10-29 13:21:38.256
number headings: first-level 2, max 3, 1.1, auto
---
> [!WARNING] This is a github note

# EKS
## 1 infra
### 1.1 cluster
```expander
(path:git/git-mkdocs/eks/infra/cluster file:.md)
-  [[$filename]]: $frontmatter:description
```
-  [[eks-cluster-with-terraform]]: 使用 Terraform 创建 EKS 集群
-  [[eks-private-access-cluster]]: 在已有 vpc 中创建私有访问的 eks 集群
-  [[eks-public-access-cluster]]: 创建公有访问的 eks 集群
-  [[eks-public-access-cluster-in-china-region]]: 在中国区域，创建共有访问的 eks 集群
<-->

### 1.2 compute
```expander
(path:git/git-mkdocs/eks/infra/compute file:.md)
- [[$filename]]: $frontmatter:description
```
- [[eks-fargate-lab]]: 在 eks 集群中使用 fargate
- [[karpenter-lab]]: 使用 Karpenter 代替 Cluster Autoscaler
<-->

### 1.3 network
```expander
(path:git/git-mkdocs/eks/infra/network file:.md)
- [[$filename]]: $frontmatter:description
```
- [[appmesh-workshop-eks]]: appmesh workshop
- [[automated-canary-deployment-using-flagger]]: 自动化 canary 部署
- [[aws-load-balancer-controller]]: 使用 aws 负载均衡控制器
- [[eks-custom-network]]: custom network 可以解决子网地址段耗尽的问题
- [[enable-sg-on-pod]]: 启用 pod 安全组
- [[externaldns-for-route53]]: 使用 externaldns 组件
- [[nginx-ingress-controller-community-ver]]: 使用 nginx ingress
- [[self-signed-certificates]]: 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
<-->

### 1.4 storage
```expander
(path:git/git-mkdocs/eks/infra/storage file:.md)
- [[$filename]]: $frontmatter:description
```
- [[ebs-for-eks]]: 使用 ebs 作为 pod 持久化存储 
- [[efs-for-eks]]: 使用 efs 作为 pod 持久化存储
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
- [[cloudwatch-to-firehose-python]]: 在 firehose 上，处理从 cloudwatch 发送来的日志
- [[export-cloudwatch-log-group-to-s3]]: 导出 cloudwatch 日志到 s3
- [[stream-k8s-control-panel-logs-to-s3]]: 目前eks控制平面日志只支持发送到cloudwatch，且在同一个log group中有5种类型6种前缀的log stream的日志，不利于统一查询。且只有audit日志是json格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
<-->

### 2.3 monitor
```expander
(path:git/git-mkdocs/eks/operation/monitor file:.md)
- [[$filename]]: $frontmatter:description
```
- [[cluster-autoscaler]]: EKS 集群中安装 Cluster Autoscaler
- [[eks-container-insights]]: 启用 EKS 的 container insight 功能
- [[enable-prometheus-in-cloudwatch]]: 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [[install-grafana-on-beanstalk]]: 在 EC2 / beanstalk / EKS 上安装 grafana 
- [[install-prometheus-grafana]]: 安装 grafana 和 prometheus
- [[metrics-server]]: EKS 集群中安装 metrics server
- [[POC-prometheus-ha-architect-with-thanos]]: Prometheus是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于HTTP的pull模式采集时序数据，提供功能强大的查询语言PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。当集群数量较多，监控平台高可用性和可靠性要求高，希望提供全局查询，需要长时间保存历史监控数据等场景下，通常使用 Thanos 扩展 Promethseus 监控架构。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制，具体来说，Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询和数据备份等方面的扩展性挑战。
<-->

### 2.4 upgrade
```expander
(path:git/git-mkdocs/eks/operation/upgrade file:.md)
- [[$filename]]: $frontmatter:description
```
- [[aws-for-fluent-bit]]: 
- [[cert-manager]]: cert-manager
- [[cni-metrics-helper]]: cni-metrics-helper
- [[eks-addons-coredns]]: eks-addons-coredns
- [[eks-addons-kube-proxy]]: eks-addons-kube-proxy
- [[eks-addons-vpc-cni]]: eks-addons-vpc-cni
- [[eks-cluster-addons-list]]: EKS 常用插件清单
- [[eks-upgrade-procedure]]: eks 集群升级
- [[eksup]]: eksup
- [[kube-no-trouble]]: kube-no-trouble
- [[kube-state-metrics]]: kube-state-metrics
- [[nginx-ingress-controller]]: nginx-ingress-controller
- [[nginx-ingress-controller-nginx-ver]]: nginx-ingress-controller-nginx-ver
- [[pluto]]: pluto
<-->
