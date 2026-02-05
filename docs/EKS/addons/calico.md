---
title: calico
created: 2021-07-01T04:49:23.679Z
last_modified: 2024-01-21
tags:
  - kubernetes/calico
---

# calico

## install

- refer [link](https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm#install-calico) 
```sh
helm repo add projectcalico https://docs.tigera.io/calico/charts
kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.26.1 --namespace tigera-operator
```

- [Install Calico](https://docs.aws.amazon.com/eks/latest/userguide/calico.html#calico-install)
```sh
cat  > append.yaml << EOF
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - patch
EOF
kubectl apply -f <(cat <(kubectl get clusterrole aws-node -o yaml) append.yaml)
kubectl set env daemonset aws-node -n kube-system ANNOTATE_POD_IP=true

kubectl delete pod calico-kube-controllers-* -n calico-system
kubectl describe pod calico-kube-controllers-* -n calico-system | grep vpc.amazonaws.com/pod-ips

```

### check version

```sh
helm list -n tigera-operator
```

## limit

- ~~calico ebpf mode could not support non-x86 host (2022/05) ([LINK](https://projectcalico.docs.tigera.io/maintenance/ebpf/enabling-ebpf#before-you-begin))~~
- support ARM64 (community supported, not actively regression tested by the Calico team) (2023/07) - [link](https://docs.tigera.io/calico/latest/operations/ebpf/enabling-ebpf#supported) 

## tigera operator

- [github](https://github.com/tigera/operator) 

## others

- [[calico-network-policy-lab]]


## refer

- [[calico-cni-overlay]]


