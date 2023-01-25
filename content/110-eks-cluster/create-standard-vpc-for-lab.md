---
title: "create-standard-vpc-for-lab"
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

## using cloudformation template 

```ad-note
title: using cloudshell

```

```sh
AWS_REGION=cn-north-1
BUCKET_NAME=$(aws s3 mb s3://panlm-$RANDOM-$RANDOM |awk '{print $2}')

# first 2 AZs
# separator `\,` is necessary for ParameterValue in cloudformation
AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text |xargs -n 1 |sed -n '1,2p' |xargs |sed 's/ /\\,/g'))

wget -O aws-vpc.template.yaml https://github.com/panlm/panlm.github.io/raw/main/content/110-eks-cluster/aws-vpc.template.yaml
aws s3 cp aws-vpc.template.yaml s3://${BUCKET_NAME}/

STACK_NAME=aws-vpc-$(date +%H%M%S)
CIDR="10.130"
aws cloudformation create-stack --stack-name ${STACK_NAME} \
  --parameters ParameterKey=AvailabilityZones,ParameterValue="${AZS}" \
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
  ParameterKey=CreateTgwAttachment,ParameterValue="false" \
  ParameterKey=TransitGatewayId,ParameterValue="tgw-0ec1b74b7d8dcea74" \
  --template-url https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com.cn/aws-vpc.template.yaml \
  --region ${AWS_REGION}

# global region
# https://${BUCKET_NAME}.s3.amazonaws.com/aws-vpc.template.yaml
# china region
# https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com.cn/aws-vpc.template.yaml

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

PublicSubnet1ID=$(aws cloudformation --region ${AWS_REGION} describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1ID`].OutputValue' --output text)

OWNER_ARN=$(aws sts get-caller-identity  --query 'Arn'  --output text)
ENV_ID=$(aws cloud9 create-environment-ec2 \
--name ${STACK_NAME} \
--instance-type t3.small \
--subnet-id ${PublicSubnet1ID} \
--automatic-stop-time-minutes 10080 \
--owner-arn ${OWNER_ARN} \
--query 'environmentId' --output text )

(C9_URL=https://${AWS_REGION}.console.aws.amazon.com/cloud9/ide/${ENV_ID}
echo "open cloud9 url:"
echo "${C9_URL}")

```

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


