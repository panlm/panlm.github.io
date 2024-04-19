---
title: Using Loki for Logging
description: 使用 loki 收集日志
created: 2023-12-18 14:09:49.975
last_modified: 2024-04-18
tags:
  - grafana/loki
---
> [!WARNING] This is a github note
# grafana loki
Loki is a backend store for long-term log retention

## diagram
![[git/git-mkdocs/git-attachment/POC-loki-for-logging-png-1.png|500]]

## walkthrough
- install with helm
```sh
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade -i -f minio.yaml loki grafana/loki -n loki
helm upgrade -i promtail grafana/promtail -n ${NAMESPACE}

# list all repo
helm search repo grafana
```
- create sa for loki
[[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]] 
```sh
CLUSTER_NAME_1=ekscluster1
NAMESPACE=loki-stack
LOKI_SA_NAME=loki-sa
AWS_DEFAULT_REGION=us-east-2
LOKI_BUCKET_NAME=store-loki-eks1217
create-iamserviceaccount -s ${LOKI_SA_NAME} -c ${CLUSTER_NAME_1} -n ${NAMESPACE} -r 0
```
- values yaml file for install
```sh
echo ${AWS_DEFAULT_REGION}
envsubst > loki-1.yaml <<-EOF
loki:
  auth_enabled: false
  storage:
    bucketNames:
      chunks: ${LOKI_BUCKET_NAME}
      ruler: ${LOKI_BUCKET_NAME}
      admin: ${LOKI_BUCKET_NAME}
    type: s3
    s3:
      region: ${AWS_DEFAULT_REGION}
      insecure: false
      s3ForcePathStyle: false
serviceAccount:
  create: false
  name: ${LOKI_SA_NAME}
write:
  replicas: 2
read:
  replicas: 1
gateway: 
  enabled: true
  replicas: 2
EOF

helm upgrade -i -f loki-1.yaml loki grafana/loki -n ${NAMESPACE}
helm upgrade -i promtail grafana/promtail -n ${NAMESPACE}
```

## dashboard-
- 12019 - quick search - good for try
    - change to `{namespace="$namespace", pod=~"$pod"} |~ "$search"` in Logs Panel definition
- loki-stack will have some predefined dashboard - https://artifacthub.io/packages/helm/grafana/loki-stack 


## sample
```yaml 
loki:
  auth_enabled: false
minio:
  enabled: true
```




