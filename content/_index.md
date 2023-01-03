---
title: "README"
chapter: true
created: 2022-09-16 13:39:08.529
last_modified: 2022-10-10 13:39:08.529
---

# HOME

## eks infra
### cluster
* [Prepare Cloud9 environment before eks lab](110-eks-cluster/setup-cloud9-for-eks)
* [Create eks cluster with public access](110-eks-cluster/eks-public-access-cluster)
* [Create eks cluster with private access](110-eks-cluster/eks-private-access-cluster)
* [Prepare vpc if you needed to](110-eks-cluster/create-standard-vpc-for-lab)

### compute
- [Fargate Lab](120-eks-compute/eks-fargate-lab)

### network
* [aws load balancer controller](130-eks-network/aws-load-balancer-controller)
* [security group on pod](130-eks-network/enable-sg-on-pod)
* [externaldns for route53](130-eks-network/externaldns-for-route53)

### storage
* [efs](150-eks-storage/efs-for-eks)
* [ebs](150-eks-storage/ebs-for-eks)

## eks operation
### devops
* [argocd](260-eks-gitops/argocd-lab)
* [flux](260-eks-gitops/flux-lab)

### monitor
* [metric server](270-eks-monitor/install-metric-server)
* [enable container insight](270-eks-monitor/eks-container-insights)
* [prometheus in cloudwatch](270-eks-monitor/enable-prometheus-in-cloudwatch)

### data analytics
* [Process CloudWatch logs sent to S3 through Kinesis Firehose](220-eks-logging/stream-k8s-control-panel-logs-to-s3)
* [export-cloudwatch-log-group-to-s3](220-eks-logging/export-cloudwatch-log-group-to-s3)

## others
* [Redshift Data API Lab](900-others/redshift-data-api-lab)
* [File Gateway Lab](900-others/file-storage-gateway-lab)

