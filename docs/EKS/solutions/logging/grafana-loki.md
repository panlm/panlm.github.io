---
title: Using Loki for Logging
description: 使用 loki 收集日志
created: 2023-12-18 14:09:49.975
last_modified: 2024-07-18
status: myblog
tags:
  - grafana/loki
---
# Grafana Loki
Loki is a backend store for long-term log retention

## diagram
![[git/git-mkdocs/git-attachment/POC-loki-for-logging-png-1.png|500]]

## walkthrough
### prerequisites
- addons needed 
    - [[../../addons/ebs-for-eks|ebs-for-eks]]
    - [[../../addons/aws-load-balancer-controller|aws-load-balancer-controller]]
    - [[../../addons/metrics-server|metrics-server]]
- install minio
```sh
helm repo add grafana https://grafana.github.io/helm-charts

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

#### simple-scalable
- create sa for loki ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
CLUSTER_NAME=ekscluster1
export AWS_DEFAULT_REGION=us-east-1
NAMESPACE=loki
LOKI_SA_NAME=role-loki-sa
LOKI_BUCKET_NAME=store-loki-eks0708
create-iamserviceaccount -s ${LOKI_SA_NAME} -c ${CLUSTER_NAME} -n ${NAMESPACE} -r 0

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
  replicas: 3
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

```

#### loki-stack
- 新集群没有安装 prometheus 或者 grafana
- 直接安装 `grafana/loki-stack`，并且enable 安装 grafana 和prometheus，默认 loki 的 datasource 就可以用，手工添加 data source 保存后验证失败，但是可以查询到数据

#### loki-distributed
- using default values of loki-distributed chat
```sh
helm upgrade -i loki grafana/loki-distributed --namespace loki --create-namespace
```

```
Default Installed components:
* gateway
* ingester
* distributor
* querier
* query-frontend

```

### promtail
- alternatives: fluent-bit / fluentd 
- customized for promtail, change client url if you deploy loki components with distributed mode
```sh
cat >promtail.values <<-EOF
config:
  clients:
    - url: http://loki-loki-distributed-gateway/loki/api/v1/push
EOF
helm upgrade -i promtail -f promtail.values grafana/promtail -n loki

```

### dashboard-
- 18042 v2 loki dashboard
- 12019 - quick search - good for try
    - change to `{namespace="$namespace", pod=~"$pod"} |~ "$search"` in Logs Panel definition
- loki-stack will have some predefined dashboard - https://artifacthub.io/packages/helm/grafana/loki-stack 


## 3 Modes
### Monolithic
- NO IG / QS in this mode
![[attachments/grafana-loki/IMG-grafana-loki-1.png|500]]

### SimpleScalable Mode
- easy to use
![[attachments/grafana-loki/IMG-grafana-loki-2.png|500]]

- reference values based on <mark style="background: #ADCCFFA6;">grafana/loki</mark> chat, not grafana/loki-simple-scalable chat
```yaml
deploymentMode: SimpleScalable

serviceAccount:
  create: false
  name: role-loki-sa

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
      chunks: 'store-loki-eks0708'	
      ruler: 'store-loki-eks0708'
      admin: 'store-loki-eks0708'
    type: s3
    s3:
      region: 'us-east-1'
      insecure: false
      s3ForcePathStyle: false

  storageConfig:
    # boltdb_shipper:
    #   shared_store: filesystem
    #   active_index_directory: /var/loki/index
    #   cache_location: /var/loki/cache
    #   cache_ttl: 168h
    tsdb_shipper:
      active_index_directory: /loki/index
      cache_location: /loki/index_cache
    aws:
      s3: s3://us-east-1/store-loki-eks0708

  commonConfig:
    path_prefix: /var/loki
    replication_factor: 1

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
  # autoscaling:
  #   enabled: true
  #   minReplicas: 1
  #   maxReplicas: 3
  #   targetCPUUtilizationPercentage: 60
  #   targetMemoryUtilizationPercentage: null
  ingress:
    enabled: true
    ingressClassName: 'alb'
    annotations: 
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=lb-access-log-1350,access_logs.s3.prefix=
    hosts:
      - host: '*.us-east-1.elb.amazonaws.com'
        paths:
          - path: /
            pathType: Prefix
  basicAuth:
    enabled: false

```

### Microservices Mode
- little hard to config
![[attachments/grafana-loki/IMG-grafana-loki.png|500]]

- ingester: sts / per node affinity
- querier: sts / per node affinity

- reference values based on <mark style="background: #ADCCFFA6;">grafana/loki</mark> chat, not grafana/loki-distributed chat
```yaml
deploymentMode: Distributed

# global:
#   image:
#     # -- Overrides the Docker registry globally for all images
#     registry: null

serviceAccount:
  create: false
  name: role-loki-sa

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
    tsdb_shipper:
      index_gateway_client:
        server_address: '{{ include "loki.indexGatewayAddress" . }}'
  storage:
    bucketNames:
      chunks: 'store-loki-eks0708'	
      ruler: 'store-loki-eks0708'
      admin: 'store-loki-eks0708'
    type: s3
    s3:
      region: 'us-east-1'
      insecure: false
      s3ForcePathStyle: false

  storageConfig:
    # boltdb_shipper:
    #   shared_store: filesystem
    #   active_index_directory: /var/loki/index
    #   cache_location: /var/loki/cache
    #   cache_ttl: 168h
    tsdb_shipper:
      active_index_directory: /loki/index
      cache_location: /loki/index_cache
    aws:
      s3: s3://us-east-1/store-loki-eks0708

  commonConfig:
    path_prefix: /var/loki
    replication_factor: 1


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
  replicas: 1
  # autoscaling:
  #   enabled: true
  #   minReplicas: 1
  #   maxReplicas: 3
  #   targetCPUUtilizationPercentage: 60
  #   targetMemoryUtilizationPercentage: null
  ingress:
    enabled: true
    ingressClassName: 'alb'
    annotations: 
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=lb-access-log-1350,access_logs.s3.prefix=
    hosts:
      - host: '*.us-east-1.elb.amazonaws.com'
        paths:
          - path: /
            pathType: Prefix
  basicAuth:
    enabled: false

ingester:
  enabled: true
  replicas: 3
  maxUnavailable: 1
  auth_enabled: false
  persistence:
    # -- Enable creating PVCs which is required when using boltdb-shipper
    enabled: true
    # -- Use emptyDir with ramdisk for storage. **Please note that all data in ingester will be lost on pod restart**
    inMemory: false
    # -- List of the ingester PVCs
    # @notationType -- list
    claims:
      - name: data
        size: 50Gi
        #   -- Storage class to be used.
        #   If defined, storageClassName: <storageClass>.
        #   If set to "-", storageClassName: "", which disables dynamic provisioning.
        #   If empty or set to null, no storageClassName spec is
        #   set, choosing the default provisioner (gp2 on AWS, standard on GKE, AWS, and OpenStack).
        storageClass: gp2
      # - name: wal
      #   size: 150Gi
    # -- Enable StatefulSetAutoDeletePVC feature
    enableStatefulSetAutoDeletePVC: true
    whenDeleted: Delete
    whenScaled: Retain

distributor:
  enabled: true
  replicas: 2

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
  replicas: 2
ruler:
  enabled: true
  replicas: 2

```

## refer
- https://cloud.tencent.com/developer/article/2307121
- https://grafana.com/docs/loki/latest/get-started/components/
- https://grafana.com/docs/loki/latest/setup/install/helm/install-microservices/

## sample
```yaml 
loki:
  auth_enabled: false
minio:
  enabled: true
```


