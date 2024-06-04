---
title: directory service
description: 常用命令
created: 2023-03-24 21:46:35.822
last_modified: 2024-02-05
icon: simple/amazon
tags:
  - aws/mgmt/directory-service
  - aws/cmd
---

# directory-service-cmd

## create ms ad

```sh
AD=corp1.aws.panlm.xyz
PASS=passworD.1
VPC=vpc-0946
SUBNETS=subnet-056f,subnet-033c

aws ds create-microsoft-ad \
    --name ${AD} \
    --short-name ${AD%%.*} \
    --password ${PASS} \
    --edition Standard \
    --vpc-settings VpcId=${VPC},SubnetIds=${SUBNETS}

MSDS_ID=d-xxxx
aws ds describe-directories \
    --directory-ids ${MSDS_ID} \
    --query DirectoryDescriptions[0].[Stage,DnsIpAddrs] \
    --output text

```

## create ms ad in default vpc

??? note "right-click & open-in-new-tab"
    ![[../../others/POC-mig-filezilla-to-transfer-family#create-AD-]]


## active directory - windows 2012

![[Enabling Federation to AWS Using Windows Active Directory ADFS and SAML 2.0#^zfsdkd]]



