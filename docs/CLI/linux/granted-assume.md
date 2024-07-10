---
title: assume
description: assume 工具，可以以另一个账号角色，快速打开 web console，或者执行命令
created: 2023-09-15 09:40:01.442
last_modified: 2024-02-12
status: myblog
tags:
  - cmd
  - aws/security/iam
---

# assume
## create role for account to assume
```sh title="create-aws-config-entity" linenums="1"
function create-aws-config-entity () {
echo WS_NAME=$(TZ=EAT-8 date +%Y%m%d-%H%M)
ACCOUNT_ID=$(GRANTED_QUIET=true . assume panlm --exec "aws sts get-caller-identity" |jq -r '.Account')
LOCAL_ACCOUNT_ID=$(aws sts get-caller-identity |jq -r '.Account')
ROLE_NAME=panlm # easy for remeber and switch from WSParticipantRole
envsubst > /tmp/${ROLE_NAME}-trust.json <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${ACCOUNT_ID}:root",
                    "arn:aws:iam::${LOCAL_ACCOUNT_ID}:root"
                ]
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

CREDENTIAL_ENTITY_NAME="0-ws-${WS_NAME}"
envsubst >> ~/.aws/config <<-EOF
[profile $CREDENTIAL_ENTITY_NAME]
role_arn=${ROLE_ARN}
source_profile=panlm
role_session_name=granted
region=us-east-2
EOF
echo ${CREDENTIAL_ENTITY_NAME}
}
```


## modify role for account to assume :material-delete:
- DEPRECATED due to new SCP policy do not allow to modify WSParticipantRole's trust policy
- login from macbook CLI
- modify existed role for login - WSParticipantRole
- create aws credential entities

```sh
assume panlm

echo ${AWS_ACCESS_KEY_ID} 
echo ${AWS_SECRET_ACCESS_KEY}
echo ${AWS_SESSION_TOKEN}

aws sts get-caller-identity
```

```sh
echo ${WS_NAME:=$(TZ=EAT-8 date +%Y%m%d)}
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


## install on mac
- https://docs.commonfate.io/granted/getting-started#installing-the-cli
```sh
brew tap common-fate/granted
brew install granted
```

- ~~still has issue until 0.20.7~~
```sh
VERSION=0.20.3
curl -OL https://releases.commonfate.io/granted/v${VERSION}/granted_${VERSION}_darwin_x86_64.tar.gz
tar -zxvf ./granted_${VERSION}_darwin_x86_64.tar.gz -C /usr/local/bin/

rm -f /usr/local/bin/assumego
ln -s /usr/local/bin/granted /usr/local/bin/assumego
```

### import existed credentials to mac `login` keychain
```sh
granted credentials import example
```

![[attachments/granted-assume/IMG-granted-assume.png]]

### export to aws credentials file
- This command can be used to return your credentials to the original insecure plaintext format in the AWS credentials file.
```sh
granted credentials export-plaintext example
```


## refer
- https://docs.commonfate.io/granted/introduction
- https://awsu.me/




