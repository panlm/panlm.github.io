---
title: api-gateway
description: api-gateway
created: 2023-03-03 09:25:15.137
last_modified: 2023-10-24 22:47:54.576
tags:
  - cmd
  - aws/cmd
---

# apigw-cmd

## delete stage

```sh
API_ID=3vnuyp4rtl
aws apigateway delete-stage \
--rest-api-id ${API_ID} \
--stage-name ip3
```

## create-apigw-role-

```sh
ROLE_NAME=apigatewayrole-`date +%Y%m%d-%H%M`
echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "apigateway.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole"
            ]
        }
    ]
}' |tee role-trust-policy.json
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://role-trust-policy.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
aws iam list-attached-role-policies --role-name ${ROLE_NAME}

role_arn=$(aws iam get-role --role-name ${ROLE_NAME} |jq -r '.Role.Arn')

echo ${role_arn}

```

^0drt2e

## attach policy to api
https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies-create-attach.html#apigateway-resource-policies-create-attach-console

```sh
envsubst >resource-policy.json <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*",
      "Condition": {
        "StringNotEquals": {
          "aws:sourceVpce": ["vpce-0941xxx828f"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*"
    }
  ]
}
EOF
str=$(cat resource-policy.json |sed 's/"/\\"/g' |xargs |sed 's/"/\\"/g')
aws apigateway update-rest-api --rest-api-id ${API_ID} --patch-operations op=replace,path=/policy,value='"'"$str"'"'

aws apigateway create-deployment \
--rest-api-id ${API_ID} --stage-name v1 

```


## create api 
### using cli

```sh
# create a simple api 
# will be replaced by poc api with vpc link
API_ID=$(aws apigateway create-rest-api \
--name 'MyAPI-POC' \
--endpoint-configuration types=PRIVATE \
--query 'id' --output text)

ROOT_RESOURCE_ID=$(aws apigateway get-resources \
--rest-api-id ${API_ID} \
--query "items[?path=='/'].id" --output text)

RESOURCE_ID_1=$(aws apigateway create-resource \
--rest-api-id ${API_ID} \
--parent-id ${ROOT_RESOURCE_ID} \
--path-part "echo" \
--query 'id' --output text)

aws apigateway put-method \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID_1} \
--http-method GET \
--authorization-type NONE

aws apigateway put-integration \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID_1} \
--http-method GET \
--type HTTP_PROXY \
--integration-http-method GET \
--uri 'https://httpbin.org' 

# --connection-type VPC_LINK \
# --connection-id ${VPCLINK_ID} \
# --tls-config insecureSkipVerification=true \

```


### using api definition

- refer: [[git/blog-private-api-gateway-dataflow/TC-private-apigw-dataflow#步骤 9-10 -- Private API Custom Domain Name Access Logging]]
- refer: [[POC-apigw#create api to use vpclink and]]

## update-access-log-for-rest-api-

- https://forum.serverless.com/t/how-to-setup-custom-access-logging-for-api-gateway-using-serverless/3288/5

```sh
echo ${API_ID}
echo $LOGGROUP_ARN

echo '{ 
	"requestId": "$context.requestId", 
	"caller": "$context.identity.caller", 
	"user": "$context.identity.user",
	"requestTime": "$context.requestTime", 
	"httpMethod": "$context.httpMethod",
	"resourcePath": "$context.resourcePath", 
	"status": "$context.status",
	"protocol": "$context.protocol", 
	"responseLength": "$context.responseLength",
	"ip": "$context.identity.sourceIp", 
	"xff": "$context.requestOverride.header.xff"
}' |tee access-log-format.json

format_str=$(cat access-log-format.json |sed 's/"/\\"/g' |xargs |sed 's/"/\\"/g')

echo '{"patchOperations": []}' |\
jq '.patchOperations[0] = {"op": "replace", "path": "/accessLogSettings/format", "value": "'"${format_str}"'"}' |\
jq '.patchOperations[1] = {"op": "replace", "path": "/accessLogSettings/destinationArn", "value": "'"${LOGGROUP_ARN}"'"}' |tee access-log-settings.json

aws apigateway update-stage \
--rest-api-id $API_ID \
--stage-name v1 \
--cli-input-json file://access-log-settings.json
```

refer: [[git/blog-private-api-gateway-dataflow/TC-private-apigw-dataflow#API Gateway-]]



