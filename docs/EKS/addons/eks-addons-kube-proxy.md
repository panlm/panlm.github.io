---
title: eks-addons-kube-proxy
description: eks-addons-kube-proxy
created: 2023-07-31 14:05:39.381
last_modified: 2023-07-31 14:05:39.381
tags: 
- aws/container/eks 
---

# eks-addons-kube-proxy

## github
- [doc](https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html)

There are two types of the `kube-proxy` container image available for each Amazon EKS cluster version:
- **Default** – This image type is based on a Debian-based Docker image that is maintained by the Kubernetes upstream community.    
- **Minimal** – This image type is based on a [minimal base image](https://gallery.ecr.aws/eks-distro-build-tooling/eks-distro-minimal-base-iptables) maintained by Amazon EKS Distro, which contains minimal packages and doesn't have shells. For more information, see [Amazon EKS Distro](https://distro.eks.amazonaws.com/).

![eks-addons-kube-proxy-png-1.png](../../git-attachment/eks-addons-kube-proxy-png-1.png)

```sh
aws eks describe-addon-versions --addon-name kube-proxy |jq -r '.addons[].addonVersions[].addonVersion'
```







