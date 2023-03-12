---
title: ssm-cmd
description: 常用命令 
chapter: true
created: 2022-12-06 14:58:34.056
last_modified: 2022-12-06 14:58:34.056
tags: 
- aws/cli 
- aws/mgmt/systems-manager 
---
```ad-attention
title: This is a github note

```
# ssm-cmd

## ssm agent
```sh
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
```

## start-session
```sh
aws ssm start-session --target  i-xxxxxx --region us-east-2

```

## send-command
- [[ssm-document-runshell]]

## create document and run it
https://aws.amazon.com/blogs/mt/amazon-ec2-systems-manager-documents-support-for-cross-platform-documents-and-multiple-steps-of-the-same-type/

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


## filter-inventory-📚

```sh
aws ssm get-inventory --filter Key="Custom:DiskUtilization.Size(GB)",Values=100,Type=Equal

aws ssm get-inventory --filter Key=Custom:DiskUtilization.Use%,Values=60,Type=GreaterThan

```


## get parameter
- [[eks-public-access-cluster]]
- [[ssm-public-parameters]]
