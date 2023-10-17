---
title: "cluster-autoscaler"
description: "EKS 集群中安装 Cluster Autoscaler"
chapter: true
weight: 4
created: 2022-02-19 11:57:07.687
last_modified: 2022-02-19 11:57:07.6870
tags: 
- kubernetes 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# cluster-autoscaler

- [Lab](#lab)
	- [blog](#blog)
- [install](#install)
	- [manual](#manual)
		- [create service account](#create-service-account)
		- [install from yaml](#install-from-yaml)
	- [helm](#helm)

## link
- [workshop](https://www.eksworkshop.com/beginner/080_scaling/deploy_ca/)
- [troubleshooting](https://github.com/kubernetes/autoscaler/issues/1607#issuecomment-842038913)
- [github](https://github.com/kubernetes/autoscaler/tree/master)

### blog
- [[Creating Kubernetes Auto Scaling Groups for Multiple Availability Zones]]

## install
### manual
https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/autoscaling.html

#### create service account

```sh
CLUSTER_NAME=ekscluster1
AWS_REGION=us-east-2

cat > cluster-autoscaler-policy.json <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/k8s.io/cluster-autoscaler/<my-cluster>": "owned"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:DescribeLaunchTemplateVersions",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations"
            ],
            "Resource": "*"
        }
    ]
}
EOF

ARN=$(aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy-$RANDOM \
    --policy-document file://cluster-autoscaler-policy.json |jq -r '.Policy.Arn')

eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=${ARN} \
  --override-existing-serviceaccounts \
  --approve
```

#### install from yaml
```sh
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
sed -i "s/.YOUR CLUSTER NAME./${CLUSTER_NAME}/" cluster-autoscaler-autodiscover.yaml

kubectl apply -f cluster-autoscaler-autodiscover.yaml

kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

```

```sh
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```

```
#add following parameter
--balance-similar-node-groups
--skip-nodes-with-system-pods=false
```

get newest version for your cluster, for example 1.21.3 / 1.22.3
```sh
VER=1.21.3
kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v${VER}
```

```sh
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler
```

### helm
https://github.com/kubernetes/autoscaler/blob/master/charts/cluster-autoscaler/README.md

- [[cluster-autoscaler|create service account]] in previous chapter
- install from helm
```sh
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install myca-release autoscaler/cluster-autoscaler \
    -n kube-system \
    --set autoDiscovery.clusterName=${CLUSTER_NAME} \
    --set awsRegion=${AWS_REGION} \
    --set rbac.serviceAccount.create=false \
    --set rbac.serviceAccount.name=cluster-autoscaler

# refer values
# wget -O myca-values.yaml https://github.com/kubernetes/autoscaler/raw/master/charts/cluster-autoscaler/values.yaml

```

- check version
```sh
helm list -n kube-system

```


## compatibility and upgrade

https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix

