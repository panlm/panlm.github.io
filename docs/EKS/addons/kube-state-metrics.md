---
title: kube-state-metrics
description: kube-state-metrics
created: 2023-08-01 08:46:22.190
last_modified: 2023-11-14
tags:
  - kubernetes
---
> [!WARNING] This is a github note

# kube-state-metrics

## github

- https://github.com/kubernetes/kube-state-metrics
- included by prometheus operator

### kube-state-metrics vs. metrics-server

The [metrics-server](https://github.com/kubernetes-incubator/metrics-server) is a project that has been inspired by [Heapster](https://github.com/kubernetes-retired/heapster) and is implemented to serve the goals of core metrics pipelines in [Kubernetes monitoring architecture](https://github.com/kubernetes/design-proposals-archive/blob/main/instrumentation/monitoring_architecture.md). It is a cluster level component which periodically scrapes metrics from all Kubernetes nodes served by Kubelet through Metrics API. The metrics are aggregated, stored in memory and served in [Metrics API format](https://git.k8s.io/metrics/pkg/apis/metrics/v1alpha1/types.go). The metrics-server stores the latest values only and is not responsible for forwarding metrics to third-party destinations.

kube-state-metrics (KSM) is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects. (See examples in the Metrics section below.) It is not focused on the health of the individual Kubernetes components, but rather on the health of the various objects inside, such as deployments, nodes and pods.

Having kube-state-metrics as a separate project also enables access to these metrics from monitoring systems such as Prometheus.






