---
title: Rancher
description: Rancher 安装部署指南
created: 2026-01-01 10:52:16.443
last_modified: 2026-01-01
tags:
  - draft
  - aws/container/eks
---

# rancher

## Install 

https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster/rancher-on-amazon-eks

```sh
# helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

# helm show values rancher-stable/rancher


helm upgrade --install rancher rancher-stable/rancher \
    -n cattle-system --create-namespace \
    -f rancher-values.yaml 

```

needed
- [[aws-load-balancer-controller]] 
- [[externaldns-for-route53]] 
- [[cert-manager]] 
    - [[git/git-mkdocs/CLI/awscli/acm-cmd#create-certificate-]]
- [[ebs-csi]] 

## EKS + Calico Overlay 环境部署指南

### 环境说明

- EKS 集群使用 Calico CNI（overlay 模式：VXLAN/IPIP）
- AWS Load Balancer Controller 使用 hostNetwork + 端口 9443
- EKS API Server 无法直接访问 Pod CIDR（Calico overlay 网络）

### 已知限制

在此环境下，需要注意：
1. Rancher 和 rancher-webhook 都需要 hostNetwork
2. ALBC 占用 9443 端口，rancher-webhook 必须改用 9444
3. Webhook 的 patch 命令必须一次性执行，否则可能被 rancher 控制器重置

### rancher-values.yaml

将以下内容保存为 `rancher-values.yaml`，并根据注释修改配置：

```yaml
# =============================================================================
# Rancher Helm Values for EKS + Calico Overlay Environment
# =============================================================================

# -----------------------------------------------------------------------------
# 基础配置 - 请修改以下内容
# -----------------------------------------------------------------------------
hostname: rancher.your-domain.com      # 修改为你的域名
replicas: 1
bootstrapPassword: "your-password"     # 修改为你的密码, 至少 12 字符

# -----------------------------------------------------------------------------
# Rancher Service 配置 - 使用 NodePort 让 ALB 可以访问
# -----------------------------------------------------------------------------
service:
  type: NodePort

# -----------------------------------------------------------------------------
# Ingress 配置 - AWS ALB
# -----------------------------------------------------------------------------
ingress:
  enabled: true
  ingressClassName: "alb"
  path: "/*"  # 重要：ALB 需要 /* 匹配所有路径
  extraAnnotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/xxx  # 修改为你的 ACM 证书 ARN
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/success-codes: '200,302'
    alb.ingress.kubernetes.io/group.name: rancher-group

# -----------------------------------------------------------------------------
# 全局配置
# -----------------------------------------------------------------------------
global:
  cattle:
    psp:
      enabled: false  # EKS 1.25+ 不支持 PSP

# -----------------------------------------------------------------------------
# 其他配置
# -----------------------------------------------------------------------------
antiAffinity: preferred
topologyKey: kubernetes.io/hostname
```

### 安装步骤

- 步骤 1：添加 Helm Repo

```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

- 步骤 2：部署 Rancher

```bash
helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  -f rancher-values.yaml \
  --timeout=10m
```

- 步骤 3：为 Rancher 启用 hostNetwork

```bash
kubectl patch deploy rancher -n cattle-system --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/hostNetwork","value":true},
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}
]'
```

- 步骤 4：为 Rancher Webhook 启用 hostNetwork
    - 等待 rancher-webhook deployment 部署成功 （但 operation pod会失败"Address is not allowed"）
    - 重要：以下命令必须一次性执行

```log
helm upgrade --history-max=5 --install=true --labels=catalog.cattle.io/cluster-repo-name=rancher-charts --namespace=cattle-turtles-system --reset-values=true --timeout=5m0s --values=/home/shell/helm/values-rancher-turtles-108.0.1-up0.25.1.yaml --version=108.0.1+up0.25.1 --wait=true rancher-turtles /home/shell/helm/rancher-turtles-108.0.1-up0.25.1.tgz        
Error: UPGRADE FAILED: failed to create resource: Internal error occurred: failed calling webhook "rancher.cattle.io.namespaces.create-non-kubesystem" : failed to call webhook: Post "https://rancher-webhook.cattle-system.svc:443/v1/webhook/validation/namespaces?timeout=10s": Address is not allowed
```

```bash
kubectl set env deploy/rancher-webhook -n cattle-system CATTLE_PORT=9444 && \
kubectl patch deploy rancher-webhook -n cattle-system --type='json' -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":9444},
  {"op":"add","path":"/spec/template/spec/hostNetwork","value":true},
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}
]' && \
kubectl patch svc rancher-webhook -n cattle-system --type='merge' -p '{"spec":{"ports":[{"name":"https","port":443,"protocol":"TCP","targetPort":9444}]}}'
```

- 步骤 5：等待部署完成

```bash
kubectl rollout status deploy/rancher -n cattle-system --timeout=300s
kubectl rollout status deploy/rancher-webhook -n cattle-system --timeout=300s
```

- 步骤 6：验证配置

```bash
# 检查 APIService（确保 AVAILABLE 为 True）
kubectl get apiservice v1.ext.cattle.io

# 检查 webhook service targetPort 是否为 9444
kubectl get svc rancher-webhook -n cattle-system -o yaml | grep targetPort
```

- 如果上述验证失败，需要删除所有 相关 helm chart ，还有 cattle-system， 重新 helm install

- 步骤 7：访问 Rancher

访问 `https://rancher.your-domain.com`，使用 bootstrapPassword 登录。


### 常见问题处理

- 问题 1：登录失败 / 密码错误

```bash
# 删除 webhook 配置（会自动恢复）
kubectl delete validatingwebhookconfiguration rancher.cattle.io
kubectl delete mutatingwebhookconfiguration rancher.cattle.io

# 重置密码
kubectl -n cattle-system exec deploy/rancher -- reset-password

# 使用新密码登录（用户名：admin）
```

- 问题 2：API Aggregation not ready

```bash
# 检查状态
kubectl get apiservice v1.ext.cattle.io -o yaml

# 如果显示 FailedDiscoveryCheck，重新 patch rancher
kubectl patch deploy rancher -n cattle-system --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/hostNetwork","value":true},
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}
]'
```

- 问题 3：Dashboard 404

```bash
# 检查 ingress path
kubectl get ingress rancher -n cattle-system -o yaml | grep "path:"

# 如果是 /，修改为 /*
kubectl patch ingress rancher -n cattle-system --type='json' -p='[
  {"op":"replace","path":"/spec/rules/0/http/paths/0/path","value":"/*"}
]'
```

- 问题 4：Webhook 证书错误

如果看到 `certificate is valid for aws-load-balancer-webhook-service...`：

```bash
# 临时删除 webhook 配置，执行需要的操作后会自动恢复
kubectl delete validatingwebhookconfiguration rancher.cattle.io
kubectl delete mutatingwebhookconfiguration rancher.cattle.io
```

- 问题 5：DNS 记录未更新

```bash
# 确保 external-dns policy 为 sync
kubectl patch deploy external-dns -n externaldns --type='json' -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/args/5","value":"--policy=sync"}
]'
```

---

### 组件端口分配

| 组件 | 端口 | hostNetwork | 说明 |
|------|------|-------------|------|
| rancher | 80, 443, 6666 | ✓ | 必须，API aggregation 需要 |
| rancher-webhook | 9444 | ✓ | 必须，改端口避免与 ALBC 冲突 |
| aws-load-balancer-controller | 9443 | ✓ | 已占用 |

---

### 快速命令参考

```bash
# 1. 部署
helm upgrade --install rancher rancher-stable/rancher \
  -n cattle-system --create-namespace \
  -f rancher-values.yaml --timeout=10m

# 2. Patch rancher hostNetwork
kubectl patch deploy rancher -n cattle-system --type='json' -p='[{"op":"add","path":"/spec/template/spec/hostNetwork","value":true},{"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}]'

# 3. Patch webhook hostNetwork + 端口 9444（一次性执行）
kubectl set env deploy/rancher-webhook -n cattle-system CATTLE_PORT=9444 && \
kubectl patch deploy rancher-webhook -n cattle-system --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":9444},{"op":"add","path":"/spec/template/spec/hostNetwork","value":true},{"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}]' && \
kubectl patch svc rancher-webhook -n cattle-system --type='merge' -p '{"spec":{"ports":[{"name":"https","port":443,"protocol":"TCP","targetPort":9444}]}}'

# 4. 检查状态
kubectl get pods -n cattle-system
kubectl get apiservice v1.ext.cattle.io
kubectl get svc rancher-webhook -n cattle-system -o yaml | grep targetPort

# 5. 重置密码（如需要）
kubectl delete validatingwebhookconfiguration rancher.cattle.io 2>/dev/null
kubectl delete mutatingwebhookconfiguration rancher.cattle.io 2>/dev/null
kubectl -n cattle-system exec deploy/rancher -- reset-password
```


