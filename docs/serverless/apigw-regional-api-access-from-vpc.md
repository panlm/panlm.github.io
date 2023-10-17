---
title: apigw-regional-api-access-from-vpc
description: apigw-regional-api-access-from-vpc
chapter: true
created: 2023-03-14 08:56:36.285
last_modified: 2023-03-14 08:56:36.285
tags: 
- aws/serverless/api-gateway 
---

# apigw-regional-api-access-from-vpc

https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-vpc-connections/

Connect to public APIs with private DNS enabled
If private DNS is enabled, set up edge-optimized custom domain names or regional custom domain names to connect to your public APIs.

Important: Resources in your VPC that try to connect to your public APIs must have internet connectivity. Also, when configuring DNS records for a regional custom domain name, you must use A type alias records. However, with edge-optimized custom domain names, use either A type alias records or CNAME records.



## refer

https://docs.aws.amazon.com/whitepapers/latest/best-practices-api-gateway-private-apis-integration/rest-api.html


