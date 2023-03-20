---
title: apigw-get-sourceip
description: 获取客户端源地址
chapter: true
created: 2023-03-11 22:57:11.866
last_modified: 2023-03-11 22:57:11.866
tags: 
- aws/serverless/api-gateway 
---
```ad-attention
title: This is a github note

```
# apigw-get-sourceip

## client ip 
- create function nodejs 12x
```js
console.log('Loading function');
exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    context.succeed(event);
};
```

- create rest api 
- create `POST` method and integration request to lambda
- add `mapping templates`, content-type is `application/json`,  content as following:
```json
{
  "sourceIp" : "$context.identity.sourceIp",
  "input" : "$input.path('$')"
}
```

- deploy it and test 
- curl
```sh
curl -X POST -H 'Content-type: application/json' \
-d '{ "key1": "value1", "key2": "value2", "key3": "value3" }' \
https://xxx.execute-api.us-east-2.amazonaws.com/prod/

```


## alb ip
如果 alb 在 api gateway 前端，将获取到 alb 的内网地址，如下场景：
- [apigw-private-api-alb-cdk](apigw-private-api-alb-cdk.md)

## refer
https://dev.classmethod.jp/articles/api-gateway-client-ip/

