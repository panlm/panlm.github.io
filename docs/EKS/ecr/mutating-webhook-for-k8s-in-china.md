---
title: Mutating Webhook for Kubernetes in China
description: 中国区域 k8s 集群 webhook ，自动修改海外镜像到国内地址
created: 2022-06-23 08:15:42.574
last_modified: 2023-11-22
status: myblog
tags:
  - kubernetes
---

# Mutating Webhook for Kubernetes in China

## solution 1: api-gateway-mutating-webhook-for-k8
https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8

This demo project is intended to illustrate how to use [Amazon API Gateway](https://aws.amazon.com/api-gateway/) and [AWS Lambda](https://aws.amazon.com/lambda/) to set up an HTTP service, then been integrated with Kubernetes as [admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to receive admission requests and mutate or validate Kubernetes resources dynamically. Particularly this project will setup a mutating webhook to modify the docker image path in K8S Pod after the deployment been submitted to K8S API server and before it's been persisted in etcd.

![[attachments/mutating-webhook-for-k8s-in-china/IMG-mutating-webhook-for-k8s-in-china.png]]

### deploy in 3xxx account
following option#2

```sh
git clone https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8.git
cd amazon-api-gateway-mutating-webhook-for-k8

export S3_BUCKET=my_s3_bucket # need existed

sam package -t sam-template.yaml --s3-bucket ${S3_BUCKET} --output-template-file packaged.yaml 

sam deploy --template-file packaged.yaml --stack-name stack-name-$RANDOM --capabilities CAPABILITY_IAM 

```

### put mutation webhoos in your cluster
```yaml
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: image-mutating
webhooks:
  - name: image.mutating.webhook
    admissionReviewVersions: ["v1", "v1beta1"]
    sideEffects: None
    failurePolicy: Ignore
    clientConfig:
      url: https://xxx.execute-api.us-east-1.amazonaws.com
    rules:
      - operations: [ "CREATE", "UPDATE" ]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]

```

## solution 2: nwcdlabs/container-mirror
- https://github.com/nwcdlabs/container-mirror

## solution 3: DTH to private ECR
- https://aws.amazon.com/solutions/implementations/data-transfer-hub/

## pod to verify
```sh
cat > pod.yaml <<-EoF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "nginx-gcr"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-gcr
  template:
    metadata:
      labels:
        app: "nginx-gcr"
    spec:
      containers:
      - image: k8s.gcr.io/nginx
        imagePullPolicy: Always
        name: "nginx"
        ports:
        - containerPort: 80
EoF
k apply -f pod.yaml

kubectl get pod nginx-gcr-deployment-784bf76d96-hjmv4 -o=jsonpath='{.spec.containers[0].image}'

```

## refer
- https://github.com/aws/amazon-eks-pod-identity-webhook/blob/master/hack/webhook-patch-ca-bundle.sh
- https://aws.amazon.com/cn/blogs/china/global-to-china-multinational-enterprise-kubernetes-application-cross-border-replication-and-deployment-solution/

## install sam
- https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html



