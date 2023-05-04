---
title: "eks-public-access-cluster"
description: "创建公有访问的 eks 集群"
chapter: true
weight: 20
created: 2022-05-21 12:43:38.021
last_modified: 2022-11-20 11:28:30.221
tags: 
- aws/container/eks
---

```ad-attention
title: This is a github note

```

# eks-public-access-cluster

```toc
```

## prep

- do not need to create vpc in advance
- [[setup-cloud9-for-eks]] or using your local environment

## cluster yaml

- don't put `subnets`/`sharedNodeSecurityGroup` in your `vpc` section. eksctl will create a clean vpc for you
- don't use `privateCluster` section, you could make cluster api server endpoint `public` or `public and private`
- you still could put your group node in private subnet for security consideration
- recommend for most of poc environment

### create-eks-cluster
- 创建空配置文件
```sh
touch c1.yaml
```

- 复制粘贴下面代码到 `c1.yaml`，如果需要的话，从上面章节获取到最新的 `ami` 并更新到配置文件中
	- 注意集群名称
	- 注意使用的 AZ 符合你所在的区域

```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster1 # MODIFY cluster name, have another one in nodeGroup section
  region: "us-east-2" # MODIFY region
  version: "1.24" # MODIFY version

availabilityZones: ["us-east-2a", "us-east-2b", "us-east-2c"]

# REPLACE THIS CODE BLOCK
# vpc:
#   subnets:
#     private:
#       us-east-2a:
#         id: subnet-xxxxxxxx
#       us-east-2b:
#         id: subnet-xxxxxxxx
#     public:
#       us-east-2a:
#         id: subnet-xxxxxxxx
#       us-east-2b:
#         id: subnet-xxxxxxxx
#   sharedNodeSecurityGroup: sg-xxxxxxxx
vpc:
  cidr: "10.251.0.0/16"
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
  minSize: 2
  maxSize: 5
  desiredCapacity: 2
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true

addons:
- name: vpc-cni 
  version: latest
- name: coredns
  version: latest # auto discovers the latest available
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

```

- 创建集群，预计需要 20 分钟
```sh
eksctl create cluster -f c1.yaml
```

### get-newest-ami
- get newest ami id for your node group, for GPU or Graviton instance ([link](https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id.html))
```sh
# get optimized eks ami id for your version & region
AWS_REGION=us-east-2
EKS_VERSION=1.24
aws ssm get-parameter --name /aws/service/eks/optimized-ami/${EKS_VERSION}/amazon-linux-2/recommended/image_id --region ${AWS_REGION} --query "Parameter.Value" --output text

```

### config sample -- self-managed node
- 如果需要使用自管节点组，添加如下配置，且使用 ami 有效，如果你在其他 region 创建集群，请使用上面命令获取该 region 对应的 ami
```yaml
nodeGroups:
- name: ng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true
  ami: "ami-03fc1b405779966cc"
  amiFamily: AmazonLinux2
  overrideBootstrapCommand: |
    #!/bin/bash
    source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} --container-runtime containerd --kubelet-extra-args "--node-labels=${NODE_LABELS}"

```


## access eks cluster from web console
- 将实验环境对应的 `TeamRole` 角色作为集群管理员，方便使用 web 页面查看 eks 集群
```sh
CLUSTER_NAME=ekscluster1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-2
eksctl create iamidentitymapping \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/TeamRole \
  --username cluster-admin \
  --group system:masters \
  --region ${AWS_REGION}

```

## default tags on subnet
- [[eksctl-default-tags-on-subnet]]

## network topo preview
- [[TC-security-group-for-eks-deepdive]]

## refer
- [[eks-private-access-cluster]]
- [[eks-nodegroup]]


