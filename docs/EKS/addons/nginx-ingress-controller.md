---
title: nginx-ingress-controller
description: nginx-ingress-controller
created: 2023-02-11 13:55:31.445
last_modified: 2023-12-31
tags:
  - kubernetes/ingress
---

# nginx-ingress-controller

## understand version

-   **Community version** – Found in the [**kubernetes/ingress-nginx**](https://github.com/kubernetes/ingress-nginx) repo on GitHub, the community Ingress controller is based on NGINX Open Source with docs on [**Kubernetes.io**](https://kubernetes.github.io/ingress-nginx/). It is maintained by the Kubernetes community with a [commitment from F5 NGINX](https://www.nginx.com/blog/nginx-sprint-2-0-clear-vision-fresh-code-new-commitments-to-open-source/#resources-for-kubernetes) to help manage the project
    - RETIREMENT due to March 2026 ([doc](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/))
    - [[nginx-ingress-controller-community-ver]] 
    - alternative: NGINX Gateway Fabric ([[nginx-gateway-fabric]])

-   **NGINX version** – Found in the [**nginxinc/kubernetes-ingress**](https://github.com/nginxinc/kubernetes-ingress) repo on GitHub, NGINX Ingress Controller is developed and maintained by F5 NGINX with docs on [**docs.nginx.com**](https://docs.nginx.com/nginx-ingress-controller/). It is available in two editions:
    -   NGINX Open Source‑based (free and open source option)
    -   [NGINX Plus-based](https://www.nginx.com/products/nginx-ingress-controller/) (commercial option)
    - [[nginx-ingress-controller-nginx-ver]]

## refer

- [[Exposing Kubernetes Applications Part 3 NGINX Ingress Controller]] 

## compatibility

- https://github.com/kubernetes/ingress-nginx#supported-versions-table


