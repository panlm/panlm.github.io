---
title: ecs
description: 常用命令
created: 2023-02-22 22:46:31.539
last_modified: 2023-11-06
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


## create cluster - new
- basic info
```sh
ECS_CLUSTER=MyCluster
VPC_ID=vpc-0948xxxx6ffb
export AWS_PAGER=""
export AWS_DEFAULT_REGION=us-east-2

```
- get ecs optimized ami
```sh
ECS_AMI=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended |jq -r '.Parameters[0].Value' |jq -r '.image_id')

```
- get default security group ([[notes/ec2-cmd#create-sg-]])
```sh
create-sg ${VPC_ID} # call my function
echo ${SG_ID}

```
- create launch template ([[notes/auto-scaling-cmd#launch-template-create-]])
```sh
echo ${SG_ID}
echo ${ECS_AMI}
launch-template-create ${SG_ID} ${ECS_AMI} # call my function
echo ${LAUNCH_TEMPLATE_ID}

```
- add user data and instance profile ([[git/git-mkdocs/CLI/awscli/iam-cmd#ec2-admin-role-create-]])
```sh
ec2-admin-role-create # call my function
echo ${INSTANCE_PROFILE_ARN}

TMP=$(mktemp --suffix .UserData)
envsubst >${TMP} <<-EOF
#!/bin/bash
echo ECS_CLUSTER=${ECS_CLUSTER} >> /etc/ecs/ecs.config
sudo iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
sudo service iptables save
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
EOF
B64STRING=$(cat ${TMP}|base64 -w 0)
aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID} \
    --version-description ${LAUNCH_TEMPLATE_ID}-$(TZ=CST-8 date +%H%M) \
    --source-version 1 \
    --launch-template-data '{"UserData":"'"${B64STRING}"'","IamInstanceProfile":{"Arn":"'"${INSTANCE_PROFILE_ARN}"'"}}' |tee ${TMP}.out

```
- create auto scaling group ([[notes/auto-scaling-cmd#auto-scaling-create-]])
```sh
auto-scaling-create ${LAUNCH_TEMPLATE_ID} # call my function
echo ${ASG_ARN}
```
- create capacity provider 
```sh
ECS_CAP_PROVIDER=MyCapacityProvider
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=100},managedTerminationProtection=ENABLED"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1

```






