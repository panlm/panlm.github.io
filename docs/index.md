---
last_modified: 2024-03-30
number headings: first-level 2, max 3, 1.1, auto
---

# Welcome to panlm docs

## 1 start from
- [[cloud9/quick-setup-cloud9|quick-setup-cloud9]]

## 2 highlights
```expander
(["status":"myblog"] OR ["status":"awsblog"])
- [$frontmatter:title]($filename): $frontmatter:description
```
- [assume](assume-tool): assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- [Cross Region Reverse Proxy with NLB and Cloudfront](others/network/cross-region-reverse-proxy-with-nlb-cloudfront.md): 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- [Enable scan on push in ECR and send notification to SNS](EKS/ecr/ecr-scan-on-push-notification-sns.md): 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- [eks-audit-log-security-lake](eks-audit-log-security-lake): 
- [Create Public Access EKS Cluster](eks-public-access-cluster): 创建公有访问的 EKS 集群
- [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3): 导出 cloudwatch 日志到 s3
- [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts): 使用 global sso 登录中国区域 aws 账号
- [Migrating Filezilla to AWS Transfer Family](POC-mig-filezilla-to-transfer-family): 迁移 Filezilla 到 Transfer Family
- [Prometheus With Thanos Manually](POC-prometheus-ha-architect-with-thanos-manually): POC-prometheus-with-thanos-manually
- [Quick Setup Cloud9](quick-setup-cloud9): 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
- [Setup Cloud9 for EKS](setup-cloud9-for-eks): 使用脚本完成实验环境初始化
- [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3): 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- [IRSA 中的 Token 剖析](TC-eks-irsa-token-deep-dive-lab): 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- [EKS Security Group Deepdive](TC-security-group-for-eks-deepdive): 深入 EKS 安全组
<-->

## 3 my aws blogs
- https://github.com/panlm/blog-private-api-gateway-dataflow
- https://aws.amazon.com/cn/blogs/china/extending-the-prometheus-high-availability-monitoring-architecture-using-thanos/


## 4 rendered

{{ pagetree }}





