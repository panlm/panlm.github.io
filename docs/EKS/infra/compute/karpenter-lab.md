---
title: karpenter-install-lab
description: 使用 Karpenter 代替 Cluster Autoscaler
created: 2023-05-29 08:42:40.334
last_modified: 2023-10-07 21:04:15.431
tags:
  - aws/container/karpenter
---
> [!WARNING] This is a github note

# karpenter-lab

## install
- https://karpenter.sh/v0.27.5/getting-started/getting-started-with-karpenter/

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

![[../../../git-attachment/karpenter-lab-png-1.png]]

## install eks-node-viewer

```sh
go install github.com/awslabs/eks-node-viewer/cmd/eks-node-viewer@latest
sudo mv -v ~/go/bin/eks-node-viewer /usr/local/bin

```


