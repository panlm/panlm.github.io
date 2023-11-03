---
title: ecs
description: 常用命令
created: 2023-02-22 22:46:31.539
last_modified: 2023-11-02 08:20:31.187
tags:
  - aws/container/ecs
  - aws/cmd
---
> [!WARNING] This is a github note
# ecs-cmd

## func ecsexec

```sh
ECS_CLUSTER=CapacityProviderDemo
function ecsexec {
aws ecs execute-command \
    --cluster ${ECS_CLUSTER} --task $1 \
    --command /bin/sh --interactive \
    --command "curl localhost:5000" \
    --region us-east-2 
}
```

## create cluster

- create asg & launch template first
    - [[auto-scaling-cmd#launch-template-and-auto-scaling-group-]]

```sh
ECS_CLUSTER_NAME=MyCluster
aws ecs create-cluster \
    --cluster-name ${ECS_CLUSTER_NAME}

ECS_CAP_PROVIDER=MyCapacityProvider
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=10}"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER_NAME} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1

```


