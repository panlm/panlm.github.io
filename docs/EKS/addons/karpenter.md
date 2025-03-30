---
title: karpenter
description: 使用 Karpenter 代替 Cluster Autoscaler
created: 2023-05-29 08:42:40.334
last_modified: 2024-08-22
tags:
  - aws/container/karpenter
  - aws/container/eks
---

# karpenter-lab

## compatibility
![[attachments/karpenter/IMG-karpenter.png]]

## install
- https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/

### using eksdemo
- https://github.com/awslabs/eksdemo/blob/main/docs/install-karpenter.md
```sh
eksdemo install karpenter -c ekscluster --dry-run

```

### using helm
- create sqs for interrupt event
```sh
aws sqs  create-queue --queue-name sqs-${CLUSTER_NAME}
```
- create service account (refer: [[../../CLI/linux/eksctl#func-create-iamserviceaccount-|func-create-iamserviceaccount]])
- install
```sh
echo ${KARPENTER_VERSION:=1.0.0}
echo ${KARPENTER_NAMESPACE:=karpenter}
echo ${CLUSTER_NAME:=ekscluster1}

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
    --version "${KARPENTER_VERSION}" \
    --namespace "${KARPENTER_NAMESPACE}" --create-namespace  \
    --set "settings.clusterName=${CLUSTER_NAME}"   \
    --set "settings.interruptionQueue=sqs-${CLUSTER_NAME}"   \
    --set controller.resources.requests.cpu=1   \
    --set controller.resources.requests.memory=1Gi   \
    --set controller.resources.limits.cpu=1   \
    --set controller.resources.limits.memory=1Gi   \
    --set serviceAccount.create=false \
    --set serviceAccount.name=karpenter 

```

```sh
helm upgrade -i -f a.value.yaml karpenter oci://public.ecr.aws/karpenter/karpenter \
    --version "${KARPENTER_VERSION}" \
    --namespace "${KARPENTER_NAMESPACE}" --create-namespace 
```

### previous version
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


## scenario
### coredns
```sh
kubectl get deploy -n kube-system coredns -o yaml

apiVersion: apps/v1
kind: Deployment
...
  template:
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
        karpenter.sh/do-not-evict: "true"
      creationTimestamp: null
      labels:
        eks.amazonaws.com/component: coredns
        foo: bar
        k8s-app: kube-dns
        ...

```

## workshop
- https://catalog.workshops.aws/karpenter/
- https://www.eksworkshop.com/beginner/085_scaling_karpenter/

## run gpu pod
- https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/

## refer
- [[Creating Kubernetes Auto Scaling Groups for Multiple Availability Zones]]
- https://stormforge.io/kubernetes-autoscaling/eks-karpenter/
- https://medium.com/@gajaoncloud/karpenter-mastery-nodepools-nodeclasses-for-workload-nirvana-bc89850fa934

![[attachments/karpenter/IMG-karpenter-2.png]]

- [[../../../../ec2-spot-instance|ec2-spot-instance]]

## sample

```
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: al2023@latest
  role: KarpenterNodeRole-ekscluster1
  securityGroupSelectorTerms:
  - tags:
      aws:eks:cluster-name: ekscluster1
  subnetSelectorTerms:
  - tags:
      Name: eksctl-ekscluster1-cluster/SubnetPrivate*
  tags:
    intent: apps

```


## sample - no amd
https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: eks.amazonaws.com/instance-cpu-manufacturer
                operator: In
                values:
                - aws
                - intel
      containers:
      - name: my-app
        image: nginx:latest

```
