---
title: "eks-public-access-cluster-in-china-region"
description: "在中国区域，创建共有访问的 eks 集群"
chapter: true
weight: 50
created: 2023-02-19 21:55:37.905
last_modified: 2023-02-19 21:55:37.905
tags: 
- aws/container/eks
- aws/china 
---
# eks-public-access-cluster-in-china-region

1. create cloud9
2. create vpc
![[create-standard-vpc-for-lab#using cloudformation template]]

3. get vpc id
![[create-standard-vpc-for-lab#get vpc id]]

4. pre-config
![[eks-private-access-cluster#^h86u1r]]

or hugo code:
{{< ref "eks-private-access-cluster#prep config" >}}

5. cluster config

```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster131 # MODIFY cluster name
  region: "cn-north-1" # MODIFY region
  version: "1.24" # MODIFY version

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
  minSize: 2
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

^8ir6w8





