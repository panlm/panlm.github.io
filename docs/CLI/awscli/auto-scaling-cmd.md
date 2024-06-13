---
title: auto-scaling-cmd
description: 常用命令
created: 2022-06-02 15:49:26.940
last_modified: 2024-06-13
icon: simple/amazonec2
tags:
  - aws/cmd
  - aws/compute/autoscaling
---

# auto-scaling-cmd
## func-create-launch-template-
- create launch template need 
    - security group id 
    - ami id
```sh title="func-create-launch-template" linenums="1"
--8<-- "docs/CLI/functions/func-create-launch-template.sh"
```
refer: [[../functions/func-create-launch-template.sh|func-create-launch-template]]

## func-create-auto-scaling-group-
- create auto scaling group need 
    - launch template id
```sh title="func-create-auto-scaling-group" linenums="1"
--8<-- "docs/CLI/functions/func-create-auto-scaling-group.sh"
```
refer: [[../functions/func-create-auto-scaling-group.sh|func-create-auto-scaling-group]]

## warmpool
- create warmpool with scale in policy
```sh
ASG_NAME="Example Auto Scaling Group"
aws autoscaling put-warm-pool \
    --auto-scaling-group-name ${ASG_NAME} \
    --pool-state Stopped \
    --instance-reuse-policy '{"ReuseOnScaleIn": true}'
```

- create warmpool with min size 4
```sh
aws autoscaling put-warm-pool \
    --auto-scaling-group-name my-asg \
    --pool-state Stopped --min-size 4
```

refer: https://docs.aws.amazon.com/autoscaling/ec2/userguide/examples-warm-pools-aws-cli.html

## refer
??? note "right-click & open-in-new-tab: "
    ![[git/git-mkdocs/CLI/awscli/ecs-cmd#update-launch-template-]]
refer [[git/git-mkdocs/CLI/awscli/ecs-cmd#update-launch-template-|update-launch-template-]]

??? note "right-click & open-in-new-tab: "
    ![[git/git-mkdocs/CLI/awscli/ecs-cmd#update-asg-]]
refer [[git/git-mkdocs/CLI/awscli/ecs-cmd#update-asg-|update-asg-]]

## launch-template-and-auto-scaling-group-

```sh
SECGRP_ID=sg-xxx
AMI_ID=ami-xxx

INSTANCE_NAME=instance-$(date +%Y%m%d%H%M)
KEY_NAME=awskey

LAUNCH_TEMPLATE_NAME=launchtemplate-$(date +%Y%m%d%H%M)
TMP=$(mktemp --suffix ${LAUNCH_TEMPLATE_NAME})
envsubst >${TMP} <<-EOF
{
  "InstanceType": "m5.large",
  "ImageId": "${AMI_ID}",
  "KeyName": "${KEY_NAME}",
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/xvda",
      "Ebs": {
        "Iops": 3000,
        "VolumeSize": 80,
        "VolumeType": "gp3",
        "Throughput": 125
      }
    }
  ],
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "${INSTANCE_NAME}"
        }
      ]
    },
    {
      "ResourceType": "volume",
      "Tags": [
        {
          "Key": "Name",
          "Value": "${INSTANCE_NAME}"
        }
      ]
    },
    {
      "ResourceType": "network-interface",
      "Tags": [
        {
          "Key": "Name",
          "Value": "${INSTANCE_NAME}"
        }
      ]
    }
  ],
  "SecurityGroupIds": [
    "${SECGRP_ID}"
  ],
  "MetadataOptions": {
    "HttpTokens": "optional",
    "HttpPutResponseHopLimit": 2
  }
}
EOF

aws ec2 create-launch-template \
  --launch-template-name ${LAUNCH_TEMPLATE_NAME} \
  --launch-template-data file://${TMP}

ASG_NAME=autoscaling-$(date +%Y%m%d%H%M)
SUBNET_ID=subnet-03c26cc2c8b2eda6e
envsubst > ${ASG_NAME}.json <<-EOF
{
  "AutoScalingGroupName": "${ASG_NAME}",
  "MinSize": 1,
  "MaxSize": 1,
  "VPCZoneIdentifier": "${SUBNET_ID}",
  "MixedInstancesPolicy":{
    "LaunchTemplate":{
      "LaunchTemplateSpecification":{
        "LaunchTemplateName": "${LAUNCH_TEMPLATE_NAME}"
      },
      "Overrides":[
        {
          "InstanceType":"m5.xlarge"
        }
      ]
    }
  }
}
EOF

aws autoscaling create-auto-scaling-group \
--cli-input-json file://${ASG_NAME}.json

export AWS_PAGER=""
ASG_ARN=$(aws autoscaling describe-auto-scaling-groups \
--auto-scaling-group-names ${ASG_NAME} \
--query 'AutoScalingGroups[0].AutoScalingGroupARN' \
--output text)

```

## auto scaling
```sh
aws launchconfig
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name AutoScalingGroup --force-delete

```




