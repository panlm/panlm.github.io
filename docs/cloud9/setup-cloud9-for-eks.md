---
title: Setup Cloud9 for EKS
description: 使用脚本完成实验环境初始化
created: 2022-05-21 12:46:05.435
last_modified: 2024-02-11
status: myblog
tags:
  - aws/container/eks
  - aws/cloud9
---

# Setup Cloud9 for EKS
快速设置 cloud9 用于日常测试环境搭建，包含从 cloudshell 中创建 cloud9 instance，然后登录 cloud9 instance 进行基础软件安装、磁盘大小调整和容器环境相关软件安装。为了更方便配置，在 [[quick-setup-cloud9]] 中，直接可以仅通过 cloudshell 即完成所有初始化动作，登录 cloud9 instance 后就可以开始使用。

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

- 点击输出的 URL 链接，打开 cloud9 测试环境 (click the URL at the bottom to open cloud9 environment)
![IMG-setup-cloud9-for-eks.png](attachments/setup-cloud9-for-eks/IMG-setup-cloud9-for-eks.png)

## using internal proxy or not

- 如果你不需要使用代理服务器下载软件包，跳过执行下面代码 (skip this code block if you do not need proxy in your environment)
```sh
cat >> ~/.bash_profile <<-EOF
export http_proxy=http://10.101.1.55:998
export https_proxy=http://10.101.1.55:998
export NO_PROXY=169.254.169.254,10.0.0.0/8,172.16.0.0/16,192.168.0.0/16
EOF
source ~/.bash_profile

```

## install-in-cloud9- 

- 下面代码块包含一些基本设置，包括：(execute this code block to install tools for your lab, and resize ebs of cloud9)
    - 安装更新常用的软件
    - 修改 cloud9 磁盘大小 ([link](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html#move-environment-resize))

=== "AL2 "

    - [[script-prep-eks-env-part-one.sh]] 
    
    ```sh title="script-prep-eks-env-part-one.sh" linenums="1"
    --8<-- "script-prep-eks-env-part-one.sh"
    ```

=== "ubuntu"

    - [[script-ubuntu-prep-eks-env-part-one.sh]]  
    
    ```sh title="script-ubuntu-prep-eks-env-part-one.sh" linenums="1"
    --8<-- "script-ubuntu-prep-eks-env-part-one.sh"
    ```

- 安装 eks 相关的常用软件 (install some eks related tools)
- for AL2 & ubuntu: [[script-prep-eks-env-part-two.sh]]
```sh title="script-prep-eks-env-part-two.sh" linenums="1"
--8<-- "script-prep-eks-env-part-two.sh"
```

- 直接执行下面代码块可能遇到权限不够的告警，需要：
	- 如果你有 workshop 的 Credentials ，直接先复制粘贴到命令行，再执行下列步骤；(copy and paste your workshop's credential to CLI and then execute this code block)
	- 或者，如果自己账号的 cloud9，先用环境变量方式（`AWS_ACCESS_KEY_ID` 和 `AWS_SECRET_ACCESS_KEY`）保证有足够权限执行 (or using environment variables to export credential yourself)
	- 下面代码块包括：
		- 禁用 cloud9 中的 credential 管理，从 `~/.aws/credentials` 中删除 `aws_session_token=` 行
		- 分配管理员权限 role 到 cloud9 instance
- for AL2: [[script-prep-eks-env-part-three.sh]] 
```sh title="script-prep-eks-env-part-three.sh" linenums="1"
--8<-- "script-prep-eks-env-part-three.sh"
```

- 在 cloud9 中，重新打开一个 terminal 窗口，并验证权限符合预期。上面代码块将创建一个 instance profile ，并将关联名为 `adminrole-xxx` 的 role，或者在 cloud9 现有的 role 上关联 `AdministratorAccess` role policy。(open new tab to verify you have new role, `adminrole-xxx`, on your cloud9)
```sh
aws sts get-caller-identity
```


## reference

- https://docs.amazonaws.cn/en_us/eks/latest/userguide/install-aws-iam-authenticator.html
- [[switch-role-to-create-dedicate-cloud9]]


