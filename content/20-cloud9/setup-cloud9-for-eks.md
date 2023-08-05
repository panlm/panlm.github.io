---
title: "setup-cloud9-for-eks"
description: "使用 cloud9 作为实验环境"
chapter: true
weight: 10
created: 2022-05-21 12:46:05.435
last_modified: 2022-11-20 11:28:25.928
tags: 
- aws/container/eks
- aws/cloud9
---

```ad-attention
title: This is a github note

```

# setup-cloud9-for-eks

- [spin-up-a-cloud9-instance-in-your-region](#spin-up-a-cloud9-instance-in-your-region)
- [using internal proxy or not](#using-internal-proxy-or-not)
- [install in cloud9](#install-in-cloud9)
- [reference](#reference)


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

^xzcvy9

- 点击输出的 URL 链接，打开 cloud9 测试环境 (click the URL at the bottom to open cloud9 environment)
![](setup-cloud9-for-eks-1.png)

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

## install in cloud9 

- 下面代码块包含一些基本设置，包括：(execute this code block to install tools for your lab, and resize ebs of cloud9)
	- 安装常用的软件
	 - 修改 cloud9 磁盘大小 ([link](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html#move-environment-resize))
```sh
###-SCRIPT-PART-ONE-BEGIN-###
# set size as your expectation, otherwize 100g as default volume size
# size=200

# install others
sudo yum -y install jq gettext bash-completion moreutils wget

# install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
echo A |unzip awscliv2.zip
sudo ./aws/install --update
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bash_profile

# remove existed aws
if [[ $? -eq 0 ]]; then
  sudo yum remove -y awscli
  source ~/.bash_profile
  aws --version
fi

# install ssm session plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm

# your default region 
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

if [[ -c /dev/nvme0 ]]; then
  wget -qO- https://github.com/amazonlinux/amazon-ec2-utils/raw/main/ebsnvme-id >/tmp/ebsnvme-id
  VOLUME_ID=$(sudo python3 /tmp/ebsnvme-id -v /dev/nvme0 |awk '{print $NF}')
  DEVICE_NAME=/dev/nvme0n1
else
  C9_INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
  VOLUME_ID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=${C9_INST_ID} --query "Volumes[0].VolumeId" --output text)
  DEVICE_NAME=/dev/xvda
fi

aws ec2 modify-volume --volume-id ${VOLUME_ID} --size ${size:-100}
sleep 10
sudo growpart ${DEVICE_NAME} 1
sudo xfs_growfs -d /

if [[ $? -eq 1 ]]; then
  ROOT_PART=$(df |grep -w / |awk '{print $1}')
  sudo resize2fs ${ROOT_PART}
fi
###-SCRIPT-PART-ONE-END-###
```

- 安装 eks 相关的常用软件 (install some eks related tools)
```sh
###-SCRIPT-PART-TWO-BEGIN-###
# install kubectl with +/- 1 cluster version 1.25.12 / 1.26.7 / 1.27.4
# refer: https://kubernetes.io/releases/
# sudo curl --location -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo curl --silent --location -o /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v1.25.12/bin/linux/amd64/kubectl"
sudo chmod +x /usr/local/bin/kubectl

kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
alias k=kubectl 
complete -F __start_kubectl k
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# install eksctl
# consider install eksctl version 0.89.0
# if you have older version yaml 
# https://eksctl.io/announcements/nodegroup-override-announcement/
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# helm newest version (3.10.3)
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
# helm 3.8.2 (helm 3.9.0 will have issue #10975)
# wget https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz
# tar xf helm-v3.8.2-linux-amd64.tar.gz
# sudo mv linux-amd64/helm /usr/local/bin/helm
helm version --short

# install aws-iam-authenticator 0.5.12 
wget -O aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.12/aws-iam-authenticator_0.5.12_linux_amd64
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/local/bin/

# install kube-no-trouble
sh -c "$(curl -sSL https://git.io/install-kubent)"

# install kubectl convert plugin
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"
echo "$(cat kubectl-convert.sha256) kubectl-convert" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
rm kubectl-convert kubectl-convert.sha256

# option install jwt-cli
# https://github.com/mike-engel/jwt-cli/blob/main/README.md
# sudo yum -y install cargo
# cargo install jwt-cli
# sudo ln -sf ~/.cargo/bin/jwt /usr/local/bin/jwt

# install flux & fluxctl
curl -s https://fluxcd.io/install.sh | sudo -E bash
flux -v
. <(flux completion bash)

# sudo wget -O /usr/local/bin/fluxctl $(curl https://api.github.com/repos/fluxcd/flux/releases/latest | jq -r ".assets[] | select(.name | test(\"linux_amd64\")) | .browser_download_url")
# sudo chmod 755 /usr/local/bin/fluxctl
# fluxctl version
# fluxctl identity --k8s-fwd-ns flux
###-SCRIPT-PART-TWO-END-###
```

- 直接执行下面代码块可能遇到权限不够的告警，需要：
	- 如果你有 workshop 的 Credentials ，直接先复制粘贴到命令行，再执行下列步骤；(copy and paste your workshop's credential to CLI and then execute this code block)
	- 或者，如果自己账号的 cloud9，先用环境变量方式（`AWS_ACCESS_KEY_ID` 和 `AWS_SECRET_ACCESS_KEY`）保证有足够权限执行 (or using environment variables to export credential yourself)
	- 下面代码块包括：
		- 禁用 cloud9 中的 credential 管理，从 `~/.aws/credentials` 中删除 `aws_session_token=` 行
		- 分配管理员权限 role 到 cloud9 instance
```sh
###-SCRIPT-PART-THREE-BEGIN-###
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

# ---
export AWS_PAGER=""
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
C9_INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
ROLE_NAME=adminrole-$RANDOM
MY_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

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
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

instance_profile_arn=$(aws ec2 describe-iam-instance-profile-associations \
  --filter Name=instance-id,Values=$C9_INST_ID \
  --query IamInstanceProfileAssociations[0].IamInstanceProfile.Arn \
  --output text)
if [[ ${instance_profile_arn} == "None" ]]; then
  # create one
  aws iam create-instance-profile \
    --instance-profile-name ${ROLE_NAME}
  sleep 10
  # attach role to it
  aws iam add-role-to-instance-profile \
    --instance-profile-name ${ROLE_NAME} \
    --role-name ${ROLE_NAME}
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
###-SCRIPT-PART-THREE-END-###
```

- 在 cloud9 中，重新打开一个 terminal 窗口，并验证权限符合预期。上面代码块将创建一个 instance profile ，并将关联名为 `adminrole-xxx` 的 role，或者在 cloud9 现有的 role 上关联 `AdministratorAccess` role policy。(open new tab to verify you have new role, `adminrole-xxx`, on your cloud9)
```sh
aws sts get-caller-identity
```


## reference

- https://docs.amazonaws.cn/en_us/eks/latest/userguide/install-aws-iam-authenticator.html
- [[switch-role-to-create-dedicate-cloud9]]


