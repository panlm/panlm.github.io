---
title: EKS Access API
description: eks-access-api
created: 2024-01-08 08:35:17.895
last_modified: 2024-02-16
tags:
  - aws/container/eks
  - aws/security/iam
---

# EKS Access API
news:
https://aws.amazon.com/about-aws/whats-new/2023/12/amazon-eks-controls-iam-cluster-access-management/
blog:
https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/

## console walkthrough 
- when use eksdemo, you use sts credential will cause failed after create cluster success. 
- go `access` tab in eks cluster page
- add instance's role to it as `AmazonEKSClusterAdminPolicy`
- switch back to instance to update kube-config and create node group using eksdemo 
- add role to aws-auth config map

## walkthrough
```sh
export AWS_DEFAULT_REGION=
REGION_SUFFIX=$(echo ${AWS_DEFAULT_REGION} |egrep -q '^cn-' && echo '-cn' || echo '')
PRINCIPAL_ARN=arn:aws${REGION_SUFFIX}:iam::xxx:user/panlm
CLUSTER_NAME=ekscluster1

# default mode for new cluster
aws eks update-cluster-config \
   --name ${CLUSTER_NAME} \
   --access-config authenticationMode=API_AND_CONFIG_MAP

aws eks list-access-entries --cluster-name ${CLUSTER_NAME}

aws eks create-access-entry --cluster-name ${CLUSTER_NAME} \
  --principal-arn ${PRINCIPAL_ARN}

aws eks associate-access-policy --cluster-name ${CLUSTER_NAME} \
  --principal-arn  ${PRINCIPAL_ARN} \
  --policy-arn arn:aws${REGION_SUFFIX}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

```

```sh
aws eks delete-access-entry --cluster-name ${CLUSTER_NAME} \
  --principal-arn ${PRINCIPAL_ARN}
```

## available in china region 
- available

## alternative
- [[eks-aws-auth|eks-aws-auth]]


## refer
https://www.wiz.io/blog/new-attack-vectors-emerge-via-recent-eks-access-entries-and-pod-identity-features

![[attachments/eks-access-api/IMG-eks-access-api.png]]

