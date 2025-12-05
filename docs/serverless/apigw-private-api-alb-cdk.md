---
title: Private API and ALB Demo
description: 通过 ALB 访问 Private API 的例子
created: 2023-03-07 22:09:46.587
last_modified: 2023-12-03
tags:
  - aws/serverless/api-gateway
  - aws/mgmt/cdk
---

# AWS CDK Private API and Application Load Balancer Demo

- https://github.com/markilott/aws-cdk-internal-private-api-demo

![apigw-private-api-alb-cdk-png-1.png](apigw-private-api-alb-cdk-png-1.png)

## prep
- 创建 host zone 可以被你的域名解析到 （在上游 route53 添加 NS 记录）
- 创建新vpc，不要创建 api gateway 的 endpoint
- 创建 cloud9 在新 vpc

## lab-setup-
- clone repo
- edit `config/index.ts`
```js
export const options = {
    vpcAttr: {
        customVpcId: 'vpc-0a766975xxxxxxd45',
        // These are the AWS default VPC subnets. Update to your own CIDR's if using a custom VPC
        subnetCidr1: '10.251.192.0/24',
        subnetCidr2: '10.251.193.0/24',
    },
    createCertificate: false,
    certificateArn: 'arn:aws:acm:us-east-2:7933xxxx2775:certificate/cc5xxxx07fc3',
    dnsAttr: {
        zoneName: 'api0320.aws.panlm.xyz',
        hostedZoneId: 'Z0xxxx73xxxxYEARSVSP',
    },
    albHostname: 'test-alb',
    apiPath1: 'test-api1',
    apiPath2: 'test-api2',
};
```

- deploy
```sh
npm install
cdk bootstrap
cdk deploy --all --require-approval never
```

## data flow
![apigw-private-api-alb-cdk-png-2.png](apigw-private-api-alb-cdk-png-2.png)

## target group settings
![apigw-private-api-alb-cdk-png-3.png](apigw-private-api-alb-cdk-png-3.png)



## refer
- https://aws.amazon.com/cn/blogs/compute/implementing-custom-domain-names-for-private-endpoints-with-amazon-api-gateway/
- https://georgemao.medium.com/enabling-private-apis-with-custom-domain-names-aws-api-gateway-df1b62b0ba7c
- https://serverlessland.com/repos/apigw-private-custom-domain-name


