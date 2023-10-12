---
title: quick-setup-cloud9-script
description: 简化运行脚本
weight: 5
chapter: true
created: 2023-08-04 15:56:59.747
last_modified: 2023-10-12 13:00:17.583
tags:
  - aws/cloud9
  - aws/container/eks
---

```ad-attention
title: This is a github note

```

# quick-setup-cloud9-script

- [spin-up-a-cloud9-instance-in-your-region](#spin-up-a-cloud9-instance-in-your-region)
	- [(prefer) stay in cloudshell to initiate cloud9](#(prefer)%20stay%20in%20cloudshell%20to%20initiate%20cloud9)
	- [(alternative) login cloud9 to initiate](#(alternative)%20login%20cloud9%20to%20initiate)
		- [script-part-one-two](#script-part-one-two)
		- [script-part-three](#script-part-three)
- [open new tab for verify](#open%20new%20tab%20for%20verify)
- [refer](#refer)


## spin-up-a-cloud9-instance-in-your-region

-  点击[这里](https://console.aws.amazon.com/cloudshell) 运行 cloudshell，执行代码块创建 cloud9 测试环境 (open cloudshell, and then execute following code to create cloud9 environment)
    - 通过 `name` 自定义 cloud9 的名称，如果不指定将自动创建
    - cloud9 将创建在默认 vpc 中第一个公有子网中
    - 等待实例创建完成并获取到 instance_id
```sh
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
    echo "you have no default vpc in ${AWS_DEFAULT_REGION}"
fi

# wait instance could be see from ec2 :D
watch -g -n 2 aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=aws-cloud9-${name}-${C9_ID}" \
    --query "Reservations[].Instances[].InstanceId" --output text

```

### (prefer) stay in cloudshell to initiate cloud9

- 下面代码将完成：
    - 创建角色名为 `ec2-admin-role-*`，添加管理员权限，且允许 4 个其他角色 assume
    - 如果 cloud9 的实例已经有关联的 role，则将 role 添加管理员权限，如果没有则赋予新建的角色
    - 允许 cloud9 的实例被其他 2 个角色使用
    - 等待 cloud9 可以被 ssm 访问
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

sudo yum install -y gettext

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

for i in WSOpsRole/Ops WSParticipantRole/Participant; do
    aws cloud9 create-environment-membership \
        --environment-id ${C9_ID} \
        --user-arn arn:aws:sts::${MY_ACCOUNT_ID}:assumed-role/${i} \
        --permissions read-write
done

# wait ssm could connect to this instance (5 mins)
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
    "curl --location -o $TMPFILE https://github.com/panlm/panlm.github.io/raw/main/content/20-cloud9/setup-cloud9-for-eks.md",
    "cat $TMPFILE |awk '/###-SCRIPT-PART-ONE-BEGIN-###/,/###-SCRIPT-PART-ONE-END-###/ {print}' > $TMPFILE-ONE.sh",
    "chmod a+x $TMPFILE-ONE.sh",
    "sudo -u ec2-user bash $TMPFILE-ONE.sh 2>&1",
    "",
    "cat $TMPFILE |awk '/###-SCRIPT-PART-TWO-BEGIN-###/,/###-SCRIPT-PART-TWO-END-###/ {print}' > $TMPFILE-TWO.sh",
    "chmod a+x $TMPFILE-TWO.sh",
    "sudo -u ec2-user bash $TMPFILE-TWO.sh 2>&1",
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
    --cloud-watch-output-config CloudWatchLogGroupName=${LOGGROUP_NAME},CloudWatchOutputEnabled=true |tee -a ssm-$$.json

# wait to Success
COMMAND_ID=$(cat ssm-$$.json |jq -r '.Command.CommandId')
watch -g -n 10 aws ssm get-command-invocation --command-id ${COMMAND_ID} --instance-id ${C9_INST_ID} --query 'Status' --output text

# disable managed credential and login cloud9
aws cloud9 update-environment  --environment-id $C9_ID --managed-credentials-action DISABLE
echo "https://${AWS_DEFAULT_REGION}.console.aws.amazon.com/cloud9/ide/${C9_ID}"

```


### (alternative) login cloud9 to initiate
#### script-part-one-two

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
- open console from local [[assume-tool]] (or [hugo]({{< ref assume-tool >}})) ([../900-others/990-command-line/assume-tool|assume-tool](../900-others/990-command-line/assume-tool%7Cassume-tool.md))



