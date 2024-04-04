---
title: Windows Authentication with gMSA for .NET Linux Containers in Amazon ECS
description: 
created: 2024-02-27 08:24:49.808
last_modified: 2024-03-20
tags:
  - microsoft/gmsa
  - aws/container/ecs
---
> [!WARNING] This is a github note
# Windows Authentication with gMSA for .NET Linux Containers in Amazon ECS

workshop
https://catalog.us-east-1.prod.workshops.aws/workshops/a6761c4f-f1f8-44e9-8455-fda420122632/en-US

blog
https://aws.amazon.com/cn/blogs/containers/using-windows-authentication-with-gmsa-on-linux-containers-on-amazon-ecs/

![[git/git-mkdocs/git-attachment/ws-gmsa-linux-containers-ecs-png-1.png]]

## lab 

wait until cdk bootstrap display on cloudformation
```sh

git clone https://github.com/aws-samples/gmsa-linux-containers-ecs.git

# has send pull request
# change cdk-dotnet\src\CdkDotnet\CdkDotnet.csproj
# 2.93.0 --> 2.130.0

$Env:AWS_DEFAULT_REGION = "us-east-1"
$Env:EC2_INSTANCE_KEYPAIR_NAME = "gmsa"
$Env:MY_SG_INGRESS_IP = "0.0.0.0" 
$Env:DOMAIN_JOIN_ECS = 0 

npm install -g aws-cdk # npm upgrade
cdk --version


npx cdk deploy "*" --require-approval "never" --verbose

# if got cdk cli version compatibility issue
# add "npx" at the front of CLI

```

create cloudformation stack to upgrade existing one
```sh
$env:DEPLOY_APP=1
$env:APP_TD_REVISION = 2
cdk deploy "*" --require-approval "never" --verbose

```

directory.amazon-ecs-gmsa-linux.com
```
 .\Add-ECSContainerInstancesToADGroup.ps1 -EcsAsgName amazon-ecs-gmsa-linux
```

```
 .\update-ecs-task-definition-cred-spec.sh -t amazon-ecs-gmsa-linux-web-site-task
```

```sh
$env:DEPLOY_APP=1
$env:APP_TD_REVISION = 2
cdk deploy "*" --require-approval "never" --verbose

```


