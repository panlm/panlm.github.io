---
title: ecr
description: 常用命令
created: 2022-03-19 21:19:57.648
last_modified: 2024-02-05
icon: simple/amazonaws
tags:
  - aws/container/ecr
  - aws/cmd
---
# ecr-cmd


- [ ] kms 
- [ ] backup 
- [ ] replication

## login

```sh
export AWS_DEFAULT_REGION=us-east-2
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d. -f1)

ecr_login() {
    if [ $AWS_CLI_VERSION -gt 1 ]; then
        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
            docker login --username AWS --password-stdin ${ECR_URL}
    else
        $(aws ecr get-login --no-include-email)
    fi
}
ecr_login

```

## create-repo-

```sh
REPO_NAME=osarch
aws ecr create-repository --repository-name ${REPO_NAME}
REPO_URI=$(aws ecr describe-repositories --repository-names ${REPO_NAME} --query repositories[0].repositoryUri --output text)

```
- refer: [[../linux/docker-cmd#build-colorapp-]]

## create ecr repo nginx

```sh
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document |jq -r '.region') export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_URL}

aws ecr create-repository --repository-name nginx

docker tag nginx:latest ${ECR_URL}/nginx:latest

```





