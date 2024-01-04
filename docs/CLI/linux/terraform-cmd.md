---
title: terraform
description: 
created: 2022-07-05 21:52:16.279
last_modified: 2024-01-03
tags:
  - terraform
---
> [!WARNING] This is a github note
# terraform-cmd

## install-

- RHEL
```sh
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```
- AL2
```sh
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```
## variable

```variables.tf
variable "region" {
  description = "region"
  type        = string
  default = "us-east-2"
}
```

```sh
terraform apply -var "region=us-east-2"
```

## workspace

```sh
# create new one
terraform workspace new test
# show current 
terraform workspace show
# list all 
terraform workspace list
```

## state

```sh
terraform state list
terraform state show xxxxxx
```


