---
title: cloudformation
description: 常用命令
created: 2021-07-01T04:49:13.611Z
last_modified: 2024-01-15
tags:
  - aws/mgmt/cloudformation
  - aws/cmd
---
> [!WARNING] This is a github note
# cloudformation-cli

## describe-stacks
```sh
AWS_REGION=us-east-1
STACK_NAME=stack1-23948

aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`VPCID`].OutputValue' --output text

aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].StackStatus' --output text

```

## create-stack
```sh
aws cloudformation create-stack --stack-name OELabStack2 \
  --parameters ParameterKey=InstanceProfile,ParameterValue="" \
               ParameterKey=KeyName,ParameterValue=sample-key \
               ParameterKey=WorkloadName,ParameterValue=Test \
  --tags Key=env,Value=stack2 \
  --template-body file://~/Downloads/OE_Inventory_and_Patch_Mgmt.json

{
    "StackId": "arn:aws-cn:cloudformation:cn-north-1:24xxxxx11488:stack/OELabStack1/64469510-5339-11ea-8854-022274580dba"
}

```


