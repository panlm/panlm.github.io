---
title: Kubernetes Best Practices - Resource Requests and Limits
description: Kubernetes 资源请求和限制的最佳实践
created: 2024-08-09 09:04:48.377
last_modified: 2024-08-09
tags:
  - kubernetes
---

# k8s-request-limit-best-practices

Kubernetes Best Practices - Resource Requests and Limits
https://www.youtube.com/watch?v=xjpHggHKm78

- 基于 request 调度； 
- 可以设置 namespace 级别限制和默认值；
- 除非科学计算应用一般不建议 cpu request 超过1000m；
- 内存不可压缩，扩展超 request 不到 limit 后， k8 会 reschedule 低优先级 pod 来释放空间从而满足请求

## cpu request / limit

[link](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-that-is-too-big-for-your-nodes) 
Pod scheduling is based on requests. A Pod is scheduled to run on a Node only if the Node has enough CPU resources available to satisfy the Pod CPU request.

[link](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#cpu-units) 
The CPU resource is measured in _CPU_ units. One CPU, in Kubernetes, is equivalent to:
-   1 AWS vCPU
-   1 GCP Core
-   1 Azure vCore
-   1 Hyperthread on a bare-metal Intel processor with Hyperthreading



