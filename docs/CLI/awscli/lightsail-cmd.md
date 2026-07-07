---
title: lightsail
description: 常用命令
created: 2023-08-24 18:29:22.661000
last_modified: 2024-02-05
tags:
- aws/compute/lightsail
- aws/cmd
permalink: git-mkdocs/cli/awscli/lightsail-cmd
---

# lightsail-cmd

## lightsail

```
aws --profile nutanix lightsail --region=ap-northeast-2 open-instance-public-ports  --instance-name Ubuntu-Seoul --port-info='fromPort=443,toPort=443,protocol="TCP",cidrs=["0.0.0.0/0"],cidrListAliases=[]'
```

## list
```sh
export AW
aws lightsail get-instances --region ap-northeast-2
```