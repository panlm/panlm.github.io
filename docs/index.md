---
last_modified: 2024-01-04
number headings: first-level 2, max 3, 1.1, auto
---

# Welcome to panlm docs

## 1 start from
- [[cloud9/quick-setup-cloud9-script|quick-setup-cloud9-script]]

## 2 highlights
```expander
(["status":"myblog"])
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Cross Region Reverse Proxy with NLB and Cloudfront](cross-region-reverse-proxy-with-nlb-cloudfront): 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- [Enable scan on push in ECR and send notification to SNS](ecr-scan-on-push-notification-sns): 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- [Export Cloudwatch Log Group to S3](export-cloudwatch-log-group-to-s3): 导出 cloudwatch 日志到 s3
- [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts): 使用 global sso 登录中国区域 aws 账号
- [Building Prometheus HA Architect with Thanos](POC-prometheus-ha-architect-with-thanos): 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
- [quick setup cloud9 script](quick-setup-cloud9-script): 简化运行脚本
- [Setup Cloud9 for EKS](setup-cloud9-for-eks): 使用 cloud9 作为实验环境
- [Stream EKS Control Panel Logs to S3](stream-k8s-control-panel-logs-to-s3): 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
<-->

## 3 my aws blogs
- https://github.com/panlm/blog-private-api-gateway-dataflow

## 4 rendered

{{ pagetree }}

