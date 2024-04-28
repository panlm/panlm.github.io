---
title: Building Prometheus HA Architect with Thanos
description: 用 Thanos 解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制
created: 2023-11-09 08:41:02.494
last_modified: 2024-02-22
status: deprecated
tags:
  - kubernetes
  - aws/container/eks
  - prometheus
---

!!! warning "This pages has been obseleted."
    released on aws
    https://aws.amazon.com/cn/blogs/china/extending-the-prometheus-high-availability-monitoring-architecture-using-thanos/

# 使用 Thanos 扩展 Prometheus 高可用监控架构
## 架构描述
Prometheus 是一款开源的监控和报警工具，专为容器化和云原生架构的设计，通过基于 HTTP 的 Pull 模式采集时序数据，提供功能强大的查询语言 PromQL，并可视化呈现监控指标与生成报警信息。客户普遍采用其用于 Kubernetes 的监控体系建设。Amazon 也在 2021 年 9 月正式发布了托管的 Prometheus 服务（Amazon Managed Service for Prometheus）简化客户部署和使用。并且在 2023 年 11 月针对 EKS 发布了托管的 Prometheus 服务的无代理采集功能（[新闻稿](https://aws.amazon.com/about-aws/whats-new/2023/11/amazon-managed-service-prometheus-agentless-collector-metrics-eks/)），进一步方便客户无需提前规划，从而可以开箱即用的使用 Prometheus 的相关组件。

截止本文发布之日，在亚马逊中国区域暂时没有发布托管的 Prometheus 服务。因此针对中国客户如何部署一套 Prometheus 监控平台的最佳实践指导可以帮助客户快速使用 Prometheus，从而将精力专注于业务需求。

独立 Kubernetes 集群通常使用 [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) 部署所有相关组件包括 Alert Manager、Grafana 等。这种独立部署的监控架构优点是部署方便，数据持久化使用 EBS 也可以满足大部分场景下查询性能的要求，但缺点也显而易见，即无法保存太长时间的历史数据。而且当客户环境中集群数量较多，监控平台自身的可用性和可靠性要求较高，同时希望提供全局查询时，管理和维护的工作量也随之增加。

Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制。当需要做历史性能数据分析，或者使用 Prometheus 进行成本分析的场景都会依赖于较长时间的历史数据。Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询历史数据和备份等方面的扩展性挑战。

在讨论基于 Thanos 的各种 Prometheus 监控架构之前，我们先了解下 Thanos 及其常用的组件，更多详细信息可以参考 [thanos.io](http://thanos.io) 。  
- Sidecar（边车）：运行在 Prometheus 的 Pod 中，读取其数据以供查询和/或上传到云端对象存储。
- Store（存储网关）：用于从对象存储（例如：AWS S3）上查询数据。
- Compactor（压缩器)：对存储在对象存储中的数据进行压缩、聚合历史数据以减小采样精度并长久保留。
- Receiver（接收器）：接收来自 Prometheus 远程写入日志的数据，并将其上传到对象存储。
- Ruler（规则器）：针对 Thanos 中的数据评估记录和警报规则。
- Query（查询器）：实现 Prometheus 的 v1 API，查询并汇总来自底层组件的数据。将所有数据源添加为 Query 的 Endpoint，包括 Sidecar、 Store、 Receiver 等。
- Query Frontend（查询前端）：实现 Prometheus 的 v1 API，将其代理给查询器，同时缓存响应，并可以拆分查询以提高性能。

第一种监控架构（对应下图蓝色集群及组件）：
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-arch-1.png]]
- 被监控集群（Observee）部署 Prometheus 且启用 Thanos 的 Sidecar 方式将监控的历史数据定期归档到 S3，通过部署 Thanos Store 组件查询历史数据（图中 Store 组件部署在集中监控集群中）；
- 集中监控集群（Observer）除了部署 Thanos 组件之外，将统一部署 Grafana 作为 Dashboard 展示。

第二种监控架构（对应下图红色集群及组件）：
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-arch-2.png]]
- 被监控集群（Observee）除了启用 Thanos Sidecar 之外，还启用了 Prometheus 的 Remote Write 功能，将未归档的数据以 WAL 方式远程传输到部署在集中监控集群（Observer）上的 Thanos Receiver，以保证数据的冗余度。 Thanos Receiver 同样可以将历史监控数据归档到 S3 上，且支持被 Thanos Query 直接查询，同时避免直接查询 Sidecar 而给被监控集群带来额外的性能损耗。

第三种监控架构（对应下图黄色集群及组件）：
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-arch-3.png]]
- 在多集群监控场景下，一般会在每个集群部署独立的 Prometheus 组件。Prometheus 提供 Agent Mode 针对这样的场景可以最小化资源占用，直接启用 Remote Write 功能将监控数据集中保存 （可以是另一个 Prometheus 集群，或者 Thanos Receiver 组件）。

第四种监控架构（对应上图绿色集群及组件）：
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-arch-4.png]]
- 在 AWS 上可以使用托管的 Prometheus 服务作为集中监控数据持久化，提供最好的性能和最低的维护成本。每个被监控集群可以使用无代理采集功能（[新闻稿](https://aws.amazon.com/about-aws/whats-new/2023/11/amazon-managed-service-prometheus-agentless-collector-metrics-eks/)），进一步方便客户无需提前规划，从而可以开箱即用的使用 Prometheus 的相关组件。

以下总结了各种 Prometheus 监控架构所适合的场景：

第一种监控架构（对应上图蓝色集群及组件）
- 适用场景
    - 适合绝大部分生产环境，尤其<mark style="background: #ADCCFFA6;">在亚马逊中国区域没有托管 Prometheus 服务，此类架构也是客户首选</mark>。
- 优点
    - 架构简单
    - 只有一份监控数据，最小化存储成本和其他资源开销
- 缺点 
    - 通过 Sidecar 查询实时监控数据时，将给被监控集群带来额外性能损耗

第二种监控架构（对应上图红色集群及组件）
    适用场景
        在 Thanos 0.19 版本之前，Sidecar 还没有实现 StoreAPI 时，只能通过 Receive 查询最新的性能数据。适合需要多副本监控数据的特殊场景。
- 优点
    - 监控数据冗余，可以使用 Compactor 对数据进行压缩、聚合历史数据以减少存储成本
    - 直接从 Thanos Receive 查询实时性能数据，对被监控集群没有额外性能损耗
- 缺点
    - 架构复杂，每个集群对应一组 Thanos Receive，建议配置副本数量和资源等与源集群的 Prometheus 副本数量和资源相同

第三种监控架构（对应上图黄色集群及组件）
- 适用场景
    - 最大程度减少对于被监控集群的资源占用，可以使用 Prometheus 的 Agent Mode：
- 优点
    - 架构简单，使用 Agent Mode 几乎无状态，可以使用除 Stateful 之外的其他 Deployment，本地存储需求低（除非远程 Endpoint 不可用时，本地缓存数据以重试）
    - 可实现集中告警 - 告警将通过 Thanos Ruler 定义，通过 Thanos Query 查询 Receive 并发送到监控集群的 Alert Manager 实现
- 缺点 
    - 无监控数据冗余，某些组件将无法在 Agent Mode 下启用，例如：Sidecar、Alert、Rules （参见[文档](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/designs/prometheus-agent.md)）

第四种监控架构（对应上图绿色集群及组件）
- 适用场景
    - <mark style="background: #BBFABBA6;">在支持托管 Prometheus 服务的亚马逊区域</mark>（[文档](https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html#AMP-supported-Regions)）<mark style="background: #BBFABBA6;">可以直接使用</mark>，实现完全开箱即用，同时避免管理 Thanos 组件，只需要部署 Grafana 即可。
- 优点
    - 架构简单，资源占用少
    - 免维护
- 缺点
    - 托管 Prometheus 服务的成本计算，参考[文档](https://aws.amazon.com/prometheus/pricing/)


## walkthrough
### Prometheus on EKS
Prometheus Operator（[link](https://github.com/prometheus-operator/prometheus-operator)）提供 Kubernetes 原生部署和管理 Prometheus 及相关监控组件的功能。该项目的目的是简化和自动配置 Kubernetes 集群基于 Prometheus 的监控堆栈。本实验基于 Prometheus Operator 部署作为基础，并通过 values.yaml 参数文件定制。 本实验中将使用 Terraform 快速创建 EKS 集群，并且自动部署上图中相关的 Prometheus 监控架构。

- 本实验中使用了预设的子域名用于简化服务之间的访问和对外暴露。需要提前在 Route53 中创建该子域名（复制[链接](https://panlm.github.io/EKS/addons/externaldns-for-route53/#func-setup-hosted-zone-)中的函数并粘贴到命令行）
```sh
PARENT_DOMAIN_NAME=eks0103.aws.panlm.xyz
create-hosted-zone -n ${PARENT_DOMAIN_NAME}
```
- 然后在上游 Route53 中创建对应的 NS 记录（复制[链接](https://panlm.github.io/CLI/awscli/route53-cmd/?h=create+ns#func-create-ns-record-)中的函数并粘贴到命令行），此处离开 Cloud9 窗口，或者确保命令行有上游 Route53 相应的权限
```sh
PARENT_DOMAIN_NAME=eks0103.panlm.xyz
NS="copy NS records from previous output and paste here"
create-ns-record -n $PARENT_DOMAIN_NAME -s "$NS" # double quote is mandortory
```
- 创建本实验的目录，后续将在此路径下克隆 2 个 REPO，分别用于创建 EKS 集群的 Terraform 代码和 Thanos 配置示例
```sh
LAB_HOME=~/environment/lab-thanos
mkdir -p ${LAB_HOME}
```
- 先获取 Thanos 配置模板，Thanos 相关组件通过 Terraform 自动化部署在被监控集群（ekscluster1），目录说明如下：
    - prometheus: 包含针对 Prometheus Operator 的定制 Values
    - s3-config: 提供 Thanos 组件访问 S3 的相关配置信息，这些配置将会被创建成 kubernetes 的 secret
    - thanos-values: 包含针对 [bitnami thanos chart](https://github.com/bitnami/charts/tree/main/bitnami/thanos) 的定制 Values
    - thanos-yaml: 包含自建 Thanos 使用的相关 Yaml 定义文件。更多模板参考 [link](https://github.com/thanos-io/kube-thanos)
```sh
cd ${LAB_HOME}
git clone https://github.com/panlm/thanos-example.git
cd thanos-example
```
- 使用下面参数进行创建本实验使用的配置文件，位于 `POC` 目录下。子域名 `thanos` 对应下一步中的 `environment_name`
```sh
CLUSTER_NAME_1=ekscluster1
CLUSTER_NAME_2=ekscluster2
CLUSTER_NAME_3=ekscluster3
DOMAIN_NAME=thanos.${PARENT_DOMAIN_NAME} # this domain will be created by terraform
THANOS_BUCKET_NAME=thanos-store-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export CLUSTER_NAME_1 CLUSTER_NAME_2 CLUSTER_NAME_3 DOMAIN_NAME THANOS_BUCKET_NAME AWS_DEFAULT_REGION

aws s3 mb s3://${THANOS_BUCKET_NAME}

mkdir POC
cd POC-template
find ./ -type d -name "[a-z]*" -exec mkdir ../POC/{} \;

find ./ -type f -name "*" |while read filename ; do
  cat $filename |envsubst '$CLUSTER_NAME_1 $CLUSTER_NAME_2 $CLUSTER_NAME_3 $DOMAIN_NAME $THANOS_BUCKET_NAME $AWS_DEFAULT_REGION' > ../POC/$filename
done
```
- 获取 Terraform 代码开始创建环境。目录说明如下：
    - environment 目录：创建实验公用的 VPC 等资源；
    - ekscluster1 目录：创建目录同名 EKS 集群，对应第一种监控架构图中所有组件；
    - ekscluster2 目录：创建目录同名 EKS 集群，对应第二种监控架构图中红色集群及组件；
    - ekscluster3 目录：创建目录同名 EKS 集群，对应第三种监控架构图中黄色集群及组件；
```sh
cd ${LAB_HOME}
git clone https://github.com/panlm/eks-blueprints-clusters.git
cd eks-blueprints-clusters/multi-cluster-thanos
```
- 修改 `terraform.tfvars` 配置如下
```text
aws_region          = "us-east-2"
environment_name    = "thanos" # sub-domain will be created by terraform
cluster_version     = "1.27"
hosted_zone_name    = "eks0103.aws.panlm.xyz" # your existing hosted zone
eks_admin_role_name = "" # Additional role admin in the cluster 
```
- 创建独立的环境用于本实验，包括 VPC，Secret，环境特定的子域名等
```sh
cd environment
terraform init
terraform apply -auto-approve
```
- 创建 ekscluster1（目录名即为 EKS 集群名），并根据命令行输出保存 kubeconfig 配置。创建集群后将自动检查 `thanos-example/POC` 路径下相关文件存在，则安装 Prometheus 和 Thanos 组件。
```sh
cd ../ekscluster1
terraform init
terraform apply -auto-approve
```
- 按照上述操作分别进入其他两个目录创建 ekscluster2 和 ekscluster3，可以通过其他 terminal 同时操作。

### Thanos 组件
方便大家了解 Thanos 的配置和工作原理，简要说明下 `thanos-example/thanos-yaml` 目录下的相关配置，方便按需修改并使用。

#### Store
Store 组件将只用于访问 S3 上的历史数据，每个 Store 使用独立的 secret 配置，且对应一个被监控集群。
- 查看创建的 s3 的 secret 和 service account
```sh
kubectl get secret -n thanos
kubectl get sa -n thanos
kubectl get po -n thanos |grep store
```

#### Query 和 Query Frontend
Query Frontend 对外提供与 Prometheus 兼容的 API，可以直接作为 Prometheus 类型的数据源添加到 Grafana 中；Query 是无状态且可以横向扩展，对外提供 Prometheus 兼容的 API 供外部工具查询，例如 Grafana，本实验中 Query Frontend 实现将查询分片（split），使用 Query 组件提供查询的横向扩展能力。
- `query-frontend-deployment` 文件中指定了如下分割查询的参数，对外域名定义在 `query-frontend-service` 文件中
```yaml
        - --query-range.split-interval=4h
        - --labels.split-interval=4h
```
- `query-deployment` 文件中指定了 Query 组件查询目标端点，包括 Sidecar，Receiver，Store 等，本实验均通过域名访问

#### Receive 
- 部署独立的 Thanos Receive 组件，分别对应 ekscluster2 和 ekscluster3。建议分配 Receive 组件的资源和数量需要和被监控集群中 Prometheus 采集组件的资源和数量相当。

### Grafana
使用 Prometheus Operator 部署 Grafana 将自带一些常用的 Dashboard，我们可以进行简单配置实现多集群数据查询。
#### 查看多集群 Dashboard
- 访问 Grafana 域名，可以通过 `thanos-example/POC/prometheus/values-ekscluster1-1.yaml` 中查看
- 修改 Grafana 默认密码 `prom-operator`
- 添加 Thanos Query Frontend 作为 Prometheus  类型的数据源
    - 定义数据源名称 `thanoslab`，并设置为默认
    - 直接使用 Kubernetes 内部域名: `http://thanoslab-query-frontend.thanos.svc.cluster.local:9090`
    - 或者上文提到的 Query Frontend Service 绑定的域名访问
- 查看预置的 dashboard： `Kubernetes / Compute Resources / Multi-Cluster` 
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-grafana-1.png]]

#### 查看其他 Dashboard
通过简单修改即可将其他预置 dashboard 修改为支持多集群查询：
- 打开预置的 dashboard：`Kubernetes / Compute Resources / Namespace (Pods)`
- 点击齿轮图标进入 Dashboard Settings 界面
- 在 Variable 中 找到 `cluster` 变量，按照下面截图修改
    - Show on dashboard 设置为 `Label and value`
    - Data source 设置为 `thanoslab`
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-grafana-2.png]]
- 点击 Apply 保存变量修改
- 点击 Save As 保存 Dashboard 即可

#### 查看 Thanos Query Frontend 数据源接口
- 打开 Frontend Service 的外部域名: `thanos-query-frontend.${DOMAIN_NAME}`
    - Receive 表中，Min Time 有值表示 Prometheus 使用 Remote Write 将数据写入 Receive 成功
    - Prometheus 中收到性能指标数据以 WAL 形式保存在内存并持久化到磁盘，启用 Sidecar 后，自动将 `min-block-duration` 和 `max-block-duration` 设置成 2小时且无法更改，即每个数据块文件保存2小时的性能指标。同时 Prometheus 设置 `retention` 时间和 `retentionSize` 大小，未到 `retention` 前，Sidecar 表中，Min Time 将显示为 `-`，到 `retention` 后，数据由 Sidecar 写入 S3，此时会显示最早数据的时间戳
    - Store 表中，Min Time 有值表示数据被写入 S3，且显示最早数据的时间戳
- 数据通过 Label 标注来源的集群名称以及采集数据的 Pod 名称
- 本实验在 Prometheus 中设置了 3 个 `ExternalLabel`，包括 `cluster`、`cluster_name`、`origin_prometheus`
![[../../../git-attachment/TC-prometheus-ha-architect-with-thanos-png-grafana-3.png]]
### 清理环境
- 按照下面步骤清理集群 `ekscluster1` 相关内容
```sh
cd ${LAB_HOME}
cd eks-blueprints-clusters/multi-cluster-thanos/${CLUSTER_NAME}
../tear-down.sh
```
- 同理进入 `ekscluster2` 和 `ekscluster3` 目录执行脚本清理集群资源 

## 结论
Prometheus 是一款开源的监控和报警工具，专为容器化和云原生架构的设计。客户普遍采用其用于 Kubernetes 的监控体系建设。Thanos是一套开源组件，构建在 Prometheus 之上，用以解决 Prometheus 在多集群大规模环境下的高可用性、可扩展性限制。当需要做历史性能数据分析，或者使用 Prometheus 进行成本分析的场景都会依赖于较长时间的历史数据。Thanos 主要通过接收并存储 Prometheus 的多集群数据副本，并提供全局查询和一致性数据访问接口的方式，实现了对于 Prometheus 的可靠性、一致性和可用性保障，从而解决了 Prometheus 单集群在存储、查询历史数据和备份等方面的扩展性挑战。

## 参考链接
- https://observability.thomasriley.co.uk/prometheus/using-thanos/high-availability/
- https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/high-availability.md
- https://medium.com/@kakashiliu/deploy-prometheus-operator-with-thanos-60210eff172b
- https://particule.io/en/blog/thanos-monitoring/
- https://blog.csdn.net/kingu_crimson/article/details/123840099
- [[../../../../../../thanos|thanos]] 
- [[prometheus#performance-testing-]]
- [[prometheus#cmd-]]
- https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
- [[../../../../../../prometheus-agent|prometheus-agent]]
- https://p8s.io/docs/operator/install/

## 文档版本
- [[../../../others/POC-prometheus-ha-architect-with-thanos-manually|POC-prometheus-ha-architect-with-thanos-manually]]


