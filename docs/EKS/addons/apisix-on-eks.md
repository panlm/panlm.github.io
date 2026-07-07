---
title: apisix-on-eks
description: null
created: 2026-01-04 11:45:36.196000
last_modified: 2026-01-04
tags:
- draft
- aws/container/eks
permalink: git-mkdocs/eks/addons/apisix-on-eks
---

# apisix-on-eks

## install

- need [[ebs-csi|ebs-csi]]
- https://apisix.apache.org/docs/apisix/installation-guide/
```sh
helm repo add apisix https://charts.apiseven.com
helm repo update

# 数据平面
helm install apisix apisix/apisix --create-namespace  --namespace apisix
# 控制平面
helm install apisix-ingress-controller apisix/apisix-ingress-controller -n apisix-prod

helm install apisix-dashboard apisix/apisix-dashboard -n apisix-prod \
    --set config.conf.etcd.endpoints[0]=http://apisix-etcd:2379

```

## deploy and expose httpbin

- deploy httpbin in ns:httpbin
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: httpbin
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
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: httpbin
spec:
  selector:
    app: httpbin
  ports:
  - port: 80
    targetPort: 80
```

- expose it use httpbin
```yaml
---
apiVersion: apisix.apache.org/v2
kind: ApisixRoute
metadata:
  name: httpbin-route
  namespace: apisix-prod
spec:
  http:
  - name: httpbin
    match:
      hosts:
      - httpbin.example.com
      paths:
      - "/*"
    backends:
    - serviceName: httpbin
      servicePort: 80
      namespace: httpbin

```

- access
```sh
curl -H "Host: httpbin.example.com" http://lb-of-apisix-gateway-svc.domainname/ip
```

## on-calico-overlay-network

- 实测：chart 2.15.0 / app 3.17.0，helm 装 `apisix/apisix` 时加 `--skip-crds`
- 原因：chart 自带的 `apisix-ingress-controller/crds/gwapi-crds.yaml` 里的 Gateway API CRD 版本比集群已装的（NGF 装的 v1.5.x）旧，k8s 1.36 新增的 `safe-upgrades.gateway.networking.k8s.io` ValidatingAdmissionPolicy 会拒绝降级安装，报 `Installing CRDs with version before v1.5.0 is prohibited`
- `service.type=ClusterIP` 会报 `spec.externalTrafficPolicy: Invalid value: "Cluster"`，因为 chart 默认给 gateway service 配了 externalTrafficPolicy（只对 NodePort/LoadBalancer 合法），改用默认 NodePort
- ingress-controller 的 validating webhook 默认 `enabled=false`（调研阶段以为默认开启，实测是关的），未触发 Calico overlay 的 webhook 坑；如果以后要开这个 webhook，需要手动给 ingress-controller deployment patch hostNetwork（chart 没有现成开关）



