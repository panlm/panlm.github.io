---
title: acm-cmd
description: 常用命令 
chapter: true
created: 2023-03-15 11:58:12.994
last_modified: 2023-03-15 11:58:12.994
tags: 
- aws/cmd 
- aws/security/acm 
- todo 
---
```ad-attention
title: This is a github note

```
# acm-cmd

## create-certificate-📚

- 创建并通过 dns 验证证书
```sh
echo ${DOMAIN_NAME}
# DOMAIN_NAME=api0413.aws.panlm.xyz

CERTIFICATE_ARN=$(aws acm request-certificate \
--domain-name "*.${DOMAIN_NAME}" \
--validation-method DNS \
--query 'CertificateArn' --output text)

sleep 10
aws acm describe-certificate --certificate-arn ${CERTIFICATE_ARN} |tee /tmp/acm.$$.1
CERT_CNAME_NAME=$(cat /tmp/acm.$$.1 |jq -r '.Certificate.DomainValidationOptions[0].ResourceRecord.Name')
CERT_CNAME_VALUE=$(cat /tmp/acm.$$.1 |jq -r '.Certificate.DomainValidationOptions[0].ResourceRecord.Value')

envsubst >certificate-route53-record.json <<-EOF
{
  "Comment": "UPSERT a record for certificate xxx ",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${CERT_CNAME_NAME}",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "${CERT_CNAME_VALUE}"
          }
        ]
      }
    }
  ]
}
EOF

ZONE_ID=$(aws route53 list-hosted-zones-by-name \
--dns-name "${DOMAIN_NAME}." \
--query HostedZones[0].Id --output text) 
aws route53 change-resource-record-sets \
--hosted-zone-id ${ZONE_ID} \
--change-batch file://certificate-route53-record.json 
aws route53 list-resource-record-sets \
--hosted-zone-id ${ZONE_ID} \
--query "ResourceRecordSets[?Name == '${CERT_CNAME_NAME}']"

```

## create certificate with pca  cross account

```sh
PCA_ARN=arn:aws:acm-pca:us-east-2:xxxxxx:certificate-authority/xxxxxx
aws acm request-certificate \
--domain-name '*.api0320.aws.panlm.xyz' \
--validation-method DNS \
--certificate-authority-arn ${PCA_ARN}

```





