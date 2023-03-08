---
title: "{{ replace .Name "-" " " | title }}"
description: 通过 alb 访问 private 的例子
chapter: true
created: 2023-03-07 22:09:46.587
last_modified: 2023-03-07 22:09:46.587
tags: 
- aws/serverless/api-gateway 
- aws/mgmt/cdk 
---
```ad-attention
title: This is a github note

```
# AWS CDK Private API and Application Load Balancer Demo

https://github.com/markilott/aws-cdk-internal-private-api-demo

![[Pasted image 20230307221003.png]]

`config/index.ts`
```ts
export const options = {
    vpcAttr: {
        customVpcId: '',
        // These are the AWS default VPC subnets. Update to your own CIDR's if using a custom VPC
        subnetCidr1: '172.31.128.0/20',
        subnetCidr2: '172.31.144.0/20',
    },
    createCertificate: true,
    certificateArn: '',
    dnsAttr: {
        zoneName: 'api.aws.panlm.xyz',
        hostedZoneId: 'Z0717xxxxxxVFVJxxxxxx',
    },
    albHostname: 'alb-test',
    apiPath1: 'test-api1',
    apiPath2: 'test-api2',
};

```






