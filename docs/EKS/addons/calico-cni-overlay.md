---
title: Calico CNI Overlay
description: Using Calico CNI overlay mode on EKS
created: 2025-12-02 10:48:26.233000
last_modified: 2026-07-07
tags:
- draft
- kubernetes/calico
status: myblog
permalink: git-mkdocs/eks/addons/calico-cni-overlay
---

# Calico CNI Overlay

> 已在 EKS 1.36 + eksctl 0.229.0 + Calico v3.32.1 实测验证 (2026-07-07)，其他组件版本见各节。Rancher 因 chart 拒装 1.36，另建 EKS 1.35 集群单独验证，见 POC 章节。

## eks cluster 

- create cluster and delete default aws vpc cni
```bash
CLUSTER_NAME=my-calico-cluster
export AWS_DEFAULT_REGION=us-west-2

eksctl create cluster --name ${CLUSTER_NAME} \
  --version 1.35 \
  --without-nodegroup

kubectl delete daemonset -n kube-system aws-node

```
- 注: 已去掉 `--enable-auto-mode=false`，当前 eksctl (0.229.0) 加 `--without-nodegroup` 时默认不会开 auto mode，此参数已不需要
- 注: 当前 eksctl 默认会把 metrics-server / vpc-cni / kube-proxy / coredns 装成 **EKS 托管 addon**（即使加了 `--without-nodegroup`）。删除 `aws-node` daemonset 效果不变（不会被自动拉回），但 `vpc-cni` addon 对象本身仍会残留在 EKS 侧且状态显示 ACTIVE/无 health issue，这只是展示层的信息不一致，不影响 Calico 联网

## calico cni 

- refer: [calico doc](https://docs.tigera.io/calico/latest/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-calico-networking) 
```bash
CALICO_VERSION=v3.32.1 # update 0707, 官方声明测试过 k8s 1.34-1.36

helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update

# Calico v3.32 起，CRD 已从 tigera-operator chart 中拆出，必须先单独装 CRD，否则 helm install 会报
# "no matches for kind APIServer/Installation/... in version operator.tigera.io/v1"
helm template calico-crds projectcalico/crd.projectcalico.org.v1 \
    --version ${CALICO_VERSION} | kubectl apply --server-side -f -

kubectl create namespace tigera-operator

# install calico using helm
helm install calico projectcalico/tigera-operator \
    --version ${CALICO_VERSION} \
    --namespace tigera-operator

kubectl patch installation default --type='json' -p='[{"op": "replace", "path": "/spec/cni", "value": {"type":"Calico"} }]'

# 确认使用节点 ip 作为出向 nat (natOutgoing=true)
# kubectl get ippool default-ipv4-ippool -o jsonpath='{.spec.natOutgoing}' 

eksctl create nodegroup \
    --cluster ${CLUSTER_NAME} \
    --node-type m6g.large \
    --max-pods-per-node 100 \
    --node-private-networking \
    --nodes 3

```

## oidc

- 必须先执行，否则后面 ebs-csi / efs-csi / external-dns 等创建 iamserviceaccount 会报 `no IAM OIDC provider associated with cluster`
```bash
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve
```
- [[git/git-mkdocs/CLI/linux/eksctl#oidc-]]

## 必须使用 hostNetwork 的组件

### CNI 插件本身

- 原因：需要配置节点网络，在网络初始化之前运行
- 实测：默认已修改

```text
NAME                                      READY   STATUS    RESTARTS   AGE    IP                NODE                                            NOMINATED NODE   READINESS GATES
calico-apiserver-565867495-ft8w2          1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
calico-apiserver-565867495-ld47h          1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-kube-controllers-578677b48-b5fgt   1/1     Running   0          2d3h   172.16.28.6       ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-node-d92rg                         1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
calico-node-fxhmc                         1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
calico-typha-68c49cdb58-wwldh             1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
goldmane-65dcd4f69b-cpnwm                 1/1     Running   0          2d3h   172.16.28.1       ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
whisker-785fcbb6fb-d6hm8                  2/2     Running   0          2d3h   172.16.186.65     ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### Kube-proxy 

- 原因：需要管理节点的 iptables/ipvs 规则
- 实测：默认已修改

```text
ubuntu:~$ kubectl get pod -A  -l k8s-app=kube-proxy -o wide
NAMESPACE     NAME               READY   STATUS    RESTARTS   AGE    IP                NODE                                            NOMINATED NODE   READINESS GATES
kube-system   kube-proxy-dxfx5   1/1     Running   0          2d3h   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
kube-system   kube-proxy-w9vtm   1/1     Running   0          2d3h   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### AWS Load Balancer Controller

- 原因：需要直接访问 AWS API 和 VPC 资源，overlay IP 无法被 AWS 服务识别
- 实测：需要手工修改
- 注：此组件非必需，按需安装（本次实测环境未安装验证）
- [[git/git-mkdocs/EKS/addons/aws-load-balancer-controller#install-|install]] it
- patch it
```bash

kubectl patch deployment aws-load-balancer-controller \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

# verify
kubectl get deployment aws-load-balancer-controller \
  -n kube-system \
  -o jsonpath='{.spec.template.spec.hostNetwork}' 

# enable gateway api support
# kubectl patch deployment aws-load-balancer-controller -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--feature-gates=NLBGatewayAPI=true,ALBGatewayAPI=true"}]'

```
- install external dns for route53 (chapter [[#External DNS]])
- install app to [[git/git-mkdocs/EKS/addons/externaldns-for-route53#verify-|verify]] 

### Metrics Server

- 原因: 需要从 kubelet 收集指标，使用 hostNetwork 可以避免网络层问题
- 实测：需要手工修改。启用后才能看到 cpu memory 等指标，不启用则 `kubectl top` 报 `Metrics API not available`
- 注: 现在 eksctl 建集群默认会把 metrics-server 装成 EKS 托管 addon，pod label 是 `app.kubernetes.io/name=metrics-server`（不是旧手工装法的 `k8s-app=metrics-server`），下面命令按新 label 查询
- refer: [[metrics-server]]
```sh

kubectl patch deployment metrics-server \
  -n kube-system \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

# verify
kubectl get deployment metrics-server \
  -n kube-system \
  -o jsonpath='{.spec.template.spec.hostNetwork}' 

```

```text
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE   IP                NODE                                            NOMINATED NODE   READINESS GATES
kube-system   metrics-server-7d4b87c6f7-csjw6   1/1     Running   0          32s   192.168.179.215   ip-192-168-179-215.us-west-2.compute.internal   <none>           <none>
kube-system   metrics-server-7d4b87c6f7-gnhvb   1/1     Running   0          32s   192.168.106.21    ip-192-168-106-21.us-west-2.compute.internal    <none>           <none>
```

### Cert-Manager-

- 原因：api server 需要通讯 webhook 验证证书
- 实测：需要手工修改。（也可在 `helm install` 时直接带 `--set webhook.hostNetwork=true --set webhook.securePort=10260` 一步到位，效果相同，实测于 v1.19.2 通过）
- 注：cert-manager 官方目前 tested 到 k8s 1.35（1.36 released 太新还没纳入测试矩阵），但实测在 1.36 上正常运行
- refer: [[cert-manager]]

```sh

kubectl patch deployment cert-manager-webhook -n cert-manager \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true}}}}'

kubectl patch deployment cert-manager-webhook -n cert-manager \
  --type=json -p='[
    {"op":"replace","path":"/spec/template/spec/containers/0/args/1","value":"--secure-port=10260"},
    {"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":10260}
  ]'
  
# verify
kubectl get deployment cert-manager-webhook -n cert-manager -o jsonpath='{.spec.template.spec.hostNetwork}' && echo

```
- or refer: [[git/git-mkdocs/EKS/addons/cert-manager#install-for-overlay-cni-]]

### nginx ingress

- 原因：
- 实测：

## 推荐使用 hostNetwork 的组件

### Cluster Autoscaler

- 原因: 需要调用 AWS API 管理 Auto Scaling Groups
- 实测：

### Node Problem Detector

- 原因：需要监控节点级别的问题
- 实测：

### CoreDNS 

- 原因：DNS 解析是关键服务，hostNetwork 可以提高可靠性，(可选但推荐)
- 实测：不使用 hostNetwork 也可以成功解析

```text
ubuntu:~$ kubectl get pod -A  -l eks.amazonaws.com/component=coredns -o wide
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE    IP            NODE                                            NOMINATED NODE   READINESS GATES
kube-system   coredns-5449774944-2d4jb   1/1     Running   0          2d4h   172.16.28.5   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
kube-system   coredns-5449774944-dnskk   1/1     Running   0          2d4h   172.16.28.4   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
```

### External DNS

- 原因：需要访问 AWS Route53 API
- 实测：不使用 hostNetwork 也可以成功创建 dns 记录
- refer: [[externaldns-for-route53]] 

```text
ubuntu:~$ kubectl get pod -A  -l "app.kubernetes.io/instance=external-dns,app.kubernetes.io/name=external-dns" -o wide
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE   IP              NODE                                            NOMINATED NODE   READINESS GATES
externaldns   external-dns-596bf4886b-lkg7k   1/1     Running   0          28h   172.16.186.69   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### EBS CSI Driver Node Plugin

- 原因：需要直接访问节点的块设备
- 实测：不使用 hostNetwork 也可以使用
- 注：helm chart 现在提示 `AmazonEBSCSIDriverPolicy` 已有更细粒度的替代品 `AmazonEBSCSIDriverPolicyV2` / `AmazonEBSCSIDriverEKSClusterScopedPolicy`，本文仍用旧 policy，验证可用，按需评估是否迁移
- refer: [[ebs-csi]]

```text
ubuntu:~$ kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-ebs-csi-driver,app.kubernetes.io/instance=storage-ebs-csi" -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP              NODE                                            NOMINATED NODE   READINESS GATES
ebs-csi-controller-97758bb7c-gnb45   5/5     Running   0          26m   172.16.186.72   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
ebs-csi-node-255gc                   3/3     Running   0          26m   172.16.28.8     ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
ebs-csi-node-t48tp                   3/3     Running   0          26m   172.16.186.71   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### EFS CSI Driver Node Plugin

- 原因：需要挂载 EFS 到节点
- 实测：不使用 hostNetwork 也可以使用，但是 efs csi node pod 自动使用 hostNetwork
- refer: [[efs-csi]]

```text
ubuntu:~$ kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=storage-efs-csi" -o wide
NAME                                  READY   STATUS    RESTARTS   AGE     IP                NODE                                            NOMINATED NODE   READINESS GATES
efs-csi-controller-784c568b8b-qgrh2   3/3     Running   0          8m46s   172.16.186.74     ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
efs-csi-node-kq96r                    3/3     Running   0          8m46s   192.168.179.147   ip-192-168-179-147.us-west-2.compute.internal   <none>           <none>
efs-csi-node-qfrhk                    3/3     Running   0          8m46s   192.168.153.130   ip-192-168-153-130.us-west-2.compute.internal   <none>           <none>
```

### Nginx Gateway Fabric 

- 原因：
- 实测：不需要 hostNetwork 也可以使用
- refer: [[nginx-gateway-fabric]]

```text
ubuntu:~$ kubectl get pod -A  -l app.kubernetes.io/instance=ngf -o wide
NAMESPACE       NAME                                        READY   STATUS    RESTARTS   AGE   IP               NODE                                            NOMINATED NODE   READINESS GATES
nginx-gateway   ngf-nginx-gateway-fabric-7d5b85c8b4-69bzl   1/1     Running   0          46h   172.16.176.16    ip-192-168-138-158.us-west-2.compute.internal   <none>           <none>
nginx-gateway   ngf-nginx-gateway-fabric-7d5b85c8b4-f6rwv   1/1     Running   0          46h   172.16.144.200   ip-192-168-100-127.us-west-2.compute.internal   <none>           <none>
nginx-gateway   production-gateway-nginx-846766b468-7nnz8   1/1     Running   0          40h   172.16.144.205   ip-192-168-100-127.us-west-2.compute.internal   <none>           <none>
nginx-gateway   production-gateway-nginx-846766b468-m4xt7   1/1     Running   0          40h   172.16.176.26    ip-192-168-138-158.us-west-2.compute.internal   <none>           <none>
```


## POC-202607

- 环境：EKS 1.35 + eksctl 0.229.0，us-west-2
- 节点：m6g.large (Graviton/arm64) x3，`--max-pods-per-node 100 --node-private-networking`
- 已验证：全部组件在纯 arm64 节点上运行正常，无兼容问题

- **Calico (tigera-operator)**
    - 版本：v3.32.1
    - 安装：helm (先装 `crd.projectcalico.org.v1` chart 再装 tigera-operator)
    - 备注：overlay/VXLAN，CNI 已切换
- **metrics-server**
    - 版本：EKS 托管 addon
    - 安装：eksctl 建集群自动装
    - 备注：需手动 patch hostNetwork=true 才能用
- **aws-ebs-csi-driver**
    - 版本：helm 最新
    - 安装：helm
    - 备注：不需要 hostNetwork
- **nginx-gateway-fabric (NGF)**
    - 版本：v2.6.6
    - 安装：helm OCI chart，**必须显式 `--version`**
    - 备注：不指定版本号会卡住不报错
- **vpc-cni / kube-proxy / coredns**
    - 版本：EKS 托管 addon
    - 安装：eksctl 建集群自动装
    - 备注：vpc-cni 的 `aws-node` daemonset 已删除，addon 对象会显示 DEGRADED（预期，不影响）
- **VictoriaMetrics (single)**
    - 版本：chart 0.41.0 / app v1.146.0
    - 安装：helm (`vm/victoria-metrics-single`)
    - 备注：无 webhook，不受 Calico overlay 影响；需显式指定 `storageClassName=gp3`（见下方存储坑）；详见 [[VictoriaMetrics#on-calico-overlay-network]]
- **Grafana Tempo (single binary)**
    - 版本：chart 2.2.3 / app 2.10.7
    - 安装：helm (**`grafana-community/tempo`**，非 `grafana/tempo`)
    - 备注：`grafana/tempo` chart 已标记 deprecated，迁到 `grafana-community` repo；无 webhook；详见 [[grafana-tempo#on-calico-overlay-network]]
- **Vault (dev mode)**
    - 版本：chart 0.34.0 / app v2.0.3
    - 安装：helm (`hashicorp/vault`)
    - 备注：**injector 有 mutating webhook，必须 `--set injector.hostNetwork=true`**，否则 Calico overlay 下 API server 连不到 injector pod。已实测验证 sidecar 注入生效；详见 [[vault#on-calico-overlay-network]]
- **APISIX + ingress-controller**
    - 版本：chart 2.15.0 / app 3.17.0
    - 安装：helm (`apisix/apisix`，`--skip-crds`)
    - 备注：见下方"坑"单独说明；validating webhook 默认 `enabled=false`，未触发 Calico 坑；详见 [[git/git-mkdocs/EKS/addons/apisix-on-eks#on-calico-overlay-network]]
- **Nacos (standalone)**
    - 版本：chart 1.0.3 / app v3.0.1
    - 安装：helm (`nacos-yunye/nacos`，官方 repo 404，用此镜像)
    - 备注：无 webhook，无 kubeVersion 限制；默认 `persistence.enabled=false` 用 emptyDir，需手动开启+指定 `storageClassName=gp3`；详见 [[nacos#on-calico-overlay-network]]
- **NeuVector**
    - 版本：chart 2.10.3 / app 5.5.3
    - 安装：helm (`neuvector/core`)，需先给 ns 打 `pod-security.kubernetes.io/enforce=privileged` 标签
    - 备注：controller/enforcer/manager/scanner 全部 Running；enforcer 本来就需要 privileged+hostPID（跟 CNI 无关）；admission webhook **默认关闭**未触发 Calico 坑，但注意下方风险说明；详见 [[NeuVector#on-calico-overlay-network]]
- **Rancher**
    - 版本：chart 2.14.3 / app v2.14.3
    - 安装：helm (`rancher-stable/rancher`)
    - 备注：EKS 1.36 被 chart `kubeVersion: < 1.36.0-0` 拒装，**EKS 1.35 验证通过**；需先装 cert-manager 提供 Issuer/Certificate CRD；rancher + rancher-webhook 均需 hostNetwork；详见 [[git/git-mkdocs/EKS/addons/rancher#on-calico-overlay-network]]

**未装**（按需评估）：
- AWS Load Balancer Controller — 本次不需要，跳过
- Cluster Autoscaler — 文档"推荐"分类，本次未装
- EFS 真实文件系统 / external-dns 的 IAM+route53 — 只验证了组件本身能装能跑，没接真实资源，本次测试不包含。
- cert-manager — EKS 1.36 环境本次测试不包含；EKS 1.35 环境为装 Rancher 而补装，见下方

### Rancher 补充验证（另建 EKS 1.35 集群，2026-07-07）

- 环境：EKS **1.35** + eksctl 0.229.0 + Calico v3.32.1，us-west-2，`my-calico-cluster-135`，节点同上（m6g.large x3）
- rancher-stable/rancher chart 2.14.3 硬编码 `kubeVersion: < 1.36.0-0`，EKS 1.36 直接被 chart 拒装（`helm install` 报错拒装），**EKS 1.35 验证通过，`helm install` 正常执行**
- 装 Rancher 前必须先装好 cert-manager（chart 依赖 `Issuer`/`Certificate` CRD），否则报 `no matches for kind "Issuer" in version cert-manager.io/v1`；cert-manager 装法见 [[git/git-mkdocs/EKS/addons/cert-manager#install-for-overlay-cni-]]
- 按文档 patch rancher + rancher-webhook 的 hostNetwork 后，`apiservice v1.ext.cattle.io` AVAILABLE=True，验证通过；详见 [[git/git-mkdocs/EKS/addons/rancher#on-calico-overlay-network]]

### NeuVector 风险提示（未触发但要知道）

- NeuVector controller 的 admission webhook（Policy → Admission Control 功能）**默认关闭**，装的时候不会碰 Calico overlay 坑
- 但如果以后在 web UI 里手动开启 Admission Control，webhook 会因为 controller pod 跑在 Calico overlay 网络上、control plane 连不到而失败（`context deadline exceeded` 或 `Address is not allowed`），跟 cert-manager/ALB controller 是同一类问题
- chart 里 `controller-deployment.yaml` **没有 hostNetwork 开关**（不像 cert-manager/vault 有现成 values 参数），需要手动 patch：
```bash
kubectl patch deployment neuvector-controller-pod -n neuvector \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}'
```
- 建议：真要用 Admission Control 前先执行上面 patch，再去 UI 里开启功能

### 存储坑：集群默认 StorageClass 缺失

- 集群自带的 `gp2` storageclass 是 **in-tree provisioner** (`kubernetes.io/aws-ebs`)，没有标记为 default，且没有对应 ebs-csi 驱动 (`ebs.csi.aws.com`) 的 storageclass
- 需要有 PVC 的组件（VictoriaMetrics、Tempo）如果不显式指定 storageClassName，PVC 会一直 Pending (`no persistent volumes available for this claim and no storage class is set`)
- 解决：手动建一个基于 `ebs.csi.aws.com` 的 gp3 storageclass 并设为默认
```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
parameters:
  type: gp3
EOF
```
- StatefulSet 的 `volumeClaimTemplate` 是不可变字段，如果先装错了 storageclass 再想改，`helm upgrade` 会报 `Forbidden: updates to statefulset spec...`，必须 `helm uninstall` + 删 PVC 重装

### APISIX 安装坑

- chart 自带的 `apisix-ingress-controller/crds/gwapi-crds.yaml` 里的 Gateway API CRD 版本比集群已装的（NGF 装的 v1.5.x）旧，k8s 1.36 新增的 `safe-upgrades.gateway.networking.k8s.io` ValidatingAdmissionPolicy 会拒绝降级安装，报 `Installing CRDs with version before v1.5.0 is prohibited`
  - 解决：`helm install` 加 `--skip-crds`，因为集群已经有更新版本的 Gateway API CRD 了
- `service.type=ClusterIP` 会报错 `spec.externalTrafficPolicy: Invalid value: "Cluster"`，因为 chart 默认给 gateway service 配了 externalTrafficPolicy（只对 NodePort/LoadBalancer 合法），本次用默认 NodePort
- ingress-controller 的 validating webhook 默认 `enabled=false`（调研阶段以为默认开启，实测是关的），所以本次没触发 Calico overlay 的 webhook 坑；如果以后要开这个 webhook，需要手动给 ingress-controller deployment patch hostNetwork（chart 没有现成开关）

重建环境时按上表顺序装：cluster → CRD → calico → nodegroup → oidc → 其余 addon → 应用层组件（先建 gp3 storageclass）。



