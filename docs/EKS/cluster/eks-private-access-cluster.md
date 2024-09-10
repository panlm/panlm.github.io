---
title: Create Private Only EKS Cluster
description: 在已有 VPC 中创建私有访问的 EKS 集群
created: 2022-03-24 11:20:13.594
last_modified: 2024-03-27
tags:
  - aws/container/eks
---

# Create Private Only EKS Cluster

## prep bastion
- 创建vpc和cloud9 
    - [[../../cloud9/create-standard-vpc-for-lab-in-china-region]] or [hugo link]({{< ref "create-standard-vpc-for-lab-in-china-region" >}}) 
    - 如果只需要创建托管节点组，私有子网路由表可以没有指向 nat 的路由
    - 如果需要创建自管节点组，私有子网路由表需要有指向 nat 的路由，否则节点加集群失败，或者提前创建 eks endpoint。
```
Connect timeout on endpoint URL: "https://eks.us-east-1.amazonaws.com/clusters/ekscluster-name"
Exited with error on line 351
```

## prep cloud9
- 安装必要的软件 
    - [[../../cloud9/setup-cloud9-for-eks]] or [hugo link]({{< ref "setup-cloud9-for-eks" >}})
```sh
sudo yum -y install jq gettext bash-completion moreutils wget
```

- 创建安全组 eks-shared-sg，inbound规则是自己 (needed if your cluster is private only mode )
```sh
# export VPC_ID=vpc-xxxxxxxx
# export AWS_REGION=cn-north-1
AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AWS_DEFAULT_REGION=${AWS_REGION}
INST_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.instanceId')
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INST_ID} |jq -r '.Reservations[0].Instances[0].VpcId')

SG_NAME=eks-shared-sg
SG_ID=$(aws ec2 describe-security-groups \
--filter Name=vpc-id,Values=$VPC_ID \
--query "SecurityGroups[?GroupName == '"${SG_NAME}"'].GroupId" \
--output text)

# if SG does not existed, then create it
if [[ -z ${SG_ID} ]]; then
SG_ID=$(aws ec2 create-security-group \
  --description ${SG_NAME} \
  --group-name ${SG_NAME} \
  --vpc-id ${VPC_ID} \
  --query 'GroupId' \
  --output text )
aws ec2 authorize-security-group-ingress \
    --group-id ${SG_ID} \
    --protocol all \
    --source-group ${SG_ID}
fi

```

- assign security group to cloud9 instance
```sh
SG_LIST=$(aws ec2 describe-instance-attribute --instance-id $INST_ID --attribute groupSet --query 'Groups[*].[GroupId]' --output text)

# before
aws ec2 describe-instance-attribute --instance-id $INST_ID --attribute groupSet
# assign
aws ec2 modify-instance-attribute --instance-id $INST_ID --groups $SG_LIST $SG_ID
# after
aws ec2 describe-instance-attribute --instance-id $INST_ID --attribute groupSet

```

- if you create private only cluster in vpc which you have created with public/private eks endpoint, using the **Shared SG** of the previous cluster

## prep-config-
- 创建完自定义 vpc 后，直接执行下面代码
```sh
echo ${AWS_DEFAULT_REGION}

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text))

echo "export VPC_ID=${VPC_ID}" 
echo "export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo "export AZS=(${AZS[@]})"

# output yaml format for vpc/subnet info
( echo 'vpc:'
echo '  id:' ${VPC_ID}
echo '  subnets:'
echo '    private:'
for i in ${AZS[@]} ; do
    subnetid=$(aws ec2 describe-subnets \
    --filter "Name=availability-zone,Values=$i" "Name=vpc-id,Values=$VPC_ID" "Name=tag-key,Values=kubernetes.io/role/internal-elb" \
    --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output text)
    if [[ ! -z $subnetid ]]; then
        echo "      ${i}:"
        echo -e "        id: $subnetid"
    fi
done
echo '    public:'
for i in ${AZS[@]} ; do
    subnetid=$(aws ec2 describe-subnets \
    --filter "Name=availability-zone,Values=$i" "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' --output text)
    if [[ ! -z $subnetid ]]; then
        echo "      ${i}:"
        echo -e "        id: $subnetid"
    fi
done
if [ ! -z $SG_ID ]; then
    echo "  sharedNodeSecurityGroup: $SG_ID"
fi )

```

- output will be used in next step
- ensure you have no s3 endpoint in your target vpc 
    - you could have ssm/ssmmessages endpoint

## cluster yaml
```sh
touch cluster1.yaml
```

- commercial region sample config
	- check [[eks-public-access-cluster-in-china-region#^8ir6w8|here]] for china region sample config
```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster-privonly # MODIFY cluster name
  region: "us-east-2" # MODIFY region
  version: "1.24" # MODIFY version

# full private cluster
privateCluster:
  enabled: true 
  skipEndpointCreation: true # uncomment, if you create 2nd cluster in same vpc
#   additionalEndpointServices:
#   - "autoscaling"
#   - "logs"
#   - "cloudformation"

# REPLACE THIS CODE BLOCK
vpc:
  subnets:
    private:
      us-east-2a:
        id: subnet-xxxxxxxx
      us-east-2b:
        id: subnet-xxxxxxxx
    public:
      us-east-2a:
        id: subnet-xxxxxxxx
      us-east-2b:
        id: subnet-xxxxxxxx
  sharedNodeSecurityGroup: sg-xxxxxxxx

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

# secretsEncryption:
#   keyARN: ${MASTER_ARN}

managedNodeGroups:
- name: mng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true

nodeGroups:
- name: ng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true
  ami: ami-06a8057d9b6a06ee6
  amiFamily: AmazonLinux2
  overrideBootstrapCommand: |
    #!/bin/bash
    source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} --container-runtime containerd --kubelet-extra-args "--node-labels=${NODE_LABELS}"

iam:
  withOIDC: true

addons:
- name: vpc-cni 
  version: latest
- name: coredns
  version: latest # auto discovers the latest available
- name: kube-proxy
  version: latest

```

```sh
eksctl create cluster -f cluster1.yaml
```

```sh
# get optimized eks ami id for your version & region
EKS_VERSION=1.24
# AWS_REGION=us-east-2
aws ssm get-parameter --name /aws/service/eks/optimized-ami/${EKS_VERSION}/amazon-linux-2/recommended/image_id --query "Parameter.Value" --output text

```

### endpoint-
https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html#private-cluster-requirements

- 设置 `skipEndpointCreation: false`，集群创建完成后将自动创建以下 endpoint，并且绑定 `sharedNodeSecurityGroup` 中指定的安全组
	- logs
	- s3 (gw)
	- sts
	- ec2 / ec2messages
	- ecr.dkr / ecr.api
- 你可以自己创建以下 endpoint，并且绑定安全组允许 80 443 访问
	- ssm / ssmmessages
- 另外还需要提前创建以下 endpoint，并且绑定安全组
	- eks （使用自管节点组时需要）
	- elasticfilesystem （使用 efs 时需要）
	- elasticloadbalancing （使用 aws lb controller时需要）
	- kms （待验证）
	- ebs （待验证）
	- cloudformation (additional)
	- autoscaling (hpa)

## access cluster
- [[create-kubeconfig-manually]]
- [[recover-access-eks]]
- [[token-different]]

## issue about kubectl
### solve 1
- download aws-iam-authenticator, and then run write-kubeconfig command
it will using aws-iam-authenticator instead of aws to create kubeconfig
- `aws eks update-kubeconfig` default using aws
- `eksctl utils write-kubeconfig` default using aws-iam-authenticator if you have installed

```
eksctl utils write-kubeconfig --cluster ekscluster1
```

### solve 2
- check if null TOKEN variable `aws_session_token=` in your `~/.aws/credentials`
- delete it

## network topo preview
- [[../solutions/network/TC-security-group-for-eks-deepdive]]

## reference
- [[eks-public-access-cluster]]
- [[eks-nodegroup]]
- [[eksctl-sample-priv-addons]]

