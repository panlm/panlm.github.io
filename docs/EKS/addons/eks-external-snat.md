---
title: eks-external-snat
description: 
created: 2022-03-08 09:12:23.947
last_modified: 2022-03-08 09:12:23.947
tags:
  - aws/container/eks
---

# eks-external-snat

## snat disabled (prefer)
work node in private subnet ([LINK](https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/#snat))

![[attachments/eks-external-snat/IMG-eks-external-snat.png|600]]
```sh
kubectl set env daemonset -n kube-system aws-node AWS_VPC_K8S_CNI_EXTERNALSNAT=true
```

## snat enabled 
work node in public subnet

![[attachments/eks-external-snat/IMG-eks-external-snat-1.png|600]]
```sh
kubectl set env daemonset -n kube-system aws-node AWS_VPC_K8S_CNI_EXTERNALSNAT=false
```



## reference
- https://docs.aws.amazon.com/eks/latest/userguide/external-snat.html

![[attachments/eks-external-snat/IMG-eks-external-snat-2.png|600]]

https://broadcast.amazon.com/videos/388152



