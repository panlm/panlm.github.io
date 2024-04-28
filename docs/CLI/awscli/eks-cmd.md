---
title: eks
description: 常用命令
created: 2022-04-22 08:17:31.190
last_modified: 2024-04-23
tags:
  - aws/container/eks
---
# eks-cmd
## network
### check network 
```
aws eks describe-cluster --name ekscluster1 --query cluster.resourcesVpcConfig
```

### check cluster security group
```
aws eks describe-cluster --name ekscluster1 --query cluster.resourcesVpcConfig.clusterSecurityGroupId
```


## addons
### check default version
```sh
aws eks describe-addon-versions \
    --addon-name amazon-cloudwatch-observability \
    --kubernetes-version "1.29" \
    --query 'addons[].addonVersions[?compatibilities[?defaultVersion==`true`]].addonVersion'

```

### install addons
- [[git/git-mkdocs/EKS/solutions/monitor/eks-container-insights|eks-container-insights]]



