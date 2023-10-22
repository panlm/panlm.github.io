---
title: cert-manager
description: cert-manager
chapter: true
weight: 131
created: 2023-07-31 15:36:34.121
last_modified: 2023-07-31 15:36:34.121
tags: 
- kubernetes 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# cert-manager

- [install](#install)
	- [helm](#helm)
- [newest version v1.12.3 (2023/07)](#newest-version-v1123-202307)


## install
- [link](https://cert-manager.io/docs/installation/) 
- install newest version 
```sh
kubectl create ns cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml \
-n cert-manager
# CM_VERSION=v1.12.3 (2023/07)
# https://github.com/cert-manager/cert-manager/releases/download/${CM_VERSION}/cert-manager.yaml

```

### helm
- install with helm
https://cert-manager.io/docs/installation/helm/

## newest version v1.12.3 (2023/07)

![cert-manager-png-1.png](../../../git-attachment/cert-manager-png-1.png)


