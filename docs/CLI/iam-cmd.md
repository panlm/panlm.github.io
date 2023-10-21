---
title: iam
description: 常用命令
chapter: true
hidden: true
created: 2021-07-18T01:04:47.248Z
modified: 2021-12-07T01:23:23.127Z
tags:
  - aws/security/iam
  - aws/cmd
---

```ad-attention
title: This is a github note

```

# iam cmd

## get role arn by name

```sh
aws iam get-role --role-name ${role_name} --query 'Role.Arn' --output text
```

## get policy arn

```sh
aws iam list-policies --query 'Policies[*].[PolicyName,Arn]' --output text |grep CloudWatchAgentServerPolicy
aws iam get-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

## create user 

```sh
aws iam create-user --user-name cwagent-onprem
# attach user policy
aws iam attach-user-policy --user-name cwagent-onprem --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
# create access key, save the output
aws iam create-access-key --user-name cwagent-onprem
```

## attach role policy

[[../others/file-storage-gateway-lab#create-nfs-share-📚]]

## create role

```shell
ROLE_NAME=example-role1
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "translate.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' |tee role-policy.json
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://role-policy.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
aws iam list-attached-role-policies --role-name ${ROLE_NAME}

role_arn=$(aws iam get-role --role-name ${ROLE_NAME} |jq -r '.Role.Arn')

```

### create role for ec2

```sh
ROLE_NAME=adminrole-$RANDOM
cat > trust.json <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}
aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME} --role-name ${ROLE_NAME}


```

### create role for firehose

- [[../EKS/operation/logging/stream-k8s-control-panel-logs-to-s3#lambda]]

### create role for api gateway

- [[apigw-cmd#create-apigw-role-]]


### create role for account

- [[assume-tool]]


### create service-linked role

```sh
aws iam create-service-linked-role --aws-service-name SERVICE-NAME.amazonaws.com
```

## assume another role

```sh
account_id=$(aws sts get-caller-identity \
  --query 'Account' --output text)
role_arn=arn:aws:iam::${account_id}:role/eksworkshop-admin
tmp_file=/tmp/$$.1

aws sts assume-role --role-arn ${role_arn} \
  --duration-seconds 43200 \
  --role-session-name Session-$RANDOM |tee ${tmp_file}

export AWS_ACCESS_KEY_ID=$(cat ${tmp_file} |jq -r '.Credentials.AccessKeyId' )
export AWS_SECRET_ACCESS_KEY=$(cat ${tmp_file} |jq -r '.Credentials.SecretAccessKey' )
export AWS_SESSION_TOKEN=$(cat ${tmp_file} |jq -r '.Credentials.SessionToken' )
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

```

### assume in credentials file

https://docs.aws.amazon.com/sdkref/latest/guide/feature-assume-role-credentials.html
```txt
[profile A]
source_profile = B
role_arn =  arn:aws:iam::123456789012:role/RoleA
                
[profile B]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

```


## reference
?
- [如何提供对 Amazon S3 存储桶中的对象的跨账户访问权限](https://aws.amazon.com/cn/premiumsupport/knowledge-center/cross-account-access-s3/)
- [策略评估逻辑](https://docs.aws.amazon.com/zh_cn/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_multi-value-conditions.html




