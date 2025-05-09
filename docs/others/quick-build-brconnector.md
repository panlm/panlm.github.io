---
title: Quick Deploy BRConnector using Cloudformation
description: 使用 Cloudformation 快速部署 BRConnector
created: 2024-06-09 11:59:37.855
last_modified: 2024-07-09
status: myblog
tags:
  - aws/mgmt/cloudformation
  - aws/compute/ec2
  - aws/network/cloudfront
---

# Quick Deploy BRConnector using Cloudformation
https://github.com/aws-samples/sample-connector-for-bedrock/blob/main/cloudformation/README.md

## TODO
 - enhance security: control cloudfront access lambda url only using prefix list: com.amazonaws.global.cloudfront.origin-facing  

## Supported Region
Cloudformation template are verified in following regions:
- us-east-1
- us-west-2

## Prerequisites
Enable Claude 3 Sonnet or Haiku in your region - If you are new to using Anthropic models, go to the [Amazon Bedrock console](https://console.aws.amazon.com/bedrock/) and choose **Model access** on the bottom left pane. Request access separately for Claude 3 Sonnet or Haiku.

## Components
Following key components will be included in this Cloudformation template: 
- Cloudfront
- BRConnector on Lambda or EC2
- RDS PostgreSQL or PostgreSQL container on EC2
- ECR with pull through cache enabled

## Deploy Guide
- Download [quick-build-brconnector.yaml](quick-build-brconnector.yaml) and upload to Cloudformation console or click this button to launch directly

[![attachments/quick-build-brconnector/launch-stack.png|100](attachments/quick-build-brconnector/launch-stack.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/template?stackName=brconnector1&templateURL=https://sample-connector-bedrock.s3.us-west-2.amazonaws.com/quick-build-brconnector.yaml)

- VPC parameters
    - Choose to create a new VPC or a existing VPC 
    - Choose one PUBLIC subnet for EC2 and two PRIVATE subnets for Lambda and RDS (subnet group need 2 AZ at least)

![attachments/quick-build-brconnector/IMG-quick-build-brconnector.png](attachments/quick-build-brconnector/IMG-quick-build-brconnector.png)

- Compute parameters
    - Choose ComputeType for BRConnector, Lambda or EC2
    - For EC2 settings
        - Now only support Amazon Linux 2023
        - You could choose to create PostgreSQL as container in same EC2 (`StandaloneDB` to false), or create standalone RDS PostgreSQL as backend (`StandaloneDB` to true)
    - For Lambda settings
        - <mark style="background: #ADCCFFA6;">PUBLIC Function URL</mark> will be used. Please ensure this security setting is acceptable
        - Define your private repository name prefix string
        - Always create RDS PostgreSQL (`StandaloneDB` to true)

![attachments/quick-build-brconnector/IMG-quick-build-brconnector-6.png](attachments/quick-build-brconnector/IMG-quick-build-brconnector-6.png)

- PostgreSQL parameters
    - Default PostgreSQL password is `mysecretpassword`
    - If you choose `StandaloneDB` to false, PostgreSQL will running on EC2 as container. RDS PostgreSQL will be create if this option is true.
    - Keep others as default

![attachments/quick-build-brconnector/IMG-quick-build-brconnector-7.png](attachments/quick-build-brconnector/IMG-quick-build-brconnector-7.png)

- Debugging parameters
    - If you choose Lambda as ComputeType, you could choose to delete EC2 after all resources deploy successfully. This EC2 is used for compiling and building BRConnector container temporarily. 
    - Don't delete EC2 if you choose EC2 as ComputeType
    - If you set `true` to AutoUpdateBRConnector, one script will be add to codebuild and scheduled everyday

![attachments/quick-build-brconnector/IMG-quick-build-brconnector-11.png](attachments/quick-build-brconnector/IMG-quick-build-brconnector-11.png)

- Until deploy successfully, go to output page and copy Cloudfront URL and first user key to your bedrock client settings page.

![attachments/quick-build-brconnector/IMG-quick-build-brconnector-9.png](attachments/quick-build-brconnector/IMG-quick-build-brconnector-9.png)

- Also you could connect to `BRConnector` EC2 instance with SSM Session Manager ([docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#start-ec2-console))

## Update BRConnector
### ECR with pull through cache enabled
- Check your ECR settings, if has rules in pull through cache page, you have enabled this feature to update ECR image with upstream repo automatically.
- Go to codebuild page, one project will be triggered to build regularly to update your lambda image 

### ECR without pull through cache enabled
- Currently, we use ECR pull through cache to update ECR image with upstream automatically
- following this script to update image manually if you do not enable ECR pull through cache
```sh
export AWS_DEFAULT_REGION=us-west-2
export ACCOUNT_ID=123456789012
export PrivateECRRepository=your_private_repo_name

aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

# pull/tag/push arm64 image for lambda
docker pull --platform=linux/arm64 cloudbeer/sample-connector-for-bedrock-lambda
docker tag cloudbeer/sample-connector-for-bedrock-lambda ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:arm64
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:arm64

# pull/tag/push amd64 image for lambda
docker pull --platform=linux/amd64 cloudbeer/sample-connector-for-bedrock-lambda
docker tag cloudbeer/sample-connector-for-bedrock-lambda ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:amd64
docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:amd64

# create/push manifest file
docker manifest create ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:latest --amend ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:arm64 --amend ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:amd64
docker manifest annotate ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:latest ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:arm64 --os linux --arch arm64
docker manifest annotate ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:latest ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:amd64 --os linux --arch amd64
docker manifest push ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${PrivateECRRepository}:latest

```
- update lambda image with correct architecture
- or login to ec2 to update local image and restart brconnector container


## Migrating to new RDS PostgreSQL database

working ...


