---
title: eks-cluster-addons-list
description: EKS 常用插件清单
created: 2022-07-20 09:00:03.399
last_modified: 2023-11-10
tags:
  - aws/container/eks
  - kubernetes
---
> [!WARNING] This is a github note

# eks-cluster-addons-list

## list

- 托管集群插件
    - [[eks-addons-coredns]] 
    - [[eks-addons-vpc-cni]] 
    - [[eks-addons-kube-proxy]] 

- 第三方插件
    - [[aws-load-balancer-controller]] 
    - [[../../infra/network/externaldns-for-route53|externaldns]] 
    - [[cert-manager]] 
    - [[../../infra/storage/ebs-for-eks|ebs-csi-driver]] 
    - [[../monitor/install-prometheus-grafana|prometheus operator]] / grafana operator
    - [[splunk-otel-collector]] 
    - [[nginx-ingress-controller]] 
    - [[metrics-server]] 
    - [[cluster-autoscaler]] 

- 其他插件
    - [[../../infra/storage/efs-for-eks|efs-csi-driver]] 
    - cloudwatch-agent / [[aws-for-fluent-bit|fluentbit]] 
    - [[k8s-dashboard-on-eks|kubernetes-dashboard]] 
    - tigera-operator for [[calico]]  
    - [[cni-metrics-helper]] 
    - [[kube-state-metrics]] 

## upgrade addons sample

- https://aws.amazon.com/blogs/containers/amazon-eks-add-ons-preserve-customer-edits/
- https://aws.amazon.com/cn/blogs/containers/amazon-eks-add-ons-advanced-configuration/
```sh
CLUSTER_NAME=ekscluster1
ADDON_NAME=coredns

aws eks describe-addon \
--cluster-name ${CLUSTER_NAME} \
--addon-name ${ADDON_NAME} | grep status

aws eks update-addon \
--cluster-name ${CLUSTER_NAME} \
--addon-name ${ADDON_NAME} \
--addon-version v1.8.7-eksbuild.3 \
--resolve-conflicts PRESERVE

```


