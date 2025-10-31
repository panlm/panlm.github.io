---
title: EKS Auto Mode
description: EKS Auto Mode 
created: 2025-01-06 11:32:14.727
last_modified: 2025-01-06
tags:
  - draft
  - aws/container/eks
---

# eks-auto-mode-sample

- https://aws.amazon.com/blogs/aws/streamline-kubernetes-cluster-management-with-new-amazon-eks-auto-mode/
- https://aws.amazon.com/blogs/containers/getting-started-with-amazon-eks-auto-mode/

![[attachments/eks-auto-mode-sample/IMG-eks-auto-mode-sample.png]]

## components 
- https://docs.aws.amazon.com/eks/latest/userguide/automode.html#_automated_components
- Karpenter 
- AWS Load Balancer Controller
- AWS EBS CSI
- AWS VPC CNI
- Identity and Access Management

## limitation

- https://docs.aws.amazon.com/eks/latest/userguide/auto-networking.html
- Security Groups per Pod (SGPP).
- Custom Networking. The IP Addresses of Pods and Nodes must be from the same CIDR Block.
- Warm IP, warm prefix, and warm ENI configurations.
- Minimum IP targets configuration.
- Enabling or disabling prefix delegation.
- Other configurations supported by the open-source AWS CNI.
- Network Policy configurations such as conntrack timer customization (default is 300s).
- Exporting network event logs to CloudWatch.

## pricing

- 额外收取 auto mode 管理的 EC2 节点的 Ondemond 价格 12% ([link](https://aws.amazon.com/eks/pricing/))

## workshop

- https://catalog.us-east-1.prod.workshops.aws/workshops/aadbd25d-43fa-4ac3-ae88-32d729af8ed4/

## sample

### eksctl sample

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster5
  region: us-west-2
  version: "1.33"

autoModeConfig:
  enabled: true

vpc:
  id: vpc-default
  subnets:
    public:
      us-west-2a:
        id: subnet-1
      us-west-2b:
        id: subnet-2
      us-west-2c:
        id: subnet-3
    private:
      us-west-2a:
        id: subnet-1
      us-west-2b:
        id: subnet-2
      us-west-2c:
        id: subnet-3

```

### test load balancer controller
- test pod with service and ingress
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echoserver
spec:
  selector:
    matchLabels:
      app: echoserver
  replicas: 1
  template:
    metadata:
      labels:
        app: echoserver
    spec:
      containers:
      - image: k8s.gcr.io/e2e-test-images/echoserver:2.5
        imagePullPolicy: Always
        name: echoserver
        ports:
        - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  name: echoserver
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  loadBalancerClass: eks.amazonaws.com/nlb
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  type: LoadBalancer
  selector:
    app: echoserver

---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  labels:
    app.kubernetes.io/name: LoadBalancerController
  name: eks-alb
spec:
  controller: eks.amazonaws.com/alb
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echoserver
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: eks-alb
  rules:
  - host: '*.us-west-2.elb.amazonaws.com'
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echoserver
            port:
              number: 80


```

### test ebs csi
- storage class ([doc](https://docs.aws.amazon.com/eks/latest/userguide/create-storage-class.html))
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: auto-ebs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.eks.amazonaws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
```

- test pod
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 9Gi
  # 不指定 storageClassName,将使用默认的 StorageClass
  
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: nginx
    volumeMounts:
    - name: test-volume
      mountPath: /test-data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc

```


