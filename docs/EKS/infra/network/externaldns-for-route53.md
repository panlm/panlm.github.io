---
title: externaldns-for-route53
description: 使用 externaldns 组件
created: 2022-08-04 13:24:34.806
last_modified: 2023-11-10
tags:
  - kubernetes
  - aws/network/route53
---
> [!WARNING] This is a github note

# externaldns-for-route53

## setup-hosted-zone-

-  执行下面命令创建 Hosted Zone， 然后手工添加 NS 记录到上游的域名服务器 domain registrar 中 (create hosted zone, and then add NS records to upstream domain registrar)
```sh
echo ${DOMAIN_NAME}

aws route53 create-hosted-zone --name "${DOMAIN_NAME}." \
  --caller-reference "external-dns-test-$(date +%s)"

ZONE_ID=$(aws route53 list-hosted-zones-by-name --output json \
  --dns-name "${DOMAIN_NAME}." --query HostedZones[0].Id --out text)

aws route53 list-resource-record-sets --output text \
  --hosted-zone-id $ZONE_ID --query \
  "ResourceRecordSets[?Type == 'NS'].ResourceRecords[*].Value | []" | tr '\t' '\n'

###
# copy above output  
# add NS record on your upstream domain registrar
# set TTL to 172800
###

```
^fgvqjb

- refer: [[../../../CLI/awscli/route53-cmd#create-ns-record-]]
- refer: [[route53-subdomian]]

### private hosted zone

- you also could create private hosted zone and associate to your vpc. plugin will insert/update record in your private hosted zone. ([link](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html))

## install 

### install-

- https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
- 创建所需要的服务账号 (create service account)
	- 确保 EKS 集群名称正确 (ensure eks cluster name is correct)
	- 确保使用正确的 Region (ensure region is correct)
	- 确保域名匹配所需 (ensure domain name is correct)
```sh
CLUSTER_NAME=ekscluster1
AWS_REGION=us-east-2
DOMAIN_NAME=api0413.aws.panlm.xyz
EXTERNALDNS_NS=externaldns
export AWS_PAGER=""

# create namespace if it does not yet exist
kubectl get namespaces | grep -q $EXTERNALDNS_NS || \
  kubectl create namespace $EXTERNALDNS_NS

cat >externaldns-policy.json <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

POLICY_NAME=AllowExternalDNSUpdates-${RANDOM}
aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://externaldns-policy.json

# example: arn:aws:iam::XXXXXXXXXXXX:policy/AllowExternalDNSUpdates
export POLICY_ARN=$(aws iam list-policies \
 --query 'Policies[?PolicyName==`'"${POLICY_NAME}"'`].Arn' --output text)

eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --name "external-dns" \
  --namespace ${EXTERNALDNS_NS:-"default"} \
  --override-existing-serviceaccounts \
  --attach-policy-arn $POLICY_ARN \
  --approve

```

- 使用上述服务账号安装 ExternalDNS (install ExternalDNS with existed SA)
```sh
echo ${EXTERNALDNS_NS}
echo ${DOMAIN_NAME}
echo ${AWS_REGION}

envsubst >externaldns-with-rbac.yaml <<-EOF
# comment out sa if it was previously created
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: external-dns
#   labels:
#     app.kubernetes.io/name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods","nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  labels:
    app.kubernetes.io/name: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns
    namespace: ${EXTERNALDNS_NS} # change to desired namespace: externaldns, kube-addons
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  labels:
    app.kubernetes.io/name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: external-dns
  template:
    metadata:
      labels:
        app.kubernetes.io/name: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
        - name: external-dns
          image: registry.k8s.io/external-dns/external-dns:v0.13.2
          args:
            - --source=service
            - --source=ingress
            - --domain-filter=${DOMAIN_NAME} # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
            - --provider=aws
            - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
            - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
            - --registry=txt
            - --txt-owner-id=external-dns
          env:
            - name: AWS_DEFAULT_REGION
              value: ${AWS_REGION} # change to region where EKS is installed
     # # Uncommend below if using static credentials
     #        - name: AWS_SHARED_CREDENTIALS_FILE
     #          value: /.aws/credentials
     #      volumeMounts:
     #        - name: aws-credentials
     #          mountPath: /.aws
     #          readOnly: true
     #  volumes:
     #    - name: aws-credentials
     #      secret:
     #        secretName: external-dns
EOF

kubectl create --filename externaldns-with-rbac.yaml \
  --namespace ${EXTERNALDNS_NS:-"default"}

```

### install-with-eksdemo-

- https://github.com/awslabs/eksdemo/blob/main/docs/install-edns.md
```sh
echo ${CLUSTER_NAME}
echo ${AWS_REGION}
eksdemo install external-dns -c ${CLUSTER_NAME} --region ${AWS_REGION}
```
^a2vlmo

## verify

- create namespace
```sh
NS=verify
kubectl create ns ${NS}
```

***service sample***

- create nlb (no more clb, 20230423) with service definition
```sh
envsubst >verify-nginx.yaml <<-EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx.${DOMAIN_NAME}
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
    targetPort: 80
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
          name: http
EOF

kubectl create --filename verify-nginx.yaml -n ${NS:-default}

```

- wait nlb available and execute
```sh
aws route53 list-resource-record-sets --output json --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name == 'nginx.${DOMAIN_NAME}.']|[?Type == 'A']"

aws route53 list-resource-record-sets --output json --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name == 'nginx.${DOMAIN_NAME}.']|[?Type == 'TXT']"

dig +short nginx.${DOMAIN_NAME}. A

curl http://nginx.${DOMAIN_NAME}

```

***ingress sample***

- ensure certificate is existed and create alb 
```sh
echo ${CERTIFICATE_ARN}

envsubst >verify-nginx-ingress.yaml <<-EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/tags: Environment=dev,Team=test,Application=nginx
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: ${CERTIFICATE_ARN}
spec:
  ingressClassName: alb
  rules:
    - host: server.${DOMAIN_NAME}
      http:
        paths:
          - backend:
              service:
                name: nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
EOF

kubectl create --filename verify-nginx-ingress.yaml -n ${NS:-default}

```

- wait alb available and execute
```sh
aws route53 list-resource-record-sets --output json --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name == 'server.${DOMAIN_NAME}.']"

dig +short server.${DOMAIN_NAME}. A

curl https://server.${DOMAIN_NAME}

```






