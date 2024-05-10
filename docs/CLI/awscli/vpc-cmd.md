---
title: vpc
description: 常用命令
created: 2021-11-05T01:08:29.064Z
last_modified: 2024-02-05
icon: simple/amazonaws
tags:
  - aws/network/vpc
  - aws/cmd
  - todo
---

# vpc-cmd
## vpc creation

- [ ] dns hostname --> true

```shell
# 10-128-vpc
CIDR=10.128
VPC_NAME=vpc-$(echo ${CIDR} |tr '.' '-')
export AWS_DEFAULT_REGION=cn-north-1

# first 2 AZs
AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text |xargs -n 1 |sed -n '1,2p' |xargs))

# create vpc
VPC_ID=$(aws ec2 create-vpc --cidr-block ${CIDR}.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value='"${VPC_NAME}"'}]' --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --enable-dns-hostnames --vpc-id ${VPC_ID} 

# create subnet 2x pub, 2x priv, 2x tgw
num=0
for j in pub priv tgw ; do
    for i in ${AZS[@]}; do
        output=$j.$(date +%H%M%S)
        aws ec2 create-subnet --vpc-id ${VPC_ID} \
        --cidr-block ${CIDR}.${num}.0/22 \
        --availability-zone ${i} \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value='"${VPC_NAME}"'-'"${j}"'-'"${i##*-}"'}]' |tee -a ${output}
        num=$((num+4))
    done
done

# create igw
IGW_ID=$( aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='"${VPC_NAME}"'-igw}]' --query InternetGateway.InternetGatewayId --output text )
aws ec2 attach-internet-gateway --vpc-id ${VPC_NAME} --internet-gateway-id ${IGW_ID}

```

## subnet find
```sh
aws ec2 describe-subnets --filters "Name=vpc-id,Values=${ovpc1_id}" \
  --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}"

aws ec2 describe-subnets --filters "Name=vpc-id,Values=${ovpc1_id}" \
  --query "Subnets[*]" |jq -r '.[].SubnetId'

```

### first 2 subnets
```sh
FIRST_2AZ=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text |awk '{print $1,$2}')
SUBNET_IDS=$(for i in ${FIRST_2AZ}; do 
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --query 'Subnets[?AvailabilityZone==`'"${i}"'`].SubnetId' \
        --output text
done |xargs)
```

```sh
FIRST_2AZ=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text |awk '{print $1,$2}')
SUBNET_IDS=$(for i in ${FIRST_2AZ}; do 
aws ec2 describe-subnets \
--filters "Name=vpc-id,Values=${VPC_ID}" \
--query 'Subnets[?(AvailabilityZone==`'"${i}"'` && MapPublicIpOnLaunch==`true`)].SubnetId' \
--output text
done |xargs)
```

### list subnet in table
```sh
aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query "Subnets[].[AvailabilityZone,SubnetId]" --output text

```
- refer: [[../../EKS/addons/eks-custom-network#lab-]]

## create/delete transit gateway
### create
```sh
aws ec2 create-transit-gateway \
  --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=otgw1}]' \
  --query TransitGateway.TransitGatewayId --output text
```

### delete transit gateway
```sh
aws ec2 describe-transit-gateway-attachments |jq -r .TransitGatewayAttachments[].TransitGatewayAttachmentId
aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id tgw-attach-012c31682d0c11f22
```

### vpc & subnet
```sh
aws ec2 create-subnet --cidr-block 10.1.0.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az1
aws ec2 create-subnet --cidr-block 10.1.16.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az2
aws ec2 create-subnet --cidr-block 10.1.32.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az3


aws ec2 create-subnet --cidr-block 10.2.0.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az1
aws ec2 create-subnet --cidr-block 10.2.16.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az2
aws ec2 create-subnet --cidr-block 10.2.32.0/20 --vpc-id vpc-xxx --availability-zone-id cnnw1-az3

```


## route table 
### peering
```sh
CLUSTER_NAME=ekscluster2
TARGET_CIDR='10.251.0.0/16'
PEER_ID=pcx-xxx

VPC_ID=$(aws eks describe-cluster \
  --name ${CLUSTER_NAME} \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

ROUTE_TABLES=($(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=${VPC_ID}" "Name=association.main,Values=false" \
  --query "RouteTables[].RouteTableId" \
  --output text))

for i in ${ROUTE_TABLES[@]}; do
  aws ec2 create-route --route-table-id $i \
    --destination-cidr-block ${TARGET_CIDR} \
    --vpc-peering-connection-id ${PEER_ID}
done

```

### tgw

![[TC-private-api-cross-environment-traffic#^lyckqs]]

## cidr range
| RFC 1918 range                                    | Example CIDR block |
| ------------------------------------------------- | ------------------ |
| 10.0.0.0 - 10.255.255.255 (10/8 prefix)           | 10.0.0.0/16        |
| 172.16.0.0 - 172.31.255.255 (172.16/12 prefix)    | 172.31.0.0/16      |
| 192.168.0.0 - 192.168.255.255 (192.168/16 prefix) | 192.168.0.0/20     | 


## func-get-default-vpc-
```sh title="func-get-default-vpc"
function get-default-vpc () {
    DEFAULT_VPC=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
    DEFAULT_CIDR=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].CidrBlock' --output text)
}
```

## func-get-subnets-
```sh title="func-get-subnets"
function get-subnets () {
    if [[ $# -lt 1 ]]; then
        echo "format: $0 VPC_ID [true|false]"
        echo "parameter 2: true for public, false for private"
        return
    else
        local VPC_ID=$1
        local IS_PUBLIC=$(echo $2 |tr 'A-Z' 'a-z') # lower case $2
    fi

    if [[ -z ${IS_PUBLIC} ]]; then
        IS_PUBLIC=true
    fi

    if [[ ${IS_PUBLIC} == 'true' || ${IS_PUBLIC} == 'false' ]]; then
        echo "get public subnet is: " ${IS_PUBLIC}
    else
        echo "parameter 2: true for public, false for private"
        return
    fi
    
    SUBNET_IDS=$(aws ec2 describe-subnets \
        --filter "Name=vpc-id,Values=${VPC_ID}" \
        --query 'Subnets[?MapPublicIpOnLaunch==`'"${IS_PUBLIC}"'`].SubnetId' \
        --output text)
}
```

also see sample in [[../../EKS/cluster/eks-private-access-cluster#prep-config-]]

## get instance vpc
```sh
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INST_ID} --query 'Reservations[0].Instances[0].VpcId' --output text)
```

## create vpc endpoint
![[../../../../gitlab/artifacts/MK/POC-apigw-dataflow#^gdy8eb]]


another sample: [[ssm-cmd#^ssm-vpce-0513]]
another sample: [[TC-private-apigw-dataflow#步骤 4]]

