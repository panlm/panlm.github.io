---
last_modified: 2024-01-13
number headings: first-level 2, max 3, 1.1, auto
---

# Container

## 1 EKS

### 1.1 cluster 

```expander
(path:git/git-mkdocs/EKS/cluster file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [EKS Addons](eks-cluster-addons-list): EKS 常用插件清单
- [Create EKS Cluster with Terraform](eks-cluster-with-terraform): 使用 Terraform 创建 EKS 集群
- [Create Public Access EKS Cluster](eks-public-access-cluster): 创建公有访问的 EKS 集群
- [EKS Auto Mode](eks-auto-mode-sample): EKS Auto Mode
- [Create Private Only EKS Cluster](eks-private-access-cluster): 在已有 VPC 中创建私有访问的 EKS 集群
- [Create Public Access EKS Cluster in China Region](eks-public-access-cluster-in-china-region): 在中国区域，创建共有访问的 EKS 集群
- [EKS Upgrade Procedure](eks-upgrade-procedure): EKS 集群升级
<-->

### 1.2 kubernetes

```expander
(path:git/git-mkdocs/EKS/kubernetes file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Gateway API](k8s-gateway-api): K8S Gateway API 配置说明
- [Liveness Readiness Startup Probes](k8s-liveness-readiness-startup-probes): Liveness probes, readiness probes and startup probes
- [Pod Disruption Budget](k8s-pdb-pod-disruption-budget): Kubernetes Pod Disruption Budget
- [Topology Spread Constraints](k8s-topology-spread-constraints): Kubernetes Topology Spread Constraints
- [Kubernetes Best Practices - Resource Requests and Limits](k8s-request-limit-best-practices): Kubernetes 资源请求和限制的最佳实践
- [horizontal pod autoscaler](k8s-hpa-horizontal-pod-autoscaler): horizontal pod autoscaler
<-->

### 1.3 solutions

```expander
( path:git/git-mkdocs/EKS/solutions file:.md )
- [$frontmatter:title]($filename): $frontmatter:description
```
- [install-prometheus-grafana-on-eks](install-prometheus-operator): 安装 grafana 和 prometheus
- [Using Grafana Loki for Logging](grafana-loki): 使用 Loki 收集日志
- [Breaking Through VPC Address Limitations Using EKS Hybrid Node Architecture](use-eks-hybrid-node-to-solve-ipaddr-exhausted): 一个关于如何使用EKS混合节点功能优雅地解决VPC地址空间不足的真实案例
- [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3): 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [cloudwatch-to-firehose-python](cloudwatch-to-firehose-python): 在 firehose 上，处理从 cloudwatch 发送来的日志
- [eks-custom-network](eks-custom-network): 可以解决子网地址段耗尽的问题
- [enable-sg-on-pod](enable-sg-on-pod): 启用 pod 安全组
- [EKS Container Insights](eks-container-insights): 启用 EKS 的 container insight 功能
- [Security Lake Support Collecting Audit Logging from EKS](eks-audit-log-security-lake): 使用 Security Lake 收集 EKS Audit 日志
- [Building Prometheus HA Architect with Thanos](TC-prometheus-ha-architect-with-thanos.zh): 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
- [EKS Access API](eks-access-api): eks-access-api
- [kubernetes events exporter](k8s-event-exporter): 
- [Fargate on EKS](eks-fargate-lab): 在 EKS 集群中使用 Fargate
- [eks-loggroup-description](eks-loggroup-description): eks 日志类型分析
- [eks-aws-auth](eks-aws-auth): EKS aws-auth
- [EKS Security Group Deepdive](TC-security-group-for-eks-deepdive): 深入 EKS 安全组
- [argocd](argocd-lab): gitops 工具
- [appmesh-workshop-eks](appmesh-workshop-eks): appmesh workshop
- [eks-prefix-assignment](eks-prefix-assignment): 
- [Install Grafana on Beanstalk](install-grafana-on-beanstalk): 在 EC2 / beanstalk / EKS 上安装 grafana 
- [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3): 导出 cloudwatch 日志到 s3
- [IRSA 中的 Token 剖析](TC-eks-irsa-token-deep-dive-lab): 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- [enable-prometheus-in-cloudwatch](enable-prometheus-in-cloudwatch): 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [flux](flux-lab): gitops 工具
- [automated-canary-deployment-using-flagger](automated-canary-deployment-using-flagger): 自动化 canary 部署
<-->

### 1.4 addons 

```expander
(file:.md path:git/git-mkdocs/EKS/addons) 
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Rancher](rancher): Rancher 安装部署指南
- [Calico CNI Overlay](calico-cni-overlay): Using Calico CNI overlay mode on EKS
- [Cert Manager](cert-manager): 证书管理插件
- [AWS Load Balancer Controller](aws-load-balancer-controller): 使用 aws 负载均衡控制器
- [ExternalDNS for Route53](externaldns-for-route53): 使用 externaldns 组件
- [apisix-on-eks](apisix-on-eks): 
- [EBS CSI on EKS](ebs-csi): 使用 EBS 作为 Pod 持久化存储
- [Nginx Gateway Fabric](nginx-gateway-fabric): Nginx Ingress 的继任者
- [eks-external-snat](eks-external-snat): eks-external-snat
- [nginx-ingress-controller](nginx-ingress-controller): nginx-ingress-controller
- [EFS CSI on EKS](efs-csi): 使用 EFS 作为 Pod 持久化存储
- [eks-addons-kube-proxy](eks-addons-kube-proxy): eks-addons-kube-proxy
- [eks-addons-coredns](eks-addons-coredns): eks-addons-coredns
- [eks-addons-vpc-cni](eks-addons-vpc-cni): eks-addons-vpc-cni
- [karpenter](karpenter): 使用 Karpenter 代替 Cluster Autoscaler
- [nginx-ingress-controller-community-ver](nginx-ingress-controller-community-ver): 使用 nginx ingress
- [Kyverno](kyverno): Kyverno
- [prometheus-adapter](prometheus-adapter): 
- [Metrics Server](metrics-server): EKS 集群中用于弹性扩展使用的指标服务
- [kube-state-metrics](kube-state-metrics): EKS 集群中用于性能监控使用的指标服务
- [cluster-autoscaler](cluster-autoscaler): EKS 集群中安装 Cluster Autoscaler
- [nginx-ingress-controller-nginx-ver](nginx-ingress-controller-nginx-ver): nginx-ingress-controller-nginx-ver
- [aws-for-fluent-bit](aws-for-fluent-bit): 
- [pluto](pluto): Kubernetes 升级小工具
- [kube-no-trouble](kube-no-trouble): Kubernetes 升级小工具
- [eksup](eksup): EKS 升级小工具
- [cni-metrics-helper](cni-metrics-helper): cni-metrics-helper
<-->

## 2 ECS

```expander
(file:.md path:git/git-mkdocs/EKS/ecs) 
- [$frontmatter:title]($filename): $frontmatter:description
```
- [poc-container-on-domainless-windows-in-ecs](poc-container-on-domainless-windows-node-in-ecs): 
- [ecs-windows-gmsa](ecs-windows-gmsa): 
- [Windows Authentication with gMSA for .NET Linux Containers in Amazon ECS](ws-gmsa-linux-containers-ecs): 
- [Migrating .NET Classic Applications to Amazon ECS Using Windows Containers](blog-migrating-net-classic-applications-to-amazon-ecs-using-windows-containers): 
<-->

## 3 ECR

```expander
(file:.md path:git/git-mkdocs/EKS/ecr) 
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Mutating Webhook for Kubernetes in China](mutating-webhook-for-k8s-in-china): 中国区域 k8s 集群 webhook ，自动修改海外镜像到国内地址
- [aws-signer](aws-signer): 
- [Enable scan on push in ECR and send notification to SNS](ecr-scan-on-push-notification-sns): 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
<-->


