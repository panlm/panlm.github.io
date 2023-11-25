---
title: ecs
description: 常用命令
created: 2023-02-22 22:46:31.539
last_modified: 2023-11-23
tags:
  - aws/container/ecs
  - aws/cmd
---
> [!WARNING] This is a github note
# ecs-cmd
## create cluster with ec2 capacity provider
- basic info
```sh
ECS_CLUSTER=myecs1
VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
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

aws ec2 modify-launch-template --launch-template-id ${LAUNCH_TEMPLATE_ID} --default-version "2"
```
- create auto scaling group ([[notes/auto-scaling-cmd#auto-scaling-create-]])
```sh
auto-scaling-create ${LAUNCH_TEMPLATE_ID} # call my function
echo ${ASG_ARN}
```
- create capacity provider 
```sh
echo ${ECS_CLUSTER}

aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
aws ecs create-cluster --cluster-name ${ECS_CLUSTER}

ECS_CAP_PROVIDER=mycp1
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=100},managedTerminationProtection=ENABLED"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1

```

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

## get ami list
```sh
aws ssm get-parameters-by-path --path /aws/service/ecs/optimized-ami/amazon-linux-2/ami- |jq -r '.Parameters[] ' |jq -s . |jq -r 'sort_by(.LastModifiedDate)'

| (map(select(.LastModifiedDate | test("2023"))))' |jq -r '.Parameters[] | (.Value, .LastModifiedDate)' |jq -r '.image_id'

```

## get task definition
```sh
ECS_SVC_NAME=test-svc
ECS_TASK_DEF_ARN=$(aws ecs describe-services --cluster ${ECS_CLUSTER} \
--services ${ECS_SVC_NAME} \
--query "services[].deployments[].["taskDefinition"]" --output text)


```

## modify task definition

```sh
NEW_AMI_ID=ami-0b7778d86d8789cff
aws ecs describe-task-definition --task-definition ${ECS_TASK_DEF_ARN} --query taskDefinition | \
jq '. + {placementConstraints: [{"expression": "attribute:ecs.ami-id == '"${NEW_AMI_ID}"'", "type": "memberOf"}]}' | \
jq 'del(.status)'| jq 'del(.revision)' | jq 'del(.requiresAttributes)' | \
jq '. + {containerDefinitions:[.containerDefinitions[] + {"memory":256, "memoryReservation": 128}]}'| \
jq 'del(.compatibilities)' | jq 'del(.taskDefinitionArn)' | jq 'del(.registeredAt)' | jq 'del(.registeredBy)' > new-task-def.json
```


## sample

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




