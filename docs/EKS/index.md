---
last_modified: 2024-01-13
number headings: first-level 2, max 3, 1.1, auto
---

# EKS
## 1 cluster 
```expander
(path:git/git-mkdocs/eks/cluster file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [EKS Addons](eks-cluster-addons-list): EKS 常用插件清单
- [Create EKS Cluster with Terraform](eks-cluster-with-terraform): 使用 Terraform 创建 EKS 集群
- [Create Private Only EKS Cluster](eks-private-access-cluster): 在已有 VPC 中创建私有访问的 EKS 集群
- [Create Public Access EKS Cluster](eks-public-access-cluster): 创建公有访问的 EKS 集群
- [Create Public Access EKS Cluster in China Region](eks-public-access-cluster-in-china-region): 在中国区域，创建共有访问的 EKS 集群
- [EKS Upgrade Procedure](eks-upgrade-procedure): EKS 集群升级
<-->

## 2 kubernetes
```expander
(path:git/git-mkdocs/eks/kubernetes file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [horizontal pod autoscaler](k8s-hpa-horizontal-pod-autoscaler): horizontal pod autoscaler
- [k8s-liveness-readiness-startup-probes](k8s-liveness-readiness-startup-probes): 
- [topology spread constraints](k8s-topology-spread-constraints): topology spread constraints
<-->

## 3 solutions
```expander
( path:git/git-mkdocs/eks/solutions file:.md )
- [$frontmatter:title]($filename): $frontmatter:description
```
- [appmesh-workshop-eks](appmesh-workshop-eks): appmesh workshop
- [argocd](argocd-lab): gitops 工具
- [automated-canary-deployment-using-flagger](automated-canary-deployment-using-flagger): 自动化 canary 部署
- [cloudwatch-to-firehose-python](cloudwatch-to-firehose-python): 在 firehose 上，处理从 cloudwatch 发送来的日志
- [EKS Access API](eks-access-api): eks-access-api
- [eks-audit-log-security-lake](eks-audit-log-security-lake): 
- [eks-aws-auth](eks-aws-auth): EKS aws-auth
- [EKS Container Insights](eks-container-insights): 启用 EKS 的 container insight 功能
- [eks-custom-network](eks-custom-network): 可以解决子网地址段耗尽的问题
- [eks-fargate](eks-fargate-lab): 在 eks 集群中使用 fargate
- [eks-loggroup-description](eks-loggroup-description): eks 日志类型分析
- [eks-prefix-assignment](eks-prefix-assignment): 
- [enable-prometheus-in-cloudwatch](enable-prometheus-in-cloudwatch): 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [enable-sg-on-pod](enable-sg-on-pod): 启用 pod 安全组
- [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3): 导出 cloudwatch 日志到 s3
- [flux](flux-lab): gitops 工具
- [Using Loki for Logging](grafana-loki): 使用 loki 收集日志
- [Install Grafana on Beanstalk](install-grafana-on-beanstalk): 在 EC2 / beanstalk / EKS 上安装 grafana 
- [install-prometheus-grafana-on-eks](install-prometheus-grafana): 安装 grafana 和 prometheus
- [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3): 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [IRSA 中的 Token 剖析](TC-eks-irsa-token-deep-dive-lab): 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- [Building Prometheus HA Architect with Thanos](TC-prometheus-ha-architect-with-thanos): 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
- [EKS Security Group Deepdive](TC-security-group-for-eks-deepdive): 深入 EKS 安全组
<-->

## 4 addons 
```expander
(file:.md path:git/git-mkdocs/eks/addons) 
- [$frontmatter:title]($filename): $frontmatter:description
```
- [aws-for-fluent-bit](aws-for-fluent-bit): 
- [aws-load-balancer-controller](aws-load-balancer-controller): 使用 aws 负载均衡控制器
- [cert-manager](cert-manager): 证书管理插件
- [cluster-autoscaler](cluster-autoscaler): EKS 集群中安装 Cluster Autoscaler
- [cni-metrics-helper](cni-metrics-helper): cni-metrics-helper
- [ebs-for-eks](ebs-for-eks): 使用 ebs 作为 pod 持久化存储 
- [EFS CSI on EKS](efs-csi): 使用 EFS 作为 Pod 持久化存储
- [eks-addons-coredns](eks-addons-coredns): eks-addons-coredns
- [eks-addons-kube-proxy](eks-addons-kube-proxy): eks-addons-kube-proxy
- [eks-addons-vpc-cni](eks-addons-vpc-cni): eks-addons-vpc-cni
- [eksup](eksup): EKS 升级小工具
- [externaldns-for-route53](externaldns-for-route53): 使用 externaldns 组件
- [karpenter](karpenter): 使用 Karpenter 代替 Cluster Autoscaler
- [kube-no-trouble](kube-no-trouble): Kubernetes 升级小工具
- [kube-state-metrics](kube-state-metrics): EKS 集群中用于性能监控使用的指标服务
- [Metrics Server](metrics-server): EKS 集群中用于弹性扩展使用的指标服务
- [nginx-ingress-controller](nginx-ingress-controller): nginx-ingress-controller
- [nginx-ingress-controller-community-ver](nginx-ingress-controller-community-ver): 使用 nginx ingress
- [nginx-ingress-controller-nginx-ver](nginx-ingress-controller-nginx-ver): nginx-ingress-controller-nginx-ver
- [pluto](pluto): Kubernetes 升级小工具
<-->

