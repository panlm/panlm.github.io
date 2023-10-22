---
title: eks-addons-vpc-cni
description: eks-addons-vpc-cni
chapter: true
weight: 123
created: 2023-07-31 08:44:28.400
last_modified: 2023-07-31 08:44:28.400
tags: 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# eks-addons-vpc-cni

- [github](#github)
- [Updating add-on](#updating-add-on)
	- [from webui (prefer)](#from-webui-prefer)
	- [from cli](#from-cli)
	- [re-install](#re-install)
- [additional](#additional)


## github

- [github](https://github.com/aws/amazon-vpc-cni-k8s) 
- [doc](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html) 

minor version
![eks-addons-vpc-cni-png-1.png](../../../git-attachment/eks-addons-vpc-cni-png-1.png)

latest version 
20230731 update: 1.13.3-eksbuild.1
![eks-addons-vpc-cni-png-2.png](../../../git-attachment/eks-addons-vpc-cni-png-2.png)


<mark style="background: #FFB86CA6;">Upgrading (or downgrading) the VPC CNI version should result in no downtime</mark>. Existing pods should not be affected and will not lose network connectivity. New pods will be in pending state until the VPC CNI is fully initialized and can assign pod IP addresses. In v1.12.0+, VPC CNI state is restored via an on-disk file: `/var/run/aws-node/ipam.json`. In lower versions, state is restored via calls to container runtime.


## Updating add-on 
### from webui (prefer)
<mark style="background: #BBFABBA6;">works</mark>
select `PRESERVE` 

### from cli
<mark style="background: #FF5582A6;">not success</mark>

- check addon version
```sh
CLUSTER_NAME=ekscluster1
export AWS_DEFAULT_REGION=us-east-2
aws eks describe-addon --cluster-name ${CLUSTER_NAME} \
--addon-name vpc-cni --query addon.addonVersion --output text

```
- backup
```sh
kubectl get daemonset aws-node -n kube-system -o yaml > aws-k8s-cni-old.yaml

```
- upgrade
```sh
SOURCE_VERSION=v1.13.2-eksbuild.1
TARGET_VERSION=v1.13.3-eksbuild.1
aws eks update-addon --cluster-name ${CLUSTER_NAME} \
--addon-name vpc-cni --addon-version ${TARGET_VERSION} \
--resolve-conflicts PRESERVE 
```

### re-install
```sh
# arn:aws:iam::xxx:role/eksctl-ekscluster1-addon-vpc-cni-Role1

# --configuration-values '{"env":{"ENABLE_IPv4":"true","ENABLE_IPv6":"false"}}'

aws eks create-addon --cluster-name ${CLUSTER_NAME} \
--addon-name vpc-cni --addon-version v1.13.2-eksbuild.1 \
--service-account-role-arn arn:aws:iam::xxx:role/eksctl-ekscluster1-addon-vpc-cni-Role1 \
--resolve-conflicts OVERWRITE

# aws eks delete-addon --cluster-name ekscluster1 --addon-name vpc-cni

```


## additional
- [[security-group-for-pod]]
	- [[../../infra/network/enable-sg-on-pod]]
- [[upgrade-vpc-cni]]






