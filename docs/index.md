---
last_modified: 2023-11-18
number headings: first-level 2, max 3, 1.1, auto
---

# Welcome to panlm docs

## 1 start from
- [[cloud9/quick-setup-cloud9-script|quick-setup-cloud9-script]]


## 2 topics 
### 2.1 cloud9
```expander
(path:git/git-mkdocs/cloud9 file:.md)
- [[$filename]]: $frontmatter:description
```
- [[quick-setup-cloud9-script]]: 简化运行脚本
- [[setup-cloud9-for-eks]]: 使用 cloud9 作为实验环境
- [[create-standard-vpc-for-lab-in-china-region]]: 创建实验环境所需要的 vpc ，并且支持直接 attach 到 tgw 方便网络访问
<-->

### 2.2 eks
refer: [[EKS/index]]

```expander
(path:git/git-mkdocs/eks file:.md)
- [[$filename]]: $frontmatter:description
```
- [[POC-prometheus-ha-architect-with-thanos]]: 用 thanos 扩展 prometheus 高可用性架构
- [[automated-canary-deployment-using-flagger]]: 自动化 canary 部署
- [[install-prometheus-grafana]]: 安装 grafana 和 prometheus
- [[eks-terraform-cluster]]: 使用 terraform 创建 eks 集群
- [[externaldns-for-route53]]: 使用 externaldns 组件
- [[cloudwatch-to-firehose-python]]: 在 firehose 上，处理从 cloudwatch 发送来的日志
- [[export-cloudwatch-log-group-to-s3]]: 导出 cloudwatch 日志到 s3
- [[stream-k8s-control-panel-logs-to-s3]]: 目前eks控制平面日志只支持发送到cloudwatch，且在同一个log group中有5种类型6种前缀的log stream的日志，不利于统一查询。且只有audit日志是json格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [[flux-lab]]: flux
- [[argocd-lab]]: argocd
- [[efs-for-eks]]: 使用 efs 作为 pod 持久化存储
- [[karpenter-lab]]: 使用 Karpenter 代替 Cluster Autoscaler
- [[cert-manager]]: cert-manager
- [[eks-private-access-cluster]]: 在已有 vpc 中创建私有访问的 eks 集群
- [[ebs-for-eks]]: 使用 ebs 作为 pod 持久化存储 
- [[aws-load-balancer-controller]]: 使用 aws 负载均衡控制器
- [[eks-public-access-cluster-in-china-region]]: 在中国区域，创建共有访问的 eks 集群
- [[eks-public-access-cluster]]: 创建公有访问的 eks 集群
- [[kube-no-trouble]]: kube-no-trouble
- [[kube-state-metrics]]: kube-state-metrics
- [[metrics-server]]: EKS 集群中安装 metrics server
- [[cluster-autoscaler]]: EKS 集群中安装 Cluster Autoscaler
- [[enable-prometheus-in-cloudwatch]]: 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [[eks-container-insights]]: 启用 EKS 的 container insight 功能
- [[install-grafana-lab]]: 在 EC2 / beanstalk / EKS 上安装 grafana 
- [[eks-cluster-addons-list]]: EKS 常用插件清单
- [[nginx-ingress-controller-community-ver]]: 使用 nginx ingress
- [[nginx-ingress-controller]]: nginx-ingress-controller
- [[eks-custom-network]]: custom network 可以解决子网地址段耗尽的问题
- [[eks-upgrade-procedure]]: eks 集群升级
- [[appmesh-workshop-eks]]: appmesh workshop
- [[aws-for-fluent-bit]]: 
- [[eks-addons-coredns]]: eks-addons-coredns
- [[eks-addons-kube-proxy]]: eks-addons-kube-proxy
- [[eks-addons-vpc-cni]]: eks-addons-vpc-cni
- [[self-signed-certificates]]: 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
- [[enable-sg-on-pod]]: 启用 pod 安全组
<-->

### 2.3 database and data analytics
```expander
(file:.md (path:git/git-mkdocs/data-analytics))
- [[$filename]]: $frontmatter:description
```
- [[redshift-data-api-lab]]: Amazon Redshift 数据 API 使您能够使用所有类型的传统、云原生和容器化、基于 Web 服务的无服务器应用程序和事件驱动的应用程序轻松访问来自 Amazon Redshift 的数据
- [[mwaa-lab]]: 在中国区使用 mwaa 服务
- [[rds-mysql-replica-cross-region-cross-account]]: 用于 1) 跨账号复制 RDS 数据库; 2) 或者将数据库转换成加密存储
<-->

### 2.4 serverless
```expander
(file:.md (path:git/git-mkdocs/serverless))
- [[$filename]]: $frontmatter:description
```
- [[apigw-cross-account-private-endpoint]]: 跨账号访问私有api
- [[apigw-private-api-alb-cdk]]: 通过 alb 访问 private api 的例子
- [[apigw-regional-api-access-from-vpc]]: apigw-regional-api-access-from-vpc
- [[apigw-get-sourceip]]: 获取客户端源地址
- [[apigw-custom-domain-name]]: 为私有 api 创建定制域名
<-->

### 2.5 others
```expander
(file:.md -file:tags.md (path:git/git-mkdocs -path:git/git-mkdocs/eks -path:git/git-mkdocs/cloud9 -path:git/git-mkdocs/serverless -path:git/git-mkdocs/data-analytics ))
- [[$filename]]: $frontmatter:description
```
- [[jq-cmd]]: 常用命令
- [[ebs-cmd]]: 1/ 转换 gp2 到 gp3 ; 2/ 获取指定 volume 每次 snapshot 占用的 block 数量 ; 3/ 创建两种不同类型的 dlm 策略
- [[ecs-cmd]]: 常用命令
- [[linux-cmd]]: 常用命令
- [[eksctl]]: 常用命令
- [[route53-cmd]]: 常用命令
- [[assume-tool]]: assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- [[docker-cmd]]: 常用命令
- [[iam-cmd]]: 常用命令
- [[acm-cmd]]: 常用命令
- [[cross-region-reverse-proxy-with-nlb-cloudfront]]: 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- [[github-page-howto]]: github-page-howto
- [[efs-cmd]]: 1/ 在默认 vpc 中创建 efs
- [[s3-cmd]]: 常用命令
- [[ecr-cmd]]: 常用命令
- [[eksdemo]]: 使用 eksdemo 快速搭建 eks 集群以及其他所需组件
- [[cloud9-cmd]]: cloud9 related commands
- [[redshift-cmd]]: 常用命令
- [[cloudwatch-cmd]]: 常用命令
- [[iptables]]: iptables
- [[lab-create-cloudwatch-dashboard-cpu-metric]]: 快速创建 cloudwatch dashboard
- [[rescue-ec2-instance]]: 
<-->

## 3 my blog
- https://github.com/panlm/blog-private-api-gateway-dataflow




