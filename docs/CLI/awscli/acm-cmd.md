---
title: acm
description: 常用命令
created: 2023-03-15 11:58:12.994
last_modified: 2024-02-05
icon: simple/amazonaws
tags:
  - aws/cmd
  - aws/security/acm
---

# acm-cmd
## create-certificate-with-eksdemo-
- https://github.com/awslabs/eksdemo/blob/main/docs/create-acm-cert.md
```sh
echo ${DOMAIN_NAME}
echo ${AWS_REGION}

eksdemo create acm-certificate "*.${DOMAIN_NAME}" --region ${AWS_REGION}
# eksdemo get hosted-zone
# eksdemo get dns-records -z poc1009.aws.panlm.xyz

eksdemo get acm-certificate # get certificate arn 

```
^kresvp

## create-certificate-
- 创建并通过添加 dns 记录验证证书 (create certificate with DNS verification)
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

- 等待状态转变成 SUCCESS (wait ValidationStatus to SUCCESS)
```sh
# wait ValidationStatus to SUCCESS
aws acm describe-certificate \
--certificate-arn ${CERTIFICATE_ARN} \
--query 'Certificate.DomainValidationOptions[0]' 

```

## create certificate with pca  cross account
```sh
PCA_ARN=arn:aws:acm-pca:us-east-2:xxxxxx:certificate-authority/xxxxxx
aws acm request-certificate \
--domain-name '*.api0320.aws.panlm.xyz' \
--validation-method DNS \
--certificate-authority-arn ${PCA_ARN}

```


## list certificate by domain name
```sh
echo $DOMAIN_NAME
CERTIFICATE_ARN=$(aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`*.'"${DOMAIN_NAME}"'`].CertificateArn' --output text)

```


