---
title: ws-aws-network-firewall-for-ingress-egress-traffic
description: 
created: 2024-03-16 22:34:51.200
last_modified: 2024-03-17
tags:
  - aws/network/nfw
---

# ws-aws-network-firewall-for-ingress-egress-traffic

## H1

https://catalog.us-east-1.prod.workshops.aws/workshops/c26b637d-e9e7-41d7-887d-fffc5d18c32f/en-US/00-overview/module4

## lab 1
**[Experiment Environment-1](https://catalog.us-east-1.prod.workshops.aws/workshops/c26b637d-e9e7-41d7-887d-fffc5d18c32f/en-US/01-option1)** is the most basic configuration, and as shown in the configuration diagram below, the Gateway Load Balancer Endpoint is located on top of the Public Subnet to simultaneously process Ingress/Egress traffic in the basic service configuration. practice proceeds.

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-1.png]]

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-2.png]]

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-3.png]]

## lab 2
**[Exercise Environment-2](https://catalog.us-east-1.prod.workshops.aws/workshops/c26b637d-e9e7-41d7-887d-fffc5d18c32f/en-US/02-option2)** is configured to handle each Gateway Load Balancer Endpoint for handling ingress traffic and Gateway Load Balancer Endpoint for handling egress traffic. The main purpose of separating and configuring GWLBE (AWS Network Firewall) for ingress and GWLBE (AWS Network Firewall) for egress is to provide fine-grained control over EC2 instances accessing the Internet via the NAT Gateway in the private subnet from AWS Network Firewall. This is to enable you to do it.

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-4.png]]

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-5.png]]

![[../../git-attachment/ws-aws-network-firewall-for-ingress-egress-traffic-png-6.png]]



