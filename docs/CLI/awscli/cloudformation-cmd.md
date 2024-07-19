---
title: cloudformation
description: 常用命令
created: 2021-07-01T04:49:13.611Z
last_modified: 2024-02-05
icon: simple/amazon
tags:
  - aws/mgmt/cloudformation
  - aws/cmd
---
# cloudformation-cli

## validate
```sh
aws cloudformation validate-template \
    --region us-east-1 \
    --template-body file://./test.yaml

```

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

## cfn-signal
```sh
/opt/aws/bin/cfn-signal -s true --stack ${AWS::StackId} --resource PrivateWaitCondition --region ${AWS::Region} 
# or 
/opt/aws/bin/cfn-signal -s true '${PrivateWaitHandle}'

```


## sample
- some sample for user data format - [[../../others/quick-build-brconnector.yaml|quick-build-brconnector.yaml]]
- some sample - [[../../EKS/cluster/aws-vpc.template.yaml|aws-vpc.template.yaml]]

## others
- ref & getatt cheatsheet
    - https://theburningmonk.com/cloudformation-ref-and-getatt-cheatsheet/
- sample
    - https://github.com/aws-cloudformation/aws-cloudformation-templates/tree/main
- snippts
    - https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/quickref-general.html


