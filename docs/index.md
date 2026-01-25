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
<%
it.files.sort((a, b) => {
  const dateA = new Date(a.frontmatter?.created || 0);
  const dateB = new Date(b.frontmatter?.created || 0);
  return dateB - dateA;
});
%>
<%= it.files.map(file => {
  const date = (file.frontmatter?.created || '').split(' ')[0];
  return `- (${date}) [[${file.basename}]] -- ${file.frontmatter?.description}`;
}).join('\n') %>
```
- (2026-01-24) [[解决 Target Group 中添加内部服务 IP 时遇到 Unsupported IP 的错误]] -- 使用 AWS PrivateLink 实现 DMZ VPC 到内部 VPC 的安全流量转发
- (2026-01-01) [[rancher]] -- Rancher 安装部署指南
- (2025-12-10) [[k8s-gateway-api]] -- K8S Gateway API 配置说明
- (2025-12-02) [[calico-cni-overlay]] -- Using Calico CNI overlay mode on EKS
- (2025-04-21) [[build-mcp-server-on-ec2]] -- 将 MCP Server 移动到远端，减少本地资源占用
- (2025-04-20) [[use-eks-hybrid-node-to-solve-ipaddr-exhausted]] -- 一个关于如何使用EKS混合节点功能优雅地解决VPC地址空间不足的真实案例
- (2025-04-08) [[searxng-mcp-server-for-cline]] -- 在 Cline 中配置 SearxNG MCP Server 实现搜索功能
- (2025-02-20) [[deepseek-poc]] -- Deepseek POC
- (2024-12-28) [[opensearch-migration]] -- 使用 snapshot 迁移 elasticsearch
- (2024-08-19) [[vscode]] -- Using code-server on EC2 instead of Cloud9 due to it has been deprecated
- (2024-07-31) [[datahub]] -- 部署 Datahub，从 Redshift 和 Glue job 中获取数据血缘
- (2024-06-09) [[quick-build-brconnector]] -- 使用 Cloudformation 快速部署 BRConnector
- (2024-05-28) [[enable-quicksight-with-identity-center]] -- 中国区域启用 Quicksight 并且集成 Microsoft Entra
- (2024-04-26) [[eks-audit-log-security-lake]] -- 使用 Security Lake 收集 EKS Audit 日志
- (2024-01-19) [[openswan-s2svpn-tgw]] -- connect to global aws using site-2-site vpn service, for example access global bedrock service
- (2023-12-18) [[grafana-loki]] -- 使用 Loki 收集日志
- (2023-12-07) [[ecr-scan-on-push-notification-sns]] -- 启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警
- (2023-10-09) [[cross-region-reverse-proxy-with-nlb-cloudfront]] -- 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
- (2023-09-26) [[global-sso-and-china-aws-accounts]] -- 使用 global sso 登录中国区域 aws 账号
- (2023-09-15) [[granted-assume]] -- assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
- (2023-08-04) [[quick-setup-cloud9]] -- 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
- (2023-03-25) [[POC-mig-filezilla-to-transfer-family]] -- 迁移 Filezilla 到 Transfer Family
- (2022-10-24) [[TC-eks-irsa-token-deep-dive-lab]] -- 本文档总结了将 AWS IAM 角色授予 AWS EKS 集群的服务账户的过程
- (2022-10-02) [[stream-k8s-control-panel-logs-to-s3]] -- 目前 EKS 控制平面日志只支持发送到 cloudwatch，且在同一个 log group 中有5种类型6种前缀的 log stream 的日志，不利于统一查询。且只有 audit 日志是 json 格式其他均是单行日志，且字段各不相同。本解决方案提供思路统一保存日志供后续分析处理
- (2022-08-17) [[export-cloudwatch-log-group-to-s3]] -- 导出 cloudwatch 日志到 s3
- (2022-06-23) [[mutating-webhook-for-k8s-in-china]] -- 中国区域 k8s 集群 webhook ，自动修改海外镜像到国内地址
- (2022-05-21) [[setup-cloud9-for-eks]] -- 使用脚本完成实验环境初始化
- (2022-05-17) [[TC-security-group-for-eks-deepdive]] -- 深入 EKS 安全组
- (2022-04-10) [[create-standard-vpc-for-lab-in-china-region]] -- 创建实验环境所需要的 VPC ，并且支持直接 attach 到 TGW 方便网络访问
- () [[obsidian]] -- obsidian 使用点滴
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


