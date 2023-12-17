---
title: 用 Thanos 扩展 Prometheus 高可用性架构
description: Prometheus是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于HTTP的pull模式采集时序数据，提供功能强大的查询语言PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。当集群数量较多，监控平台高可用性和可靠性要求高，希望提供全局查询，需要长时间保存历史监控数据等场景下，通常使用 Thanos 扩展 Promethseus 监控架构。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制，具体来说，Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询和数据备份等方面的扩展性挑战。
created: 2023-11-09 08:41:02.494
last_modified: 2023-12-17
tags:
  - kubernetes
  - aws/container/eks
---
> [!WARNING] This is a github note

# 使用 Thanos 扩展 Prometheus 高可用监控架构
## 架构描述
Prometheus是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于HTTP的pull模式采集时序数据，提供功能强大的查询语言PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。当集群数量较多，监控平台高可用性和可靠性要求高，希望提供全局查询，需要长时间保存历史监控数据等场景下，通常使用 Thanos 扩展 Promethseus 监控架构。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制，具体来说，Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询和数据备份等方面的扩展性挑战。

在讨论不同监控架构之前，我们先了解下 Thanos 及其常用的组件，更多详细信息可以参考 thanos.io 。

- Sidecar（边车）：运行在 Prometheus 的 Pod 中，读取其数据以供查询和/或上传到云存储。
- Store（存储网关）：用于从对象存储桶（例如：AWS S3）上查询数据
- Compactor（压缩器)：对存储在对象存储桶中的数据进行压缩、聚合历史数据以减小采样精度并长久保留。
- Receive（接收器）：接收来自 Prometheus 远程写入日志的数据，并将其上传到对象存储。
- Ruler（规则器）：针对 Thanos 中的数据评估记录和警报规则。
- Query（查询器）：实现 Prometheus 的 v1 API，查询并汇总来自底层组件的数据。将所有数据源添加为 Query 的 Endpoint，包括 Sidecar、 Store、 Receive 等。
- Query Frontend（查询前端）：实现 Prometheus 的 v1 API，将其代理给查询器，同时缓存响应，并可以拆分查询以提高性能。

第一种监控架构（对应下图蓝色和绿色集群及组件），被监控集群（Observee）只部署 Prometheus 和 Alert Manager 等组件用于监控集群本身，且启用 Thanos 的 Sidecar 方式将 Prometheus 监控的历史数据定期归档到 S3；被监控集群中不启用 Grafana 组件。监控集群（Observer）除了部署 Prometheus 和 Alert Manager 组件用于监控集群本身之外，将额外部署 Grafana 作为统一 Dashboard 展示，此外还将部署 Thanos 相关组件，包括： Receive 和 Store。Prometheus 收到监控指标后会保存在内存中，并且通过 WAL (Write-ahead Log) 方式持久化到磁盘。 Pod 重启后，将重新读取 WAL 文件到内存，如果未使用 EBS 作为数据持久化存储，将可能导致最近的监控数据缺失（参见 refer 章节 1 关于 tsdb block duration 的描述）。

![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-1.png]]

第二种监控架构（对应上图红色集群及组件），与第一种监控架构的区别在于被监控集群（Observee）除了启用 Thanos Sidecar 之外，还启用了 Prometheus 的 Remote Write 功能，将未归档的数据以 WAL 方式远程传输到部署在监控集群（Observer）上的 Thanos Receive，以保证数据的冗余度。 Thanos Receive 同样可以将历史监控数据归档到 S3 上，且支持被 Thanos Query 直接查询，同时避免直接查询 Sidecar 而给被监控集群带来额外的性能损耗。

以下总结了 Prometheus 的监控场景以及适合的环境。监控集群（Observer）上将部署 Grafana 作为统一 Dashboard 展示：

- 第一种监控架构，上图蓝色和绿色集群及组件适合普通生产环境，可以容忍额外性能损耗
    - 监控集群（Observer）- Prometheus & Grafana + Thanos Store
    - 被监控集群（Observee）- Prometheus + Thanos Sidecar
    - 优点
        - 架构简单
        - 只有一份监控数据，最小化存储成本
    - 缺点 
        - 无监控数据冗余
        - 查询监控数据将给被监控集群带来额外性能损耗
- 第二种监控架构，上图红色集群及组件适合生产环境对于监控数据冗余度要求高的场景
    - 监控集群（Observer）- Prometheus & Grafana + Thanos Store & Receive
    - 被监控集群（Observee）- Prometheus with Remote Write + Thanos Sidecar & Compactor
    - 优点
        - 直接从 Thanos Receive 查询监控数据，对被监控集群没有额外性能损耗
    - 缺点
        - 每个集群对应一组 Thanos Receive，建议配置副本数量与源集群 Prometheus 副本数量相同
        - 监控数据冗余，可以使用 Compactor 对数据进行压缩、聚合历史数据以减少存储成本
- 第三种监控架构，上图黄色集群及组件
    - 监控集群（Observer）- Prometheus & Grafana + Thanos Store & Receive
    - 被监控集群（Observee）- Prometheus Agent Mode (Or Prometheus with Remote Write, no additional components)
    - 优点
        - 架构简单
        - 可实现集中告警 - 告警将通过 Thanos Ruler 定义，通过 Thanos Query 查询 Receive 并发送到监控集群的 Alert Manager 实现
    - 缺点 
        - 不适用分布式告警
        - 无监控数据冗余

## go-through-
接下来我们将创建 3 个 EKS 集群，分别对应上图中的蓝色、红色、黄色集群验证 Thanos 相关配置。
### prometheus
- we will create 3 clusters, `ekscluster1` for observer, `ekscluster2` and `ekscluster3` for observee ([[../../infra/cluster/eks-cluster-with-terraform#sample-create-3x-clusters-for-thanos-poc-]])
- following 3 addons will be included in each cluster
    - [[git/git-mkdocs/EKS/infra/network/aws-load-balancer-controller#install-with-eksdemo-|aws load balancer controller]] 
    - [[git/git-mkdocs/EKS/infra/storage/ebs-for-eks#install-using-eksdemo-|ebs csi]] 
    - [[git/git-mkdocs/EKS/infra/network/externaldns-for-route53|externaldns-for-route53]] 
    - `DOMAIN_NAME` should be `environment_name.hosted_zone_name`, for example `thanos.eks1217.aws.panlm.xyz`
- get sample yaml 
```sh
git clone https://github.com/panlm/thanos-example.git
cd thanos-example
```
- following` README.md` to build your version yaml files
```sh
CLUSTER_NAME_1=ekscluster1
CLUSTER_NAME_2=ekscluster2
CLUSTER_NAME_3=ekscluster3
DOMAIN_NAME=thanos.eks1217.aws.panlm.xyz
THANOS_BUCKET_NAME=thanos-store-eks1217
AWS_DEFAULT_REGION=us-east-2
export CLUSTER_NAME_1 CLUSTER_NAME_2 CLUSTER_NAME_3 DOMAIN_NAME THANOS_BUCKET_NAME AWS_DEFAULT_REGION

mkdir POC
cd POC-template
find ./ -type d -name "[a-z]*" -exec mkdir ../POC/{} \;

find ./ -type f -name "*" |while read filename ; do
  cat $filename |envsubst > ../POC/$filename
done

cd ../POC/
```
- prepare to install thanos with helm
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm show values prometheus-community/kube-prometheus-stack > values_default.yaml
```
#### observer cluster
- switch to observer (ekscluster1)
```sh
kubectx ekscluster1
```
- create s3 config file for thanos sidecar
```sh
DEPLOY_NAME_1=prom-operator-${CLUSTER_NAME_1}
NAMESPACE_NAME=monitoring

kubectl create ns ${NAMESPACE_NAME}
kubectl create secret generic thanos-s3-config-${CLUSTER_NAME_1} --from-file=thanos-s3-config-${CLUSTER_NAME_1}=s3-config/thanos-s3-config-${CLUSTER_NAME_1}.yaml --namespace ${NAMESPACE_NAME} 
```
- deploy Prometheus with Thanos and Grafana
```sh
echo ${CLUSTER_NAME_1} ${DEPLOY_NAME_1} ${NAMESPACE_NAME}
helm upgrade -i -f prometheus/values-${CLUSTER_NAME_1}-1.yaml -f prometheus/values-${CLUSTER_NAME_1}-2.yaml ${DEPLOY_NAME_1} prometheus-community/kube-prometheus-stack --namespace ${NAMESPACE_NAME}
```

- create irsa in monitoring namespace for thanos ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
echo ${DEPLOY_NAME_1}
echo ${CLUSTER_NAME_1}
SA_NAME=${DEPLOY_NAME_1}-prometheus
create-iamserviceaccount -s ${SA_NAME} -c ${CLUSTER_NAME_1} -n monitoring -r 0
```

- rollout statefulset (or using k9s to delete pod and make it restart to use new SA)
```sh
kubectl rollout restart sts prometheus-prom-operator-${CLUSTER_NAME_1}-prometheus -n monitoring
```

#### observee-cluster-
- switch to observee cluster (ekscluster2)
```sh
kubectx ekscluster2
```
- on observee cluster (ekscluster2)
```sh
DEPLOY_NAME_2=prom-operator-${CLUSTER_NAME_2}
NAMESPACE_NAME=monitoring

kubectl create ns ${NAMESPACE_NAME}
kubectl create secret generic thanos-s3-config-${CLUSTER_NAME_2} --from-file=thanos-s3-config-${CLUSTER_NAME_2}=s3-config/thanos-s3-config-${CLUSTER_NAME_2}.yaml --namespace ${NAMESPACE_NAME}
```

- deploy Prometheus with remote write and Thanos Sidecar, no Grafana
```sh
echo ${CLUSTER_NAME_2} ${DEPLOY_NAME_2} ${NAMESPACE_NAME}
helm upgrade -i -f prometheus/values-${CLUSTER_NAME_2}-1.yaml -f prometheus/values-${CLUSTER_NAME_2}-2.yaml ${DEPLOY_NAME_2} prometheus-community/kube-prometheus-stack --namespace ${NAMESPACE_NAME}
```
- using remote write, WAL log will be transfer to receive pod, you could query real time data from thanos receive.

- create irsa in monitoring namespace for thanos ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
echo ${DEPLOY_NAME_2}
echo ${CLUSTER_NAME_2}
SA_NAME=${DEPLOY_NAME_2}-prometheus
create-iamserviceaccount -s ${SA_NAME} -c ${CLUSTER_NAME_2} -n monitoring -r 0
```

- rollout statefulset (or using k9s to delete pod and make it restart to use new SA)
```sh
kubectl rollout restart sts prometheus-prom-operator-${CLUSTER_NAME_2}-prometheus -n monitoring
```

#### observee cluster with prometheus agent mode
- switch to observee cluster (ekscluster3)
```sh
kubectx ekscluster3
```
- on observee cluster (ekscluster3)
```sh
DEPLOY_NAME_3=prom-operator-${CLUSTER_NAME_3}
NAMESPACE_NAME=monitoring

kubectl create ns ${NAMESPACE_NAME}
kubectl create secret generic thanos-s3-config-${CLUSTER_NAME_3} --from-file=thanos-s3-config-${CLUSTER_NAME_3}=s3-config/thanos-s3-config-${CLUSTER_NAME_3}.yaml --namespace ${NAMESPACE_NAME}
```

- deploy prometheus in agent mode with remote write
```sh
echo ${CLUSTER_NAME_3} ${DEPLOY_NAME_3} ${NAMESPACE_NAME}
helm upgrade -i -f prometheus/values-${CLUSTER_NAME_3}-1.yaml ${DEPLOY_NAME_3} prometheus-community/kube-prometheus-stack --namespace ${NAMESPACE_NAME}
```

- create irsa in monitoring namespace for thanos ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
echo ${DEPLOY_NAME_3}
echo ${CLUSTER_NAME_3}
SA_NAME=${DEPLOY_NAME_3}-prometheus
create-iamserviceaccount -s ${SA_NAME} -c ${CLUSTER_NAME_3} -n monitoring -r 0
```

- rollout statefulset (need to delete pod and make it restart to use new SA)
```sh
kubectl rollout restart sts prometheus-prom-operator-${CLUSTER_NAME_3}-prometheus -n monitoring
```

### thanos
- switch to observer cluster (ekscluster1), we will install all Thanos components on Observer cluster
```sh
kubectx ekscluster1
```

#### store
- reuse 3 cluster s3 config file for thanos store on observer
```sh
kubectl create ns thanos
for CLUSTER_NAME in ekscluster1 ekscluster2 ekscluster3 ; do
    kubectl create secret generic thanos-s3-config-${CLUSTER_NAME} --from-file=thanos-s3-config-${CLUSTER_NAME}=./s3-config/thanos-s3-config-${CLUSTER_NAME}.yaml -n thanos
done
```
- create thanos store for history data query
```sh
kubectl apply -f store/
```
- create role for sa ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]]) and annotate to existed sa
```sh
for SA_NAME in thanos-store-cluster1 thanos-store-cluster2 thanos-store-cluster3 ; do
    create-iamserviceaccount -s ${SA_NAME} -c ${CLUSTER_NAME_1} -n thanos -r 0
done
```
- rollout 2 stores (or using k9s to delete pod and make it restart to use new SA)
```sh
for i in thanos-store-cluster1 thanos-store-cluster2 thanos-store-cluster3 ; do
    kubectl rollout restart sts $i -n thanos
done
```

#### query-and-query-frontend-
- In query deployment yaml file, all endpoints we needed in this POC will be added to container's args, including sidecar, receive, store, etc.
- In query frontend service yaml file, it will bind domain name
- In query frontend deployment yaml file, using split parameters to improve query performance 
```yaml
        - --query-range.split-interval=1h
        - --labels.split-interval=1h
```
- deploy
```sh
kubectl apply -f query/
```

#### receive 
- use existed s3 config file in secret
- deploy 2 receives, one for ekscluster2 and another for ekscluster3
```sh
kubectl apply -f receive/
```
- create irsa in thanos namespace for receive ([[git/git-mkdocs/CLI/linux/eksctl#func-create-iamserviceaccount-]])
```sh
for SA_NAME in thanos-receive-cluster2 thanos-receive-cluster3 ; do
    create-iamserviceaccount -s ${SA_NAME} -c ${CLUSTER_NAME_1} -n thanos -r 0
done
```
- rollout 2 receives (or using k9s to delete pod and make it restart to use new SA)
```sh
for i in thanos-receive-cluster2 thanos-receive-cluster3 ; do
    kubectl rollout restart sts ${i} -n thanos
done
```
- (option) get receive svc domain name to: 
    - add it to prometheus remote write in ekscluster2 and ekscluster3 ([[git/git-mkdocs/EKS/operation/monitor/POC-prometheus-ha-architect-with-thanos#observee-cluster-]])
    - add it to query deployment yaml ([[git/git-mkdocs/EKS/operation/monitor/POC-prometheus-ha-architect-with-thanos#query-and-query-frontend-]])

### grafana
#### query history metrics
- change default password
- add prometheus type data source 
    - url: http://thanos-query-frontend.thanos.svc.cluster.local:9090
- go this dashboard `Kubernetes / Networking / Namespace (Pods)`
![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-3.png]]
- we have history data, but no latest 2 hour metrics
- go to query deployment to add thanos sidecar svc (`xxx-kub-thanos-external`) to endpoint list with port `10901`
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

#### thanos frontend 
- open svc of thanos frontend: `thanos-query-frontend.${DOMAIN_NAME}`
    - min time in receive table: means prometheus remote write has valid and data has been received by thanos receive
    - min time in sidecar table: data in thanos local before duration, 2 hr will write data from WAL to duration, if < 2hrs "-" will display. if over 2hrs, oldest data in local will be display
    - min time in store table: data has been store to s3, check labelset to identify data was written by receive or sidecar

![[../../../git-attachment/POC-prometheus-ha-architect-with-thanos-png-7.png]]


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
- if using Thanos sidecar, `max-block-duration` will be `2h`

### samples 
#### thanos config sample in this POC
- https://github.com/panlm/thanos-example

#### grafana ingress with alb sample
- `DOMAIN_NAME` should be `environment_name.hosted_zone_name`, for example `thanos.eks1217.aws.panlm.xyz`
```yaml
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
```

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
    storageClassName: gp2
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
          storageClassName: gp2
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
- https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/designs/prometheus-agent.md


### todo
- thanos receive router
- thanos compact component
- configmap in prometheus 

