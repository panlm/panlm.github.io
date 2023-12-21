---
title: topology spread constraints
description: topology spread constraints
created: 2023-07-10 12:53:37.606
last_modified: 2023-12-20
tags:
  - kubernetes
---

# k8s-topology-spread-constraints

## link
- https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/topology-spread-constraints/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/

## 集群级别的默认约束

### 内置默认约束
```yaml
defaultConstraints:
  - maxSkew: 3
    topologyKey: "kubernetes.io/hostname"
    whenUnsatisfiable: ScheduleAnyway
  - maxSkew: 5
    topologyKey: "topology.kubernetes.io/zone"
    whenUnsatisfiable: ScheduleAnyway
```


## sample
- 6 node in 3 az
- 1.25

### nginx deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: "kubernetes.io/hostname"
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: nginx
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

```

### pod 
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    app: nginx
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    # topologyKey: "kubernetes.io/hostname"
    topologyKey: "topology.kubernetes.io/zone"
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: nginx
  containers:
  - name: pause
    image: registry.k8s.io/pause:3.1
```

### result 
- for zone
![[git/git-mkdocs/git-attachment/k8s-topology-spread-constraints-png-1.png]]

- for hostname
check up topology in previous diagram






