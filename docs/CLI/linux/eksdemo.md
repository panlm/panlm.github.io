---
title: eksdemo
description: 使用 eksdemo 快速搭建 eks 集群以及其他所需组件
chapter: true
created: 2023-07-15 09:44:34.470
last_modified: 2023-10-28 20:22:30.668
tags:
  - aws/container/eks
  - aws/cmd
---

# eksdemo

## install

```sh
curl --location "https://github.com/awslabs/eksdemo/releases/latest/download/eksdemo_$(uname -s)_x86_64.tar.gz" |tar xz -C /tmp
sudo mv -v /tmp/eksdemo /usr/local/bin

```

## create eks cluster-

```sh
CLUSTER_NAME=ekscluster2
eksdemo create cluster ${CLUSTER_NAME} -i m5.large -N 3
```

## addons-

- externaldns
![[../../EKS/infra/network/externaldns-for-route53#^a2vlmo]]

refer: [[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#install-with-eksdemo-]]

- aws load balancer controller
![[../../EKS/infra/network/aws-load-balancer-controller#^yddjq0]]

refer: [[git/git-mkdocs/EKS/infra/network/aws-load-balancer-controller#install-with-eksdemo-]]

- 2 certificates, one for each domain name in original region
![[../awscli/acm-cmd#^kresvp]]

refer: [[../awscli/acm-cmd#create-certificate-with-eksdemo-]]

