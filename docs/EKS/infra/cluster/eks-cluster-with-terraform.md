---
title: eks-terraform-cluster
description: 使用 Terraform 创建 EKS 集群
created: 2023-06-30 15:02:19.833
last_modified: 2023-12-06
tags:
  - aws/container/eks
  - terraform
---
> [!WARNING] This is a github note

# create-cluster-with-terraform
## install terraform
```sh
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

## sample-create-2x-clusters-for-thanos-poc-
- get terraform template 
```sh
git clone https://github.com/panlm/eks-blueprints-clusters.git
cd eks-blueprints-clusters/multi-cluster-thanos
```

- execute function to create an existed host zone ([[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#setup-hosted-zone-]])
```sh
DOMAIN_NAME=eks1206.aws.panlm.xyz
create-host-zone ${DOMAIN_NAME}
```
- need setup upstream domain registry from your labtop ([[git/git-mkdocs/CLI/awscli/route53-cmd#create-ns-record-]])

- terraform.tfvars
```text
aws_region          = "us-east-2"
environment_name     = "thanos"
hosted_zone_name    = "eks1206.aws.panlm.xyz" # your Existing Hosted Zone
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

# go to another terminal to execute simultaneously
cd ../ekscluster2
terraform init
terraform apply -auto-approve

# following output to save kubeconfig file
```

## refer
- [[eks-blueprints-blue-green-upgrade]]




