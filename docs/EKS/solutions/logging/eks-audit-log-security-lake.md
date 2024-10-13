---
title: Security Lake Support Collecting Audit Logging from EKS
description: 使用 Security Lake 收集 EKS Audit 日志
created: 2024-04-26 11:33:36.335
last_modified: 2024-05-11
status: myblog
tags:
  - aws/container/eks
  - aws/security/security-lake
---

# Security Lake Support Collecting Audit Logging from EKS

news: https://aws.amazon.com/about-aws/whats-new/2024/02/amazon-security-lake-audit-logs-eks/?nc1=h_ls

## diagram 
- both accounts in same Organizations
![[../../../git-attachment/eks-audit-log-security-lake-png-1.png]]

## accounts
- account A 产生 eks audit log
- account B security lake delegate admin, owned all data

## enable security lake
- for account in orgs
    - need delegate administrator to enable for log type & account & region in orgs
- for standalone account
    - enable by itself

## settings in eks
- no need EKS to enable logging for audit (account A)

## query from athena account B
- glue table has been created in db: `amazon_security_lake_glue_db_us_east_2`

## query from athena in account A
- account B
    - create subscribers with lake formation data access in security lake
    - share named resource to account A ([[../../../git-attachment/Securely share your data across AWS accounts using AWS Lake Formation|Securely share your data across AWS accounts using AWS Lake Formation]])
        - grant database describe permissions to account A (need grant grant permission for quicksight use it)
- account A
    - accept resource sharing in RAM
    - select databases in lake formation, create resource link (input new database name)
    - query tables in new database name in Athena

## query from quicksight's athena dataset
- account A
    - grant quicksight user to access new database name in lake formation
    - create dataset and analytics in quicksight
- sample dashboard for security lake 1.0 format
    - https://github.com/aws-samples/amazon-security-lake-quicksight


## refer
- supported in terraform provider aws 5.40+
- https://docs.splunk.com/Documentation/AddOns/released/AWS/SecurityLake
- https://schema.ocsf.io/1.1.0/classes/api_activity?extensions=
- https://docs.aws.amazon.com/security-lake/latest/userguide/open-cybersecurity-schema-framework.html



