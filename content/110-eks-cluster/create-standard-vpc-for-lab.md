---
title: "create-standard-vpc-for-lab"
description: "创建实验环境所需要的 vpc ，并且支持直接 attach 到 tgw 方便网络访问"
chapter: true
weight: 40
created: 2022-04-10 22:12:29.404
last_modified: 2022-04-10 22:12:29.404
tags: 
- aws/network/vpc 
- aws/mgmt/cloudformation
---

```ad-attention
title: This is a github note

```

# create-standard-vpc-for-lab

## using-cloudformation-template 
- search `cloud9` in marketplace, and launch instance from it
- assign `AdministratorAccess` to instance profile

```sh
AWS_REGION=cn-north-1
export AWS_DEFAULT_REGION=${AWS_REGION}
UNIQ_STR=$(date +%Y%m%d-%H%M%S)
BUCKET_NAME=$(aws s3 mb s3://panlm-${UNIQ_STR} |awk '{print $2}')

wget -O aws-vpc.template.yaml https://github.com/panlm/panlm.github.io/raw/main/content/110-eks-cluster/aws-vpc.template.yaml
aws s3 cp aws-vpc.template.yaml s3://${BUCKET_NAME}/

# first 2 AZs
# separator `\,` is necessary for ParameterValue in cloudformation
TWOAZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text |xargs -n 1 |sed -n '1,2p' |xargs |sed 's/ /\\,/g'))

```

if you create vpc in china region, you could put your existed tgw id here for attach automatically.
```sh
# new vpc will connect with TGW, if TGW existed
TGW_ID=tgw-0ec1b74b7d8dcea74
TGW_NUMBER=$(aws ec2 describe-transit-gateways \
--filter Name=transit-gateway-id,Values=${TGW_ID} \
|jq -r '.TransitGateways | length')
if [[ ${TGW_NUMBER} -eq 1 ]]; then
  TGW_ATTACH=true
else
  TGW_ATTACH=false
fi
# do not create public subnet & igw
CREATE_PUB_SUB=false

```

you could create vpc without tgw
```sh
TGW_ATTACH=false
CREATE_PUB_SUB=true
```

create your vpc with specific CIDR
```sh
CIDR="10.130"

STACK_NAME=aws-vpc-${CIDR##*.}-${UNIQ_STR}
# global region: amazonaws.com
# china region: amazonaws.com.cn
if [[ ${AWS_REGION%%-*} == "cn" ]]; then
  SUFFIX=".cn"
else
  SUFFIX=""
fi
aws cloudformation create-stack --stack-name ${STACK_NAME} \
  --parameters ParameterKey=AvailabilityZones,ParameterValue="${TWOAZS}" \
  ParameterKey=VPCCIDR,ParameterValue="${CIDR}.0.0/16" \
  ParameterKey=NumberOfAZs,ParameterValue=2 \
  ParameterKey=PublicSubnet1CIDR,ParameterValue="${CIDR}.128.0/24" \
  ParameterKey=PublicSubnet2CIDR,ParameterValue="${CIDR}.129.0/24" \
  ParameterKey=PublicSubnet3CIDR,ParameterValue="${CIDR}.130.0/24" \
  ParameterKey=PublicSubnet4CIDR,ParameterValue="${CIDR}.131.0/24" \
  ParameterKey=PrivateSubnet1ACIDR,ParameterValue="${CIDR}.0.0/19" \
  ParameterKey=PrivateSubnet2ACIDR,ParameterValue="${CIDR}.32.0/19" \
  ParameterKey=PrivateSubnet3ACIDR,ParameterValue="${CIDR}.64.0/19" \
  ParameterKey=PrivateSubnet4ACIDR,ParameterValue="${CIDR}.96.0/19" \
  ParameterKey=CreateTgwSubnets,ParameterValue="true" \
  ParameterKey=TgwSubnet1CIDR,ParameterValue="${CIDR}.132.0/24" \
  ParameterKey=TgwSubnet2CIDR,ParameterValue="${CIDR}.133.0/24" \
  ParameterKey=TgwSubnet3CIDR,ParameterValue="${CIDR}.134.0/24" \
  ParameterKey=TgwSubnet4CIDR,ParameterValue="${CIDR}.135.0/24" \
  ParameterKey=CreateTgwAttachment,ParameterValue="${TGW_ATTACH}" \
  ParameterKey=TransitGatewayId,ParameterValue="${TGW_ID}" \
  ParameterKey=CreatePublicSubnets,ParameterValue="${CREATE_PUB_SUB}" \
  ParameterKey=CreatePrivateSubnets,ParameterValue="true" \
  ParameterKey=CreateNATGateways,ParameterValue="false" \
  --template-url https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com${SUFFIX}/aws-vpc.template.yaml \
  --region ${AWS_REGION}

# until get CREATE_COMPLETE
while true ; do
  status=$(aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].StackStatus' --output text)
  echo ${status}
  if [[ ${status} == 'CREATE_IN_PROGRESS' ]]; then
    sleep 10
  else
    break
  fi
done

```

## get-vpc-id
```sh
VPC_ID=$(aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`VPCID`].OutputValue' --output text)

# PublicSubnet1ID=$(aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1ID`].OutputValue' --output text)

```

## (option) create cloud9 in target subnet 
refer: [[setup-cloud9-for-eks#^xzcvy9]] or [hugo-link]({{< ref "setup-cloud9-for-eks#spin-up-a-cloud9-instance-in-your-region" >}}) 

```sh
# name=<give your cloud9 a name>
datestring=$(date +%Y%m%d-%H%M)
name=${name:=cloud9-$datestring}
export AWS_DEFAULT_REGION=us-east-2 # need put each command

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
    --instance-type m5.xlarge \
    --subnet-id ${FIRST_SUBNET} \
    --automatic-stop-time-minutes 10080 \
    --region ${AWS_DEFAULT_REGION} |tee /tmp/$$
  echo "Open URL to access your Cloud9 Environment:"
  C9_ID=$(cat /tmp/$$ |jq -r '.environmentId')
  echo "https://${AWS_DEFAULT_REGION}.console.aws.amazon.com/cloud9/ide/${C9_ID}"
else
  echo "you have no default vpc in $AWS_DEFAULT_REGION"
fi

```

## description in this template
- no s3 endpoint
- security group named eks-shared-sg (only it self)
- security group named normal-sg ( icmp/80/443 for all )
- tag subnet 
    - `kubernetes.io/role/internal-elb` = `1`
    - `kubernetes.io/role/elb` = `1`
    - (option) `kubernetes.io/cluster/<vpc_name>` = `shared`
- verified in china region
- add tgw subnet and associate tgw route table with `0.0.0.0/0` to tgw
- add `10.0.0.0/8` route to public/private1A/private2A route table

## refer
- [[cloudformation-cli]] 
- [quickstart-aws-vpc](https://aws-quickstart.github.io/quickstart-aws-vpc/) 


