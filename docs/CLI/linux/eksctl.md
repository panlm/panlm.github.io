---
title: eksctl
description: 常用命令
created: 2022-03-09 21:30:00.815
last_modified: 2024-04-23
tags:
  - aws/container/eks
---

# eksctl-cmd
## install
```sh
# install eksctl
# consider install eksctl version 0.89.0
# if you have older version yaml 
# https://eksctl.io/announcements/nodegroup-override-announcement/
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
```

refer: [[../../cloud9/setup-cloud9-for-eks#install-in-cloud9-]] 

## oidc
```sh
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --region $AWS_REGION --approve
```

## iamidentitymapping-
- add role to `aws-auth` configmap ([[../../EKS/solutions/security/eks-aws-auth|eks-aws-auth]])
```sh
CLUSTER_NAME=ekscluster1
ARN=role-arn
AWS_REGION=us-west-2

eksctl get iamidentitymapping \
    --cluster ${CLUSTER_NAME} --region ${AWS_REGION}

eksctl create iamidentitymapping \
    --cluster ${CLUSTER_NAME} --region ${AWS_REGION} \
    --arn ${ARN} \
    --group system:masters --username admin 
```

## create windows self-managed node group
```sh
CLUSTER_NAME=myeksctl
export AWS_DEFAULT_REGION=us-west-2
eksctl create nodegroup   \
  --cluster $CLUSTER_NAME   \
  --name nodegroup-win-1   \
  --node-type m5.xlarge   \
  --nodes 1   \
  --nodes-min 1   \
  --nodes-max 2 \
  --node-ami-family WindowsServer2019FullContainer \
  --managed=false
```

```sh
CLUSTER_NAME=myeksctl
export AWS_DEFAULT_REGION=us-west-2
eksctl create nodegroup   \
  --cluster $CLUSTER_NAME   \
  --name nodegroup-br-1   \
  --node-type m5.xlarge   \
  --nodes 1   \
  --nodes-min 1   \
  --nodes-max 2 \
  --node-ami-family Bottlerocket
```


## create nodegroup
- create nodegroup on a cluster which not created by eksctl
    - https://eksctl.io/usage/unowned-clusters/#creating-nodegroups
```sh
CLUSTER_NAME=ekscluster2
export AWS_DEFAULT_REGION=us-west-2
eksctl create nodegroup   \
  --cluster ${CLUSTER_NAME}   \
  --name mng-a   \
  --node-type m5.large   \
  --nodes 3   \
  --node-private-networking \
  --subnet-ids subnet-aaa,subnet-bbb \
  --node-security-groups sg-xxx # this is the ControlPlaneSecurityGroup

```

## scale nodegroup
```sh
CLUSTER_NAME=ekscluster1
NODEGROUP_NAME=managed-ng
AWS_REGION=us-east-2

eksctl scale nodegroup \
    --cluster=${CLUSTER_NAME} \
    --region ${AWS_REGION} \
    --nodes=3 \
    ${NODEGROUP_NAME}

```

## func-create-iamserviceaccount-
```sh title="func-create-iamserviceaccount" linenums="1"
echo ${CLUSTER_NAME}
echo ${NAMESPACE_NAME}

function create-iamserviceaccount () {
    OPTIND=1
    OPTSTRING="h?s:c:n:r:"
    local SA_NAME=""
    local CLUSTER_NAME=""
    local NAMESPACE_NAME=""
    local ROLE_ONLY=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            s) SA_NAME=${OPTARG} ;;
            c) CLUSTER_NAME=${OPTARG} ;;
            n) NAMESPACE_NAME=${OPTARG} ;;
            r) ROLE_ONLY=${OPTARG} ;;
            h|\?) 
                echo "format: create-iamserviceaccount -s SERVICE_ACCOUNT_NAME -c CLUSTER_NAME -n NAMESPACE_NAME -r [0|1] "
                echo -e "\tsample: create-iamserviceaccount -s sa_name -c ekscluster1 -n monitoring -r 1 "
                return 0
            ;;
        esac
    done
    : ${SA_NAME:?Missing -s}
    : ${CLUSTER_NAME:?Missing -c}
    : ${NAMESPACE_NAME:?Missing -n}
    : ${ROLE_ONLY:?Missing -r}

    if [[ ROLE_ONLY -eq 1 ]]; then
        local ROLE_OPTION="--role-only"
    else
        local ROLE_OPTION=""
    fi

    echo ${SA_NAME:=sa-s3-admin-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)}
    eksctl create iamserviceaccount -c ${CLUSTER_NAME} \
        --name ${SA_NAME} --namespace ${NAMESPACE_NAME} \
        --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
        --role-name ${SA_NAME}-$(TZ=EAT-8 date +%Y%m%d-%H%M%S) ${ROLE_OPTION} --approve \
        --override-existing-serviceaccounts
    unset S3_ADMIN_ROLE_ARN
    S3_ADMIN_ROLE_ARN=$(eksctl get iamserviceaccount -c $CLUSTER_NAME \
        --name ${SA_NAME} -o json |jq -r '.[].status.roleARN')
    echo ${S3_ADMIN_ROLE_ARN}
}
```

## ~~appmesh cluster~~

```sh
eksctl create cluster \
--name appmeshtest \
--nodes-min 2 \
--nodes-max 3 \
--nodes 2 \
--auto-kubeconfig \
--full-ecr-access \
--appmesh-access

```

### appmesh-access-
`--appmesh-access` will apply customer inline policy for appmesh

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "servicediscovery:CreateService",
                "servicediscovery:DeleteService",
                "servicediscovery:GetService",
                "servicediscovery:GetInstance",
                "servicediscovery:RegisterInstance",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:ListInstances",
                "servicediscovery:ListNamespaces",
                "servicediscovery:ListServices",
                "servicediscovery:GetInstancesHealthStatus",
                "servicediscovery:UpdateInstanceCustomHealthStatus",
                "servicediscovery:GetOperation",
                "route53:GetHealthCheck",
                "route53:CreateHealthCheck",
                "route53:UpdateHealthCheck",
                "route53:ChangeResourceRecordSets",
                "route53:DeleteHealthCheck",
                "appmesh:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
```


### full-ecr-access
`--full-ecr-access` will apply ECR power user policy to node

- and others
![[../../git-attachment/eksctl-cmd-png-1.png]]


## refer
- https://eksctl.io/usage/minimum-iam-policies/



