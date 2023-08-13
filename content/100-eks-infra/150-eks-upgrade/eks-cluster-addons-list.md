---
title: "eks-cluster-addons-list"
description: "EKS 常用插件清单"
chapter: true
weight: 20
created: 2022-07-20 09:00:03.399
last_modified: 2022-07-20 09:00:03.399
tags: 
- aws/container/eks 
- kubernetes 
---

```ad-attention
title: This is a github note

```

# eks-cluster-addons-list

- [list](#list)
- [upgrade addons sample](#upgrade-addons-sample)

## list

- 托管集群插件
	- eks-addons-coredns ([link](eks-addons-coredns.md) or [hugo](eks-addons-coredns))
	- eks-addons-vpc-cni ([link](eks-addons-vpc-cni.md) or [hugo](eks-addons-vpc-cni))
	- eks-addons-kube-proxy ([link](eks-addons-kube-proxy.md) or [hugo](eks-addons-kube-proxy))
- 第三方插件
	- aws-load-balancer-controller ([link](aws-load-balancer-controller.md) or [hugo]({{< ref "aws-load-balancer-controller" >}}))
	 - tigera-operator for [[calico]]  
	- [[cert-manager]] 
	- [[splunk-otel-collector]] 
	- [[cluster-autoscaler]] 
	- [[metrics-server]] 
- 其他插件
	- [[externaldns-for-route53|externaldns]] 
	- cloudwatch-agent / [[aws-for-fluent-bit|fluentbit]] 
	- [[efs-for-eks|efs-csi-driver]] 
	- [[ebs-for-eks|ebs-csi-driver]] 
	- [[k8s-dashboard-on-eks|kubernetes-dashboard]] 
	- [[install-prometheus-grafana|prometheus operator]] / grafana operator
	- [[cni-metrics-helper]] 
	- [[nginx-ingress-controller]] 
	- [[kube-state-metrics]] 

## upgrade addons sample
- [blog1](https://aws.amazon.com/blogs/containers/amazon-eks-add-ons-preserve-customer-edits/)
- [blog2](https://aws.amazon.com/cn/blogs/containers/amazon-eks-add-ons-advanced-configuration/)
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


