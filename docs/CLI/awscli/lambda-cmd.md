---
title: lambda
description: 
created: 2022-08-19 10:57:53.314
last_modified: 2024-02-04
tags:
  - aws/serverless/lambda
  - aws/cmd
---
> [!WARNING] This is a github note
# lambda-cmd

## create execute role 
- https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html#permissions-executionrole-console
```sh
role_name=lambda-ex-$RANDOM
aws iam create-role --role-name ${role_name} --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name ${role_name} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

```

## save code 
```sh
wget -O index.js 'https://raw.githubusercontent.com/panlm/aws-eks-example/main/lambda/kinesis-firehose-cloudwatch-logs-processor'
zip function.zip index.js

```

## create lambda
```sh
role_arn=$(aws iam get-role --role-name ${role_name} |jq -r '.Role.Arn')
aws lambda create-function \
--function-name cwl-s3-${role_name} \
--timeout 60 \
--runtime 'nodejs14.x' \
--role ${role_arn} \
--zip-file fileb://function.zip \
--handler index.handler

```


## add-layer-to-lambda-
- upload zip package from mac to lambda, seems works

```sh
mkdir -p $$/python/lib/python3.8/site-packages
pip install flatten_json -t $$/python/lib/python3.8/site-packages
cd $$
zip -r package.zip ./python

```

- push layer version
```sh
aws lambda publish-layer-version --layer-name layer_flatten_json --description "flatten_json" --zip-file fileb://package.zip --compatible-runtimes python3.8
layer_arn=$(aws lambda list-layer-versions --layer-name layer_flatten_json \
--query 'LayerVersions[0].LayerVersionArn' --output text)

aws lambda update-function-configuration --function-name ${lambda_name} \
--layers ${layer_arn}

```


