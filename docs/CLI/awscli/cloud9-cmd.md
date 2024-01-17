---
title: cloud9
description: cloud9 related commands
created: 2022-07-01 09:18:29.572
last_modified: 2024-01-17
tags:
  - aws/cloud9
  - aws/cmd
---
> [!WARNING] This is a github note

# cloud9-cmd
## spin-up-a-cloud9-instance-in-your-region
- refer: [[../../cloud9/setup-cloud9-for-eks#spin-up-a-cloud9-instance-in-your-region]] 

```sh
aws cloud9 describe-environments

```

## disable aws credential management
```sh
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials
```

## get subnet id and vpc id from cloud9 instance
```sh
# get cloud9 vpc
C9_INST_ID=$(curl http://169.254.169.254/1.0/meta-data/instance-id 2>/dev/null)
C9_VPC_ID=$(aws ec2 describe-instances \
--instance-ids ${C9_INST_ID} \
--query 'Reservations[0].Instances[0].VpcId' --output text)

# get public subnet for external alb
C9_SUBNETS_ID=$(aws ec2 describe-subnets \
--filter "Name=vpc-id,Values=${C9_VPC_ID}" \
--query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
--output text)

# get default security group 
C9_DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
--filter Name=vpc-id,Values=${C9_VPC_ID} \
--query "SecurityGroups[?GroupName == 'default'].GroupId" \
--output text)

```

^wxvp2s

## share cloud9 to others
```sh
C9_ID=
aws cloud9 create-environment-membership \
    --environment-id ${C9_ID} \
    --user-arn arn:aws:sts::${MY_ACCOUNT_ID}:user/panlm \
    --permissions read-write
```

```
Value 'arn:aws:sts:::user/panlm' at 'userArn' failed to satisfy constraint: Member must satisfy regular expression pattern: ^arn:(aws|aws-cn|aws-us-gov|aws-iso|aws-iso-b):(iam|sts)::\d+:(root|(user\/[\w+=/:,.@-]{1,64}|federated-user\/[\w+=/:,.@-]{2,32}|assumed-role\/[\w+=:,.@-]{1,64}\/[\w+=,.@-]{1,64}))$
```

## get tags
```sh
C9_INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
aws ec2 describe-instances --instance-ids $C9_INST_ID --query 'Reservations[].Instances[].Tags[?Key==`aws:cloud9:environment`].Value' --output text
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
    --owner-arn arn:aws:iam::123456789012:role/adminrole \

fi

An error occurred (ValidationException) when calling the CreateEnvironmentEC2 operation: 1 validation error detected: Value 'arn:aws:iam::861xxxxxx173:role/adminrole' at 'ownerArn' failed to satisfy constraint: Member must satisfy regular expression pattern: ^arn:(aws|aws-cn|aws-us-gov|aws-iso|aws-iso-b):(iam|sts)::\d+:(root|(user\/[\w+=/:,.@-]{1,64}|federated-user\/[\w+=/:,.@-]{2,32}|assumed-role\/[\w+=:,.@-]{1,64}\/[\w+=,.@-]{1,64}))$


```


## Turn off AWS managed temporary credentials 
[LINK](https://docs.aws.amazon.com/cloud9/latest/user-guide/security-iam.html#auth-and-access-control-temporary-managed-credentials)

If you turn off AWS managed temporary credentials, by default the environment cannot access any AWS services, regardless of the AWS entity who makes the request. If you can't or don't want to turn on AWS managed temporary credentials for an environment, but you still need the environment to access AWS services, consider the following alternatives:

- Attach an instance profile to the Amazon EC2 instance that connects to the environment. For instructions, see [Create and Use an Instance Profile to Manage Temporary Credentials](https://docs.aws.amazon.com/cloud9/latest/user-guide/credentials.html#credentials-temporary).
- Store your permanent AWS access credentials in the environment, for example, by setting special environment variables or by running the `aws configure` command. For instructions, see [Create and store permanent access credentials in an Environment](https://docs.aws.amazon.com/cloud9/latest/user-guide/credentials.html#credentials-permanent-create).



