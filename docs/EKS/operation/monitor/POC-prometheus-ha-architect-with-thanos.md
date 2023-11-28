---
title: POC-prometheus-ha-architect-with-thanos
description: 用 thanos 扩展 prometheus 高可用性架构
created: 2023-11-09 08:41:02.494
last_modified: 2023-11-28
tags:
  - kubernetes
  - aws/container/eks
---
> [!WARNING] This is a github note

# Prometheus HA Architect with Thanos
## diagram

使用 Thanos 可以扩展 Prometheus 的高可用性架构，包含 2 种典型的多集群架构。

下图展示第一种 Prometheus 架构，被监控集群（Observee）只部署 Prometheus 和 Alert Manager 等组件用于监控集群本身，且启用 Thanos 的 Sidecar 方式将 Prometheus 监控的历史数据定期归档到 S3；被监控集群上不部署 Grafana 组件。

监控集群（Observer）除了部署 Prometheus 和 Alert Manager 组件用于监控集群本身之外，将额外部署 Grafana 作为统一 Dashboard 展示，此外还将部署 Thanos 相关组件，包括：
- Thanos Store 组件：用于从 S3 上查询历史任务
- Thanos Query 组件：用于执行查询任务，将所有数据源添加为 Query 的 Endpoint，包括被监控集群的 Thanos Sider Car、 Thanos Store、 Thanos Receive 等
- Thanos Query Frontend：用于统一查询入口，并且负责将查询分片以提高性能

![[git/git-mkdocs/git-attachment/POC-prometheus-ha-architect-with-thanos-png-1.png]]

下图展示另一种 Prometheus 监控架构，与之前架构的区别在于被监控集群（Observee）除了启用 Thanos Sidecar 之外（下图中未展示），还启用了 Prometheus 的 Remote Write 功能，将未归档的数据以 WAL 方式远程传输到部署在监控集群（Observer）上的 Thanos Receive，以保证数据的冗余度。 Thanos Receive 同样可以将历史监控数据归档到 S3 上，且支持被 Thanos Query 直接查询。

![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-2.png]]

## go-through-
### prometheus
- we will create 2 clsuters, `ekscluster1` for observer, `ekscluster2` for observee ([[git/git-mkdocs/EKS/infra/cluster/eks-terraform-cluster#sample-create-2x-clusters-for-thanos-poc-]])
- following addons will be included in each cluster
    - [[git/git-mkdocs/EKS/infra/network/aws-load-balancer-controller#install-with-eksdemo-|aws load balancer controller]] 
    - [[git/git-mkdocs/EKS/infra/storage/ebs-for-eks#install-using-eksdemo-|ebs csi]] 
    - [[git/git-mkdocs/EKS/infra/network/externaldns-for-route53|externaldns-for-route53]] 
        - setup host zone ([[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#setup-hosted-zone-]])
        - create ns record on up stream dns register ([[git/git-mkdocs/CLI/awscli/route53-cmd#create-ns-record-]])
        - install addon to eks ([[git/git-mkdocs/EKS/infra/network/externaldns-for-route53#install-with-eksdemo-]])
- export values for customization
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm show values prometheus-community/kube-prometheus-stack > values_default.yaml
```
- get sample yaml to foler `POC`
```sh
mkdir POC && cd POC
mkdir prometheus s3-config query store receive receive-controller
```

#### observer cluster
- on observer (ekscluster1)
- create s3 config file for thanos sider car
```sh
CLUSTER_NAME=ekscluster1
DEPLOY_NAME=prom-operator-${CLUSTER_NAME}
THANOS_BUCKET_NAME=thanos-store-1234
NAMESPACE_NAME=monitoring

```

- code block `refer-s3-config`
```sh title="refer-s3-config"
echo ${DOMAIN_NAME}
echo ${CLUSTER_NAME}
echo ${STORAGECLASS_NAME:=gp2}
echo ${THANOS_BUCKET_NAME}
echo ${AWS_DEFAULT_REGION}
echo ${CERTIFICATE_ARN}
echo ${NAMESPACE_NAME}

kubectl create ns ${NAMESPACE_NAME}

envsubst >s3-config/thanos-s3-config-${CLUSTER_NAME}.yaml <<-EOF
type: S3
prefix: "${CLUSTER_NAME}"
config:
    bucket: "${THANOS_BUCKET_NAME}"
    endpoint: "s3.${AWS_DEFAULT_REGION}.amazonaws.com"
    region: "${AWS_DEFAULT_REGION}"
    sts_endpoint: "https://sts.amazonaws.com"
EOF

kubectl -n ${NAMESPACE_NAME} create secret generic thanos-s3-config-${CLUSTER_NAME} --from-file=thanos-s3-config-${CLUSTER_NAME}=s3-config/thanos-s3-config-${CLUSTER_NAME}.yaml

```
^refer-s3-config

- deploy prometheus with thanos and grafana
```sh
# enable grafana and typical prometheus
envsubst >prometheus/values-${CLUSTER_NAME}-1.yaml <<-EOF
grafana:
  enabled: true
  deploymentStrategy:
    type: Recreate
  service:
    type: NodePort
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
    hosts:
      - grafana-${DOMAIN_NAME%%.*}.${DOMAIN_NAME}
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 4h
    retentionSize: "20GB"
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    topologySpreadConstraints: 
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: prometheus
    # additionalScrapeConfigsSecret: 
    #   enabled: true
    #   name: additional-scrape-configs
    #   key: avalanche-additional.yaml
    storageSpec: 
      volumeClaimTemplate:
        spec:
          storageClassName: ${STORAGECLASS_NAME}
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
        selector: {}
    externalLabels: 
      cluster: "${CLUSTER_NAME}"
      cluster_name: "${CLUSTER_NAME}"
      origin_prometheus: "${CLUSTER_NAME}"
EOF

# enable prometheus with thanos
envsubst >prometheus/values-${CLUSTER_NAME}-1-1.yaml <<-EOF
prometheus:
  thanosService:
    enabled: true
  thanosServiceMonitor:
    enabled: true
  thanosServiceExternal:
    enabled: true
    type: LoadBalancer
  prometheusSpec:
    thanos: 
      objectStorageConfig:
        existingSecret:
          name: thanos-s3-config-${CLUSTER_NAME}
          key: thanos-s3-config-${CLUSTER_NAME}
EOF

helm upgrade -i -f prometheus/values-${CLUSTER_NAME}-1.yaml -f prometheus/values-${CLUSTER_NAME}-1-1.yaml ${DEPLOY_NAME} prometheus-community/kube-prometheus-stack --namespace ${NAMESPACE_NAME}
# helm uninstall ${DEPLOY_NAME} --namespace monitoring

```

- create irsa in monitoring namespace for thanos ([[git/git-mkdocs/CLI/linux/eksctl#create-iamserviceaccount-]])
```sh
echo ${DEPLOY_NAME}
echo ${CLUSTER_NAME}
SA_NAME=${DEPLOY_NAME}-prometheus

```

- code block `refer-irsa-prometheus`
```sh title="refer-irsa-prometheus"
create-iamserviceaccount ${SA_NAME} ${CLUSTER_NAME} monitoring 0
echo ${S3_ADMIN_ROLE_ARN}
kubectl annotate sa prom-operator-${CLUSTER_NAME}-prometheus -n monitoring eks.amazonaws.com/role-arn=${S3_ADMIN_ROLE_ARN} --overwrite

```
^refer-irsa-prometheus

- rollout deployment
```sh
kubectl rollout restart sts prometheus-prom-operator-${CLUSTER_NAME}-prometheus -n monitoring

```

#### observee-cluster-
- switch to observee cluster (ekscluster2)
```sh
kubectx #switch to ekscluster2
```
- on observee cluster (ekscluster2)
```sh
CLUSTER_NAME=ekscluster2
DEPLOY_NAME=prom-operator-${CLUSTER_NAME}
THANOS_BUCKET_NAME=thanos-store-1234
NAMESPACE_NAME=monitoring

```

!!! note "refer code block `refer-s3-config`"
    ![[POC-prometheus-ha-architect-with-thanos#^refer-s3-config]]

- deploy prometheus with remote write and thanos sider car
```sh
# enable grafana and typical prometheus
envsubst >prometheus/values-${CLUSTER_NAME}-1.yaml <<-EOF
grafana:
  enabled: false
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 4h
    retentionSize: "20GB"
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    topologySpreadConstraints: 
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: prometheus
    # additionalScrapeConfigsSecret: 
    #   enabled: true
    #   name: additional-scrape-configs
    #   key: avalanche-additional.yaml
    storageSpec: 
      volumeClaimTemplate:
        spec:
          storageClassName: ${STORAGECLASS_NAME}
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
        selector: {}
    remoteWrite: 
    - url: http://k8s-thanos-thanosre-xxx.elb.us-east-2.amazonaws.com:19291/api/v1/receive
    remoteWriteDashboards: true
    externalLabels: 
      cluster: "${CLUSTER_NAME}"
      cluster_name: "${CLUSTER_NAME}"
      origin_prometheus: "${CLUSTER_NAME}"
EOF

# enable prometheus with thanos
envsubst >prometheus/values-${CLUSTER_NAME}-1-1.yaml <<-EOF
prometheus:
  thanosService:
    enabled: true
  thanosServiceMonitor:
    enabled: true
  thanosServiceExternal:
    enabled: true
    type: LoadBalancer
  prometheusSpec:
    thanos: 
      objectStorageConfig:
        existingSecret:
          name: thanos-s3-config-${CLUSTER_NAME}
          key: thanos-s3-config-${CLUSTER_NAME}
EOF

helm upgrade -i -f prometheus/values-${CLUSTER_NAME}-1.yaml -f prometheus/values-${CLUSTER_NAME}-1-1.yaml ${DEPLOY_NAME} prometheus-community/kube-prometheus-stack --namespace ${NAMESPACE_NAME}
# helm uninstall ${DEPLOY_NAME} --namespace monitoring

```
- using remote write, WAL log will be transfer to receive pod, you could query real time data from receive.

- create irsa in monitoring namespace for thanos ([[git/git-mkdocs/CLI/linux/eksctl#create-iamserviceaccount-]])
```sh
echo ${DEPLOY_NAME}
echo ${CLUSTER_NAME}
SA_NAME=${DEPLOY_NAME}-prometheus
```

!!! note "refer code block `refer-irsa-prometheus`"
    ![[POC-prometheus-ha-architect-with-thanos#^refer-irsa-prometheus]]

- rollout
```sh
kubectl rollout restart sts prometheus-prom-operator-${CLUSTER_NAME}-prometheus -n monitoring
```

### thanos
#### store
- reuse 2 cluster s3 config file for thanos store on observer
```sh
k create ns thanos
for CLUSTER_NAME in ekscluster1 ekscluster2 ; do
    kubectl create secret generic thanos-s3-config-${CLUSTER_NAME} --from-file=thanos-s3-config-${CLUSTER_NAME}=./s3-config/thanos-s3-config-${CLUSTER_NAME}.yaml -n thanos
done
```
- create thanos store for history data query
    - download [[store.tar.gz]] 
```sh
kubectl apply -f store/
```
- create role for sa ([[git/git-mkdocs/CLI/linux/eksctl#create-iamserviceaccount-]]) and annotate to existed sa
```sh
CLUSTER_NAME=ekscluster1
for SA_NAME in thanos-store-cluster1 thanos-store-cluster2 ; do
    create-iamserviceaccount ${SA_NAME} ${CLUSTER_NAME} thanos 0
    echo ${SA_NAME}
    echo ${S3_ADMIN_ROLE_ARN}
    kubectl annotate sa ${SA_NAME} -n thanos eks.amazonaws.com/role-arn=${S3_ADMIN_ROLE_ARN} --overwrite
done
```
- rollout 2 stores (need to be deleted and apply again)
```sh
kubectl rollout restart sts thanos-store-cluster1 -n thanos
kubectl rollout restart sts thanos-store-cluster2 -n thanos
```

#### query-and-query-frontend-
- download [[query.tar.gz]] 
- modify query frontend ingress yaml
```sh
  rules:
    - host: thanos-query-frontend-ingress.${DOMIAN_NAME}
```
- improve query performance in query frontend deployment yaml
```yaml
        - --query-range.split-interval=1h
        - --labels.split-interval=1h
```
- modify query deployment yaml as need, add endpoint for sider car, receive, store, etc.
- deploy
```sh
kubectl apply -f query/
```

#### receive
- create receive for ekscluster2
- use existed s3 config file in secret
- download [[receive.tar.gz]]
- deploy receive for ekscluster2 dedicate
```sh
k apply -f receive/
```
- create irsa in thanos namespace for receive ([[git/git-mkdocs/CLI/linux/eksctl#create-iamserviceaccount-]])
```sh
CLUSTER_NAME=ekscluster1
SA_NAME=thanos-receive-cluster2

create-iamserviceaccount ${SA_NAME} ${CLUSTER_NAME} thanos 0
echo ${S3_ADMIN_ROLE_ARN}
kubectl annotate sa ${SA_NAME} -n thanos eks.amazonaws.com/role-arn=${S3_ADMIN_ROLE_ARN} --overwrite
```
- rollout (delete and apply again)
```sh
k rollout restart sts thanos-receive-cluster2 -n thanos
```
- get receive svc 
    - add it to prometheus remote write in ekscluster2 ([[git/git-mkdocs/EKS/operation/monitor/POC-prometheus-ha-architect-with-thanos#observee-cluster-]])
    - add it to query deployment yaml ([[git/git-mkdocs/EKS/operation/monitor/POC-prometheus-ha-architect-with-thanos#query-and-query-frontend-]])

### grafana
#### query history metrics
- change default password
- add prometheus type data source 
    - url: http://thanos-query-frontend.thanos.svc.cluster.local:9090
- go this dashboard `Kubernetes / Networking / Namespace (Pods)`
![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-3.png]]
- we have history data, but no latest 2 hour metrics
- go to query deployment to add thanos sidercar svc (`xxx-kub-thanos-external`) to endpoint list with port `10901`
- query again from grafana, we will get full metrics


#### query by label cluster (prefer)
- modify existed variable to use cluster label
    - no need to change dashboard definitions 
![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-4.png]]
- we already label data in prometheus yaml and receive yaml with `cluster=my_cluster_name`

#### query by externalLabels (alternative)
- custom dashboard
![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-5.png]]

#### others
- 刷新 receive 数据时抖动严重
    - 检查是否多副本 receive sts，且未做数据 replica


## refer

### prometheus tsdb block duration

- change block-duration, will cause prometheus statefulset cannot be start
    - https://github.com/prometheus-operator/prometheus-operator/issues/4414
```yaml
  prometheusSpec:
    additionalArgs: 
    - name: storage.tsdb.min-block-duration
      value: 30m
    - name: storage.tsdb.max-block-duration
      value: 30m
```

### samples 
#### thanos config sample in this POC
- https://github.com/panlm/thanos-example

#### grafana ingress with nginx sample
```sh
envsubst >${TMP}-1.yaml <<-EOF
grafana:
  deploymentStrategy:
    type: Recreate
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - grafana.${DOMAIN_NAME}
    tls:
      - secretName: grafana.${DOMAIN_NAME}
        hosts:
          - grafana.${DOMAIN_NAME}
  persistence:
    enabled: true
    storageClassName: ${STORAGECLASS_NAME}
    accessModes:
      - ReadWriteOnce
    size: 1Gi
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 12h
    retentionSize: "10GB"
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ${STORAGECLASS_NAME}
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
EOF
```

#### thanos ingress with nginx sample
```sh
# enable prometheus with thanos
envsubst >${TMP##*.}-1-1.yaml <<-EOF
prometheus:
  thanosService:
    enabled: true
  thanosServiceMonitor:
    enabled: true
  thanosServiceExternal:
    enabled: true
    type: LoadBalancer
  thanosIngress:
    enabled: true
    ingressClassName: nginx
    hosts: 
    - thanos-gateway.${DOMAIN_NAME}
    paths: []
    # - /
    pathType: ImplementationSpecific
    tls: 
    - secretName: thanos-gateway-tls
      hosts:
      - thanos-gateway.${DOMAIN_NAME}
  prometheusSpec:
    thanos: 
      objectStorageConfig:
        existingSecret: {}
          key: thanos.yaml
          name: thanos-s3-config
EOF
```

#### other samples
- https://github.com/thanos-io/kube-thanos/tree/main/examples
- https://github.com/infracloudio/thanos-receiver-demo/tree/main/manifests

### receive controller 
- https://github.com/observatorium/thanos-receive-controller/tree/main
- receive controller does not included in this POC, it could based on header in remote write traffic to forward data to specific receive, refer (https://www.infracloud.io/blogs/multi-tenancy-monitoring-thanos-receiver/)
- In this POC we use dedicate receive. you could use receive route with receive controller project. refer (https://thanos.io/tip/proposals-accepted/202012-receive-split.md/)
- download  [[receive-controller.tar.gz]] 
- create receive controller in thanos namespace
```sh
kubectx $c1
k apply -f receive-controller/
```
- receive controller will generate `thanos-receive-generated` configmap with endpoint for receive route scenarios, include this file as hashring-config
- create default s3 config
```sh
CLUSTER_NAME=default
NAMESPACE=thanos
```

!!! note "refer code block `refer-s3-config`"
    ![[POC-prometheus-ha-architect-with-thanos#^refer-s3-config]]

- create sa
```sh
SA_NAME=thanos-receive-default
CLUSTER_NAME=ekscluster1
create-iamserviceaccount ${SA_NAME} ${CLUSTER_NAME} thanos 1
```

### links
- https://observability.thomasriley.co.uk/prometheus/using-thanos/high-availability/
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/high-availability.md
- https://medium.com/@kakashiliu/deploy-prometheus-operator-with-thanos-60210eff172b
- https://particule.io/en/blog/thanos-monitoring/
- https://blog.csdn.net/kingu_crimson/article/details/123840099
- [[../../../../../../thanos|thanos]] 
- [[prometheus#performance-testing-]]
- [[prometheus#cmd-]]

### todo
- thanos receive router

