---
title: eks-prefix-assignment
description: 
created: 2022-05-07 09:54:31.890
last_modified: 2023-10-05 12:33:08.924
tags:
  - aws/container/eks
---

# prefix-assignment

## doc
https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html

When configured for prefix assignment, the CNI add-on can assign significantly more IP addresses to a network interface than it can when you assign individual IP addresses

- cni version 1.9.0 or over
- Enable the parameter to assign prefixes to network interfaces for the Amazon VPC CNI `DaemonSet`

```sh
kubectl describe ds aws-node -n kube-system |grep -i PREFIX
kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true

```




