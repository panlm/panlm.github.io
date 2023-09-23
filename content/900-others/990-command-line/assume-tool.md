---
title: assume-tool
description: assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
chapter: true
hidden: false
created: 2023-09-15 09:40:01.442
last_modified: 2023-09-15 09:40:01.442
tags:
- cmd 
- aws/security/iam 
---

```ad-attention
title: This is a github note

```

# assume-tool

- [create role for account](#create-role-for-account)
- [install](#install)
- [refer](#refer)



## modify role for account to assume

- login from macbook CLI
- modify existed role for login - WSParticipantRole
- create aws credential entities

```sh
assume panlm

echo ${AWS_ACCESS_KEY_ID} 
echo ${AWS_SECRET_ACCESS_KEY}
echo ${AWS_SESSION_TOKEN}

echo ${WS_NAME:=$(TZ=EAT-8 date +%Y%m%d)}

aws sts get-caller-identity

```

```sh
ACCOUNT_ID=$(GRANTED_QUIET=true . assume panlm --exec "aws sts get-caller-identity" |jq -r '.Account')
ROLE_NAME="WSParticipantRole"

TEMP=$(mktemp)
aws iam get-role --role-name ${ROLE_NAME} --output json > ${TEMP}.1
cat ${TEMP}.1 |jq '.Role.AssumeRolePolicyDocument.Statement[0].Principal.AWS += ["arn:aws:iam::'"${ACCOUNT_ID}"':root"]' |jq -r '.Role.AssumeRolePolicyDocument' |tee ${TEMP}.2
aws iam update-assume-role-policy --role-name ${ROLE_NAME} \
  --policy-document file://${TEMP}.2
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
ROLE_ARN=$(cat ${TEMP}.1 |jq -r '.Role.Arn')

CREDENTIAL_ENTITY_NAME="0-ws-${WS_NAME}"
echo '['"$CREDENTIAL_ENTITY_NAME"']' >> ~/.aws/credentials
echo 'role_arn='${ROLE_ARN} >> ~/.aws/credentials
echo 'source_profile=panlm' >> ~/.aws/credentials
echo 'role_session_name=granted' >> ~/.aws/credentials
echo 'region=us-east-2' >> ~/.aws/credentials
echo ''
echo ${CREDENTIAL_ENTITY_NAME}

```


## create role for account to assume

```sh
ACCOUNT_ID=$(GRANTED_QUIET=true . assume panlm --exec "aws sts get-caller-identity" |jq -r '.Account')
ROLE_NAME=WSAdminRole
envsubst > /tmp/${ROLE_NAME}-trust.json <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
}
EOF
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file:///tmp/${ROLE_NAME}-trust.json \
  --max-session-duration 43200 |tee /tmp/${ROLE_NAME}-role.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
ROLE_ARN=$(cat /tmp/${ROLE_NAME}-role.json |jq -r '.Role.Arn')

```



## install
https://docs.commonfate.io/granted/getting-started#installing-the-cli

## refer
https://docs.commonfate.io/granted/introduction

