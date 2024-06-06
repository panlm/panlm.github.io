---
title: karpenter
description: 使用 Karpenter 代替 Cluster Autoscaler
created: 2023-05-29 08:42:40.334
last_modified: 2023-11-22
tags:
  - aws/container/karpenter
  - aws/container/eks
---

# karpenter-lab

## compatibility
![[attachments/karpenter/IMG-karpenter.png]]

## install
- https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/

```sh

echo ${CLUSTER_NAME:=eks-upgrade-demo}
echo ${AWS_DEFAULT_REGION:=us-east-2}

export KARPENTER_VERSION=v0.27.5
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT=$(mktemp)

echo $KARPENTER_VERSION $CLUSTER_NAME $AWS_DEFAULT_REGION $AWS_ACCOUNT_ID $TEMPOUT

```

```sh
curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

```

## instance family

```yaml
spec:
  requirements:
  - key: karpenter.k8s.aws/instance-family
    operator: In
    values: [c5, m5, r5]

```

![[attachments/karpenter/IMG-karpenter-1.png]]

## install eks-node-viewer

```sh
go install github.com/awslabs/eks-node-viewer/cmd/eks-node-viewer@latest
sudo mv -v ~/go/bin/eks-node-viewer /usr/local/bin

```

## Lab
- [workshop](https://www.eksworkshop.com/beginner/085_scaling_karpenter/)

## run gpu pod
- https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/

## refer
- https://karpenter.sh/v0.32/
- [[Creating Kubernetes Auto Scaling Groups for Multiple Availability Zones]]


![[attachments/karpenter/IMG-karpenter-2.png]]




