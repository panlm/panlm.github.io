---
last_modified: 2023-12-31
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
- [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts): 使用 global sso 登录中国区域 aws 账号
- [Building Prometheus HA Architect with Thanos](POC-prometheus-ha-architect-with-thanos): Prometheus是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于HTTP的pull模式采集时序数据，提供功能强大的查询语言PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。当集群数量较多，监控平台高可用性和可靠性要求高，希望提供全局查询，需要长时间保存历史监控数据等场景下，通常使用 Thanos 扩展 Promethseus 监控架构。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制，具体来说，Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询和数据备份等方面的扩展性挑战。
<-->

## 3 my blog
- https://github.com/panlm/blog-private-api-gateway-dataflow

## 4 rendered

{{ pagetree }}

