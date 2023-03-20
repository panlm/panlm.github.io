---
title: efs-cmd
description: 1/ 在默认 vpc 中创建 efs 
chapter: true
created: 2023-02-24 08:03:38.967
last_modified: 2023-02-24 08:03:38.967
tags: 
- aws/cli 
- aws/storage/efs 
---
```ad-attention
title: This is a github note

```
# efs-cmd

## create efs

在默认 vpc 中创建 efs
```sh
CLUSTER_NAME=${CLUSTER_NAME:-eks0630}
AWS_REGION=${AWS_REGION:-us-east-2}

VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} \
  --query "Vpcs[].CidrBlock"  --region ${AWS_REGION} --output text )

# create security group
SG_ID=$(aws ec2 create-security-group --description ${CLUSTER_NAME}-efs-eks-sg \
  --group-name efs-sg-$RANDOM --vpc-id ${VPC_ID} |jq -r '.GroupId' )
# allow tcp 2049 (nfs v4)
aws ec2 authorize-security-group-ingress --group-id ${SG_ID}  --protocol tcp --port 2049 --cidr ${VPC_CIDR}

# create efs
FILESYSTEM_ID=$(aws efs create-file-system \
  --creation-token ${CLUSTER_NAME} \
  --region ${AWS_REGION} |jq -r '.FileSystemId' )
echo ${FILESYSTEM_ID}

# create mount target
PUBLIC_SUBNETS=($(aws ec2 describe-subnets \
--filter "Name=vpc-id,Values=$VPC_ID" \
--query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
--output text))

for i in ${PUBLIC_SUBNETS[@]} ; do
  echo "creating mount target in: " $i
  aws efs create-mount-target --file-system-id ${FILESYSTEM_ID} \
    --subnet-id ${i} --security-group ${SG_ID}
done

```

^d4lka9

another example: [[efs-for-eks#^mgh326]] 


