---
title: EKS Addons
description: EKS 常用插件清单
created: 2022-07-20 09:00:03.399
last_modified: 2023-12-31
tags:
  - aws/container/eks
  - kubernetes
---

# EKS Addons
## list
- 托管集群插件
    - [[../addons/eks-addons-coredns]] 
    - [[../addons/eks-addons-vpc-cni]] 
    - [[../addons/eks-addons-kube-proxy]] 

- 第三方插件
    - [[../addons/aws-load-balancer-controller]] 
    - [[../addons/externaldns-for-route53|externaldns]] 
    - [[../addons/cert-manager]] 
    - [[../addons/ebs-csi|ebs-csi-driver]] 
    - [[../solutions/monitor/install-prometheus-operator|prometheus operator]] / grafana operator
    - [[splunk-otel-collector]] 
    - [[../addons/nginx-ingress-controller]] 
    - [[../addons/metrics-server]] 
    - [[../addons/cluster-autoscaler]] 

- 其他插件
    - [[../addons/efs-csi|efs-csi-driver]] 
    - cloudwatch-agent / [[../addons/aws-for-fluent-bit|fluentbit]] 
    - [[k8s-dashboard-on-eks|kubernetes-dashboard]] 
    - tigera-operator for [[calico]]  
    - [[../addons/cni-metrics-helper]] 
    - [[../addons/kube-state-metrics]] 

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





