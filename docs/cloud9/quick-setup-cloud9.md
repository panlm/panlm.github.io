---
title: Quick Setup Cloud9
description: 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
created: 2023-08-04 15:56:59.747
last_modified: 2024-04-02
status: myblog
tags:
  - aws/cloud9
  - aws/container/eks
---

# Quick Setup Cloud9 
在 [[setup-cloud9-for-eks]] 基础上进一步简化操作，使用不同方法在 cloud9 中完成所有常用软件安装等初始化操作。推荐：
- 使用 Option 1 使用 Cloudformation 自动化部署
    - 支持 ubuntu 和 amazon linux 2
- 或者使用 Option 2.1 在 Cloudshell 中复制粘贴脚本即完成初始化
    - 在 ubuntu 中，`sudo` 命令需要包含在 `()` 中，否则可能复制粘贴后无法执行
- 另外可以使用 Option 2.2 在 Cloudshell 中创建 Cloud9 实例，然后登录 Cloud9 完成初始化部署

## Option 1 - create cloud9 with cloudformation template
- download [[example_instancestack_ubuntu.yaml]] 
- 如果 role/panlm 不存在，指定 `ExampleC9EnvOwner` 为 `current`
    - C9 instance owner: role/WSParticipantRole (assumed-role/WSParticipantRole/Participant)
    - AWS managed temporary credentials: <mark style="background: #BBFABBA6;">Enabled</mark>
    - `aws sts get-caller-identity` in cloud9 is owner role
- 如果 role/panlm 存在 (参考[[../CLI/linux/granted-assume|这里]]创建)，可以指定 `ExampleC9EnvOwner` 为 `3rdParty`  设置 Owner 为 role/panlm
    - C9 instance owner: role/panlm (assumed-role/panlm/granted)
    - AWS managed temporary credentials: <mark style="background: #FF5582A6;">Disabled</mark>
    - `aws sts get-caller-identity` in cloud9 is EC2 instance role
- 在 CloudShell 中执行下面脚本
```sh
wget https://panlm.github.io/CLI/functions/func-create-c9-from-cloudshell.sh

```
- [[../CLI/functions/func-create-c9-from-cloudshell.sh|func-create-c9-from-cloudshell]]
```sh title="func-create-c9-from-cloudshell" linenums="1" hl_lines="8-15 22"
--8<-- "docs/CLI/functions/func-create-c9-from-cloudshell.sh"
```
- 如何 share cloud9 实例，可以参考 ([[git/git-mkdocs/CLI/awscli/cloud9-cmd#share-cloud9-with-other-users-]])

- get C9_PID, and disable aws credential in Cloud9 instance.
```sh
C9PID=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[].Outputs[?OutputKey==`C9PID`].OutputValue' --output text)
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
```

## Option 2 - spin up a cloud9 instance with Cloudshell
-  点击[这里](https://console.aws.amazon.com/cloudshell) 运行 cloudshell，执行代码块创建 cloud9 测试环境 (open cloudshell, and then execute following code to create cloud9 environment)
    - 通过 `name` 自定义 cloud9 的名称，如果不指定将自动创建
    - cloud9 将创建在默认 vpc 中第一个公有子网中
    - 等待实例创建完成并获取到 instance_id
- ensure aws region is correct and walkthrough
```sh
aws configure list
export AWS_DEFAULT_REGION AWS_REGION

# name=<give your cloud9 a name>
datestring=$(TZ=CST-8 date +%Y%m%d-%H%M)
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
        --query 'Subnets[?(MapPublicIpOnLaunch==`true`)].SubnetId' \
        --output text \
        --region ${AWS_DEFAULT_REGION} |\
        xargs -n 1 |tail -n 1)
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
    echo "you have no default vpc in ${AWS_DEFAULT_REGION}"
fi

# wait instance could be see from ec2 :D
watch -g -n 2 aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=aws-cloud9-${name}-${C9_ID}" \
    --query "Reservations[].Instances[].InstanceId" --output text

( # needed on ubuntu when sudo
sudo yum install -yq gettext
)

```

### Option 2.1 stay in cloudshell to initiate cloud9 (prefer)
- 代码将从 GitHub 下载：
    - https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/setup-cloud9-for-eks.md
- 代码将完成：
    - 创建角色名为 `ec2-admin-role-*`，添加管理员权限，且允许 4 个其他角色 assume
    - 如果 cloud9 的实例已经有关联的 role，则将 role 添加管理员权限，如果没有则赋予新建的角色
    - 允许 cloud9 的实例被其他 2 个角色使用
    - 重启 cloud9，等待 cloud9 可以被 ssm 访问
    - <mark style="background: #BBFABBA6;">检查脚本存在</mark>，并且创建 ssm 初始化脚本
    - 创建日志组，并使用 ssm 执行初始化脚本
    - 显示登录 cloud9 的 URL
```sh
echo ${C9_ID}
echo ${name}

export AWS_PAGER=""
C9_INST_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=aws-cloud9-${name}-${C9_ID}" \
  --query "Reservations[].Instances[].InstanceId" --output text)
MY_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_NAME=ec2-admin-role-$(TZ=CST-8 date +%Y%m%d-%H%M%S)

# build trust.json
cat > ec2.json <<-EOF
{
  "Effect": "Allow",
  "Principal": {
    "Service": "ec2.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
EOF
STATEMENT_LIST=ec2.json

for i in WSParticipantRole WSOpsRole TeamRole OpsRole ; do
  aws iam get-role --role-name $i >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    envsubst >$i.json <<-EOF
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::${MY_ACCOUNT_ID}:role/$i"
  },
  "Action": "sts:AssumeRole"
}
EOF
    STATEMENT_LIST=$(echo ${STATEMENT_LIST} "$i.json")
  fi
done

jq -n '{Version: "2012-10-17", Statement: [inputs]}' ${STATEMENT_LIST} > trust.json
echo ${STATEMENT_LIST}
rm -f ${STATEMENT_LIST}

# create role
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

instance_profile_arn=$(aws ec2 describe-iam-instance-profile-associations \
  --filter Name=instance-id,Values=$C9_INST_ID \
  --query IamInstanceProfileAssociations[0].IamInstanceProfile.Arn \
  --output text)
if [[ ${instance_profile_arn} == "None" ]]; then
  # create one
  aws iam create-instance-profile --instance-profile-name ${ROLE_NAME} |tee /tmp/inst-profile-$$.1
  sleep 10
  # attach role to it
  aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME} --role-name ${ROLE_NAME}
  sleep 10
  # attach instance profile to ec2
  aws ec2 associate-iam-instance-profile \
    --iam-instance-profile Name=${ROLE_NAME} \
    --instance-id ${C9_INST_ID}
else
  existed_role_name=$(aws iam get-instance-profile \
    --instance-profile-name ${instance_profile_arn##*/} \
    --query 'InstanceProfile.Roles[0].RoleName' \
    --output text)
  aws iam attach-role-policy --role-name ${existed_role_name} \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
fi

# share with other specific user
# cannot use user-arn: arn:aws:iam::${MY_ACCOUNT_ID}:root to share everyone
# cannot assign role to access cloud9, only root/user/assumed-role/federated-user
for i in WSOpsRole/Ops WSParticipantRole/Participant panlm/granted; do
  aws cloud9 create-environment-membership \
    --environment-id ${C9_ID} \
    --user-arn arn:aws:sts::${MY_ACCOUNT_ID}:assumed-role/${i} \
    --permissions read-write
done

# reboot instance, make role effective ASAP
aws ec2 reboot-instances --instance-ids ${C9_INST_ID}

# wait ssm could connect to this instance 
while true ; do
  sleep 60
  CONN_STAT=$(aws ssm get-connection-status \
  --target ${C9_INST_ID} \
  --query "Status" --output text)
  echo ${CONN_STAT}
  if [[ ${CONN_STAT} == 'connected' ]]; then
    break
  fi
done

# script source location:
# https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/script-prep-eks-env-part-one.sh
# check script existed or not
RET_CODE=$(curl -sL -w '%{http_code}' -o /dev/null  https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/script-prep-eks-env-part-one.sh)
if [[ ${RET_CODE} -ne 200 ]]; then
  echo "######"
  echo "###### SCRIPT ONE NOT EXISTED"
  echo "######"
fi

cat >$$.json <<-'EOF'
{
  "workingDirectory": [
    ""
  ],
  "executionTimeout": [
    "3600"
  ],
  "commands": [
    "",
    "TMPFILE=$(mktemp)",
    "curl --location -o ${TMPFILE}-ONE.sh https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/script-prep-eks-env-part-one.sh",
    "chmod a+x ${TMPFILE}-ONE.sh",
    "sudo -u ec2-user bash ${TMPFILE}-ONE.sh 2>&1",
    "",
    "curl --location -o ${TMPFILE}-TWO.sh https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/script-prep-eks-env-part-two.sh",
    "chmod a+x ${TMPFILE}-TWO.sh",
    "sudo -u ec2-user bash ${TMPFILE}-TWO.sh 2>&1",
    ""
  ]
}
EOF

LOGGROUP_NAME=ssm-runshellscript-log-$(TZ=CST-8 date +%Y%m%d-%H%M)
aws logs create-log-group \
  --log-group-name ${LOGGROUP_NAME}

aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --document-version "1" \
  --targets '[{"Key":"InstanceIds","Values":["'${C9_INST_ID}'"]}]' \
  --parameters file://$$.json \
  --timeout-seconds 600 \
  --max-concurrency "50" --max-errors "0"  \
  --cloud-watch-output-config CloudWatchLogGroupName=${LOGGROUP_NAME},CloudWatchOutputEnabled=true |tee ssm-$$.json
# comment "-a" in tee 2023/11/20

# wait to Success
COMMAND_ID=$(cat ssm-$$.json |jq -r '.Command.CommandId')
watch -g -n 10 aws ssm get-command-invocation --command-id ${COMMAND_ID} --instance-id ${C9_INST_ID} --query 'Status' --output text

# disable managed credential and login cloud9
aws cloud9 update-environment  --environment-id $C9_ID --managed-credentials-action DISABLE
echo "https://${AWS_DEFAULT_REGION}.console.aws.amazon.com/cloud9/ide/${C9_ID}"

```


### ~~Option 2.2 login cloud9 to initiate (alternative)~~ 
- 代码将从 GitHub 下载：
    - https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/setup-cloud9-for-eks.md

#### script-part-one-two
- 下面代码块包含一些基本设置，包括：(execute this code block to install tools for your lab, and resize ebs of cloud9)
	- 安装常用的软件
	- 修改 cloud9 磁盘大小 ([docs](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html#move-environment-resize))
- 安装 eks 相关的常用软件 (install some eks related tools)

```sh
TMPFILE=$(mktemp)
curl --location -o $TMPFILE https://github.com/panlm/panlm.github.io/raw/main/docs/cloud9/setup-cloud9-for-eks.md
for i in ONE TWO ; do
  cat $TMPFILE |awk '/###-SCRIPT-PART-'"${i}"'-BEGIN-###/,/###-SCRIPT-PART-'"${i}"'-END-###/ {print}' > $TMPFILE-$i.sh
  chmod a+x $TMPFILE-$i.sh
  sudo -u ec2-user bash $TMPFILE-$i.sh 2>&1
done
```

#### script-part-three
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
sudo -u ec2-user bash $TMPFILE-$i.sh 2>&1

```

## open new tab for verify
- 在 cloud9 中，重新打开一个 terminal 窗口，并验证权限符合预期。上面代码块将创建一个 instance profile ，并将关联名为 `adminrole-xxx` 的 role，或者在 cloud9 现有的 role 上关联 `AdministratorAccess` role policy。(open new tab to verify you have new role, `adminrole-xxx`, on your cloud9)

```sh
aws sts get-caller-identity
```

## refer
- open console from local [[../CLI/linux/granted-assume]] 



