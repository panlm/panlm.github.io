---
title: Create EKS Cluster with Terraform
description: 使用 Terraform 创建 EKS 集群
created: 2023-06-30 15:02:19.833
last_modified: 2024-02-10
tags:
  - aws/container/eks
  - terraform
---
> [!WARNING] This is a github note

# Create EKS Cluster with Terraform
## install terraform
- https://developer.hashicorp.com/terraform/install
- this step has been included in [[../../cloud9/setup-cloud9-for-eks|setup-cloud9-for-eks]] 

=== "CentOS / AL2"
    ```sh
    sudo yum install -y yum-utils shadow-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform
    ```

=== "Ubuntu"
    ```sh
    sudo apt install terraform=1.5.7-1
    sudo apt-mark hold terraform
    ```


## sample-create-3x-clusters-for-thanos-poc-
- get terraform template 
```sh
git clone https://github.com/panlm/eks-blueprints-clusters.git
cd eks-blueprints-clusters/multi-cluster-thanos
```

- execute function to create an existed host zone ([[../../CLI/awscli/route53-cmd#func-create-hosted-zone-|route53-cmd]])
```sh
DOMAIN_NAME=eks1224.aws.panlm.xyz
create-hosted-zone -n ${DOMAIN_NAME}
```
- need setup upstream domain registry from your labtop ([[git/git-mkdocs/CLI/awscli/route53-cmd#func-create-ns-record-]])

- terraform.tfvars
```text
aws_region          = "us-east-2"
environment_name    = "thanos"
cluster_version     = "1.27"
hosted_zone_name    = "eks1206.aws.panlm.xyz" # your Existing Hosted Zone
eks_admin_role_name = "panlm" # Additional role admin in the cluster 
```

- build environment
```sh
cd environment
terraform init
terraform apply -auto-approve
```

- create ekscluster1, following output to save kubeconfig file
```sh
cd ekscluster1
terraform init
terraform apply -auto-approve
```
- create ekscluster2 and ekscluster3 from their folder with same commands

- in each eks cluster, will install following addons by argocd. access argocd svc url with default password saved in aws secret manager
![[../../git-attachment/eks-cluster-with-terraform-png-1.png]]

### internal error
- re-run `terraform apply` if you got following errors
```error
│       * Internal error occurred: failed calling webhook "mservice.elbv2.k8s.aws": failed to call webhook: Post "https://aws-load-balancer-webhook-service.kube-system.svc:443/mutate-v1-service?timeout=10s": no endpoints available for service "aws-load-balancer-webhook-service"
│ 
│   with module.eks_cluster.module.eks_blueprints_addons.module.cert_manager.helm_release.this[0],
│   on .terraform/modules/eks_cluster.eks_blueprints_addons.cert_manager/main.tf line 9, in resource "helm_release" "this":
│    9: resource "helm_release" "this" {
```


## refer
- [[eks-blueprints-blue-green-upgrade]]
- [[../../../../../helm-in-terraform|helm-in-terraform]]



