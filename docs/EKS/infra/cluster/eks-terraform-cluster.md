---
title: eks-terraform-cluster
description: 使用 terraform 创建 eks 集群
created: 2023-06-30 15:02:19.833
last_modified: 2023-11-26
tags:
  - aws/container/eks
  - terraform
---
> [!WARNING] This is a github note

# create-cluster-with-terraform
## sample-create-2x-clusters-for-thanos-poc-
- get terraform template 
```sh
git clone https://github.com/panlm/eks-blueprints-clusters.git
cd eks-blueprints-clusters/multi-cluster-thanos
```

- need an existed host zone ([[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#setup-hosted-zone-]])
```sh
DOMAIN_NAME=eks1127.aws.panlm.xyz
```
- need setup upstream domain registry ([[git/git-mkdocs/CLI/awscli/route53-cmd#create-ns-record-]])

- terraform.tfvars
```text
aws_region          = "us-east-2"
environment_name     = "eks1127"
hosted_zone_name    = "eks1127.aws.panlm.xyz" # your Existing Hosted Zone
eks_admin_role_name = "panlm" # Additional role admin in the cluster 

```

- environment
```sh
cd environment
terraform init
terraform apply -auto-approve
```

- create two eks clusters
```sh
cd ../ekscluster1
terraform init
terraform apply -auto-approve
cd ../ekscluster2
terraform init
terraform apply -auto-approve

for i in ekscluster1 ekscluster2 ; do
    aws eks --region us-east-2 update-kubeconfig --name ${i} --alias ${i}
done

```


## refer
- [[eks-blueprints-blue-green-upgrade]]




