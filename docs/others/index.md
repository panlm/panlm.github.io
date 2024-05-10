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

## 3 windows
```expander
(path:git/git-mkdocs/others/windows file:.md)
- [$frontmatter:title]($filename): $frontmatter:description
```
- [Migrating .NET Classic Applications to Amazon ECS Using Windows Containers](blog-migrating-net-classic-applications-to-amazon-ecs-using-windows-containers): 
- [ecs-windows-gmsa](ecs-windows-gmsa): 
- [poc-container-on-domainless-windows-in-ecs](poc-container-on-domainless-windows-node-in-ecs): 
- [Windows Authentication with gMSA for .NET Linux Containers in Amazon ECS](ws-gmsa-linux-containers-ecs): 
<-->

## 4 others

```expander
(path:git/git-mkdocs/others) AND (NOT "git/git-mkdocs/others/well-architected") 
- [$frontmatter:title]($filename): $frontmatter:description
```
<-->
```dataview
LIST
FROM ("git/git-mkdocs/others") 
and  (!"git/git-mkdocs/others/network") 
and  (!"git/git-mkdocs/others/well-architected") 
and  (!"git/git-mkdocs/others/windows")
```




