---
title: apigw-custom-domain-name
description: 为私有 api 创建定制域名
chapter: true
created: 2023-03-07 23:01:19.519
last_modified: 2023-03-07 23:01:19.519
tags: 
- aws/serverless/api-gateway 
---

```ad-attention
title: This is a github note

```

# apigw-custom-domain-name

- [for private api](#for-private-api)
	- [route 53 to customer domain name](#route-53-to-customer-domain-name)
	- [refer](#refer)
- [for regional api](#for-regional-api)
	- [route 53 to customer domain name](#route-53-to-customer-domain-name)
	- [refer](#refer)

## for private api 
- 在 acm 中发布证书 `*.api.aws.panlm.xyz`
- 在与 API 同区域中创建 route53 的 public host zone `api.aws.panlm.xyz`
- 创建 私有 API 
- 创建 interface endpoint ，并且配置 resource policy 允许从该 `vpce` 访问
- 创建定制域名，例如 `api1.api.aws.panlm.xyz`
    - 映射到 private api 的某个 stage
- 在 route53 中，将定制域名 alias 到 vpce 的 dns 上，访问可以成功，因为从该 vpce 访问 api 是被允许的 （但是存在证书 issue，需要 `curl -k` ）
    - 如果该 api 是私有的，定制域名 alias 到 apigw 上，则将访问禁止 `Forbidden` 。
- 需要使用 alb 或者 nlb over tls 消除证书 issue （[link](https://github.com/aws-samples/serverless-samples/tree/main/apigw-private-custom-domain-name)）
- ![png-on-github](https://github.com/aws-samples/serverless-samples/blob/main/apigw-private-custom-domain-name/assets/apigw_pcdn_nlb_200.png)

### route 53 to customer domain name

|          | enable endpoint private dns name | disable endpoint private dns name |
| -------- | -------------------------------- | --------------------------------- |
| alias    | {"message":"Forbidden"}          | {"message":"Forbidden"}           |
| cname    | certificate issue                | {"message":"Forbidden"}           |
| api name | certificate issue                | Could not resolve host            |
| vpce     | certificate issue                | certificate issue                 |

certificate issue: "no alternative certificate subject name matches target host name"

### refer
- https://github.com/aws-samples/serverless-patterns/tree/main/public-alb-private-api-terraform

## for regional api 
- 如果该 api 是 regional ，创建定制域名，记录下定制域名配置中的 `API Gateway domain name`，不是 api stage 页面中的域名，参照 [[apigw-regional-api-access-from-vpc]]
- 使用 route53 alias（或 cname） 将定制域名指向 `API Gateway domain name`
- 访问定制域名，浏览器将显示证书有效
- 如果定制域名指向 api 的 url （在 api stage 页面中），将遇到证书验证不通过的问题

### route 53 to customer domain name

|          | regional api      |
| -------- | ----------------- |
| alias    | success           |
| cname    | success           | 
| api name | certificate issue |


### refer
- https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-domain-certificate/
- https://serverlessland.com/repos/apigw-private-custom-domain-name



