---
title: regctl
description: container registry 同步工具
created: 2024-08-07 09:22:32.402
last_modified: 2024-08-07
tags:
  - linux
  - cmd
---

# regctl
sync registry tool, support multi architecture container images

## install
```sh
curl https://github.com/regclient/regclient/releases/download/v0.7.1/regctl-linux-amd64

```

## cmd
- login
```sh
# login
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} |regctl registry login ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com --user AWS --pass-stdin
```
- export
```sh
regctl image export 123456789012.dkr.ecr.us-west-2.amazonaws.com/$REPO_PREFIX/$IMG_LAMBDA:latest /dev/null

IMG_LAMBDA=x6u9o2u4/sample-connector-for-bedrock-lambda
regctl image copy public.ecr.aws/${IMG_LAMBDA}:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/brconn/${IMG_LAMBDA}:latest

```
- copy to private registry
```sh
regctl image copy  nginx:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/nginx

```





