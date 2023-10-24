---
title: directory-service
description: 
created: 2023-03-24 21:46:35.822
last_modified: 2023-10-22 17:18:42.355
tags:
  - aws/mgmt/directory-service
  - aws/cmd
---

```ad-attention
title: This is a github note
```

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

```

## create ms ad in default vpc

![[POC-mig-filezilla-to-transfer-family#^8ov5l3]]

refer: [[POC-mig-filezilla-to-transfer-family#create AD-]]


## active directory - windows 2012

![[Enabling Federation to AWS Using Windows Active Directory ADFS and SAML 2.0#^zfsdkd]]



