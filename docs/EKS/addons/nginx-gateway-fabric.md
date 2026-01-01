---
title: Nginx Gateway Fabric
description: Nginx Ingress 的继任者
created: 2025-12-17 09:12:06.087
last_modified: 2025-12-17
tags:
  - draft
  - nginx
---

# Nginx Gateway Fabric

- 不支持OpenResty

## Install with HELM

- [official doc](https://docs.nginx.com/nginx-gateway-fabric/install/helm/) 
- install gateway api 
```sh
VERSION=v2.2.2 # v2.3.0
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=${VERSION}" | kubectl apply -f -

```
- check gateway api version ([[git/git-mkdocs/EKS/kubernetes/k8s-gateway-api#检查集群是否启用-gateway-api-|check-gateway-api]])

- create irsa
```sh
CLUSTER_NAME=my-calico-cluster
export AWS_DEFAULT_REGION=us-west-2
NGF_NS=nginx-gateway
NGF_SA=ngf-nginx-gateway-fabric

eksctl utils associate-iam-oidc-provider \
    --cluster=${CLUSTER_NAME} \
    --approve

eksctl create iamserviceaccount \
    --cluster=${CLUSTER_NAME} \
    --namespace=${NGF_NS} \
    --name=${NGF_SA} \
    --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
    --approve \
    --role-only

eksctl get iamserviceaccount --cluster=${CLUSTER_NAME}
# put role arn to nginx-gateway-values-default.yaml

```

- create `nginx-gateway-values-default.yaml`
```sh

cat >nginx-gateway-values-default.yaml <<-EOF
# EKS + IRSA + Calico overlay 环境配置
nginxGateway:
  replicas: 2
  serviceAccount:
    # create: false # 没这个参数
    # name: "ngf-nginx-gateway-fabric" # 指定这个参数后，annotate 不生效
    annotations:
      eks.amazonaws.com/role-arn: "role ARN HERE"

  # # 资源限制
  # resources:
  #   requests:
  #     cpu: 100m
  #     memory: 128Mi
  #   limits:
  #     cpu: 500m
  #     memory: 512Mi

  metrics:
    enable: true
    port: 9113

nginx:
  replicas: 2
  
  service:
    type: LoadBalancer
    externalTrafficPolicy: Local  # 保留源IP
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  
  # # 容器资源配置
  # container:
  #   resources:
  #     requests:
  #       cpu: 100m
  #       memory: 128Mi
  #     limits:
  #       cpu: 1000m
  #       memory: 1Gi
  
  # Pod配置 - 适合overlay网络
  pod:
    # 确保Pod分布在不同节点
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: nginx-gateway-fabric
            topologyKey: kubernetes.io/hostname
    
    # 容忍节点污点
    tolerations: []
    
    terminationGracePeriodSeconds: 30

  autoscaling:
    enable: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

EOF

```

- install from OCI
```sh
echo ${NGF_NS}

# helm show values oci://ghcr.io/nginx/charts/nginx-gateway-fabric
helm upgrade -i ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
    -n ${NGF_NS} --create-namespace \
	-f nginx-gateway-values-default.yaml

```


## verify 

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: production-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  infrastructure:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:us-west-2:0123456789012:certificate/xxxxx"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
      # 添加多个域名到External DNS
      external-dns.alpha.kubernetes.io/hostname: "gateway.domainname,httpbin.domainname"
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    # 移除hostname限制，支持所有域名
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTP
    # 移除hostname限制，支持所有域名
    allowedRoutes:
      namespaces:
        from: All

---
# HTTP to HTTPS redirect for gateway.poc1217.aws.panlm.click
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: gateway-https-redirect
  namespace: nginx-gateway
spec:
  parentRefs:
  - name: production-gateway
    sectionName: http
  hostnames:
  - "gateway.domainname"
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301

---
# HTTP to HTTPS redirect for httpbin.poc1217.aws.panlm.click
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-https-redirect
  namespace: nginx-gateway
spec:
  parentRefs:
  - name: production-gateway
    sectionName: http
  hostnames:
  - "httpbin.domainname"
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301

```

```yaml
---
# httpbin Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
      - name: httpbin
        image: kennethreitz/httpbin
        ports:
        - containerPort: 80

---
# httpbin Service
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
spec:
  selector:
    app: httpbin
  ports:
  - port: 80
    targetPort: 80

---
# HTTPRoute for /abc path with URL rewrite - HTTPS listener
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-route-https
  namespace: default
spec:
  parentRefs:
  - name: production-gateway
    namespace: nginx-gateway
    sectionName: https
  hostnames:
  - "gateway.domainname"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: "/httpbin"
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: "/"
    backendRefs:
    - name: httpbin
      port: 80
---
# HTTPRoute for httpbin.poc1217.aws.panlm.click (direct access)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-direct
  namespace: default
spec:
  parentRefs:
  - name: production-gateway
    namespace: nginx-gateway
    sectionName: https
  hostnames:
  - "httpbin.domainname"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: "/"
    backendRefs:
    - name: httpbin
      port: 80

```


## refer

Gateway API TCPRoute does not support
https://docs.nginx.com/nginx-gateway-fabric/overview/gateway-api-compatibility/





