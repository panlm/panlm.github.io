---
title: Design your firewall deployments to protect your internet applications - NIS301
description: 
created: 2023-02-28 18:26:59.089
last_modified: 2024-03-17
tags:
  - aws/network/nfw
  - aws/network/gwlb
  - aws/security/waf
---

# Design your firewall deployments to protect your internet applications - NIS301

- https://www.youtube.com/watch?v=LLuxZDf6vrs
- https://d1.awsstatic.com/events/aws-reinforce-2022/NIS301_Design-your-firewall-deployments-to-protect-your-internet-applications.pdf
- 202403 更新中文版本 [Design_your_firewall_deployments_to_protect_your_internet_applications zh.pptx](file:///Users/panlm/Documents/SA-Baseline-50-12/network/nfw/Design_your_firewall_deployments_to_protect_your_internet_applications%20zh.pptx) 

## [[NIST cybersecurity framework]] 

![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-1.png]]

![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-2.png]]

## foundational constructs

18
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-3.png]]

22
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-4.png]]

23 - *ingress routing* is prefer
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-5.png]]

27
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-6.png]]

## design considerations

![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-7.png]]
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-8.png]]

## architectures

### waf

40
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-9.png]]

43
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-10.png]]

### gwlb

50/52
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-11.png]]

56
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-12.png]]

59
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-13.png]]

62
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-14.png]]

### aws network firewall

71/73
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-15.png]]

77
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-16.png]]

80
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-17.png]]

### elb sandwich

85
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-18.png]]

89/91
![[blog-design-your-firewall-deployments-to-protect-your-internet-applications-nis30-png-19.png]]





