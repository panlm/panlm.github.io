---
title: Welcome
last_modified: 2024-03-30
number headings: first-level 2, max 3, 1.1, auto
---

# Welcome to panlm docs
## 1 start from
- [[cloud9/quick-setup-cloud9|Quick Setup Cloud9]] -- 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化

## 2 highlights
```expander
(["status":"myblog"] OR ["status":"awsblog"])
- [$frontmatter:title]($filename) -- $frontmatter:description
```
- [Datahub](datahub) -- 部署 Datahub，从 Redshift 和 Glue job 中获取数据血缘
- [Quick Deploy BRConnector using Cloudformation](quick-build-brconnector) -- 使用 Cloudformation 快速部署 BRConnector
- [Enable Quicksight with Identity Center](enable-quicksight-with-identity-center) -- 中国区域启用 Quicksight 并且集成 Microsoft Entra
- [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts) -- 使用 global sso 登录中国区域 aws 账号
- [Cross Region Reverse Proxy with NLB and Cloudfront](cross-region-reverse-proxy-with-nlb-cloudfront) -- 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- [Migrating Filezilla to AWS Transfer Family](POC-mig-filezilla-to-transfer-family) -- 迁移 Filezilla 到 Transfer Family
- [Enable scan on push in ECR and send notification to SNS](ecr-scan-on-push-notification-sns) -- 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- [Create Standard VPC for Lab in China Region or Global Region](create-standard-vpc-for-lab-in-china-region) -- 创建实验环境所需要的 VPC ，并且支持直接 attach 到 TGW 方便网络访问
- [IRSA 中的 Token 剖析](TC-eks-irsa-token-deep-dive-lab) -- 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- [EKS Security Group Deepdive](TC-security-group-for-eks-deepdive) -- 深入 EKS 安全组
- [Using Grafana Loki for Logging](grafana-loki) -- 使用 Loki 收集日志
- [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3) -- 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3) -- 导出 cloudwatch 日志到 s3
- [Create Public Access EKS Cluster](eks-public-access-cluster) -- 创建公有访问的 EKS 集群
- [Security Lake Support Collecting Audit Logging from EKS](eks-audit-log-security-lake) -- 
- [Quick Setup Cloud9](quick-setup-cloud9) -- 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
- [Setup Cloud9 for EKS](setup-cloud9-for-eks) -- 使用脚本完成实验环境初始化
- [assume](granted-assume) -- assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- [openswan-s2svpn-tgw-lab](openswan-s2svpn-tgw) -- connect to global site-2-site vpn service
- [Obsidian Tips](obsidian) -- obsidian 使用点滴
<-->

## 3 my aws blogs
- https://github.com/panlm/blog-private-api-gateway-dataflow
- https://aws.amazon.com/cn/blogs/china/extending-the-prometheus-high-availability-monitoring-architecture-using-thanos/

## 4 deprecated docs
```expander
(["status":"deprecated"])
- [$frontmatter:title]($filename) -- $frontmatter:description
```
- [appmesh-workshop-eks](appmesh-workshop-eks) -- appmesh workshop
- [Prometheus With Thanos Manually](others/POC-prometheus-ha-architect-with-thanos-manually.md) -- POC-prometheus-with-thanos-manually
- [script-api-resource-method](script-api-resource-method) -- 每个 api 的每个 resource 的每个 method 都需要单独通过命令行启用“tlsConfig/insecureSkipVerification”，通过这个脚本简化工作
- [Building Prometheus HA Architect with Thanos](EKS/solutions/monitor/TC-prometheus-ha-architect-with-thanos.zh.md) -- 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
<-->

## 5 rendered

{{ pagetree }}





