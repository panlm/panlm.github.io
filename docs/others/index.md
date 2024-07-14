---
last_modified: 2024-01-13
number headings: first-level 2, max 3, 1.1, auto
---

# Others

## 1 network
```expander
(path:git/git-mkdocs/others/network file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [aws-nfw-network-firewall](aws-nfw-network-firewall): 
- [Cross Region Reverse Proxy with NLB and Cloudfront](cross-region-reverse-proxy-with-nlb-cloudfront): 跨区域的 Layer 4 反向代理，并使用 nlb + cloudfront，考察证书使用需求
<-->

## 2 well-architected
```expander
(path:git/git-mkdocs/others/well-architected file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [WA-卓越运营-Operational-Excellence-202310-Summary](WA-卓越运营-Operational-Excellence-202310-Summary): 
- [WA-可持续性-Sustainability-202310-Summary](WA-可持续发展-Sustainability-202310-Summary): 
- [WA-可靠性-Reliability-202310-Summary](WA-可靠性-Reliability-202310-Summary): 
- [WA-安全-Security-202310-Summary](WA-安全-Security-202310-Summary): 
- [WA-性能效率-Performance-Efficiency-202310-Summary](WA-性能效率-Performance-Efficiency-202310-Summary): 
- [WA-成本优化-Cost-Optimization-202310-Summary](WA-成本优化-Cost-Optimization-202310-Summary): 
<-->

## 3 others
```expander
(file:.md path:git/git-mkdocs/others -path:git/git-mkdocs/others/windows -path:git/git-mkdocs/others/network -path:git/git-mkdocs/others/well-architected)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Storage File Gateway](file-storage-gateway-lab): create file storage gateway from cli
- [github-page-howto](github-page-howto): github-page-howto
- [Using Global SSO to Login China AWS Accounts](global-sso-and-china-aws-accounts): 使用 global sso 登录中国区域 aws 账号
- [create-dashboard-for-instance-cpu-matrics](lab-create-cloudwatch-dashboard-cpu-metric): 快速创建 cloudwatch dashboard
- [obsidian-help](obsidian): obsidian 使用点滴
- [Migrating Filezilla to AWS Transfer Family](POC-mig-filezilla-to-transfer-family): 迁移 Filezilla 到 Transfer Family
- [Prometheus With Thanos Manually](POC-prometheus-ha-architect-with-thanos-manually): POC-prometheus-with-thanos-manually
- [Quick Deploy BRConnector using Cloudformation](quick-build-brconnector.md): 使用 Cloudformation 快速部署 BRConnector
- [Rescue EC2 Instance](rescue-ec2-instance): 恢复 EC2 实例步骤
- [script-api-resource-method](script-api-resource-method): 每个 api 的每个 resource 的每个 method 都需要单独通过命令行启用“tlsConfig/insecureSkipVerification”，通过这个脚本简化工作
- [script-convert-mp3-to-text](script-convert-mp3-to-text): script-convert-mp3-to-text
- [self-signed-certificates](self-signed-certificates): 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
<-->


```dataview
LIST
FROM ("git/git-mkdocs/others") 
and  (!"git/git-mkdocs/others/network") 
and  (!"git/git-mkdocs/others/well-architected") 
and  (!"git/git-mkdocs/others/windows")
```




