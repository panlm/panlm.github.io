---
title: eks-audit-log-security-lake
description: 
created: 2024-04-26 11:33:36.335
last_modified: 2024-04-26
tags:
  - aws/container/eks
  - aws/security/security-lake
---

# eks-audit-log-security-lake
news:
https://aws.amazon.com/about-aws/whats-new/2024/02/amazon-security-lake-audit-logs-eks/?nc1=h_ls

## enable security lake
- for account in orgs
    - need delegate administrator to enable for log type & account & region in orgs
- for standalone account
    - enable by itself

## settings in eks
- no need EKS to enable logging for audit

## query from athena
- glue table has been created in db:`amazon_security_lake_glue_db_us_east_2`

## create subscribers with lake formation data access
- share data access to producer account
    - [[../../../git-attachment/Securely share your data across AWS accounts using AWS Lake Formation|Securely share your data across AWS accounts using AWS Lake Formation]]


## refer
- enabled in account 365


