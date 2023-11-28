---
title: ecs
description: 常用命令
created: 2023-02-22 22:46:31.539
last_modified: 2023-11-28
tags:
  - aws/container/ecs
  - aws/cmd
---
> [!WARNING] This is a github note
# ecs-cmd
## get ami list
- get full list
```sh
aws ssm get-parameters-by-path \
    --path /aws/service/ecs/optimized-ami/amazon-linux-2 \
    --query 'Parameters[?contains(ARN, `arn:aws:ssm:us-east-2::parameter/aws/service/ecs/optimized-ami/amazon-linux-2/ami-`)==`true`]' \
    |jq -r 'sort_by(.LastModifiedDate)' 
```

- last 2 AMI ID
```sh
AMI_IDS=($(
aws ssm get-parameters-by-path \
    --path /aws/service/ecs/optimized-ami/amazon-linux-2 \
    --query 'sort_by(Parameters,&LastModifiedDate)[?contains(ARN, `arn:aws:ssm:us-east-2::parameter/aws/service/ecs/optimized-ami/amazon-linux-2/ami-`)==`true`]' \
    |jq -r '.[].Value' |jq -r '.image_id' \
    |tail -n 2
))

OLD_AMI_ID=${AMI_IDS[0]}
NEW_AMI_ID=${AMI_IDS[1]}
```

## create cluster with ec2 capacity provider
- basic info
```sh
ECS_CLUSTER=myecs1
VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
export AWS_PAGER=""
export AWS_DEFAULT_REGION=us-east-2
```
- get ecs recommended optimized ami
```sh
ECS_AMI=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended |jq -r '.Parameters[0].Value' |jq -r '.image_id')
```
- get default security group ([[notes/ec2-cmd#create-sg-]])
```sh
create-sg ${VPC_ID} # call my function
echo ${SG_ID}
```
- create launch template ([[notes/auto-scaling-cmd#func-create-aunch-template-]])
```sh
echo ${SG_ID}
echo ${OLD_AMI_ID}
create-launch-template ${SG_ID} ${OLD_AMI_ID} # call my function
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
- create auto scaling group ([[notes/auto-scaling-cmd#func-create-auto-scaling-group]])
```sh
create-auto-scaling ${LAUNCH_TEMPLATE_ID} # call my function
echo ${ASG_ARN}
```
- create ecs cluster 
```sh
echo ${ECS_CLUSTER}

aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
aws ecs create-cluster --cluster-name ${ECS_CLUSTER}
```
- capacity provider 
```sh
ECS_CAP_PROVIDER=mycp1
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=100},managedTerminationProtection=ENABLED"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1

```

## register task definition
```sh
TASK_NAME=task2-$(TZ=EAT-8 date +%Y%m%d-%H%M)

envsubst >task-definition.json <<-EOF
{
  "containerDefinitions": [
    {
      "name": "nginx",
      "image": "nginx",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp",
          "name": "nginx-80-tcp",
          "appProtocol": "http"
        }
      ],
      "essential": true
    }
  ],
  "family": "${TASK_NAME}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": [
    "EC2"
  ],
  "cpu": "1024",
  "memory": "3072"
}
EOF

aws ecs register-task-definition \
    --cli-input-json file://./task-definition.json

```

## create service
- create alb and target group first ([[elb-cmd#func-alb-and-tg]])
- create service
```sh
echo ${ECS_CLUSTER}
echo ${TG80_ARN}
echo ${TASK_NAME}
echo ${VPC_ID}
SERVICE_NAME=${TASK_NAME}-svc
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
    --filter Name=vpc-id,Values=${VPC_ID} \
    --query "SecurityGroups[?GroupName == 'default'].GroupId" \
    --output text)
ALL_SUBNET_ID=$(aws ec2 describe-subnets \
    --filter "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId')

envsubst >svc-definition.json <<-EOF
{
    "serviceName": "${SERVICE_NAME}",
    "taskDefinition": "${TASK_NAME}",
    "loadBalancers": [
        {
            "targetGroupArn": "${TG80_ARN}",
            "containerName": "nginx",
            "containerPort": 80
        }
    ],
    "networkConfiguration": {
        "awsvpcConfiguration": {
            "subnets": ${ALL_SUBNET_ID},
            "securityGroups": [
                "${DEFAULT_SG_ID}"
            ],
            "assignPublicIp": "DISABLED"
        }
    }, 
    "desiredCount": 3
}
EOF

aws ecs create-service \
    --cluster ${ECS_CLUSTER} \
    --service-name ${SERVICE_NAME} \
    --cli-input-json file://svc-definition.json

```

## update launch template

```sh
echo ${NEW_AMI_ID}

LT_DEF_VER=$(aws ec2 describe-launch-templates --launch-template-ids  ${LAUNCH_TEMPLATE_ID} --query 'LaunchTemplates[0].DefaultVersionNumber' --output text)

aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID} \
    --version-description ${LAUNCH_TEMPLATE_ID}-$(TZ=CST-8 date +%H%M) \
    --source-version ${LT_DEF_VER} \
    --launch-template-data '{"ImageId":"'"${NEW_AMI_ID}"'"}' |tee /tmp/$$-new-lt

LT_VER=$(cat /tmp/$$-new-lt |jq -r '.LaunchTemplateVersion.VersionNumber')

```

## update asg

```sh
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_ARN##*/} \
    --launch-template LaunchTemplateId=${LAUNCH_TEMPLATE_ID},Version=${LT_VER}

```


## get task definition
```sh
ECS_SVC_NAME=${SERVICE_NAME}
ECS_TASK_DEF_ARN=$(aws ecs describe-services --cluster ${ECS_CLUSTER} \
--services ${ECS_SVC_NAME} \
--query "services[].deployments[].["taskDefinition"]" --output text)

```

## modify-task-definition-
- update task definition
```sh
# ami-0b7778d86d8789cff / ami-0f896121197c465b6
echo ${NEW_AMI_ID}
aws ecs describe-task-definition --task-definition ${ECS_TASK_DEF_ARN} --query taskDefinition | \
jq '. + {placementConstraints: [{"expression": "attribute:ecs.ami-id == '"${NEW_AMI_ID}"'", "type": "memberOf"}]}' | \
jq 'del(.status)'| jq 'del(.revision)' | jq 'del(.requiresAttributes)' | \
jq '. + {containerDefinitions:[.containerDefinitions[] + {"memory":256, "memoryReservation": 128}]}'| \
jq 'del(.compatibilities)' | jq 'del(.taskDefinitionArn)' | jq 'del(.registeredAt)' | jq 'del(.registeredBy)' > new-task-def.json
```
- register new one
```sh
aws ecs register-task-definition \
    --cli-input-json file://./new-task-def.json |tee /tmp/$$-new-task-def
TASK_DEF_ARN=$(cat /tmp/$$-new-task-def |jq -r '.taskDefinition.taskDefinitionArn')

```

## update service 
```sh
aws ecs update-service --cluster ${ECS_CLUSTER} --service ${SERVICE_NAME} --task-definition ${TASK_DEF_ARN##*/}
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




