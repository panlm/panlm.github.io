---
title: aws-nfw-network-firewall
description: AWS Network Firewall
created: 2023-07-22 10:07:37.041
last_modified: 2024-04-19
tags:
  - aws/network/nfw
---
# AWS Network Firewall

## stateless-vs-stateful-
AWS Network Firewall支持有状态的规则（最大规则组容量50,000），也支持无状态的规则（最大规则组容量10,000）
- 无状态规则优先于有状态规则执行，且按配置的顺序执行，支持pass，drop和forward到有状态的规则三种处理方式；
- 假如无状态规则配置有冲突，按优先级匹配执行；
- 有状态的规则如果有冲突
    - Action Order：（例如某个规则设置了允许ssh，另外一个规则设置了禁止ssh），它是合并后再统一匹配执行，优先级为pass > drop > alert，所以只要有一个pass的设置，其他的非pass设置全部会失效，所以我们在设置规则时要明确具体。
    - 推荐 Strict order，按顺序执行

![[../../git-attachment/aws-nfw-network-firewall-png-1.png|500]]

- https://docs.aws.amazon.com/network-firewall/latest/developerguide/firewall-rules-engines.html
- https://aws.amazon.com/cn/blogs/china/effective-protection-of-ns-resources-and-services-through-aws-network-firewall/


## available in china
- from  2024/2
    - https://www.amazonaws.cn/en/new/2024/amazon-network-firewall-is-available-in-amazon-web-services-china-regions/
- increase to 50k stateful rules
    - https://www.amazonaws.cn/new/2024/amazon-network-firewall-increases-quota-for-stateful-rules/


## workshop
- [[../../../../ws-aws-network-firewall-workshop]] 
- [[../../../../ws-hands-on-network-firewall-workshop]] 
- [[../../../../ws-aws-network-firewall-for-ingress-egress-traffic]] 
- [[../../../../ws-approaches-to-layered-security-for-amazon-vpc]] 


## blog
- https://aws.amazon.com/cn/blogs/security/how-to-deploy-aws-network-firewall-to-help-protect-your-network-from-malware/
- [[../../git-attachment/blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows|blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows]] 
- [[../../git-attachment/blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30|blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30]] 
- [[../../git-attachment/blog-deployment-models-for-aws-network-firewall|blog-deployment-models-for-aws-network-firewall]]


## refer
- [[aws-nfw-network-firewall-internal]]


