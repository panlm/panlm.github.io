---
title: horizontal pod autoscaler
description: horizontal pod autoscaler
created: 2022-05-17 15:41:26.222
last_modified: 2023-12-20
tags:
  - kubernetes
---
> [!WARNING] This is a github note
# hpa-horizontal-pod-autoscaler

## sample
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

### v1
- https://user-images.githubusercontent.com/16036481/72983523-c4634f00-3de1-11ea-9a46-fa5229580d06.jpg

### v2
```sh
k autoscale sts thanos-receive-cluster3-tmp -n thanos --cpu-percent=60   --min=1  --max=10 --dry-run=client -oyaml > ~/environment/hpa.yaml
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  creationTimestamp: null
  name: thanos-receive-cluster3-tmp
spec:
  maxReplicas: 10
  minReplicas: 1
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: thanos-receive-cluster3-tmp
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```


## resource

- [doc](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/horizontal-pod-autoscaler.html)
- [workshop](https://www.eksworkshop.com/beginner/080_scaling/deploy_hpa/)
- [[sysctl]]



