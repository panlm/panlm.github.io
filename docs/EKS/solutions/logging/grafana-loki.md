---
title: Using Grafana Loki for Logging
description: 使用 loki 收集日志
created: 2023-12-18 14:09:49.975
last_modified: 2024-07-18
status: myblog
tags:
  - grafana/loki
---

# Using Grafana Loki for Logging
Loki is a backend store for long-term log retention

## diagram for distributed microservices
![[attachments/grafana-loki/IMG-grafana-loki-6.png]]

refer: [[../../../../../Excalidraw/loki.excalidraw|loki.excalidraw]]

## walkthrough
### prerequisites
- ekscluster 
    - [[../../../CLI/linux/eksdemo#create-eks-cluster-|eks cluster]]
- addons needed 
    - [[../../addons/ebs-for-eks|ebs-for-eks]] 
    - [[../../addons/aws-load-balancer-controller|aws-load-balancer-controller]] 
    - [[../../addons/metrics-server|metrics-server]] 
    - [[../monitor/install-prometheus-operator|install-prometheus-operator]] 

- this lab will ingest ELB access log for performance testing (see [[#tools-]])
```sh
ELB_LOG_BUCKET=elb-access-log-$RANDOM
LOKI_BUCKET=loki-bucket-$RANDOM
aws s3 mb s3://${ELB_LOG_BUCKET}
aws s3 mb s3://${LOKI_BUCKET}

```

- add helm repo
```sh
helm repo add grafana https://grafana.github.io/helm-charts

```

- create sa for loki ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
CLUSTER_NAME=ekscluster1
export AWS_DEFAULT_REGION=us-east-1
NAMESPACE=loki
LOKI_SA_NAME=role-loki-sa
create-iamserviceaccount -s ${LOKI_SA_NAME} -c ${CLUSTER_NAME} -n ${NAMESPACE} -r 0

```

### loki 
- select one sub-chapter to install 
- grafana/loki chat 提供 3 种部署模式： 
    - singlebinary, 
    - simple-scaleable (default), suitable for up to 1TB/day
    - distributed, suitable for over 1TB/day
- 并提供多种 loki 配置生成方法
    - 默认使用 template value 生成 loki config
    - 使用 `structuredConfig` 自定义 loki config
    - 外部定义 secret or cm，使用 `configObjectName` 引用

#### distributed
- using default values of loki-distributed chat
```sh
helm upgrade -i loki grafana/loki-distributed --namespace loki --create-namespace
```

- use customized values to install
```sh
echo ${AWS_DEFAULT_REGION}
echo ${ELB_LOG_BUCKET}
echo ${LOKI_BUCKET}
echo ${LOKI_SA_NAME}

# values based on grafana/loki chat, not grafana/loki-distributed chat
envsubst > loki-distributed.yaml <<-EOF
deploymentMode: Distributed

serviceAccount:
  create: false
  name: ${LOKI_SA_NAME}

loki:
  auth_enabled: false
  useTestSchema: true
  testSchemaConfig:
    configs:
      - from: 2024-04-01
        store: tsdb
        # object_store: '{{ include "loki.testSchemaObjectStore" . }}'
        object_store: 's3'
        schema: v13
        index:
          prefix: index_
          period: 24h
  storage_config:
    object_prefix: "s3prefix"
  storage:
    bucketNames:
      chunks: '${LOKI_BUCKET}'
      ruler: '${LOKI_BUCKET}'
      admin: '${LOKI_BUCKET}'
    type: s3
    s3:
      region: '${AWS_DEFAULT_REGION}'
      insecure: false
      s3ForcePathStyle: false
  commonConfig:
    path_prefix: /var/loki
    replication_factor: 1
  limits_config:
    ingestion_rate_mb: 19
    ingestion_burst_size_mb: 29
  ingester: 
    # max_transfer_retries: 0 # move this option to ingester.Config
    chunk_encoding: snappy # gzip / flate
    chunk_idle_period: 1h
    chunk_target_size: 524288 # default 1.5MB, advice 512KB - 1MB for lower amount of logging
    max_chunk_age: 2h
    chunk_retain_period: 5m
  compactor:
    # shared_store: s3 # move this option to compactor.Config
    apply_retention_interval: 48h
    compaction_interval: 2h # lower value will cause chunk update to s3 more frequently 
    retention_enabled: true
    delete_request_store: s3
    # retention_delete_worker_count: 100
    # working_directory: /loki/compactor

chunksCache:
  enabled: false
write:
  enabled: false
  replicas: 0
read:
  enabled: false
  replicas: 0
backend:
  enabled: false
  replicas: 0

gateway:
  enabled: true
  replicas: 2
  ingress:
    enabled: true
    ingressClassName: 'alb'
    annotations: 
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=${ELB_LOG_BUCKET},access_logs.s3.prefix=
    hosts:
      - host: '*.${AWS_DEFAULT_REGION}.elb.amazonaws.com'
        paths:
          - path: /
            pathType: Prefix
  basicAuth:
    enabled: false

ingester:
  enabled: true
  replicas: 2
  maxUnavailable: 1
  auth_enabled: false
  persistence:
    # -- Enable creating PVCs which is required when using boltdb-shipper
    enabled: true # best to have due to we keep chunk more logger time locally
    # -- Use emptyDir with ramdisk for storage. **Please note that all data in ingester will be lost on pod restart**
    inMemory: false
    # -- List of the ingester PVCs
    # @notationType -- list
    claims:
      - name: data
        size: 50Gi
    enableStatefulSetAutoDeletePVC: false # default false
    whenDeleted: Retain # default Retain
    whenScaled: Retain
  Config: 
    max_transfer_retries: 0 # mandortory
  zoneAwareReplication:
    # -- Enable zone awareness.
    enabled: false

distributor:
  enabled: true
  replicas: 2
  maxUnavailable: 1

querier:
  enabled: true
  replicas: 3
  maxUnavailable: 1

queryFrontend:
  enabled: true
  replicas: 2
  maxUnavailable: 1

# backend target: QS/IG/C/R
queryScheduler:
  enabled: true
  replicas: 2
indexGateway:
  enabled: true
  replicas: 2
  maxUnavailable: 1
compactor:
  enabled: true
  replicas: 1
  Config:
    shared_store: s3 # mandortory
ruler:
  enabled: true
  replicas: 2
  maxUnavailable: 1

EOF

helm upgrade -i -f loki-distributed.yaml loki grafana/loki -n ${NAMESPACE} 

```

#### simple-scalable (deprecated)
- values yaml file for install
```sh
echo ${AWS_DEFAULT_REGION}
echo ${ELB_LOG_BUCKET}
echo ${LOKI_BUCKET}
echo ${LOKI_SA_NAME}

# values based on grafana/loki chat, not grafana/loki-simple-scalable chat
envsubst > loki-simple.yaml <<-EOF
deploymentMode: SimpleScalable

serviceAccount:
  create: false
  name: ${LOKI_SA_NAME}

loki:
  auth_enabled: false
  useTestSchema: true
  testSchemaConfig:
    configs:
      - from: 2024-04-01
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: index_
          period: 24h
  storage:
    bucketNames:
      chunks: '${LOKI_BUCKET}'	
      ruler: '${LOKI_BUCKET}'
      admin: '${LOKI_BUCKET}'
    type: s3
    s3:
      region: '${AWS_DEFAULT_REGION}'
      insecure: false
      s3ForcePathStyle: false

  # storageConfig:
  #   # boltdb_shipper:
  #   #   shared_store: filesystem
  #   #   active_index_directory: /var/loki/index
  #   #   cache_location: /var/loki/cache
  #   #   cache_ttl: 168h
  #   tsdb_shipper:
  #     active_index_directory: /loki/index
  #     cache_location: /loki/index_cache
  #   aws:
  #     s3: s3://us-west-2/loki-bucket-16127

  commonConfig:
    path_prefix: /var/loki
    replication_factor: 1
  limits_config:
    ingestion_rate_mb: 20
    ingestion_burst_size_mb: 30
  compactor:
    apply_retention_interval: 1h
    compaction_interval: 5m
    retention_delete_worker_count: 500
    retention_enabled: true
    shared_store: s3

chunksCache:
  enabled: false
write:
  replicas: 3
read:
  replicas: 2
backend:
  replicas: 2
gateway:
  replicas: 2
  ingress:
    enabled: true
    ingressClassName: 'alb'
    annotations: 
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=${ELB_LOG_BUCKET},access_logs.s3.prefix=
    hosts:
      - host: '*.${AWS_DEFAULT_REGION}.elb.amazonaws.com'
        paths:
          - path: /
            pathType: Prefix
  basicAuth:
    enabled: false
EOF

helm upgrade -i -f loki-simple.yaml loki grafana/loki -n ${NAMESPACE}

```

#### loki-stack
- 新集群没有安装 prometheus 或者 grafana
- 直接安装 `grafana/loki-stack`，并且 enable 安装 grafana 和prometheus，默认 loki 的 datasource 就可以用，手工添加 data source 保存后验证失败，但是可以查询到数据

### promtail
- alternatives: fluent-bit / fluentd 
- customized for promtail, change client url if you deploy loki components with distributed mode
```sh
cat >promtail.values <<-EOF
config:
  clients:
    - url: http://loki-gateway/loki/api/v1/push
EOF
helm upgrade -i promtail -f promtail.values grafana/promtail -n loki

```

### sample pod to generate logs
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-logging
spec:
  selector:
    matchLabels:
      app: myapp-logging
  replicas: 2
  template:
    metadata:
      labels:
        app: myapp-logging
    spec:
      containers:
      - name: myapp-logging
        image: ubuntu
        command: 
        - 'bash'
        - '-c'
        - 'while true ; do echo `date +%Y-%m-%dT%H:%M:%S.%NZ` "a682775d0d85649f5b0d42f3b9f6896a 35.95.65.104:${RANDOM} 10.10.108.62:${RANDOM} 0.000301 0.000009 0.000017 - - 135 163 \"- - - \" \"-\" - -"; sleep 0.02; done'

```
### dashboard-
- 18042 v2 loki dashboard
- 12019 - quick search - good for try
    - change to `{namespace="$namespace", pod=~"$pod"} |~ "$search"` in Logs Panel definition
- loki-stack will have some predefined dashboard - https://artifacthub.io/packages/helm/grafana/loki-stack 

### tools-
- using terraform to deploy promtail in lambda ([loki github](https://github.com/grafana/loki/tree/main/tools/lambda-promtail))
![[attachments/grafana-loki/IMG-grafana-loki-3.png]]

- change lambda execution time to 15min
- enable access log in ELB (refer: [[aws-elb-elastic-load-balancer#access-log-]])

## 3 Modes
### Monolithic
- NO IG / QS in this mode
![[attachments/grafana-loki/IMG-grafana-loki-1.png|500]]

### Microservices Mode
- little hard to config
![[attachments/grafana-loki/IMG-grafana-loki.png|500]]

- ingester: sts / per node affinity
- querier: sts / per node affinity

### SimpleScalable Mode (deprecated)
https://github.com/grafana/helm-charts/tree/main/charts/loki-simple-scalable

- architecture
![[git/git-mkdocs/git-attachment/POC-loki-for-logging-png-1.png|500]]

- easy to use
![[attachments/grafana-loki/IMG-grafana-loki-2.png|500]]

## refer
- https://cloud.tencent.com/developer/article/2307121
- https://grafana.com/docs/loki/latest/get-started/components/
- https://grafana.com/docs/loki/latest/setup/install/helm/install-microservices/
- https://github.com/grafana/loki/issues/9131
- https://grafana.com/blog/2020/04/21/how-labels-in-loki-can-make-log-queries-faster-and-easier/

## sample
```yaml 
loki:
  auth_enabled: false
minio:
  enabled: true
```


