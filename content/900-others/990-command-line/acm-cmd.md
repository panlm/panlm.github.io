---
title: acm-cmd
description: 常用命令 
chapter: true
created: 2023-03-15 11:58:12.994
last_modified: 2023-03-15 11:58:12.994
tags: 
- aws/cli 
- aws/security/acm 
- todo 
---
```ad-attention
title: This is a github note

```
# acm-cmd

## create-certificate-📚
```sh
aws acm request-certificate \
--domain-name '*.api0409.aws.panlm.xyz' \
--validation-method DNS \
--query 'CertificateArn'

```

## create certificate with pca  cross account
```sh
PCA_ARN=arn:aws:acm-pca:us-east-2:xxxxxx:certificate-authority/xxxxxx
aws acm request-certificate \
--domain-name '*.api0320.aws.panlm.xyz' \
--validation-method DNS \
--certificate-authority-arn ${PCA_ARN}

```





