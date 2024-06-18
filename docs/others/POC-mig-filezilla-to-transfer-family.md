---
title: Migrating Filezilla to AWS Transfer Family
description: 迁移 Filezilla 到 Transfer Family
created: 2023-03-25 10:08:47.022
last_modified: 2024-04-04
status: myblog
comments: true
tags:
  - aws/storage/transfer-family
  - aws/mgmt/directory-service
---
# Migrating Filezilla to AWS Transfer Family
## requirement
- same domain for both sftp and ftps server
- BU manage users themselves
- password and public key access

## diagram

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-1.png]]

## walkthrough
### directory-service
#### create-AD-
- create managed directory service on aws
```sh
AD=corp2.aws.panlm.xyz
PASS=${PASS:-passworD.1}

export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""
VPC=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text)

# SUBNETS=$(aws ec2 describe-subnets \
#     --filters "Name=vpc-id,Values=${VPC}" "Name=map-public-ip-on-launch,Values=true" \
#     --query "Subnets[].SubnetId" \
#     --output text |awk 'BEGIN{OFS=","} {print $1,$2}')

# sort by AZ name and get first 2 subnets
# sometimes will failed in us-west-2 if dont sort output
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${VPC}" \
        "Name=map-public-ip-on-launch,Values=true" |\
    jq -r '.Subnets | sort_by(.AvailabilityZone) | .[].SubnetId' |\
    xargs |awk 'BEGIN{OFS=","} {print $1,$2}')

aws ds create-microsoft-ad \
    --name ${AD} \
    --short-name ${AD%%.*} \
    --password ${PASS} \
    --edition Standard \
    --vpc-settings VpcId=${VPC},SubnetIds=${SUBNETS} |tee /tmp/ds-$$.1
MSDS_ID=$(cat /tmp/ds-$$.1 |jq -r '.DirectoryId')

# until "Requested" - "Creating" - "Active"
watch -g -n 60 aws ds describe-directories \
    --directory-ids ${MSDS_ID} \
    --query DirectoryDescriptions[0].Stage \
    --output text

MSDS_IP=($(aws ds describe-directories \
    --directory-ids ${MSDS_ID} \
    --query DirectoryDescriptions[0].DnsIpAddrs \
    --output text))

```

#### create instance and join domain 
- launch instance and join domain seamlessly ([link](https://repost.aws/knowledge-center/manage-ad-directory-from-ec2-windows))
- create role for joining domain instance
```sh
ROLE_NAME=ec2-msds-role-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
cat > trust.json <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
aws iam create-role --role-name ${ROLE_NAME} \
    --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
aws iam attach-role-policy --role-name ${ROLE_NAME} \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
aws iam attach-role-policy --role-name ${ROLE_NAME} \
    --policy-arn "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"
aws iam create-instance-profile --instance-profile-name ${ROLE_NAME} |tee /tmp/inst-profile-$$.1
aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME} --role-name ${ROLE_NAME}
INSTANCE_PROFILE_ARN=$(cat /tmp/inst-profile-$$.1 |jq -r '.InstanceProfile.Arn')

```

- create key - [[git/git-mkdocs/CLI/awscli/ec2-cmd#create-key-]]
- create instance
```sh
# IMAGE_ID=ami-06fe4639440b3ab22 # windows 2019 base
# IMAGE_ID=ami-0dd478adda4cc704d # windows 2016
echo ${INSTANCE_PROFILE_ARN}

IMAGE_ID=$(aws ssm get-parameters \
    --names "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base" --query 'Parameters[].Value' --output text )

# SUBNET_PARAMETER="--subnet-id subnet-0d568921201a89751"

KEY_NAME=aws-key
STR=$(TZ=EAT-8 date +%H%M)
aws ec2 run-instances \
    ${SUBNET_PARAMETER} \
    --key-name ${KEY_NAME} \
    --image-id ${IMAGE_ID} --instance-type m5.large \
    --iam-instance-profile Arn=${INSTANCE_PROFILE_ARN} \
    --associate-public-ip-address \
    --private-dns-name-options "HostnameType=ip-name,EnableResourceNameDnsARecord=true,EnableResourceNameDnsAAAARecord=false" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=win-'"${STR}"'},{Key=os,Value=windows}]' |tee /tmp/instance-$$.1
INST_ID=$(cat /tmp/instance-$$.1 |jq -r '.Instances[0].InstanceId')
# private dns name option is important for join domain
# false/false will run ssm document failed
# true/false will run ssm document successful

while true ; do
    RESULT=$(aws ec2 describe-instance-status \
        --instance-ids ${INST_ID} \
        --query 'InstanceStatuses[?(InstanceStatus.Status==`ok` && SystemStatus.Status==`ok`)].InstanceId' \
        --output text)
    if [[ $RESULT == "${INST_ID}" ]]; then
        break
    else
        sleep 60
    fi
done

```

^goacm2

##### join-domain-
- (option) logon windows instance once at least 
- execute ssm document to join domain
```sh
echo ${AD}
echo ${MSDS_ID}
echo ${INST_ID}
echo ${MSDS_IP[@]}

aws ssm send-command \
    --document-name "AWS-JoinDirectoryServiceDomain" \
    --document-version "1" \
    --targets '[{"Key":"InstanceIds","Values":["'"${INST_ID}"'"]}]' \
    --parameters '{"directoryOU":[""],"directoryId":["'"${MSDS_ID}"'"],"directoryName":["'"${AD}"'"],"dnsIpAddresses":["'"${MSDS_IP[0]}"'","'"${MSDS_IP[1]}"'"]}' \
    --timeout-seconds 600 \
    --max-concurrency "50" \
    --max-errors "0" \
    --cloud-watch-output-config '{"CloudWatchOutputEnabled":true,"CloudWatchLogGroupName":"ssm-powershell-log-2024"}' |tee /tmp/ssm-$$.json

# wait to Success
COMMAND_ID=$(cat /tmp/ssm-$$.json |jq -r '.Command.CommandId')
watch -g -n 10 aws ssm get-command-invocation --command-id ${COMMAND_ID} --instance-id ${INST_ID} --query 'Status' --output text

```

- check join domain successfully or not, see `Domain:` in output
```sh
aws ssm send-command \
--document-name "AWS-RunPowerShellScript" \
--document-version "1" \
--targets '[{"Key":"InstanceIds","Values":["'"${INST_ID}"'"]}]' \
--parameters '{"workingDirectory":[""],"executionTimeout":["3600"],"commands":["systeminfo"]}' \
--timeout-seconds 600 --max-concurrency "50" --max-errors "0" \
--cloud-watch-output-config '{"CloudWatchOutputEnabled":true,"CloudWatchLogGroupName":"ssm-powershell-log-2024"}' 

```

#### install-some-tool-to-manage-ad-
- install `Remote Server Administration Tools` from powershell
```powershell
Install-WindowsFeature RSAT-ADDS-Tools
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature
```

- login instance with domain admin `admin@your.domain.com`
- create group for sftp access `testgroup1`
- create user belong this group `testuser1`
- get sid of ad group ([link](https://docs.aws.amazon.com/en_us/transfer/latest/userguide/directory-services-users.html#managed-ad-prereq))
```sh
Get-ADGroup -Filter {samAccountName -like "testgroup1*"} -Properties * | Select SamAccountName,ObjectSid
```

### transfer family

- allocate at least one elastic ip in your vpc
- request a certificate `ftp.your.domain.com` in acm
- create role to access s3, using transfer service as trust entity `access-s3-role`
- add directory service permissions to current user/role who will create ftp server ([link](https://docs.aws.amazon.com/en_us/transfer/latest/userguide/directory-services-users.html#managed-ad-prereq))

- create server with sftp and ftps protocol
- select `aws directory service` as **IdP**
- select `vpc hosted` as endpoint type, using `internet facing` access
- select public subnet and elastic ip
- modify or create security group for ports: `22,21,8192-8200` 
- s3 as backend
- select `enable` in `TLS session resumption` ([link](https://repost.aws/questions/QURR9WVIbjQ-uYYFu_gMCdhw/ftp-transfer-family-ftps-tls-resume-failed))

- after server created, add sid to `accesses`, mapping to role `access-s3-role`
- test user

### route53
- create cname record `ftp.your.domain.com` to ftp server's endpoint, or alias to vpce public dns name

### access ftp server
```sh
sftp testuser1@your.domain.com@ftp.your.domain.com
# or
lftp -d ftp://ftp.your.domain.com \
-u 'testuser1@your.domain.com,PASSWORD'
```

## conclusion

meeting requirement

## refer
- https://aws.amazon.com/blogs/aws/new-aws-transfer-for-ftp-and-ftps-in-addition-to-existing-sftp/
- https://aws.amazon.com/blogs/storage/announcing-the-open-source-release-of-web-client-for-aws-transfer-family/


## screenshots

### ftp client configuration

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-2.png]]

### upload and download using ftp client

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-3.png]]

### s3 bucket

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-4.png]]

### transfer family

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-5.png]]

### directory service

![[../git-attachment/POC-mig-filezilla-to-transfer-family-png-6.png]]

## refer
- https://repost.aws/knowledge-center/manage-ad-directory-from-ec2-windows

