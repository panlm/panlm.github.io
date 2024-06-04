---
title: ip-ranges
description: 
created: 2022-03-26 10:25:49.147
last_modified: 2024-02-05
icon: simple/amazon
tags:
  - aws/network
  - aws/cmd
---
# ip-range

## blog
- How to Automatically Update Your Security Groups for Amazon CloudFront and AWS WAF by Using AWS Lambda 
    - ([link](https://aws.amazon.com/blogs/security/how-to-automatically-update-your-security-groups-for-amazon-cloudfront-and-aws-waf-by-using-aws-lambda/)) ([github](https://github.com/aws-samples/aws-cloudfront-samples/blob/master/update_security_groups_lambda/update_security_groups.py))

## download
```
wget https://ip-ranges.amazonaws.com/ip-ranges.json
```

## CLI

- s3
```bash
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="cn-northwest-1") | select(.service=="S3")'
```

- dynamodb
```
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="cn-northwest-1") | select(.service=="DYNAMODB")'
```

- lambda
```
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="cn-northwest-1") | select(.service=="LAMBDA")'
```

- ec2
```
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="cn-northwest-1") | select(.service=="EC2")'
```

- eks
```
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="cn-northwest-1") | select(.service=="EKS")'
```

- route 53
```sh
cat ip-ranges.json |jq -r '.prefixes[]  | select(.service=="ROUTE53")'

cat ip-ranges.json |jq -r '.prefixes[]  | select(.region=="us-east-2") | select(.service=="ROUTE53_RESOLVER")'

```

- api gateway
```sh
cat ip-ranges.json |jq -r '.prefixes[] | select(.region=="us-east-2") | select(.service=="API_GATEWAY")'
```



