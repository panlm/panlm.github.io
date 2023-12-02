---
title: eks-public-access-cluster
description: 创建公有访问的 eks 集群
created: 2022-05-21 12:43:38.021
last_modified: 2023-11-18
tags:
  - aws/container/eks
---
> [!WARNING] This is a github note

# eks-public-access-cluster

## prep

- do not need to create vpc in advance
- [[../../../cloud9/setup-cloud9-for-eks]] or using your local environment

## create cluster from scratch

- don't put `subnets`/`sharedNodeSecurityGroup` in your `vpc` section. eksctl will create a clean vpc for you
- don't use `privateCluster` section, you could make cluster api server endpoint `public` or `public and private`
- you still could put your group node in private subnet for security consideration
- recommend for most of POC environment

### create eks cluster

- 将在下面区域创建 EKS 集群 (prepare to create eks cluster)
```sh
export AWS_PAGER=""
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AWS_REGION=${AWS_DEFAULT_REGION}

export CLUSTER_NAME=ekscluster1
export EKS_VERSION=1.25
CLUSTER_NUM=$(eksctl get cluster |wc -l)
export CIDR="10.25${CLUSTER_NUM}.0.0/16"

```

- 执行下面代码创建配置文件 (create eks cluster)
	- 注意集群名称
	- 注意使用的 AZ 符合你所在的区域
```sh
AZS=($(aws ec2 describe-availability-zones \
--query 'AvailabilityZones[].ZoneName' --output text |awk '{print $1,$2}'))
export AZ0=${AZS[0]}
export AZ1=${AZS[1]}

cat >$$.yaml <<-'EOF'
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: "${CLUSTER_NAME}"
  region: "${AWS_REGION}"
  version: "${EKS_VERSION}"

availabilityZones: ["${AZ0}", "${AZ1}"]

vpc:
  cidr: "${CIDR}"
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

# secretsEncryption:
#   keyARN: ${MASTER_ARN}

managedNodeGroups:
- name: managed-ng
  minSize: 1
  maxSize: 5
  desiredCapacity: 2
  instanceType: m5.large
  privateNetworking: true

addons:
- name: vpc-cni 
  version: latest
- name: coredns
  version: latest 
- name: kube-proxy
  version: latest

iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
  - metadata:
      name: ebs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      ebsCSIController: true
  - metadata:
      name: efs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      efsCSIController: true
  - metadata:
      name: cloudwatch-agent
      namespace: amazon-cloudwatch
    attachPolicyARNs:
    - "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  - metadata:
      name: fluent-bit
      namespace: amazon-cloudwatch
    attachPolicyARNs:
    - "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
EOF
cat $$.yaml |envsubst '$CLUSTER_NAME $AWS_REGION $AZ0 $AZ1 $EKS_VERSION $CIDR ' > cluster-${CLUSTER_NAME}.yaml

```

- 创建集群，预计需要 20 分钟 (wait about 20 mins)
```sh
eksctl create cluster -f cluster-${CLUSTER_NAME}.yaml

```

### get-newest-ami

- get newest ami id for your self-managed node group, for GPU or Graviton instance ([link](https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id.html))
```sh
echo ${AWS_REGION}
echo ${EKS_VERSION}

export AMI=$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${EKS_VERSION}/amazon-linux-2/recommended/image_id --region ${AWS_REGION} --query "Parameter.Value" --output text)

cat  <<-'EOF' |envsubst '$AMI' |tee -a cluster-${CLUSTER_NAME}.yaml
nodeGroups:
- name: ng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true
  ami: "${AMI}"
  amiFamily: AmazonLinux2
  overrideBootstrapCommand: |
    #!/bin/bash
    source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} --container-runtime containerd --kubelet-extra-args "--node-labels=${NODE_LABELS} --max-pods=110"
EOF

```
- 托管节点没有 `/var/lib/cloud/scripts/eksctl/bootstrap.helper.sh` 脚本，导致当使用定制 ami 并且 extra args 中 NODE_LABELS 参数丢失。(refer [link](https://eksctl.io/announcements/nodegroup-override-announcement/))


### access eks cluster from web console

- 将实验环境对应的 `TeamRole` 角色作为集群管理员，方便使用 web 页面查看 eks 集群
```sh
echo ${CLUSTER_NAME}

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-2

for i in TeamRole WSOpsRole WSParticipantRole WSAdminRole ; do
eksctl create iamidentitymapping \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/${i} \
  --username cluster-admin \
  --group system:masters \
  --region ${AWS_REGION}
done

```


## create cluster in existed VPC

- get target vpc id
- create SG ([[../../../CLI/awscli/ec2-cmd#func-create-sg-]])
    - or using existed cluster's shared SG (see chapter refer)
- get vpc info ([[git/git-mkdocs/EKS/infra/cluster/eks-private-access-cluster#prep-config-]])
- cluster yaml
```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster2 # MODIFY cluster name
  region: "us-east-2" # MODIFY region
  version: "1.25" # MODIFY version

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
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

# secretsEncryption:
#   keyARN: ${MASTER_ARN}

managedNodeGroups:
- name: mng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 2
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true

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


## refer

- [[TC-security-group-for-eks-deepdive]]
- [[eks-private-access-cluster]]
- [[eks-nodegroup]]
- [[eksctl-default-tags-on-subnet]]


