---
title: eks-terraform-cluster
description: 使用 Terraform 创建 EKS 集群
created: 2023-06-30 15:02:19.833
last_modified: 2023-12-10
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

- execute function to create an existed host zone ([[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#func-setup-hosted-zone-]])
```sh
DOMAIN_NAME=eks1206.aws.panlm.xyz
create-host-zone ${DOMAIN_NAME}
```
- need setup upstream domain registry from your labtop ([[git/git-mkdocs/CLI/awscli/route53-cmd#func-create-ns-record-]])

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

- create ekscluster1
```sh
cd ekscluster1
terraform init
terraform apply -auto-approve

# following output to save kubeconfig file
```

- create ekscluster2
```sh
# go to another terminal to execute simultaneously
cd ekscluster2
terraform init
terraform apply -auto-approve

# following output to save kubeconfig file
```

### internal error
```error
│       * Internal error occurred: failed calling webhook "mservice.elbv2.k8s.aws": failed to call webhook: Post "https://aws-load-balancer-webhook-service.kube-system.svc:443/mutate-v1-service?timeout=10s": no endpoints available for service "aws-load-balancer-webhook-service"
│ 
│   with module.eks_cluster.module.eks_blueprints_addons.module.cert_manager.helm_release.this[0],
│   on .terraform/modules/eks_cluster.eks_blueprints_addons.cert_manager/main.tf line 9, in resource "helm_release" "this":
│    9: resource "helm_release" "this" {

```

- re-run `terraform apply`


## refer
- [[eks-blueprints-blue-green-upgrade]]




