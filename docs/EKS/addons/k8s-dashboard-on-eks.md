---
title: kubernetes dashboard
created: 2022-03-28 14:39:22.434
last_modified: 2022-03-28 14:39:22.434
tags:
  - kubernetes
  - aws/container/eks
---
# k8s-dashboard-on-eks

## setup

[doc](https://docs.amazonaws.cn/eks/latest/userguide/dashboard-tutorial.html) 

1. change service type to loadbalancer
[[k8s-change-clusterip-to-nodeport]]

2. get token
```
kubectl -n kube-system describe secret deployment-controller-token-5k4gz
```
refer: [LINK](https://stackoverflow.com/questions/46664104/how-to-sign-in-kubernetes-dashboard)

3. access clb login with token 

4. (option) kubectl proxy to localhost and browser it

