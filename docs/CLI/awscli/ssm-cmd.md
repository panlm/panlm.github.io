---
title: ssm
description: 常用命令
created: 2022-12-06 14:58:34.056
last_modified: 2024-02-05
tags:
  - aws/cmd
  - aws/mgmt/systems-manager
---

# ssm-cmd
## ssm agent
### centos
```sh
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
```
### ubuntu
amazon-ssm-agent has been installed in ubuntu 24

## test connect available or not
```sh
aws ssm get-connection-status \
--target i-xxxx8c8d

```

## start-session
```sh
INST_ID=
aws ssm start-session --target  ${INST_ID} --region us-east-1
```

### port forward
- https://aws.amazon.com/blogs/aws/new-port-forwarding-using-aws-system-manager-sessions-manager/

```sh
INST_ID=
aws ssm start-session --target ${INST_ID} \
--document-name AWS-StartPortForwardingSession \
--parameters '{"localPortNumber":["9999"],"portNumber":["80"]}' 

# target 81 
# local 9999
# curl http://localhost:9999

```

### port forward to remote host
```sh
INST_ID=
REMOTE_HOST=
aws ssm start-session --target ${INST_ID} \
--document-name AWS-StartPortForwardingSessionToRemoteHost \
--parameters '{
"localPortNumber":["9999"],
"host":["'"${REMOTE_HOST}"'"],
"portNumber":["443"]
}' 

```


## send-command
- [[ssm-document-runshell]]

## create document and run it
- https://aws.amazon.com/blogs/mt/amazon-ec2-systems-manager-documents-support-for-cross-platform-documents-and-multiple-steps-of-the-same-type/

```sh
aws ssm create-document --name step3demo --content file://a.json --document-type Command
```

```sh
# create automation document
for FILE in * ; do
    aws ssm create-document \
    --content file://./${FILE} \
    --name ${FILE%%.json} \
    --document-type Automation
done

```


## parameter
```sh
aws ssm put-parameter \
    --name  /brconnector/first-user-key  \
    --value "" \
    --type String \
    --overwrite \
    --region us-west-2

```

## filter-inventory-
```sh
aws ssm get-inventory --filter Key="Custom:DiskUtilization.Size(GB)",Values=100,Type=Equal
aws ssm get-inventory --filter Key=Custom:DiskUtilization.Use%,Values=60,Type=GreaterThan

```


## get parameter
- [[../../EKS/cluster/eks-public-access-cluster]]
- [[ssm-public-parameters]]

## join domain sample
??? note "right-click & open-in-new-tab: "
    ![[../../others/POC-mig-filezilla-to-transfer-family#join-domain-]]


- example
```sh
aws ssm send-command --document-name "AWS-JoinDirectoryServiceDomain" --document-version "1" --targets '[{"Key":"InstanceIds","Values":["i-0e23xxxx8bdc6xxxx"]}]' --parameters '{"directoryOU":[""],"directoryId":["d-9axxxxe3cf"],"directoryName":["xxxx.aws.panlm.xyz"],"dnsIpAddresses":["172.31.xx.xx","172.31.xx.xx"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region us-east-2

```


## create ssm vpc endpoint

```sh
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AWS_PAGER=''

# get cloud9 vpc
C9_INST_ID=$(curl http://169.254.169.254/1.0/meta-data/instance-id 2>/dev/null)
C9_VPC_ID=$(aws ec2 describe-instances \
--instance-ids ${C9_INST_ID} \
--query 'Reservations[0].Instances[0].VpcId' --output text)

# get public subnet 
C9_SUBNETS_ID=$(aws ec2 describe-subnets \
--filter "Name=vpc-id,Values=${C9_VPC_ID}" \
--query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
--output text)

# get default security group 
C9_DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
--filter Name=vpc-id,Values=${C9_VPC_ID} \
--query "SecurityGroups[?GroupName == 'default'].GroupId" \
--output text)

# allow 80/443 from anywhere
for i in 80 443 ; do
aws ec2 authorize-security-group-ingress \
  --group-id ${C9_DEFAULT_SG_ID} \
  --protocol tcp \
  --port $i \
  --cidr 0.0.0.0/0  
done

# ssm ssmmessages
for i in ssm ssmmessages ; do
aws ec2 create-vpc-endpoint \
--vpc-id ${C9_VPC_ID} \
--vpc-endpoint-type Interface \
--service-name com.amazonaws.${AWS_DEFAULT_REGION}.${i} \
--subnet-ids ${C9_SUBNETS_ID} \
--security-group-id ${C9_DEFAULT_SG_ID} 
done

```
^ssm-vpce-0513




