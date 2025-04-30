---
title: Welcome
last_modified: 2024-03-30
number headings: first-level 2, max 3, 1.1, auto
---

# Welcome to panlm docs
## 1 start from
- [CodeServer](vscode) -- Using code-server on EC2 instead of Cloud9 due to it has been deprecated
- [[cloud9/quick-setup-cloud9|Quick Setup Cloud9]] -- 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化

## 2 highlights
```expander
(["status":"myblog"] OR ["status":"awsblog"])
- ($frontmatter:last_modified) [$frontmatter:title]($filename) -- $frontmatter:description
```
- (2025-05-01) [突破VPC地址限制：EKS混合节点架构实战指南](use-eks-hybrid-node-to-solve-ipaddr-exhausted) -- 一个关于如何使用EKS混合节点功能优雅地解决VPC地址空间不足的真实案例
- (2025-04-21) [MCP Server on EC2](build-mcp-server-on-ec2) -- 将 MCP Server 移动到远端，减少本地资源占用
- (2025-02-20) [deepseek-poc](deepseek-poc) -- Deepseek POC
- (2025-04-16) [Configure SearxNG MCP Server in Cline](searxng-mcp-server-for-cline) -- 在 Cline 中配置 SearxNG MCP Server 实现搜索功能
- (2024-01-08) [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3) -- 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- (2024-01-01) [Obsidian Tips](obsidian) -- obsidian 使用点滴
- (2024-09-19) [CodeServer](vscode) -- Using code-server on EC2 instead of Cloud9 due to it has been deprecated
- (2024-06-28) [Enable Quicksight with Identity Center](enable-quicksight-with-identity-center) -- 中国区域启用 Quicksight 并且集成 Microsoft Entra
- (2025-01-02) [AWS Opensearch / Elasticsearch Migration](aos-migration) -- 使用 snapshot 迁移 elasticsearch
- (2024-07-18) [Using Grafana Loki for Logging](grafana-loki) -- 使用 Loki 收集日志
- (2024-02-12) [assume](granted-assume) -- assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- (2024-08-19) [openswan-s2svpn-tgw-lab](openswan-s2svpn-tgw) -- connect to global aws using site-2-site vpn service, for example access global bedrock service
- (2024-02-04) [Cross Region Reverse Proxy with NLB and Cloudfront](cross-region-reverse-proxy-with-nlb-cloudfront) -- 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- (2024-07-09) [Quick Deploy BRConnector using Cloudformation](quick-build-brconnector) -- 使用 Cloudformation 快速部署 BRConnector
- (2024-08-05) [Datahub](datahub) -- 部署 Datahub，从 Redshift 和 Glue job 中获取数据血缘
- (2023-11-22) [Mutating Webhook for Kubernetes in China](mutating-webhook-for-k8s-in-china) -- 中国区域 k8s 集群 webhook ，自动修改海外镜像到国内地址
- (2024-05-11) [Security Lake Support Collecting Audit Logging from EKS](eks-audit-log-security-lake) -- 使用 Security Lake 收集 EKS Audit 日志
- (2023-12-31) [Enable scan on push in ECR and send notification to SNS](ecr-scan-on-push-notification-sns) -- 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- (2024-04-02) [Quick Setup Cloud9](quick-setup-cloud9) -- 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
- (2024-03-27) [Create Standard VPC for Lab in China Region or Global Region](create-standard-vpc-for-lab-in-china-region) -- 创建实验环境所需要的 VPC ，并且支持直接 attach 到 TGW 方便网络访问
- (2024-04-04) [Migrating Filezilla to AWS Transfer Family](POC-mig-filezilla-to-transfer-family) -- 迁移 Filezilla 到 Transfer Family
- (2024-02-11) [Setup Cloud9 for EKS](setup-cloud9-for-eks) -- 使用脚本完成实验环境初始化
- (2024-02-25) [EKS Security Group Deepdive](TC-security-group-for-eks-deepdive) -- 深入 EKS 安全组
- (2024-01-21) [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts) -- 使用 global sso 登录中国区域 aws 账号
- (2024-02-18) [IRSA 中的 Token 剖析](TC-eks-irsa-token-deep-dive-lab) -- 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- (2023-12-31) [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3) -- 导出 cloudwatch 日志到 s3
<-->

## 3 my aws blogs
- https://github.com/panlm/blog-private-api-gateway-dataflow
- https://aws.amazon.com/cn/blogs/china/extending-the-prometheus-high-availability-monitoring-architecture-using-thanos/

## 4 deprecated docs
```expander
(["status":"deprecated"])
- [$frontmatter:title]($filename) -- $frontmatter:description
```
- [script-api-resource-method](script-api-resource-method) -- 每个 api 的每个 resource 的每个 method 都需要单独通过命令行启用“tlsConfig/insecureSkipVerification”，通过这个脚本简化工作
- [Building Prometheus HA Architect with Thanos](TC-prometheus-ha-architect-with-thanos.zh) -- 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
- [Prometheus With Thanos Manually](POC-prometheus-ha-architect-with-thanos-manually) -- POC-prometheus-with-thanos-manually
- [appmesh-workshop-eks](appmesh-workshop-eks) -- appmesh workshop
<-->

## 5 rendered

{{ pagetree }}


