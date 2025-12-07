---
title: route53
description: 常用命令
created: 2022-09-20 09:02:35.112
last_modified: 2024-03-13
tags:
  - aws/network/route53
---

# route53-cmd
## func-create-hosted-zone-
- 执行下面命令创建 Hosted Zone，然后手工添加 NS 记录到上游的域名服务器 domain registrar 中 (create hosted zone, and then add NS records to upstream domain registrar)
- [[../functions/func-create-hosted-zone.sh|func-create-hosted-zone]] 
```sh title="func-create-hosted-zone" linenums="1"
--8<-- "docs/CLI/functions/func-create-hosted-zone.sh"
```

## func-create-ns-record-
- create host zone in your child account and get NS (previous chapter)
- [[../linux/granted-assume|assume]] to your parent account to execute this function to add NS record to upstream route53 host zone
    - or export your AWS_PROFILE
- [[../functions/func-create-ns-record.sh|func-create-ns-record]]
```sh title="func-create-ns-record" linenums="1"
--8<-- "docs/CLI/functions/func-create-ns-record.sh"
```

## func-create-outbound-resolver-

```sh
function create-outbound-resolver () {
    OPTIND=1
    OPTSTRING="h?s:"
    local SG_ID=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            s) SG_ID=${OPTARG} ;;
            h|\?) 
                echo "format: create-outbound-resolver -s security_group_id "
                echo -e "\tsample: create-outbound-resolver -s sg-xxx "
                return 0
            ;;
        esac
    done
    : ${SG_ID:?Missing -s}

    # find 2 subnet id in vpc
    

    # RANDOM
    REQUEST_ID=$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
    aws route53resolver create-resolver-endpoint \
        --creator-request-id ${REQUEST_ID} \
        --name my-outbound-endpoint \
        --security-group-ids ${SG_ID} \
        --direction OUTBOUND \
        --ip-addresses SubnetId=${SUBNET_ID[0]} SubnetId=${SUBNET_ID[1]}  \
        --resolver-endpoint-type IPV4 \
        --protocols "Do53" "DoH"

}
```

## create cname record

![[../../../../gitlab/handover/C-MK/apigw/POC-apigw-dataflow#^d0liwm]]

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



