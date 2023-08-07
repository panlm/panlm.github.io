---
title: quick-setup-cloud9-script
description: 简化运行脚本
weight: 21
chapter: true
created: 2023-08-04 15:56:59.747
last_modified: 2023-08-04 15:56:59.747
tags: 
- aws/cloud9 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# quick-setup-cloud9-script

- [spin-up-a-cloud9-instance-in-your-region](#spin-up-a-cloud9-instance-in-your-region)
- [script-part-one-two](#script-part-one-two)
- [script-part-three](#script-part-three)
- [open new tab for verify](#open-new-tab-for-verify)


## spin-up-a-cloud9-instance-in-your-region

-  点击[这里](https://console.aws.amazon.com/cloudshell) 运行 cloudshell，执行代码块创建 cloud9 测试环境 (open cloudshell, and then execute following code to create cloud9 environment)
```sh
# name=<give your cloud9 a name>
datestring=$(date +%Y%m%d-%H%M)
echo ${name:=cloud9-$datestring}

# VPC_ID=<your vpc id> 
# ensure you have public subnet in it
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --filter Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text \
  --region ${AWS_DEFAULT_REGION})
VPC_ID=${VPC_ID:=$DEFAULT_VPC_ID}

if [[ ! -z ${VPC_ID} ]]; then
  FIRST_SUBNET=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[?(AvailabilityZone==`'"${AWS_DEFAULT_REGION}a"'` && MapPublicIpOnLaunch==`true`)].SubnetId' \
    --output text \
    --region ${AWS_DEFAULT_REGION})
  aws cloud9 create-environment-ec2 \
    --name ${name} \
    --image-id amazonlinux-2-x86_64 \
    --instance-type m5.large \
    --subnet-id ${FIRST_SUBNET%% *} \
    --automatic-stop-time-minutes 10080 \
    --region ${AWS_DEFAULT_REGION} |tee /tmp/$$
  echo "Open URL to access your Cloud9 Environment:"
  C9_ID=$(cat /tmp/$$ |jq -r '.environmentId')
  echo "https://${AWS_DEFAULT_REGION}.console.aws.amazon.com/cloud9/ide/${C9_ID}"
else
  echo "you have no default vpc in $AWS_DEFAULT_REGION"
fi

```

## script-part-one-two

- 下面代码块包含一些基本设置，包括：(execute this code block to install tools for your lab, and resize ebs of cloud9)
	- 安装常用的软件
	- 修改 cloud9 磁盘大小 ([link](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html#move-environment-resize))
- 安装 eks 相关的常用软件 (install some eks related tools)

```sh
TMPFILE=$(mktemp)
curl --location -o $TMPFILE https://github.com/panlm/panlm.github.io/raw/main/content/20-cloud9/setup-cloud9-for-eks.md
for i in ONE TWO ; do
cat $TMPFILE |awk '/###-SCRIPT-PART-'"${i}"'-BEGIN-###/,/###-SCRIPT-PART-'"${i}"'-END-###/ {print}' > $TMPFILE-$i.sh
chmod a+x $TMPFILE-$i.sh
$TMPFILE-$i.sh
done

```

## script-part-three

- 直接执行下面代码块可能遇到权限不够的告警，需要：
	- 如果你有 workshop 的 Credentials ，直接先复制粘贴到命令行，再执行下列步骤；(copy and paste your workshop's credential to CLI and then execute this code block)
	- 或者，如果自己账号的 cloud9，先用环境变量方式（`AWS_ACCESS_KEY_ID` 和 `AWS_SECRET_ACCESS_KEY`）保证有足够权限执行 (or using environment variables to export credential yourself)
	- 下面代码块包括：
		- 禁用 cloud9 中的 credential 管理，从 `~/.aws/credentials` 中删除 `aws_session_token=` 行
		- 分配管理员权限 role 到 cloud9 instance

```sh
i=THREE
cat $TMPFILE |awk "/###-SCRIPT-PART-${i}-BEGIN-###/,/###-SCRIPT-PART-${i}-END-###/ {print}" > $TMPFILE-$i.sh
chmod a+x $TMPFILE-$i.sh
$TMPFILE-$i.sh

```

## open new tab for verify

- 在 cloud9 中，重新打开一个 terminal 窗口，并验证权限符合预期。上面代码块将创建一个 instance profile ，并将关联名为 `adminrole-xxx` 的 role，或者在 cloud9 现有的 role 上关联 `AdministratorAccess` role policy。(open new tab to verify you have new role, `adminrole-xxx`, on your cloud9)

```sh
aws sts get-caller-identity
```


