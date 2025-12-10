---
title: Gateway API
description: K8S Gateway API 配置说明
created: 2025-12-10 08:50:30.146
last_modified: 2025-12-10
tags:
  - draft
  - kubernetes
status: myblog
---

# Gateway API 配置说明

## 概述

本项目展示了在 EKS 上暴露服务的三种方式：

1. **传统 Service (LoadBalancer)** - 创建 NLB
2. **Ingress** - 创建 ALB
3. **Gateway API** - 新一代 Kubernetes 流量管理 API

## Gateway API 架构

Gateway API 是 Kubernetes 的下一代流量管理 API,提供了更灵活和表达力更强的方式来配置负载均衡器。

### 核心概念

```
GatewayClass (基础设施模板)
    ↓
Gateway (负载均衡器实例)
    ↓
Route (路由规则: HTTPRoute, TCPRoute, UDPRoute, TLSRoute)
    ↓
Service (后端服务)
```

## L4 Gateway (NLB) 配置

文件: gateway-api-l4-nlb-deploy.yaml

### 1. GatewayClass
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: aws-nlb-gateway-class
spec:
  controllerName: gateway.k8s.aws/nlb # aws nlb controller
```

### 2. LoadBalancerConfiguration
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: LoadBalancerConfiguration
metadata:
  name: nginx-nlb-config
  namespace: verify
spec:
  scheme: internet-facing # public
  targetType: instance  # 显式指定
```

### 3. Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: nginx-nlb-gateway
  namespace: verify
  annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx-l4.<DOMAIN_NAME>
spec:
  gatewayClassName: aws-nlb-gateway-class
  infrastructure:
    parametersRef:
      kind: LoadBalancerConfiguration
      name: nginx-nlb-config
      group: gateway.k8s.aws
  listeners:
  - name: tcp-http
    protocol: TCP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
```

### 4. TCPRoute
```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: nginx-tcp-route
  namespace: verify
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-nlb-gateway
    sectionName: tcp-http
  rules:
  - backendRefs:
    - name: nginx
      port: 80
```

### L4 限制
- 每个 L4 Gateway Listener 只能有一个 Route
- 每个 L4 Route 只能有一个 backend reference
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.16/guide/gateway/l4gateway/

## L7 Gateway (ALB) 配置

文件: gateway-api-l7-alb-deploy.yaml

### 1. GatewayClass
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: aws-alb-gateway-class
spec:
  controllerName: gateway.k8s.aws/alb
```

### 2. LoadBalancerConfiguration
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: LoadBalancerConfiguration
metadata:
  name: nginx-alb-config
  namespace: verify
spec:
  scheme: internet-facing
  targetType: instance  # 显式指定
  listenerConfigurations:
    - protocolPort: HTTPS:443
      defaultCertificate: <CERTIFICATE_ARN>
```

### 3. Gateway
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: nginx-alb-gateway
  namespace: verify
  annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx-gateway.<DOMAIN_NAME>
spec:
  gatewayClassName: aws-alb-gateway-class
  infrastructure:
    parametersRef:
      kind: LoadBalancerConfiguration
      name: nginx-alb-config
      group: gateway.k8s.aws
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
  - name: https
    protocol: HTTPS
    port: 443
    allowedRoutes:
      namespaces:
        from: Same
```

### 4. HTTPRoute
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: nginx-http-route
  namespace: verify
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-alb-gateway
    sectionName: http
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-alb-gateway
    sectionName: https
  hostnames:
  - "nginx-gateway.<DOMAIN_NAME>"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx
      port: 80
```

## 验证部署

### 查看 Gateway 状态
```bash
kubectl get gateway -n verify -o wide
kubectl describe gateway nginx-nlb-gateway -n verify
kubectl describe gateway nginx-alb-gateway -n verify
```

### 查看 Route 状态
```bash
kubectl get tcproute,httproute -n verify
```

### 获取负载均衡器地址
```bash
kubectl get gateway -n verify -o jsonpath='{.items[*].status.addresses[0].value}'
```

## 访问方式对比

| 方式 | 负载均衡器类型 | 协议 | Target Type |
|------|---------------|------|-------------|
| Service | NLB | TCP/HTTP | instance |
| Ingress | ALB | HTTP/HTTPS | instance |
| Gateway API (L4) | NLB | TCP | instance |
| Gateway API (L7) | ALB | HTTP/HTTPS | instance |

## Gateway API 优势

1. **角色分离**: 
   - 平台管理员管理 GatewayClass 和 Gateway
   - 应用开发者管理 Route

2. **更强的表达能力**:
   - 支持更复杂的路由规则
   - 支持多协议 (HTTP, HTTPS, TCP, UDP, TLS)
   - 支持跨命名空间路由

3. **可扩展性**:
   - 通过 CRD 扩展功能 (如 LoadBalancerConfiguration)
   - 支持自定义过滤器和插件

4. **标准化**:
   - Kubernetes 官方标准
   - 跨云平台一致的 API

## 重要配置说明

### 对于 Calico Overlay 网络:

**必须使用 instance 模式**:
- Pod IP (172.16.x.x) 与 Node IP (192.168.x.x) 不在同一网段
- 负载均衡器无法直接路由到 Pod IP
- 必须通过 Node + NodePort 转发

**Ingress 配置**:
```yaml
annotations:
  alb.ingress.kubernetes.io/target-type: instance  # 必须
```

**Gateway API 配置**:
- 不指定 targetType,使用 Controller 默认值 `instance`
- 更简洁,不容易出错
- 可在 LoadBalancerConfiguration 中显示指定 `targetType: instance`

### Scheme 配置

**公网访问 (internet-facing)**:
- Ingress: `alb.ingress.kubernetes.io/scheme: internet-facing`
- Gateway API: 在 LoadBalancerConfiguration 中指定 `scheme: internet-facing`

**内网访问 (internal)**:
- 默认值,或明确指定 `scheme: internal`

### API Group -- `group: gateway.k8s.aws` 的说明

API Group 是 Kubernetes 中用于组织和版本化 API 资源的机制。在 Gateway API 配置中经常看到 `group` 字段:

```yaml
infrastructure:
  parametersRef:
    kind: LoadBalancerConfiguration
    name: nginx-alb-config
    group: gateway.k8s.aws  # API Group 标识符
```

#### 常见的 API Group

**1. 标准 Gateway API**
```yaml
# 标准 Gateway API 资源
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway, HTTPRoute, TCPRoute

# 引用时使用
parentRefs:
- group: gateway.networking.k8s.io
  kind: Gateway
  name: my-gateway
```

**2. AWS 扩展 API**
```yaml
# AWS Load Balancer Controller 扩展资源
apiVersion: gateway.k8s.aws/v1beta1
kind: LoadBalancerConfiguration, TargetGroupConfiguration

# 引用时使用
parametersRef:
  group: gateway.k8s.aws  # 固定值,不会变化
  kind: LoadBalancerConfiguration
  name: my-config
```

**3. Kubernetes 核心 API**
```yaml
# Kubernetes 核心资源 (Service, Pod, ConfigMap 等)
apiVersion: v1
kind: Service

# 引用时使用
backendRefs:
- group: ""  # 空字符串表示核心 API 组
  kind: Service
  name: nginx
```

#### 云平台差异

| 云平台 | API Group | 示例资源 |
|--------|-----------|----------|
| **AWS** | `gateway.k8s.aws` | LoadBalancerConfiguration |
| **Azure** | `gateway.azure.com` | ApplicationGatewayConfiguration |
| **GCP** | `gateway.gcp.io` | LoadBalancerPolicy |
| **标准** | `gateway.networking.k8s.io` | Gateway, HTTPRoute |

#### 关键要点

1. **必需字段**: `group` 是必需的,不能省略
2. **固定值**: 对于 AWS,`group: gateway.k8s.aws` 是固定不变的
3. **资源定位**: 告诉 Kubernetes 在哪个 API 组中查找资源
4. **避免冲突**: 不同厂商的扩展资源通过 API Group 隔离


## 启用 Gateway API 支持

### Helm 安装时启用
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set controllerConfig.featureGates.NLBGatewayAPI=true \
  --set controllerConfig.featureGates.ALBGatewayAPI=true
```

### 或在 values.yaml 中
```yaml
controllerConfig:
  featureGates:
    NLBGatewayAPI: true
    ALBGatewayAPI: true
```

## 参考文档

- [AWS Load Balancer Controller - L4 Gateway](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.16/guide/gateway/l4gateway/) 
- [AWS Load Balancer Controller - L7 Gateway](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.16/guide/gateway/l7gateway/) 
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) 





