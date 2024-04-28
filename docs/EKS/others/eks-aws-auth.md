---
title: eks-aws-auth
description: 
created: 2022-03-15 08:51:03.927
last_modified: 2024-04-23
tags:
  - aws/container/eks
---
# AWS Auth

The Advantage of using Role to access the cluster instead of specifying directly IAM users is that it will be easier to manage: we won’t have to update the ConfigMap each time we want to add or remove users, we will just need to add or remove users from the IAM Group and we just configure the ConfigMap to allow the IAM Role associated to the IAM Group.

https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

```sh
CLUSTER_NAME=ekscluster1
export AWS_DEFAULT_REGION=us-west-2
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query \"Account\" --output text)
eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} \
    --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/WSParticipantRole --username admin --group system:masters \
    --no-duplicate-arns
```
- [[git/git-mkdocs/CLI/linux/eksctl#iamidentitymapping-|eksctl]] 

## alternatives
- [[eks-access-api]]

## add user/role to aws-auth manually

```sh
kubectl edit configmap aws-auth -n kube-system
```

``` yaml
  mapUsers: |
    - userarn: arn:aws:iam::XXXXXXXXXXXX:user/testuser
      username: testuser
      groups:
      - system:masters
```

```yaml
  mapRoles: |
    - groups:
      - system:masters
      rolearn: arn:aws:iam::XXXXXXXXXXXX:role/WSParticipantRole
      username: system:role:adminrole
```

## more specific sample
https://aws.amazon.com/premiumsupport/knowledge-center/eks-kubernetes-object-access-error/

从这个章节“Create a cluster role and cluster role binding, or a role and role binding”，第一步或者第二步都可以实现查看pod资源，区别就是第一步权限更大，比如可以查看configmap secret之类的。

另外一个章节“View Kubernetes resources in a specific namespace”可以按照namespace进行区分允许细粒度查看资源（第一步或者第二步）。界面上可能报错，但是选对namespace就可以查看不会报错。





