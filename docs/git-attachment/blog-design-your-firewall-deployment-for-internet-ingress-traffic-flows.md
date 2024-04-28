---
title: Design your firewall deployment for Internet ingress traffic flows
description: 
created: 2022-05-26 07:45:20.570
last_modified: 2024-03-17
tags:
  - aws/network/nfw
  - aws/network/gwlb
  - aws/security/waf
  - aws/network/elb
---

# Design your firewall deployment for Internet ingress traffic flows

https://aws.amazon.com/cn/blogs/networking-and-content-delivery/design-your-firewall-deployment-for-internet-ingress-traffic-flows/

Exposing Internet-facing applications requires careful consideration of what security controls are needed to protect against external threats and unwanted access. These security controls can vary depending on the type of application, size of the environment, operational constraints, or required inspection depth. For some scenarios, running Network Access Control Lists (NACL) and Security Groups (SG) can provide sufficient protection, and for others, additional firewall components might be required.

Going beyond NACLs and SGs, you can deploy [AWS Web Application Firewall](https://aws.amazon.com/waf/) (AWS WAF) or even bring third-party security appliances into your AWS network. The addition of new services like [AWS Network Firewall](https://aws.amazon.com/network-firewall/) and [AWS Gateway Load Balancer](https://aws.amazon.com/elasticloadbalancing/gateway-load-balancer/) has created even more flexibility in designing your firewall architectures on AWS.

We covered the various architecture options for each service in the following past blog posts: [Network Firewall Deployments Models](https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall-with-vpc-routing-enhancements/), [Centralized Inspection Architectures with AWS Gateway Load Balancers](https://aws.amazon.com/blogs/networking-and-content-delivery/centralized-inspection-architecture-with-aws-gateway-load-balancer-and-aws-transit-gateway/), [Defense-in-depth with AWS WAF](https://aws.amazon.com/blogs/security/defense-in-depth-using-aws-managed-rules-for-aws-waf-part-1/). We’ve also published a [white paper](https://docs.aws.amazon.com/whitepapers/latest/aws-best-practices-ddos-resiliency/aws-best-practices-ddos-resiliency.pdf) covering best practices for DDoS resiliency.

In this blog post, I share network architectures for these various firewalling options to protect inbound traffic to your internet-facing applications. The post is focusing on the ingress flow from Internet (i.e., Internet to VPC) as it requires the most consideration and the related network deployment options can vary significantly depending on the requirements. Egress flow (i.e. VPC to the Internet) and East/West (i.e. VPC to VPC or VPC to on-premises) inspection patterns are well established and covered in-depth in the previous blog posts linked above.

## Architectures for distributed deployment (Orange)

分布式入口架构依赖于每个 VPC 通过专用 Internet 网关 (IGW) 拥有自己的进出 Internet 的路径。这意味着无论您拥有一个还是多个 VPC，每个 VPC 的入口流量的数据路径看起来都相同。这种方法使管理更容易、爆炸半径减小并简化了故障排除。

分配你的入口流量并不意味着你也需要分配你的出口流量。您可以独立处理这些流。通过弹性负载均衡（特别是网络、经典和应用程序负载均衡器）进入您的环境的流量将始终通过该负载均衡器返回。从 VPC 到 Internet 的流量可以遵循单独的路径。

以下部分将介绍各种防火墙解决方案的分布式架构——本地和第三方。它们还将涵盖选项之间的主要区别，例如如何将流量引入防火墙服务、如何跨多个 VPC 扩展以及源客户端 IP 地址的可见性。每个架构都显示了从 Internet 到 VPC 中托管的应用程序的流量。

## Architectures for centralized deployment (Blue)

在您无法使用分布式架构的场景中（例如，您的策略不允许在应用程序 VPC 上使用 IGW），您可以探索集中式架构。请注意，通过创建集中式流程，您会使架构更加复杂并增加爆炸半径（即，集中式 ELB 上的错误配置可能会影响多个后端应用程序）。

进入您的 AWS 网络的所有流量都来自在此模型中托管您的安全堆栈的边缘 VPC。从那里，它通过 Transit Gateway 或 PrivateLink 转发到另一个 VPC 中的目标应用程序。

当 ELB 向另一个 VPC 中的远程目标发送流量时，它必须使用 IP 作为目标类型。 NLB 和 PrivateLink 端点都有静态 IP 地址，可以作为任何 ELB 的目标。

如果您在 ALB 上托管目标应用程序，则其 IP 地址可能会更改。要在 ALB 上获取静态 IP 地址，您必须将其放在 NLB 后面。这篇博文([LINK](https://aws.amazon.com/blogs/networking-and-content-delivery/application-load-balancer-type-target-group-for-network-load-balancer/))详细介绍了该设置。

下面的架构与我在分布式部署部分中已经介绍的相同考虑因素一致。他们扩展了之前的部署，展示了如果设置是集中式的，来自 Internet 的流量将如何流动。

请注意，使用 Transit Gateway 或 PrivateLink 模型之间会有性能和扩展性差异。请参阅特定于服务的文档以了解您正在考虑的每项服务的配额。

## AWS WAF
distributed 
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-1.png]]

centralized
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-2.png]]

## AWS Network Firewall
distributed 
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-3.png]]

centralized
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-4.png]]

## Gateway Load Balancer
distributed 
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-5.png]]

centralized
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-6.png]]

## ELB sandwich
distributed 
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-7.png]]
The client IP preservation depends on the type of internet-facing ELB you use. NLB can preserve the client IP. [This document](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation) goes into detail on what’s required to achieve that. In the case of ALB, it doesn’t preserve the client IP in the packet. The ALB adds it to an X-Forwarded-For HTTP header.

centralized
![[blog-design-your-firewall-deployment-for-internet-ingress-traffic-flows-png-8.png]]




