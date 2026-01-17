---
title: Cert Manager
description: 证书管理插件
created: 2023-07-31 15:36:34.121
last_modified: 2024-04-02
tags:
  - kubernetes
  - aws/container/eks
---

# Cert Manager
## install
### install with eksdemo

- https://github.com/awslabs/eksdemo/blob/main/docs/install-cert-manager.md
```sh
echo ${CLUSTER_NAME}
echo ${AWS_DEFAULT_REGION}
eksdemo install cert-manager -c ${CLUSTER_NAME}

kubectl get clusterissuer
# default name is letsencrypt-prod
```

### install with helm
- sa (https://cert-manager.io/docs/configuration/acme/dns01/route53/)
```sh
echo ${CLUSTER_NAME}
echo ${AWS_DEFAULT_REGION}
echo ${CERT_MANAGER_NS:=cert-manager}
echo ${CERT_MANAGER_SA:=cert-manager-sa}

cat >cert-manager-policy.json <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF

policy_name=CertManagerIAMPolicy-`date +%m%d%H%M`
policy_arn=$(aws iam create-policy \
  --policy-name ${policy_name}  \
  --policy-document file://cert-manager-policy.json \
  --query 'Policy.Arn' \
  --output text)

kubectl create ns ${CERT_MANAGER_NS}
eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace ${CERT_MANAGER_NS} \
  --name=${CERT_MANAGER_SA} \
  --role-name=${policy_name/Policy/Role} \
  --attach-policy-arn=${policy_arn} \
  --override-existing-serviceaccounts \
  --approve
```

- https://cert-manager.io/docs/installation/helm/
```sh
echo ${CERT_MANAGER_NS:=cert-manager}
echo ${CERT_MANAGER_SA:=cert-manager-sa}

CERT_MANAGER_VER=v1.19.2
helm upgrade --install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version ${CERT_MANAGER_VER} \
  --namespace ${CERT_MANAGER_NS} --create-namespace \
  --set crds.enabled=true \
  --set startupapicheck.enabled=true \
  --set serviceAccount.create=false \
  --set serviceAccount.name=${CERT_MANAGER_SA} \
  --timeout=5m \
  --wait
```

### install-for-overlay-cni-

```sh
helm upgrade --install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version ${CERT_MANAGER_VER} \
  --namespace ${CERT_MANAGER_NS} --create-namespace \
  --set crds.enabled=true \
  --set startupapicheck.enabled=true \
  --set serviceAccount.create=false \
  --set serviceAccount.name=${CERT_MANAGER_SA} \
  --set webhook.hostNetwork=true \
  --set webhook.securePort=10260 \
  --timeout=5m \
  --wait
  
# defult port is 10250, conflict to kubelet port 

```
- or refer: [[git/git-mkdocs/EKS/addons/calico-cni-overlay#Cert-Manager-]]

### install manually

- https://cert-manager.io/docs/installation/
- install newest version 
```sh
kubectl create ns cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml \
-n cert-manager
# CM_VERSION=v1.12.3 (2023/07)
# https://github.com/cert-manager/cert-manager/releases/download/${CM_VERSION}/cert-manager.yaml

```

## issuer-certificates-
```
TEST_DOMAIN=thanos-gateway.poc1109.aws.panlm.xyz
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${TEST_DOMAIN}
  namespace: monitoring
spec:
  secretName: thanos-gateway-tls
  dnsNames:
    - ${TEST_DOMAIN}
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
EOF

```


## newest version v1.12.3 (2024/04)
https://cert-manager.io/docs/releases/

![[../../git-attachment/cert-manager-png-1.png]]


