---
title: route53
description: 常用命令
created: 2022-09-20 09:02:35.112
last_modified: 2023-11-18
tags:
  - aws/network/route53
---
> [!WARNING] This is a github note

# route53-cmd

## create hosted zone

![[../../EKS/infra/network/externaldns-for-route53#^fgvqjb]]

refer: [[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#setup-hosted-zone-]]

## create-ns-record-

- create host zone in your child account and get NS (previous chapter)
- [[../linux/assume-tool|assume]] to your parent account to add NS record to route53 host zone
```sh
DOMAIN_NAME=poc1029.aws.panlm.xyz
NS='ns-1716.awsdns-22.co.uk.
ns-934.awsdns-52.net.
ns-114.awsdns-14.com.
ns-1223.awsdns-24.org.
'

PARENT_DOMAIN_NAME=${DOMAIN_NAME#*.}
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
--dns-name "${PARENT_DOMAIN_NAME}." \
--query HostedZones[0].Id --output text)

envsubst >ns-route53-record.json <<-EOF
{
  "Comment": "UPSERT a record for poc.xxx.com ",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
        ]
      }
    }
  ]
}
EOF

for i in ${NS}; do
    cat ns-route53-record.json |jq '.Changes[0].ResourceRecordSet.ResourceRecords += [{"Value": "'"${i}"'"}]' \
        |tee ns-route53-record-tmp.json
    mv -f ns-route53-record-tmp.json ns-route53-record.json
done

aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file://ns-route53-record.json

aws route53 list-resource-record-sets --hosted-zone-id ${ZONE_ID} --query "ResourceRecordSets[?Name == '${DOMAIN_NAME}.']"

```

## create cname record-

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



