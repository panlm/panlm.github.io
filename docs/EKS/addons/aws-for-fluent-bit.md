---
title: aws-for-fluent-bit
description: 
created: 2022-07-22 10:28:26.502
last_modified: 2024-04-13
tags:
  - kubernetes
  - aws/container/eks
---

# aws-for-fluent-bit
- https://github.com/aws/aws-for-fluent-bit
- https://github.com/aws/eks-charts/blob/master/stable/aws-for-fluent-bit/README.md

## default cloudwatch log group
- `/aws/containerinsights/<CLUSTER_NAME>/application`

## disable logging capture
- set `READ_FROM_TAIL` to `Off` for `fluent-bit` daemonset
- need to verify this CLI
```sh
aws eks create-addon --cluster-name ${CLUSTER_NAME} \
    --addon-name amazon-cloudwatch-observability \
    --addon-version ${ADDON_DEFAULT_VERSION} \
    --configuration-values '{ "containerLogs": { "enabled": false } }' \
    --resolve-conflicts OVERWRITE
```

### query configuration values 
```sh
aws eks describe-addon-configuration \
    --addon-name amazon-cloudwatch-observability \
    --addon-version v1.5.3-eksbuild.1
```


## refer
[[../solutions/logging/eks-loggroup-description|eks-loggroup-description]]


