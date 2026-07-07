---
title: nginx-ingress-controller-nginx-ver
description: nginx-ingress-controller-nginx-ver
created: 2022-08-28 09:40:48.305000
last_modified: 2022-08-28 09:40:48.305000
tags:
- aws/container/eks
- kubernetes/ingress
- nginx
permalink: git-mkdocs/eks/addons/nginx-ingress-controller-nginx-ver
---

# nginx-ingress-controller-nginx-version

## install
- https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/

```sh
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install my-release nginx-stable/nginx-ingress

kubectl annotate service/my-release-nginx-ingress \
  service.beta.kubernetes.io/aws-load-balancer-type=nlb
      nginx.ingress.kubernetes.io/rewrite-target: /:q


  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '60'
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: 'true'
    service.beta.kubernetes.io/aws-load-balancer-type: nlb

```
or
```sh
git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v2.3.0
cd kubernetes-ingress/deployments/helm-chart
helm install my-release .
```

## app expose
```sh


```