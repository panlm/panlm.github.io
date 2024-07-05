---
title: sam
description: 常用命令
created: 2021-12-13T03:44:40.679Z
last_modified: 2021-12-13
icon: simple/amazon
tags:
  - aws/serverless
  - aws/cmd
---

# sam-cli

```sh
sudo amazon-linux-extras install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
sam --version

```

```sh
curl 'https://static.us-east-1.prod.workshops.aws/public/5c7d1dc8-9201-4bf3-b2d4-26195a661014/static/bin/bootstrap.sh' | bash

```

## basic-template-

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: >-
  sam-app

Transform:
- AWS::Serverless-2016-10-31

Resources:
  MyApi:
    Type: AWS::Serverless::Api
    Properties:
      StageName: prod
      DefinitionBody:
        swagger: '2.0'
        info:
          title: My API
          version: '1.0'
        paths:
          /hello:
            get:
              responses:
                '200':
                  description: OK
                  schema:
                    type: string
              x-amazon-apigateway-integration:
                httpMethod: GET
                type: HTTP_PROXY
                uri: 'https://jsonplaceholder.typicode.com/todos/1'
```

```sh
export AWS_DEFAULT_REGION=us-east-2

bucket_name=panlm-230408-$RANDOM
aws s3api create-bucket --bucket ${bucket_name} \
--create-bucket-configuration LocationConstraint=${AWS_DEFAULT_REGION}

sam package --template-file template.yaml \
    --s3-bucket ${bucket_name} \
    --output-template-file packaged.yaml
sam deploy --template-file packaged.yaml \
    --stack-name ${bucket_name} \
    --capabilities CAPABILITY_IAM

```


