---
title: route53-cmd
description: 常用命令 
chapter: true
created: 2022-09-20 09:02:35.112
last_modified: 2022-09-20 09:02:35.112
tags: 
- aws/network/route53 
---

```ad-attention
title: This is a github note

```

# route53-cmd

- [[#insert TXT record with multi values|insert TXT record with multi values]]
- [[#create-hosted-zone-📚|create-hosted-zone-📚]]
- [[#create cname record|create cname record]]
- [[#refer|refer]]


## insert TXT record with multi values

```json
{
    "Comment": "Update record to add new TXT record",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "@.panlm.com.",
                "Type": "TXT",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "\"test1=1\""
                    },
                    {
                        "Value": "\"test2=1\""
                    }
                ]
            }
        }
    ]
}
```

```sh
aws route53 change-resource-record-sets \
  --hosted-zone-id Z07xxxxZD1 \
  --change-batch file://a.json

```

## create-hosted-zone-📚

![[externaldns-for-route53#setup-hosted-zone-📚]]

## create cname record

![[POC-apigw#^d0liwm]]

refer: [link](https://repost.aws/knowledge-center/simple-resource-record-route53-cli) 
sample: [[acm-cmd#create-certificate-📚]]

## refer

- https://serverfault.com/questions/815841/multiple-txt-fields-for-same-subdomain?rq=1
- https://serverfault.com/questions/616407/tried-to-create-2-record-set-type-txt-in-route53

- https://www.learnaws.org/2022/02/04/aws-cli-route53-guide/



