---
title: appmesh-workshop-eks
description: appmesh workshop
created: 2023-01-06 12:22:19.360
last_modified: 2024-04-23
status: deprecated
tags:
  - aws/container/appmesh
  - aws/container/eks
---

```ad-attention
title: This is a github note
```

# appmesh-workshop-eks

https://www.eksworkshop.com/intermediate/330_app_mesh/deploy_dj_app/clone_repo/

## install appmesh-controller
- [doc](https://docs.aws.amazon.com/app-mesh/latest/userguide/getting-started-kubernetes.html)
- [workshop](https://www.eksworkshop.com/advanced/330_servicemesh_using_appmesh/appmesh_installation/install_appmesh/)

```sh
CLUSTER_NAME=ekscluster4
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# Create the namespace
kubectl create ns appmesh-system

# Install the App Mesh CRDs
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"

# Create your OIDC identity provider for the cluster
eksctl utils associate-iam-oidc-provider \
--region=${AWS_DEFAULT_REGION} \
--cluster ${CLUSTER_NAME} --approve

# Download the IAM policy for AWS App Mesh Kubernetes Controller
curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json

# Create an IAM policy called AWSAppMeshK8sControllerIAMPolicy
aws iam create-policy \
--policy-name AWSAppMeshK8sControllerIAMPolicy \
--policy-document file://controller-iam-policy.json

# Create an IAM role for the appmesh-controller service account
eksctl create iamserviceaccount --cluster ${CLUSTER_NAME} \
--namespace appmesh-system \
--name appmesh-controller \
--attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSAppMeshK8sControllerIAMPolicy,arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess  \
--override-existing-serviceaccounts --approve

# install using helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=${AWS_DEFAULT_REGION} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller

#    --set tracing.enabled=true \
#    --set tracing.provider=x-ray

# check version
kubectl get deployment appmesh-controller -n appmesh-system -o json |jq -r ".spec.template.spec.containers[].image" | cut -f2 -d ':'
# check crds
kubectl get crds | grep appmesh
# check pods
kubectl -n appmesh-system get all          

```


## ensure node role
- ensure node role has `AWSAppMeshEnvoyAccess` policy

~~[[../../../CLI/linux/eksctl#appmesh-access-]]~~

## flagger
[automated-canary-deployment-using-flagger](automated-canary-deployment-using-flagger.md)



# others
## appmesh on eks
[link](https://github.com/aws/aws-app-mesh-examples/blob/main/walkthroughs/eks/base.md)

```sh
git clone https://github.com/aws/aws-app-mesh-examples.git
cd aws-app-mesh-examples/walkthroughs/eks/
```

## github repo
```sh
git clone https://github.com/aws/aws-app-mesh-examples.git

```


## howto-k8s-http2
[link](https://github.com/aws/aws-app-mesh-examples/tree/main/walkthroughs/howto-k8s-http2)

```sh
CLUSTER_NAME=ekscluster1

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

export VPC_ID=$(aws eks describe-cluster \
  --name ${CLUSTER_NAME} \
  --query "cluster.resourcesVpcConfig.vpcId" --output text )

```

```sh
cd aws-app-mesh-examples/walkthroughs/howto-k8s-http2/
./deploy

```




## refer

[[automated-canary-deployment-using-flagger]]


