---
title: Create Public Access EKS Cluster in China Region
description: 在中国区域，创建共有访问的 EKS 集群
created: 2023-02-19 21:55:37.905
last_modified: 2024-01-21
tags:
  - aws/container/eks
  - aws/china
---
> [!WARNING] This is a github note
# Create Public Access EKS Cluster in China Region

- create cloud9
- create vpc
??? note "right-click & open-in-new-tab: "
    ![[../../cloud9/create-standard-vpc-for-lab-in-china-region#using-cloudformation-template-]]

- get vpc id
??? note "right-click & open-in-new-tab: "
    ![[../../cloud9/create-standard-vpc-for-lab-in-china-region#get-vpc-id-]]

- pre-config
??? note "right-click & open-in-new-tab: "
    ![[eks-private-access-cluster#prep-config-]]


- cluster config
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





