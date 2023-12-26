---
last_modified: 2023-12-15
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
- [[create-standard-vpc-for-lab-in-china-region]]: 创建实验环境所需要的 vpc ，并且支持直接 attach 到 tgw 方便网络访问
- [[quick-setup-cloud9-script]]: 简化运行脚本
- [[setup-cloud9-for-eks]]: 使用 cloud9 作为实验环境
<-->

### 2.2 eks
refer: [[EKS/index]]

```expander
(path:git/git-mkdocs/eks file:.md)
- [[$filename]]: $frontmatter:description
```
- [[appmesh-workshop-eks]]: appmesh workshop
- [[argocd-lab]]: argocd
- [[automated-canary-deployment-using-flagger]]: 自动化 canary 部署
- [[aws-for-fluent-bit]]: 
- [[aws-load-balancer-controller]]: 使用 aws 负载均衡控制器
- [[cert-manager]]: cert-manager
- [[cloudwatch-to-firehose-python]]: 在 firehose 上，处理从 cloudwatch 发送来的日志
- [[cluster-autoscaler]]: EKS 集群中安装 Cluster Autoscaler
- [[cni-metrics-helper]]: cni-metrics-helper
- [[ebs-for-eks]]: 使用 ebs 作为 pod 持久化存储 
- [[efs-for-eks]]: 使用 efs 作为 pod 持久化存储
- [[eks-addons-coredns]]: eks-addons-coredns
- [[eks-addons-kube-proxy]]: eks-addons-kube-proxy
- [[eks-addons-vpc-cni]]: eks-addons-vpc-cni
- [[eks-cluster-addons-list]]: EKS 常用插件清单
- [[eks-cluster-with-terraform]]: 使用 Terraform 创建 EKS 集群
- [[eks-container-insights]]: 启用 EKS 的 container insight 功能
- [[eks-custom-network]]: custom network 可以解决子网地址段耗尽的问题
- [[eks-fargate-lab]]: 在 eks 集群中使用 fargate
- [[eks-private-access-cluster]]: 在已有 vpc 中创建私有访问的 eks 集群
- [[eks-public-access-cluster]]: 创建公有访问的 eks 集群
- [[eks-public-access-cluster-in-china-region]]: 在中国区域，创建共有访问的 eks 集群
- [[eks-upgrade-procedure]]: eks 集群升级
- [[eksup]]: eksup
- [[enable-prometheus-in-cloudwatch]]: 将 EKS 集群的 prometheus 数据汇总到 cloudwatch
- [[enable-sg-on-pod]]: 启用 pod 安全组
- [[export-cloudwatch-log-group-to-s3]]: 导出 cloudwatch 日志到 s3
- [[externaldns-for-route53]]: 使用 externaldns 组件
- [[flux-lab]]: flux
- [[install-grafana-on-beanstalk]]: 在 EC2 / beanstalk / EKS 上安装 grafana 
- [[install-prometheus-grafana]]: 安装 grafana 和 prometheus
- [[k8s-hpa-horizontal-pod-autoscaler]]: horizontal pod autoscaler
- [[k8s-topology-spread-constraints]]: topology spread constraints
- [[karpenter-lab]]: 使用 Karpenter 代替 Cluster Autoscaler
- [[kube-no-trouble]]: kube-no-trouble
- [[kube-state-metrics]]: kube-state-metrics
- [[metrics-server]]: EKS 集群中安装 metrics server
- [[nginx-ingress-controller]]: nginx-ingress-controller
- [[nginx-ingress-controller-community-ver]]: 使用 nginx ingress
- [[nginx-ingress-controller-nginx-ver]]: nginx-ingress-controller-nginx-ver
- [[pluto]]: pluto
- [[POC-loki-for-logging]]: 使用 loki 收集日志
- [[POC-prometheus-ha-architect-with-thanos]]: Prometheus是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于HTTP的pull模式采集时序数据，提供功能强大的查询语言PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。当集群数量较多，监控平台高可用性和可靠性要求高，希望提供全局查询，需要长时间保存历史监控数据等场景下，通常使用 Thanos 扩展 Promethseus 监控架构。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制，具体来说，Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询和数据备份等方面的扩展性挑战。
- [[self-signed-certificates]]: 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
- [[stream-k8s-control-panel-logs-to-s3]]: 目前eks控制平面日志只支持发送到cloudwatch，且在同一个log group中有5种类型6种前缀的log stream的日志，不利于统一查询。且只有audit日志是json格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
<-->

### 2.3 database and data analytics
```expander
(file:.md (path:git/git-mkdocs/data-analytics))
- [[$filename]]: $frontmatter:description
```
- [[mwaa-lab]]: 在中国区使用 mwaa 服务
- [[rds-mysql-replica-cross-region-cross-account]]: 用于 1) 跨账号复制 RDS 数据库; 2) 或者将数据库转换成加密存储
- [[redshift-data-api-lab]]: Amazon Redshift 数据 API 使您能够使用所有类型的传统、云原生和容器化、基于 Web 服务的无服务器应用程序和事件驱动的应用程序轻松访问来自 Amazon Redshift 的数据
<-->

### 2.4 serverless
```expander
(file:.md (path:git/git-mkdocs/serverless))
- [[$filename]]: $frontmatter:description
```
- [[apigw-cross-account-private-endpoint]]: 跨账号访问私有api
- [[apigw-custom-domain-name]]: 为私有 api 创建定制域名
- [[apigw-get-sourceip]]: 获取客户端源地址
- [[apigw-private-api-alb-cdk]]: 通过 alb 访问 private api 的例子
- [[apigw-regional-api-access-from-vpc]]: apigw-regional-api-access-from-vpc
<-->

### 2.5 others
```expander
(file:.md (path:git/git-mkdocs/others ))
- [[$filename]]: $frontmatter:description
```
- [[cross-region-reverse-proxy-with-nlb-cloudfront]]: 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- [[ecr-scan-on-push-notification-sns]]: 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- [[file-storage-gateway-lab]]: create file storage gateway from cli
- [[github-page-howto]]: github-page-howto
- [[global-sso-and-china-aws-accounts]]: 使用 global sso 登录中国区域 aws 账号
- [[lab-create-cloudwatch-dashboard-cpu-metric]]: 快速创建 cloudwatch dashboard
- [[rescue-ec2-instance]]: 恢复 EC2 实例步骤
- [[script-api-resource-method]]: 每个 api 的每个 resource 的每个 method 都需要单独通过命令行启用“tlsConfig/insecureSkipVerification”，通过这个脚本简化工作
- [[script-convert-mp3-to-text]]: script-convert-mp3-to-text
<-->

### 2.6 CLI
```expander
(file:.md (path:git/git-mkdocs/CLI))
- [[$filename]]: $frontmatter:description
```
- [[acm-cmd]]: 常用命令
- [[apigw-cmd]]: api-gateway
- [[assume-tool]]: assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- [[aws-ip-range]]: 
- [[cloud9-cmd]]: cloud9 related commands
- [[cloudformation-cmd]]: 常用命令
- [[cloudwatch-cmd]]: 常用命令
- [[directory-service-cmd]]: 常用命令
- [[docker-cmd]]: 常用命令
- [[ebs-cmd]]: 1/ 转换 gp2 到 gp3 ; 2/ 获取指定 volume 每次 snapshot 占用的 block 数量 ; 3/ 创建两种不同类型的 dlm 策略
- [[ec2-cmd]]: 常用命令
- [[ecr-cmd]]: 常用命令
- [[ecs-cmd]]: 常用命令
- [[efs-cmd]]: 1/ 在默认 vpc 中创建 efs
- [[eksctl]]: 常用命令
- [[eksdemo]]: 使用 eksdemo 快速搭建 eks 集群以及其他所需组件
- [[func-create-sg.sh]]: 
- [[iam-cmd]]: 常用命令
- [[iptables]]: iptables
- [[jq-cmd]]: 常用命令
- [[linux-cmd]]: 常用命令
- [[powershell]]: 常用命令
- [[rds-cmd]]: 常用命令
- [[redshift-cmd]]: 常用命令
- [[route53-cmd]]: 常用命令
- [[s3-cmd]]: 常用命令
- [[sns-cmd]]: 常用命令
- [[sqs-cmd]]: 常用命令
- [[ssm-cmd]]: 常用命令
- [[terraform-cmd]]: 
- [[vpc-cmd]]: 常用命令
<-->

## 3 my blog
- https://github.com/panlm/blog-private-api-gateway-dataflow




