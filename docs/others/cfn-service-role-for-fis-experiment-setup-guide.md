---
title: cfn-service-role-for-fis-experiment-setup-guide
description: 使用cloudformation服务角色实现最小化权限
type: note
permalink: git-mkdocs/others/cfn-service-role-for-fis-experiment-setup-guide
share_link: https://notes-share.aws.panlm.click/3qvt83ae
share_updated: 2026-04-02T20:04:26+08:00
---

# FIS 实验环境权限配置指南

> **目的：** 为 EC2 实例配置最小权限，使其能通过 CloudFormation 部署 FIS 实验相关资源（IAM Role、FIS 实验模板、CloudWatch Dashboard），而 EC2 自身无需拥有 IAM/FIS/CloudWatch 写入权限。
>
> **原理：** 采用 [CloudFormation Service Role](https://docs.aws.amazon.com/prescriptive-guidance/latest/least-privilege-cloudformation/service-roles-for-cloudformation.html) 模式，将资源创建权限委托给 CFN Service Role，EC2 只需 `iam:PassRole` 将该角色传递给 CloudFormation。

---

## 架构说明

```
EC2 Instance Profile                    CFN Service Role
┌─────────────────────┐                ┌──────────────────────────────┐
│ - cloudformation:*  │  --PassRole--> │ Trust: cloudformation.amazonaws.com │
│ - iam:PassRole      │                │ - iam:CreateRole/DeleteRole  │
│ - 只读权限 (已有)    │                │ - fis:Create/DeleteTemplate  │
│                     │                │ - cloudwatch:Put/Delete      │
└─────────────────────┘                └──────────────────────────────┘
```

---

## 一、CFN Service Role（需管理员创建，一次性）

### 1.1 信任策略（Trust Policy）

只允许 CloudFormation 服务 assume 此角色：

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudformation.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### 1.2 权限策略（Permissions Policy）

此策略授予 CloudFormation 创建 FIS 实验所需的所有资源权限，通过资源名称前缀限制作用范围：

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IAMRoleManagement",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:TagRole",
                "iam:UntagRole"
            ],
            "Resource": "arn:aws:iam::123456789012:role/*"
        },
        {
            "Sid": "IAMPassRoleToFIS",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::123456789012:role/*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "fis.amazonaws.com"
                }
            }
        },
        {
            "Sid": "FISFullAccess",
            "Effect": "Allow",
            "Action": "fis:*",
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchFullAccess",
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        }
    ]
}
```

### 1.3 创建命令

```bash
# 1. 创建角色
aws iam create-role \
    --role-name CFN-ServiceRole-FIS \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "cloudformation.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' \
    --description "CloudFormation Service Role for FIS experiment deployment"

# 2. 附加权限策略（将上面 1.2 的 JSON 保存为 cfn-service-role-policy.json）
aws iam put-role-policy \
    --role-name CFN-ServiceRole-FIS \
    --policy-name FISDeploymentPolicy \
    --policy-document file://cfn-service-role-policy.json
```

---

## 二、EC2 Instance Profile 附加策略

以下策略需要附加到 EC2 实例的 Instance Profile 角色上。EC2 已有的只读权限保持不变，仅需**额外添加**此策略：

> **注意：** `cloudformation:RoleArn` 条件键仅对 `CreateStack`/`UpdateStack`/`DeleteStack` 有效，
> `CreateChangeSet`/`ExecuteChangeSet` 等操作不支持此条件键，因此需要拆分为两个 Statement。
> `CreateStack`/`UpdateStack`/`DeleteStack` 通过条件键强制必须使用指定的 Service Role，
> 而 ChangeSet 操作本身不会直接创建资源（资源创建由关联的 Stack 操作完成，受条件键约束）。

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudFormationWithRoleCondition",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:UpdateStack",
                "cloudformation:DeleteStack"
            ],
            "Resource": "arn:aws:cloudformation:us-west-2:123456789012:stack/*/*",
            "Condition": {
                "StringEquals": {
                    "cloudformation:RoleArn": "arn:aws:iam::123456789012:role/CFN-ServiceRole-FIS"
                }
            }
        },
        {
            "Sid": "CloudFormationChangeSetAndDescribe",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeStacks",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeChangeSet",
                "cloudformation:GetTemplate",
                "cloudformation:ListStacks"
            ],
            "Resource": "arn:aws:cloudformation:us-west-2:123456789012:stack/*/*"
        },
        {
            "Sid": "CloudFormationValidateAny",
            "Effect": "Allow",
            "Action": "cloudformation:ValidateTemplate",
            "Resource": "*"
        },
        {
            "Sid": "PassCFNServiceRole",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::123456789012:role/CFN-ServiceRole-FIS",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "cloudformation.amazonaws.com"
                }
            }
        },
        {
            "Sid": "FISExperimentExecution",
            "Effect": "Allow",
            "Action": [
                "fis:StartExperiment",
                "fis:StopExperiment",
                "fis:GetExperiment",
                "fis:ListExperiments"
            ],
            "Resource": "*"
        }
    ]
}
```

### 附加命令

```bash
# 将上面的 JSON 保存为 ec2-fis-cfn-policy.json，然后附加到 EC2 Instance Profile 的角色上
# 替换 <EC2_ROLE_NAME> 为实际的 EC2 Instance Profile 角色名

aws iam put-role-policy \
    --role-name <EC2_ROLE_NAME> \
    --policy-name FIS-CloudFormation-Access \
    --policy-document file://ec2-fis-cfn-policy.json
```

---

## 三、使用方式

管理员完成上述配置后，EC2 上部署 FIS 实验时需在 `aws cloudformation deploy` 命令中指定 `--role-arn`：

```bash
aws cloudformation deploy \
    --template-file cfn-template.yaml \
    --stack-name fis-rds-reboot-demo-mysql-xxxxx \
    --role-arn arn:aws:iam::123456789012:role/CFN-ServiceRole-FIS \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-west-2
```

---

## 四、安全约束总结

| 约束项 | 实现方式 |
|-------|---------|
| EC2 无 IAM/CloudWatch 写入权限 | 所有 IAM/CW 操作由 CFN Service Role 执行 |
| EC2 可直接执行 FIS 实验 | `fis:StartExperiment`/`StopExperiment` 等执行权限 |
| EC2 只能用指定的 Service Role 部署 | `cloudformation:RoleArn` 条件键限制 |
| CFN Service Role 只能创建 FIS 相关角色 | IAM 资源 ARN 限定 `*` |
| CFN Service Role 只能被 CloudFormation 使用 | 信任策略仅允许 `cloudformation.amazonaws.com` |
| CloudWatch 完全访问 | CFN Service Role 附加 `cloudwatch:*` |

---

## 五、清理

如需撤销此配置：

```bash
# 1. 删除 EC2 上的附加策略
aws iam delete-role-policy --role-name <EC2_ROLE_NAME> --policy-name FIS-CloudFormation-Access

# 2. 删除 CFN Service Role
aws iam delete-role-policy --role-name CFN-ServiceRole-FIS --policy-name FISDeploymentPolicy
aws iam delete-role --role-name CFN-ServiceRole-FIS
```