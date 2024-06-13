---
title: ec2
description: 常用命令
created: 2021-07-17T04:01:46.968Z
last_modified: 2024-03-05
icon: simple/amazonec2
tags:
  - aws/compute/ec2
  - aws/cmd
---

# ec2 cmd
## others
- [[ebs-cmd]]

## get image id
### get all ubuntu image from here (click to launch)
- https://cloud-images.ubuntu.com/locator/ec2/

### option-1-get-AL2-ami-id-
- https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/

```sh
export AWS_DEFAULT_REGION=us-west-2
AMI_ID=$(aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --query 'Parameters[0].Value' --output text)

```

2022.6.27
us-east-1: ami-065efef2c739d613b
us-east-2: ami-07251f912d2a831a3

### option 2
```sh
# ubuntu
export region=ap-southeast-1
aws ec2 describe-images --region ${region} --owners 099720109477 \
  --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64*  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text |sort -k2 -r |column -t

# windows 2012
export region=ap-southeast-1
aws ec2 describe-images --region ${region}  --owners 801119661308 \
  --filter "Name=name,Values=Windows_Server-2012-R2_RTM-English-64Bit-Base*"  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text |sort -k2 -r |column -t

# windows 2012
export AWS_DEFAULT_REGION=us-east-2
aws ec2 describe-images --owners 801119661308 \
  --filter "Name=name,Values=Windows_Server-2019-English-Full-Base*"  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text |sort -k2 -r |column -t

# amzn2
export region=ap-southeast-1
aws ec2 describe-images --region ${region} --owners 137112412989 \
  --filters Name=name,Values=amzn2-ami-hvm-*2021*gp2*  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text |sort -k2 -r |column -t

# centos
export AWS_DEFAULT_REGION=us-east-2
aws ec2 describe-images \
  --filters Name=name,Values='CentOS Linux 7 x86_64*'  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text \
  |sort -k2 -r |column -t
# --owners 679593333241


export region=cn-northwest-1
awscn ec2 describe-images --region ${region} --owners 336777782633 \
  --filters Name=name,Values='CentOS-7*'  \
  --query 'Images[*].[ImageId,CreationDate,Name]' --output text \
  |sort -k2 -r |column -t

# centos ami
# https://wiki.centos.org/Cloud/AWS
# aws --region us-east-1 ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=cvugziknvmxgqna9noibqnnsy

```

### get cloud9 newest image
```sh
export AWS_DEFAULT_REGION=us-east-2
aws ec2 describe-images --region ${AWS_DEFAULT_REGION} --owners amazon \
  --filters "Name=name,Values=Cloud9AmazonLinux2-*" \
  --query 'reverse(sort_by(Images, &CreationDate)[].[Name,ImageId])' \
  --output text |column -t 
```

## create instance
```sh
# IMAGE_ID=ami-026bd3163cafd87ed #ubuntu
IMAGE_ID=ami-0f511ead81ccde020 #amzn2 ap-southeast-1
IMAGE_ID=ami-028584814b5504f5b #amzn2 cn-northwest-1
IMAGE_ID=ami-01b887d5e264569f5 #amzn2 cn-north-1
region=cn-north-1
KEY_NAME=awskey
aws ec2 run-instances --region ${region} --key-name $KEY_NAME \
  --image-id $IMAGE_ID --instance-type c5.large --query Instances[*].InstanceId --output text

SUBNET_ID=
aws ec2 run-instances --region ${region} \
  --image-id $IMAGE_ID --instance-type c5.large \
  --subnet-id ${SUBNET_ID} --query Instances[*].InstanceId --output text

```

```sh
# centos
IMAGE_ID=ami-07f65177cb990d65b
AWS_REGION=ap-southeast-1
KEY_NAME=aws-key
echo '#!/bin/bash
sudo yum install -y https://s3.'"$AWS_REGION"'.amazonaws.com/amazon-ssm-'"$region"'/latest/linux_amd64/amazon-ssm-agent.rpm' |tee /tmp/tmp_$$.txt
aws ec2 run-instances --region ${AWS_REGION} --key-name $KEY_NAME \
  --image-id $IMAGE_ID --instance-type t2.micro \
  --user-data file:///tmp/tmp_$$.txt

```

### windows instance
- get image
```sh
export AWS_DEFAULT_REGION=us-west-2
WINDOWS_AMI_ID=$(aws ssm get-parameters \
    --names "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base" \
    --query 'Parameters[].Value' --output text )

```

- create instance 
```sh
# windows 2016 base
IMAGE_ID=ami-02c88710773712fea
AWS_REGION=us-east-2
# INSTANCE_PROFILE_ARN=arn:aws:iam::123456789012:instance-profile/windows-instance

# windows 2016 base in china region
IMAGE_ID=ami-0cdfdbad775669b71
AWS_REGION=cn-northwest-1
INSTANCE_PROFILE_ARN=arn:aws-cn:iam::123456789012:instance-profile/windows-instance

KEY_NAME=awskey
STR=$(date +%H%M)
aws ec2 run-instances \
    --region ${AWS_REGION} --key-name ${KEY_NAME} \
    --image-id ${IMAGE_ID} --instance-type m5.large \
    --iam-instance-profile Arn=${INSTANCE_PROFILE_ARN} \
    --private-dns-name-options "HostnameType=ip-name,EnableResourceNameDnsARecord=true,EnableResourceNameDnsAAAARecord=false"
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=win-'"${STR}"'},{Key=os,Value=windows}]' |tee /tmp/instance-$$.1
INST_ID=$(cat /tmp/instance-$$.1 |jq -r '.Instances[0].InstanceId')
# private dns name option is important for join domain
# false/false will run ssm document failed
# true/false will run ssm document successful

```

another example:
- [[../../others/POC-mig-filezilla-to-transfer-family#^goacm2]]

## list instance
```bash
# using Name to filter
aws ec2 describe-instances |jq -r '.Reservations[].Instances[] | select((.Tags[]|select(.Key=="Name")|.Value) | match(".*") ) | [.InstanceId, (del((.Tags[]|select(.Key!="Name")))|.Tags[]|.Value|tostring)]|@tsv'

# list all instance, name, ips
aws ec2 describe-instances |jq -r '.Reservations[].Instances[] | 
  [.InstanceId, .State.Name, .PrivateIpAddress, .PublicIpAddress, (del((.Tags[]|select(.Key!="Name")))|.Tags[]|.Value|tostring)]|@tsv'

# add sort in output
aws ec2 describe-instances |jq -r '.Reservations[].Instances[] |=sortby(.LaunchTime) | 
  [.InstanceId, .State.Name, .PrivateIpAddress, .PublicIpAddress, (del((.Tags[]|select(.Key!="Name")))|.Tags[]|.Value|tostring)]|@tsv'
```

```sh
# by ssh key name
aws ec2 describe-instances --filters "Name=key-name,Values=sshkey-aws"

# by name
aws ec2 describe-instances --filters "Name=tag:Name,Values=eks*"

```


## install ssm
```sh
sudo yum install -y https://s3.ap-northeast-2.amazonaws.com/amazon-ssm-ap-northeast-2/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl status amazon-ssm-agent

```

## region cmd
```sh
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
#export AWS_REGION=ap-northeast-1
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

```

## get instance ids 
### from vpc
```sh
INSTANCE_IDS=($(aws ec2 describe-instances \
  --filters "Name=${TAG},Values=owned" "Name=vpc-id,Values=vpc-xxx"\
  |jq -r '.Reservations[].Instances[].InstanceId' ) )

```

### filter tags
```sh
tag=
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=cloud9-130" \
  |jq -r '.Reservations[].Instances[].InstanceId' 

```

```sh
aws ec2 describe-volumes \
--filters "Name=tag:kubernetes.io/cluster/ekscluster1,Values=owned" \
--query 'Volumes[].[Tags[?Key==`Name`].Value,State]' --output=text \
|xargs -n 2

aws ec2 describe-volumes \
--filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
--query 'Volumes[*].[`aws ec2 delete-volume --volume-id`, VolumeId,`#`,State,Tags[?Key==`Name`].Value | [0]]' --output=text 

```
- https://stackoverflow.com/questions/76115278/aws-cli-query-return-on-one-line


## associate instance profile to ec2
- [[../../cloud9/setup-cloud9-for-eks]]

```sh
aws ec2 describe-iam-instance-profile-associations
aws ec2 disassociate-iam-instance-profile
aws ec2 associate-iam-instance-profile

C9_INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
instance_profile_arn=$(aws ec2 describe-iam-instance-profile-associations \
  --filter Name=instance-id,Values=$C9_INST_ID \
  --query IamInstanceProfileAssociations[0].IamInstanceProfile.Arn \
  --output text)

aws iam get-instance-profile \
  --instance-profile-name ${instance_profile_arn##*/}

## add your needed role to it
aws iam add-role-to-instance-profile \
  --instance-profile-name ${instance_profile_arn} 
  --role-name ${ROLE_NAME}

```


## security group
```sh
# ensure you have security group called 'eks-shared-sg'
aws ec2 describe-security-groups  --region $AWS_REGION --filter Name=vpc-id,Values=$VPC_ID --query 'SecurityGroups[*].[GroupName,GroupId]'

# if you have multi eni, do bond sg to instance manually
export SG_ID=$(aws ec2 describe-security-groups  --region $AWS_REGION --filter Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[?GroupName == 'eks-shared-sg'].GroupId" --output text)

```

### func-create-sg-
- to create security group, you need VPC_ID ([[git/git-mkdocs/CLI/awscli/vpc-cmd#func-get-default-vpc-]])
```sh title="func-create-sg.sh" linenums="1"
--8<-- "docs/CLI/functions/func-create-sg.sh"
```
refer: [[../functions/func-create-sg.sh]] 
### create sg allow itself
- refer: [[git/git-mkdocs/data-analytics/mwaa-lab#prepare-endpoint-for-your-private-network-]]

## count vcpu
```sh
aws ec2 describe-instances --region us-east-2 \
--query Reservations[].Instances[].CpuOptions.[CoreCount,ThreadsPerCore] \
--output text \
|awk 'BEGIN {sum=0} {line=$1*$2;sum=sum+line} END {print sum} '

```

## troubleshooting

https://linuxconfig.org/how-to-name-label-a-partition-or-volume-on-linux

- refer:  [[linux-cmd#lsblk-]]
- refer: e2label

## KB

- How do I move my EC2 instance to another subnet, Availability Zone, or VPC? ([LINK](https://aws.amazon.com/premiumsupport/knowledge-center/move-ec2-instance/))
    - 不能 detach primary eni
    - 只能 attach 同可用区的 eni （即便是另一个 subnet ）

## source-destination-check-

- disable `Change Source / destination check`
```sh
INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
aws ec2 modify-instance-attribute \
    --instance-id=${INST_ID} --source-dest-check
```

## create-key-
- [[../functions/import-aws-key.sh|import-aws-key]] 
```sh title="import-aws-key.sh" linenums="1"
--8<-- "docs/CLI/functions/import-aws-key.sh"
```

## create instance by chatgpt

```sh
KEY_NAME=aws-key
AMI_ID=$(aws ec2 describe-images \
    --region us-east-2 \
    --filters "Name=name,Values=Windows_Server-2019-English-Full-Base-*" \
              "Name=architecture,Values=x86_64" \
              "Name=root-device-type,Values=ebs" \
              "Name=virtualization-type,Values=hvm" \
    --query "reverse(sort_by(Images, &CreationDate))[0].ImageId" \
    --output text)

aws ec2 run-instances \
--image-id ${AMI_ID} \
--instance-type t3.medium \
--key-name ${KEY_NAME} \
--subnet-id $(aws ec2 describe-subnets --filters "Name=default-for-az,Values=true" "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)" --query "Subnets[0].SubnetId" --output text) \
--iam-instance-profile Name=EC2DomainJoin-Instance-Profile \
--user-data '<powershell>
Import-Module "C:\Program Files\Amazon\Ec2ConfigService\Scripts\InitializeInstance.ps1"
Initialize-EC2Instance -Schedule -DomainName "corp1.aws.panlm.xyz" -DomainUserName "admin" -DomainPassword "password"
</powershell>' \
--associate-public-ip-address \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance4}]' \
--region us-east-2

```


## instance-connect-
### ssh connect
- from public ip 
```sh
aws ec2-instance-connect ssh \
    --instance-id i-xxx
```

- from private ip (need to create instance connect endpoint first)
```sh
aws ec2-instance-connect ssh \
    --instance-id i-xxx \
    --instance-ip 172.31.7.81  \
    --connection-type eice
```

### send ssh public key
```sh
aws ec2-instance-connect send-ssh-public-key \
--region us-east-2 \
--ssh-public-key file://out.pub \
--instance-id i-xxx \
--instance-os-user ec2-user

```




