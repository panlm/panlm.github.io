---
title: cloud9-cmd
description: cloud9 related commands
chapter: true
created: 2022-07-01 09:18:29.572
last_modified: 2022-07-01 09:18:29.572
tags: 
- aws/cloud9 
- aws/cli 
---
```ad-attention
title: This is a github note

```
# cloud9-cmd

![[setup-cloud9-for-eks#spin-up-a-cloud9-instance-in-your-region]]


```sh
aws cloud9 describe-environments

```





## old

```sh


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


```sh

DEFAULT_VPC=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)

if [[ ! -z ${DEFAULT_VPC} ]]; then

  FIRST_SUBNET=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${DEFAULT_VPC}" \
    --query "Subnets[0].SubnetId" \
    --output text)
  
  aws cloud9 create-environment-ec2 \
    --name cloud9-$RANDOM \
    --instance-type t3.small \
    --subnet-id ${FIRST_SUBNET} \
    --automatic-stop-time-minutes 10080 \
    --owner-arn arn:aws:iam::861006941173:role/adminrole \

fi

An error occurred (ValidationException) when calling the CreateEnvironmentEC2 operation: 1 validation error detected: Value 'arn:aws:iam::861006941173:role/adminrole' at 'ownerArn' failed to satisfy constraint: Member must satisfy regular expression pattern: ^arn:(aws|aws-cn|aws-us-gov|aws-iso|aws-iso-b):(iam|sts)::\d+:(root|(user\/[\w+=/:,.@-]{1,64}|federated-user\/[\w+=/:,.@-]{2,32}|assumed-role\/[\w+=:,.@-]{1,64}\/[\w+=,.@-]{1,64}))$


```



