---
title: "README"
chapter: true
created: 2022-09-16 13:39:08.529
last_modified: 2022-10-10 13:39:08.529
---

# README

```ad-note
title: compatible github md format
```

## eks

* [Prepare Cloud9 environment before eks lab](110-eks-cluster/setup-cloud9-for-eks.md)
* [Create eks cluster with public access](110-eks-cluster/eks-public-access-cluster.md)
* [Create eks cluster with private access](110-eks-cluster/eks-private-access-cluster.md)
* [Prepare vpc if you needed to](110-eks-cluster/create-standard-vpc-for-lab.md)

### network
* [aws load balancer controller](130-eks-network/aws-load-balancer-controller.md)
* [security group on pod](130-eks-network/enable-sg-on-pod.md)
* [externaldns for route53](130-eks-network/externaldns-for-route53.md)

### devops
* [argocd](260-eks-gitops/argocd-lab.md)
* [flux](260-eks-gitops/flux-lab.md)

### csi
* [efs](efs-for-eks.md)
* [ebs](ebs-for-eks.md)

### monitor
* [enable container insight](2-eks-container-insights.md)
* [prometheus in cloudwatch](3-enable-prometheus-in-cloudwatch.md)
* [metric server](1-install-metric-server.md)

### fargate
- [Fargate Lab](eks-fargate-lab.md)

## data analytics
* [Process CloudWatch logs sent to S3 through Kinesis Firehose](stream-k8s-control-panel-logs-to-s3.md)
* [export-cloudwatch-log-group-to-s3](export-cloudwatch-log-group-to-s3.md)

## redshift
* [Redshift Data API Lab](1-redshift-data-api-lab.md)

## storage gateway
* [File Gateway Lab](2-file-storage-gateway-lab.md)





