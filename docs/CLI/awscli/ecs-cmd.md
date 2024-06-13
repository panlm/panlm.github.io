---
title: ecs
description: 常用命令
created: 2023-02-22 22:46:31.539
last_modified: 2024-03-19
icon: simple/amazonecs
tags:
  - aws/container/ecs
  - aws/cmd
---
# ecs-cmd
## get ami list
### al2
- get full list
```sh
aws ssm get-parameters-by-path \
    --path /aws/service/ecs/optimized-ami/amazon-linux-2 \
    --query 'Parameters[?contains(ARN, `arn:aws:ssm:us-east-2::parameter/aws/service/ecs/optimized-ami/amazon-linux-2/ami-`)==`true`]' \
    |jq -r 'sort_by(.LastModifiedDate)' 
```

- get ecs recommended optimized ami
```sh
ECS_AMI=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended |jq -r '.Parameters[0].Value' |jq -r '.image_id')
```

- get last 2 AMI ID
```sh
export AWS_DEFAULT_REGION=us-east-1

AMI_IDS=($(
aws ssm get-parameters-by-path \
    --path /aws/service/ecs/optimized-ami/amazon-linux-2 \
    --query 'sort_by(Parameters,&LastModifiedDate)[?contains(ARN, `arn:aws:ssm:'"${AWS_DEFAULT_REGION}"'::parameter/aws/service/ecs/optimized-ami/amazon-linux-2/ami-`)==`true`]' \
    |jq -r '.[].Value' |jq -r '.image_id' \
    |tail -n 2
))

OLD_AMI_ID=${AMI_IDS[0]}
NEW_AMI_ID=${AMI_IDS[1]}
echo ${AMI_IDS[@]}
```

### windows 2019
```sh
export AWS_DEFAULT_REGION=us-east-1
export AMI_WIN2019_NAME="Windows_Server-2019-English-Full-ECS_Optimized"

AMI_IDS=($(
aws ec2 describe-images \
    --filter "Name=name,Values=${AMI_WIN2019_NAME}*" \
    --query  'Images[*].[ImageId,CreationDate,Name]' --output text |grep ECS_Optimized |sort -k2 |tail -n 2 |awk '{print $1}'
))

OLD_AMI_ID=${AMI_IDS[0]}
NEW_AMI_ID=${AMI_IDS[1]}
echo ${AMI_IDS[@]}

```

## create-ecs-cluster-
### create launch template v1
```sh
ECS_CLUSTER=myecs1
VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
export AWS_PAGER=""
export AWS_DEFAULT_REGION=us-east-1

```
- get default security group ([[../functions/func-create-sg.sh|func-create-sg.sh]])
```sh
create-sg -v ${VPC_ID} -c 0.0.0.0/0 # call my function
echo ${SG_ID}

```
- execute function to create launch template ([[auto-scaling-cmd#func-create-launch-template-]])
```sh
echo ${SG_ID}
echo ${OLD_AMI_ID}
create-launch-template ${SG_ID} ${OLD_AMI_ID} # call my function
echo ${LAUNCH_TEMPLATE_ID}

```
- execute function to create ec2 admin role ([[git/git-mkdocs/CLI/awscli/iam-cmd#func-ec2-admin-role-create-]])
```sh
ec2-admin-role-create # call my function
echo ${INSTANCE_PROFILE_ARN}

```
### add user data to launch template and make v2 as default
#### linux node
```sh
TMP=$(mktemp --suffix .UserData)
envsubst >${TMP} <<-EOF
#!/bin/bash
echo ECS_CLUSTER=${ECS_CLUSTER} >> /etc/ecs/ecs.config
sudo iptables --insert FORWARD 1 --in-interface docker+ --destination 169.254.169.254/32 --jump DROP
sudo service iptables save
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
EOF
B64STRING=$(cat ${TMP}|base64 -w 0)
aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID} \
    --version-description ${LAUNCH_TEMPLATE_ID}-$(TZ=CST-8 date +%H%M) \
    --source-version 1 \
    --launch-template-data '{"UserData":"'"${B64STRING}"'","IamInstanceProfile":{"Arn":"'"${INSTANCE_PROFILE_ARN}"'"}}' |tee ${TMP}.out

aws ec2 modify-launch-template --launch-template-id ${LAUNCH_TEMPLATE_ID} --default-version "2"
```

if you use gMSA on linux, add following lines to beginning of user data
```sh
#!/bin/bash
echo "ECS_GMSA_SUPPORTED=true" >> /etc/ecs/ecs.config
echo "sleeping for 80 secs to avoid RPM lock error..."
sleep 80s
dnf install dotnet realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation samba-common-tools credentials-fetcher -y
systemctl enable credentials-fetcher
systemctl start credentials-fetcher

```

#### windows node
```sh
TMP=$(mktemp --suffix .UserData)
envsubst >${TMP} <<-EOF
Content-Type: multipart/mixed; boundary="67fa5624dc94e98fee4093fbc2d9d1de2825990f57aa9b139aed1acf3b3a"
MIME-Version: 1.0

--67fa5624dc94e98fee4093fbc2d9d1de2825990f57aa9b139aed1acf3b3a
Content-Type: text/text/plain; charset="utf-8"
Mime-Version: 1.0

<powershell>
Import-Module ECSTools;
[Environment]::SetEnvironmentVariable("ECS_CLUSTER", "${ECS_CLUSTER}", "Machine");
[Environment]::SetEnvironmentVariable("ECS_GMSA_SUPPORTED", "true", "Machine")
[Environment]::SetEnvironmentVariable("ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE", "true", "Machine");
[Environment]::SetEnvironmentVariable("ECS_ENABLE_TASK_ENI", "true", "Machine");
[Environment]::SetEnvironmentVariable("ECS_AVAILABLE_LOGGING_DRIVERS", '["json-file","awslogs"]', "Machine");
[Environment]::SetEnvironmentVariable("ECS_ENABLE_TASK_IAM_ROLE", "true", "Machine");
Install-PackageProvider -Name NuGet -Force;
Initialize-ECSAgent -Cluster '${ECS_CLUSTER}' -EnableTaskIAMRole -AwsvpcBlockIMDS
</powershell>

--67fa5624dc94e98fee4093fbc2d9d1de2825990f57aa9b139aed1acf3b3a
Content-Type: text/text/x-shellscript; charset="utf-8"
Mime-Version: 1.0


#!/bin/bash
echo ECS_CLUSTER=${ECS_CLUSTER} >> /etc/ecs/ecs.config
echo ECS_GMSA_SUPPORTED=true >> /etc/ecs/ecs.config

--67fa5624dc94e98fee4093fbc2d9d1de2825990f57aa9b139aed1acf3b3a--
EOF

B64STRING=$(cat ${TMP}|base64 -w 0)
aws ec2 create-launch-template-version \
    --launch-template-id ${LAUNCH_TEMPLATE_ID} \
    --version-description ${LAUNCH_TEMPLATE_ID}-$(TZ=CST-8 date +%H%M) \
    --source-version 1 \
    --launch-template-data '{"UserData":"'"${B64STRING}"'","IamInstanceProfile":{"Arn":"'"${INSTANCE_PROFILE_ARN}"'"}}' |tee ${TMP}.out

aws ec2 modify-launch-template --launch-template-id ${LAUNCH_TEMPLATE_ID} --default-version "2"

```

### create auto scaling group
- execute function to create auto scaling group ([[auto-scaling-cmd#func-create-auto-scaling-group-]])
- ASG's desire number is zero
```sh
create-auto-scaling-group ${LAUNCH_TEMPLATE_ID} # call my function
echo ${ASG_ARN}

```

### create cluster
- create ecs cluster (before create asg if desire number is greater than 0)
```sh
echo ${ECS_CLUSTER}

# this command will failed if you already have service linked role
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com

aws ecs create-cluster --cluster-name ${ECS_CLUSTER}

```

#### create capacity provider
- capacity provider (if desire number in asg is greater than 0, than no CP needed)
```sh
ECS_CAP_PROVIDER=mycp1
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=100},managedTerminationProtection=ENABLED"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1
```

#### change asg desire number to non-zero
- if you do not create CP, change ASG desire number to 1, EC2 will be spun up and add to ECS cluster

## get container instances
```sh
CONTAINER_INST_ARN=($(aws ecs list-container-instances --cluster ${ECS_CLUSTER} \
    --query 'containerInstanceArns[]' --output text |xargs ))
CONTAINER_INST=($(
    for i in ${CONTAINER_INST_ARN[@]} ; do
        echo ${i##*/}
    done
))
echo ${CONTAINER_INST[@]}
aws ecs describe-container-instances --cluster ${ECS_CLUSTER} \
    --container-instances ${CONTAINER_INST[@]} |tee /tmp/$$-instance
cat /tmp/$$-instance |jq -r '.containerInstances[] | [.ec2InstanceId, .versionInfo.agentVersion]|@tsv' 
```


## sample for ami upgrade / replace 
### register task definition
```sh
TASK_NAME=task2-$(TZ=EAT-8 date +%Y%m%d-%H%M)

envsubst >task-definition.json <<-EOF
{
  "containerDefinitions": [
    {
      "name": "nginx",
      "image": "nginx",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp",
          "name": "nginx-80-tcp",
          "appProtocol": "http"
        }
      ],
      "essential": true
    }
  ],
  "family": "${TASK_NAME}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": [
    "EC2"
  ],
  "cpu": "1024",
  "memory": "3072"
}
EOF

aws ecs register-task-definition \
    --cli-input-json file://./task-definition.json

```

### create service
- create alb and target group first ([[elb-cmd#func-alb-and-tg-]])
```sh
create-alb-and-tg
echo ${TG80_ARN}
```
- create service
```sh
echo ${ECS_CLUSTER}
echo ${TG80_ARN}
echo ${TASK_NAME}
echo ${VPC_ID}
SERVICE_NAME=${TASK_NAME}-svc
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
    --filter Name=vpc-id,Values=${VPC_ID} \
    --query "SecurityGroups[?GroupName == 'default'].GroupId" \
    --output text)
ALL_SUBNET_ID=$(aws ec2 describe-subnets \
    --filter "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId')

envsubst >svc-definition.json <<-EOF
{
    "serviceName": "${SERVICE_NAME}",
    "taskDefinition": "${TASK_NAME}",
    "loadBalancers": [
        {
            "targetGroupArn": "${TG80_ARN}",
            "containerName": "nginx",
            "containerPort": 80
        }
    ],
    "networkConfiguration": {
        "awsvpcConfiguration": {
            "subnets": ${ALL_SUBNET_ID},
            "securityGroups": [
                "${DEFAULT_SG_ID}"
            ],
            "assignPublicIp": "DISABLED"
        }
    }, 
    "desiredCount": 3
}
EOF

aws ecs create-service \
    --cluster ${ECS_CLUSTER} \
    --service-name ${SERVICE_NAME} \
    --cli-input-json file://svc-definition.json

```

### update-launch-template-
- update launch template based on default version
```sh
echo ${NEW_AMI_ID}

LT_DEF_VER=$(aws ec2 describe-launch-templates --launch-template-ids  ${LAUNCH_TEMPLATE_ID} --query 'LaunchTemplates[0].DefaultVersionNumber' --output text)

aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID} \
    --version-description ${LAUNCH_TEMPLATE_ID}-$(TZ=CST-8 date +%H%M) \
    --source-version ${LT_DEF_VER} \
    --launch-template-data '{"ImageId":"'"${NEW_AMI_ID}"'"}' |tee /tmp/$$-new-lt

LT_VER=$(cat /tmp/$$-new-lt |jq -r '.LaunchTemplateVersion.VersionNumber')

```

### update-asg-
- update asg using new template version
```sh
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_ARN##*/} \
    --launch-template LaunchTemplateId=${LAUNCH_TEMPLATE_ID},Version=${LT_VER}

```


### get task definition
```sh
ECS_SVC_NAME=${SERVICE_NAME}
ECS_TASK_DEF_ARN=$(aws ecs describe-services --cluster ${ECS_CLUSTER} \
--services ${ECS_SVC_NAME} \
--query "services[].deployments[].["taskDefinition"]" --output text)

```

### modify-task-definition-
- update task definition
```sh
# ami-0b7778d86d8789cff / ami-0f896121197c465b6
echo ${NEW_AMI_ID}
aws ecs describe-task-definition --task-definition ${ECS_TASK_DEF_ARN} --query taskDefinition | \
jq '. + {placementConstraints: [{"expression": "attribute:ecs.ami-id == '"${NEW_AMI_ID}"'", "type": "memberOf"}]}' | \
jq 'del(.status)'| jq 'del(.revision)' | jq 'del(.requiresAttributes)' | \
jq '. + {containerDefinitions:[.containerDefinitions[] + {"memory":256, "memoryReservation": 128}]}'| \
jq 'del(.compatibilities)' | jq 'del(.taskDefinitionArn)' | jq 'del(.registeredAt)' | jq 'del(.registeredBy)' > new-task-def.json
```
- register new one
```sh
aws ecs register-task-definition \
    --cli-input-json file://./new-task-def.json |tee /tmp/$$-new-task-def
TASK_DEF_ARN=$(cat /tmp/$$-new-task-def |jq -r '.taskDefinition.taskDefinitionArn')

```

### update service 
```sh
aws ecs update-service --cluster ${ECS_CLUSTER} --service ${SERVICE_NAME} --task-definition ${TASK_DEF_ARN##*/}
```

### func ecsexec to test
```sh
ECS_CLUSTER=CapacityProviderDemo
function ecsexec {
aws ecs execute-command \
    --cluster ${ECS_CLUSTER} --task $1 \
    --command /bin/sh --interactive \
    --command "curl localhost:5000" \
    --region us-east-2 
}
```


## sample for domain-less windows

```sh
envsubst >${TMP}.td.3 <<-'EOF'
{
  "family": "windows-gmsa-domainless-task",
  "containerDefinitions": [
    {
      "name": "windows_sample_app",
      "image": "111111111111.dkr.ecr.us-east-1.amazonaws.com/amazon-ecs-gmsa-linux/web-site",
      "cpu": 1024,
      "memory": 1024,
      "essential": true,
      "credentialSpecs": [
        "credentialspecdomainless:arn:aws:ssm:us-east-1:111111111111:parameter/amazon-ecs-gmsa-linux/credspec"
      ],
      "entryPoint": [
        "powershell",
        "-Command"
      ],
      "command": [
        "New-Item -Path C:\\inetpub\\wwwroot\\index.html -ItemType file -Value '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p>' -Force ; C:\\ServiceMonitor.exe w3svc"
      ],
      "portMappings": [
        {
          "protocol": "tcp",
          "containerPort": 80,
          "hostPort": 8080
        }
      ]
    }
  ],
  "taskRoleArn": "arn:aws:iam::111111111111:role/ecs-exec-demo-task-role",
  "executionRoleArn": "arn:aws:iam::111111111111:role/ecs-exec-demo-task-execution-role"
}
EOF

aws ecs register-task-definition \
    --cli-input-json file://${TMP}.td.3
```




## others
### get-windows-ecs-ami-list-
```sh
aws ssm get-parameters-by-path \
    --path /aws/service/ami-windows-latest \
    --query 'Parameters[].Name' |grep 2019 |grep ECS

aws ssm get-parameter \
    --name "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-ECS_Optimized"
    
```



### sample

- create asg & launch template first
    - [[auto-scaling-cmd#launch-template-and-auto-scaling-group-]]

```sh
ECS_CLUSTER_NAME=MyCluster
aws ecs create-cluster \
    --cluster-name ${ECS_CLUSTER_NAME}

ECS_CAP_PROVIDER=MyCapacityProvider
aws ecs create-capacity-provider \
    --name "${ECS_CAP_PROVIDER}" \
    --auto-scaling-group-provider "autoScalingGroupArn=${ASG_ARN},managedScaling={status=ENABLED,targetCapacity=10}"

aws ecs put-cluster-capacity-providers \
    --cluster ${ECS_CLUSTER_NAME} \
    --capacity-providers ${ECS_CAP_PROVIDER} \
    --default-capacity-provider-strategy capacityProvider=${ECS_CAP_PROVIDER},weight=1

```




