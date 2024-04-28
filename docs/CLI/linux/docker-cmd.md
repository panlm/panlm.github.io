---
title: docker
description: 常用命令
created: 2022-03-23 13:58:01.257
last_modified: 2024-04-23
tags:
  - docker
  - linux
  - cmd
---
# docker cmd

## docker build

```
docker build --tag panlm/ntnx:app2 .
docker run -d --name app2 -p 5000:5000 app2
docker login -u panlm
docker push panlm/ntnx:app2

```

```
docker pull panlm/ntnx:app2
docker run -d --name app2 -p 5000:5000 panlm/ntnx:app2

docker exec -it app2 /bin/bash

```

## docker-buildx-

- download binary from [link](https://github.com/docker/buildx/)  
```
mkdir -p ~/.docker/cli-plugins
mv <buildx> ~/.docker/cli-plugins/docker-buildx
chmod a+x ~/.docker/cli-plugins/docker-buildx
```
- check qemu emulators
```
docker buildx ls
docker run -it --rm --privileged tonistiigi/binfmt --install all
# docker buildx create --use --platform=linux/arm64,linux/amd64 --name multi-platform-builder
docker buildx inspect --bootstrap
```
- build multi arch
```sh
docker buildx build \
--platform linux/amd64,linux/arm64 \
-t 123456789012.dkr.ecr.us-east-2.amazonaws.com/osarch:latest \
--push .
```
- refer: [[../../../../WebClip/How to quickly setup an experimental environment to run containers on x86 and AWS Graviton2 based Amazon EC2 instances]]

## docker image
### clean

```
docker image prune -a

```

### samples
#### flask app

- python_app.py
```python
#!/usr/bin/env python3
from flask import Flask
import os

app = Flask(__name__)
@app.route('/')
def index():
    return f"{{ OS Architecture: {os.uname().machine} }}"

if __name__ == '__main__':
    app().run(host='0.0.0.0')

```
- Dockerfile
```dockerfile
FROM public.ecr.aws/bitnami/python:3.7
EXPOSE 5000
WORKDIR /
COPY ./python_app.py /app.py
RUN pip install flask
CMD ["flask", "run", "--host", "0.0.0.0"]
```
- create repo [[../awscli/ecr-cmd#create-repo-]]
- build
```sh
echo ${REPO_URI}
docker build -t ${REPO_URI}:latest .
docker push ${REPO_URI}:latest

```
- docker run for testing
```sh
docker run --rm -d -p 8080:5000 --name osarch ${REPO_URI}:latest

```

#### build-colorapp-

- v1
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

- v2
```sh
cd v2
docker build . -t ${ECR_IMAGE_NAME}:v2
docker push ${ECR_IMAGE_NAME}:v2

```

- refer: https://github.com/sanjeevrg89/samplecolorapp

#### ubuntu-based

```
FROM python:2.7
#RUN ["apt-get", "update"]
#RUN ["apt-get", "install", "-y", "vim"]
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python ./app.py

```

#### centos-based

```
FROM centos:7
RUN ["yum", "install", "-y", "epel-release", "gcc", "python-devel", "python2-pip"]
RUN ["rpm", "-Uvh", "https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm"]
RUN ["yum", "install", "-y", "--enablerepo=mysql80-community", "mysql-community-devel"]
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python ./app.py

```



## docker run 

- [[docker-run]]

```sh
docker run --restart=unless-stopped redis

```

## docker push

- https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html


## docker environment variable

https://phoenixnap.com/kb/docker-environment-variables

ENV SPARK_VERSION=3.3.3

