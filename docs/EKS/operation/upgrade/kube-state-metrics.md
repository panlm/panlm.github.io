---
title: kube-state-metrics
description: kube-state-metrics
chapter: true
created: 2023-08-01 08:46:22.190
last_modified: 2023-08-01 08:46:22.190
tags:
  - kubernetes
---

```ad-attention
title: This is a github note

```

# kube-state-metrics

## github

https://github.com/kubernetes/kube-state-metrics

### kube-state-metrics vs. metrics-server

The [metrics-server](https://github.com/kubernetes-incubator/metrics-server) is a project that has been inspired by [Heapster](https://github.com/kubernetes-retired/heapster) and is implemented to serve the goals of core metrics pipelines in [Kubernetes monitoring architecture](https://github.com/kubernetes/design-proposals-archive/blob/main/instrumentation/monitoring_architecture.md). It is a cluster level component which periodically scrapes metrics from all Kubernetes nodes served by Kubelet through Metrics API. The metrics are aggregated, stored in memory and served in [Metrics API format](https://git.k8s.io/metrics/pkg/apis/metrics/v1alpha1/types.go). The metrics-server stores the latest values only and is not responsible for forwarding metrics to third-party destinations.

kube-state-metrics is focused on generating completely new metrics from Kubernetes' object state (e.g. metrics based on deployments, replica sets, etc.). It holds an entire snapshot of Kubernetes state in memory and continuously generates new metrics based off of it. And just like the metrics-server it too is not responsible for exporting its metrics anywhere.

Having kube-state-metrics as a separate project also enables access to these metrics from monitoring systems such as Prometheus.






