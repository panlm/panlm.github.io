---
title: nginx-ingress-controller-community-ver
description: 使用 nginx ingress
created: 2022-06-16 10:25:37.971
last_modified: 2023-11-10
tags:
  - nginx
  - kubernetes/ingress
  - aws/container/eks
---

# nginx-ingress-controller-community-ver
## install
### install with eksdemo
- https://github.com/awslabs/eksdemo/blob/main/docs/install-ingress-nginx.md
```sh
echo ${CLUSTER_NAME}
eksdemo install ingress-nginx -c ${CLUSTER_NAME} --namespace kube-system
```

### install manually
- link
```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install my-ing1 ingress-nginx/ingress-nginx

kubectl annotate service/my-ing1-ingress-nginx-controller \
  service.beta.kubernetes.io/aws-load-balancer-internal="false" \
  service.beta.kubernetes.io/aws-load-balancer-type=nlb \
  service.beta.kubernetes.io/aws-load-balancer-nlb-target-type=ip

# need aws lbc 
# service.beta.kubernetes.io/aws-load-balancer-nlb-target-type=ip

```


## resources
```sh
$ kubectl apply -f https://raw.githubusercontent.com/cornellanthony/nlb-nginxIngress-eks/master/apple.yaml 
$ kubectl apply -f https://raw.githubusercontent.com/cornellanthony/nlb-nginxIngress-eks/master/banana.yaml

```

## tls certificate
for nlb
```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls-n.key -out tls-n.crt -subj "/CN=*elb.us-east-2.amazonaws.com/O=*.elb.us-east-2.amazonaws.com"

kubectl create secret tls tls-secret-n --key tls-n.key --cert tls-n.crt

```

for your domain
- create certificate for your domain
- create cname record in route53 to mapping your domain to nlb domain name
- using your domain name in ingress yaml definition

## ingress
for nlb
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - '*.elb.us-east-2.amazonaws.com'
    secretName: tls-secret-n
  rules:
  - host: '*.elb.us-east-2.amazonaws.com'
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service: 
              name: apple-service
              port: 
                number: 5678
        - path: /banana
          pathType: Prefix
          backend:
            service: 
              name: banana-service
              port: 
                number: 5678
```
(refer: appendix)

## refer
- [[Using a Network Load Balancer with the NGINX Ingress Controller on Amazon EKS]] 
- https://kubernetes.github.io/ingress-nginx/deploy/
```sh
k apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

### appendix - for clb
#### certificate
for clb
```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls-c.key -out tls-c.crt -subj "/CN=*.us-east-2.elb.amazonaws.com/O=*.us-east-2.elb.amazonaws.com"

kubectl create secret tls tls-secret-c --key tls-c.key --cert tls-c.crt

```

#### ingress
for clb
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - '*.us-east-2.elb.amazonaws.com'
    secretName: tls-secret-c
  rules:
  - host: '*.us-east-2.elb.amazonaws.com'
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service: 
              name: apple-service
              port: 
                number: 5678
        - path: /banana
          pathType: Prefix
          backend:
            service: 
              name: banana-service
              port: 
                number: 5678
```

### appendix - ingress-nginx-output

```output
LAST DEPLOYED: Mon Aug 15 01:17:43 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w my-ing1-ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```


### appendix - other sample

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: game-2048-ns2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: game-2048-ns2
  name: deployment-2048
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app-2048
  replicas: 5
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app-2048
    spec:
      containers:
      - image: public.ecr.aws/l6m2t8p7/docker-2048:latest
        imagePullPolicy: Always
        name: app-2048
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  namespace: game-2048-ns2
  name: service-2048
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: app-2048
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: game-2048-ns2
  name: ingress-2048
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - '*.elb.us-east-2.amazonaws.com'
    secretName: tls-secret-n
  rules:
    - http:
        paths:
        - path: /abc(/|$)(.*)
          pathType: Prefix
          backend:
            service:
              name: service-2048
              port:
                number: 80

```

