---
title: "build-colorapp"
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
## v1
```sh
cd /tmp
git clone https://github.com/sanjeevrg89/samplecolorapp.git
cd samplecolorapp

PROJ_NAME=sample
APP_NAME=colorapp
ECR_IMAGE_NAME=${ECR_URL}/${PROJ_NAME}/${APP_NAME}
aws ecr create-repository --repository-name ${PROJ_NAME}/${APP_NAME}
docker build . -t ${ECR_IMAGE_NAME}:v1
docker push ${ECR_IMAGE_NAME}:v1

```

## v2
```sh
cd v2
docker build . -t ${ECR_IMAGE_NAME}:v2
docker push ${ECR_IMAGE_NAME}:v2

```


## refer
https://github.com/sanjeevrg89/samplecolorapp


