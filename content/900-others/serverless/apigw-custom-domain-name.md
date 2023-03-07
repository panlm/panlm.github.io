---
title: apigw-custom-domain-name
description: 为私有 api 创建定制域名
created: 2023-03-07 23:01:19.519
last_modified: 2023-03-07 23:01:19.519
tags: 
- aws/serverless/api-gateway 
---
```ad-attention
title: This is a github note

```

# apigw-custom-domain-name

## for private api 
- 在 acm 中发布证书 `*.api.aws.panlm.xyz`
- 在与 API 同区域中创建 route53 的 public host zone `api.aws.panlm.xyz`
- 创建 私有 API 
- 创建 interface endpoint ，并且配置 resource policy 允许从该 `vpce` 访问
- 创建定制域名，例如 `api1.api.aws.panlm.xyz`
    - 映射到 private api 的某个 stage
- 在 route53 中，将定制域名 alias 到 vpce 的 dns 上，访问可以成功，因为从该 vpce 访问 api 是被允许的
    - 如果定制域名 alias 到 apigw 上，则将访问禁止 `Forbidden` ，因为该 api 是私有的




