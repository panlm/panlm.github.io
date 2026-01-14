---
title: apisix-on-eks
description:
created: 2026-01-04 11:45:36.196
last_modified: 2026-01-04
tags:
  - draft
  - aws/container/eks
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


