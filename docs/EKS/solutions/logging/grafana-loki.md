---
title: Using Loki for Logging
description: 使用 loki 收集日志
created: 2023-12-18 14:09:49.975
last_modified: 2024-04-18
tags:
  - grafana/loki
---
# Grafana Loki
Loki is a backend store for long-term log retention

## diagram
![[git/git-mkdocs/git-attachment/POC-loki-for-logging-png-1.png|500]]

## walkthrough
- ebs addon is needed ([[../../addons/ebs-for-eks|ebs-for-eks]])
- install with helm
```sh
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade -i -f minio.yaml loki grafana/loki -n loki
helm upgrade -i promtail grafana/promtail -n ${NAMESPACE}

# list all repo
helm search repo grafana
helm show value grafana/loki-canary
```
- create sa for loki
[[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]] 
```sh
CLUSTER_NAME_1=ekscluster1
NAMESPACE=loki
LOKI_SA_NAME=loki-sa
export AWS_DEFAULT_REGION=us-west-2
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
chunksCache:
  enabled: false
write:
  replicas: 2
read:
  replicas: 2
gateway: 
  enabled: true
  replicas: 2
backend:
  replicas: 2
EOF

helm upgrade -i -f loki-1.yaml loki grafana/loki -n ${NAMESPACE} \
    --set loki.useTestSchema=true
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

## install loki-stack
- 新集群没有安装 prometheus 或者 grafana
- 直接安装 `grafana/loki-stack`，并且enable 安装 grafana 和prometheus，默认 loki 的 datasource 就可以用，手工添加 data source 保存后验证失败，但是可以查询到数据

## refer
- https://cloud.tencent.com/developer/article/2307121
- https://grafana.com/docs/loki/latest/get-started/components/

