---
title: eks-custom-network
description: custom network 可以解决子网地址段耗尽的问题
created: 2023-08-21 17:56:37.517
last_modified: 2023-10-29 13:24:49.648
tags:
  - aws/container/eks
  - kubernetes/cni
---

> [!WARNING] This is a github note

# eks-custom-network-lab

## link

- [link](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/cni-custom-network.html)
- [[Leveraging CNI custom networking alongside security groups for pods in Amazon EKS]]
- [[Automating custom networking to solve IPv4 exhaustion in Amazon EKS Containers]]

- There are a limited number of IP addresses available in a subnet. Using different subnets for pods allows you to increase the number of available IP addresses
- For security reasons, your pods must use different security groups or subnets than the node's primary network interface.
- The nodes are configured in public subnets and you want the pods to be placed in private subnets using a NAT Gateway


## lab-
https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/cni-custom-network.html

- prep cidr / subnet id 
```sh
CLUSTER_NAME=ekscluster1
AWS_REGION=us-east-2
export AWS_DEFAULT_REGION=${AWS_REGION}

VPC_ID=$(aws eks describe-cluster \
  --name ${CLUSTER_NAME} --region ${AWS_REGION} \
  --query "cluster.resourcesVpcConfig.vpcId" --output text )

aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query "Subnets[].[AvailabilityZone,SubnetId]" --output text

aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" \
--query 'Subnets[].{Name:Tags[?Key==`Name`].Value|[0],SubnetId:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' --output table

# copy paste origin private subnet to following variables (10.x.x.x)
subnet_id_1=subnet-xxx
subnet_id_2=subnet-xxx
# copy paste new private subnet to following variables (100.64.x.x)
new_subnet_id_1=subnet-xxx
new_subnet_id_2=subnet-xxx

AZ_1=$(aws ec2 describe-subnets --subnet-ids $subnet_id_1 --query 'Subnets[*].AvailabilityZone' --output text)
AZ_2=$(aws ec2 describe-subnets --subnet-ids $subnet_id_2 --query 'Subnets[*].AvailabilityZone' --output text)

```

- enable CUSTOM NETWORK 
```sh
kubectl describe ds aws-node -n kube-system |grep -e CUSTOM_NETWORK -e EXTERNALSNAT
# AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
# AWS_VPC_K8S_CNI_EXTERNALSNAT
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_EXTERNALSNAT=true
# need a default value for all NEW NODE in ANY nodegroup
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone

CLUSTER_SECURITY_GROUP_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)

```

- ENIConfig
```sh
envsubst >${AZ_1}.yaml <<-EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata: 
  name: ${AZ_1}
spec: 
  securityGroups: 
    - ${CLUSTER_SECURITY_GROUP_ID}
  subnet: ${new_subnet_id_1}
EOF

cat >${AZ_2}.yaml <<EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata: 
  name: ${AZ_2}
spec: 
  securityGroups: 
    - ${CLUSTER_SECURITY_GROUP_ID}
  subnet: ${new_subnet_id_2}
EOF

kubectl apply -f ${AZ_1}.yaml
kubectl apply -f ${AZ_2}.yaml
kubectl get ENIConfigs

```

- create new node group or scale existed node group

## run pod on specific node

```sh
cat >pod-ubuntu1.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-ubuntu1
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    command: ["sh", "-c", "while true ; do sleep 10; done"]
  nodeSelector:
    alpha.eksctl.io/nodegroup-name: mng1
#    kubernetes.io/hostname: ip-10-x-x-x.us-east-2.compute.internal
EOF
kubectl apply -f pod-ubuntu1.yaml

```

^hennaq





