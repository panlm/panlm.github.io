---
title: route53
description: 常用命令
created: 2022-09-20 09:02:35.112
last_modified: 2024-02-17
icon: simple/amazonroute53
tags:
  - aws/network/route53
---
> [!WARNING] This is a github note

# route53-cmd
## func-create-hosted-zone-
- 执行下面命令创建 Hosted Zone，然后手工添加 NS 记录到上游的域名服务器 domain registrar 中 (create hosted zone, and then add NS records to upstream domain registrar)
- [[../functions/func-create-hosted-zone.sh|func-create-hosted-zone]]
```sh title="func-create-hosted-zone" linenums="1"
--8<-- "docs/CLI/functions/func-create-hosted-zone.sh"
```

## func-create-ns-record-
- create host zone in your child account and get NS (previous chapter)
- [[../linux/assume-tool|assume]] to your parent account to execute this function to add NS record to upstream route53 host zone
- [[../functions/func-create-ns-record.sh|func-create-ns-record]]
```sh title="func-create-ns-record" linenums="1"
--8<-- "docs/CLI/functions/func-create-ns-record.sh"
```

## create cname record

![[POC-apigw#^d0liwm]]

refer: [link](https://repost.aws/knowledge-center/simple-resource-record-route53-cli) 
sample: [[acm-cmd#create-certificate-]]

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

## refer

- https://serverfault.com/questions/815841/multiple-txt-fields-for-same-subdomain?rq=1
- https://serverfault.com/questions/616407/tried-to-create-2-record-set-type-txt-in-route53
- https://www.learnaws.org/2022/02/04/aws-cli-route53-guide/



