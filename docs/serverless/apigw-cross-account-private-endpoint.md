---
title: apigw-cross-account-private-endpoint
description: 跨账号访问私有api
created: 2023-03-05 22:05:10.532
last_modified: 2023-03-05 22:05:10.532
tags:
  - aws/serverless/api-gateway
---
> [!WARNING] This is a github note

# How can I access an API Gateway private REST API in another AWS account using an interface VPC endpoint

## topo
- https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-private-cross-account-vpce/?nc1=h_ls

![apigw-cross-account-private-endpoint-png-1.png](apigw-cross-account-private-endpoint-png-1.png)


## In Account A
- create vpc & `execute-api` endpoint
- no peering or tgw needed

## In API gateway Service Account
### access-control-with-cidr
- works. 
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "execute-api:/*/*/*",
            "Condition": {
                "NotIpAddress": {
                    "aws:SourceIp": "10.251.0.0/16"
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
```

### access-control-with-vpce
- works.
```json
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
          "aws:sourceVpce": ["vpce-0e8c7xxb45","vpce-05d2xx259"]
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

```

### access-control-with-vpc
- works
```json
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
                    "aws:sourceVpc": "vpc-0204axxx0"
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
```

### deploy
- redeploy after you change `Resource Policy`

## refer
- https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-authorization-flow.html



