---
title: "build-colorapp"
description: "创建 color 应用"
chapter: true
weight: 20
created: 2023-01-09 14:13:56.452
last_modified: 2023-01-09 14:13:56.452
tags: 
- docker 
---

```ad-attention
title: This is a github note
```

# build colorapp

- [v1](#v1)
- [v2](#v2)
- [refer](#refer)


## v1
```sh
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document |jq -r '.region')
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_URL}

cd /tmp
git clone https://github.com/sanjeevrg89/samplecolorapp.git
cd samplecolorapp

PROJ_NAME=sample
APP_NAME=colorapp
ECR_IMAGE_NAME=${ECR_URL}/${PROJ_NAME}/${APP_NAME}
aws ecr create-repository \
--repository-name ${PROJ_NAME}/${APP_NAME}
docker build . -t ${ECR_IMAGE_NAME}:v1
docker push ${ECR_IMAGE_NAME}:v1

```

^y8c1ci

## v2
```sh
cd v2
docker build . -t ${ECR_IMAGE_NAME}:v2
docker push ${ECR_IMAGE_NAME}:v2

```


## refer
https://github.com/sanjeevrg89/samplecolorapp


