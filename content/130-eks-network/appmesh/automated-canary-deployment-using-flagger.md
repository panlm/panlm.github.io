---
title: "automated-canary-deployment-using-flagger"
description: "自动化 canary 部署"
chapter: true
weight: 30
created: 2023-01-08 14:36:17.163
last_modified: 2023-01-08 14:36:17.163
tags: 
- aws/container/eks 
- aws/container/appmesh 
- flagger
---

```ad-attention
title: This is a github note
```

# flagger lab

## install
[[appmesh-workshop-eks#install appmesh-controller]]

### metrics-server and prometheus
```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

helm upgrade -i appmesh-prometheus eks/appmesh-prometheus \
--namespace appmesh-system \
--set serviceAccount.create=false \
--set serviceAccount.name=appmesh-controller

```

### flagger
```sh
helm repo add flagger https://flagger.app
helm upgrade -i flagger flagger/flagger \
--namespace=appmesh-system \
--set meshProvider=appmesh:v1beta2 \
--set metricsServer=http://appmesh-prometheus:9090 \
--set serviceAccount.create=false \
--set serviceAccount.name=appmesh-controller

kubectl get po -n appmesh-system | grep flagger

```


## Automated Canary Deployments

**Step 1.** Create a mesh.
- must have the 2nd label 
- need the 1st label for unique selection

```sh
set -u
UNIQ_STR=$(date +%H%M)
MESH_NAME=mesh${UNIQ_STR}
envsubst >mesh.yaml <<-EOF
apiVersion: appmesh.k8s.aws/v1beta2
kind: Mesh
metadata:
  name: ${MESH_NAME}
spec:
  namespaceSelector:
    matchLabels:
      mash: ${MESH_NAME}
      appmesh.k8s.aws/sidecarInjectorWebhook: enabled
EOF
kubectl apply -f mesh.yaml
```

**Step 2.** Create a new namespace with App Mesh sidecar injection enabled.
```sh
NS_NAME=namespace${UNIQ_STR}
# NS_NAME=${MESH_NAME}
envsubst >namespace.yaml <<-EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NS_NAME}
  labels:
    mash: ${MESH_NAME}
    appmesh.k8s.aws/sidecarInjectorWebhook: enabled
EOF
kubectl apply -f namespace.yaml
```

**Step 3.** Create a Kubernetes Deployment object.
- [build-colorapp](build-colorapp)

```sh
IMAGE_URL=694242712155.dkr.ecr.us-east-2.amazonaws.com/sample/colorapp:v1
envsubst >deployment.yaml <<-EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: ${NS_NAME}
spec:
  minReadySeconds: 3
  revisionHistoryLimit: 5
  progressDeadlineSeconds: 60
  strategy:
    rollingUpdate:
      maxUnavailable: 0
    type: RollingUpdate
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: ${IMAGE_URL}
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          successThreshold: 3
        ports:
        - name: http
          containerPort: 80
        resources:
          limits:
            cpu: 2000m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 64Mi
EOF
kubectl apply -f deployment.yaml
```

```sh
kubectl get deploy -n ${NS_NAME}
```

**Step 4.** Deploy a canary object.
```sh
envsubst >canary.yaml <<-EOF
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: webapp
  namespace: ${NS_NAME}
spec:
  # App Mesh API reference
  provider: appmesh:v1beta2
  # deployment reference
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  # the maximum time in seconds for the canary deployment
  # to make progress before it is rollback (default 600s)
  progressDeadlineSeconds: 60
  service:
    # container port
    port: 80
    targetPort: 80
    # App Mesh ingress timeout (optional)
    timeout: 15s
    # App Mesh retry policy (optional)
    retries:
      attempts: 3
      perTryTimeout: 5s
      retryOn: "gateway-error,client-error,stream-error"
    # App Mesh URI settings
    match:
      - uri:
          prefix: /
    rewrite:
      uri: /
  # define the canary analysis timing and KPIs
  analysis:
    # schedule interval (default 60s)
    interval: 1m
    # max number of failed metric checks before rollback
    threshold: 5
    # max traffic percentage routed to canary
    # percentage (0-100)
    maxWeight: 50
    # canary increment step
    # percentage (0-100)
    stepWeight: 10
    # App Mesh Prometheus checks
    metrics:
    - name: request-success-rate
      # minimum req success rate (non 5xx responses)
      # percentage (0-100)
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      # maximum req duration P99
      # milliseconds
      thresholdRange:
        max: 500
      interval: 30s
EOF
kubectl apply -f canary.yaml
```

```sh
kubectl get canary -n ${NS_NAME} -w
```

**Step 5.** To expose the webapp application outside the mesh, create an App Mesh gateway.
```sh
helm upgrade -i appmesh-gateway-${UNIQ_STR} eks/appmesh-gateway \
--namespace ${NS_NAME}
```

**Step 6.** Create a gateway route that points to the webapp virtual service.
```sh
envsubst >gatewayroute.yaml <<-EOF
apiVersion: appmesh.k8s.aws/v1beta2
kind: GatewayRoute
metadata:
  name: webapp
  namespace: ${NS_NAME}
spec:
  httpRoute:
    match:
      prefix: "/"
    action:
      target:
        virtualService:
          virtualServiceRef:
            name: webapp
EOF
kubectl apply -f gatewayroute.yaml
```

get URL
```sh
URL="http://$(kubectl -n ${NS_NAME} get svc/appmesh-gateway-${UNIQ_STR} -ojson | jq -r ".status.loadBalancer.ingress[].hostname")"
echo ${URL}
```

## Automated Canary Promotion

```sh
IMAGE_URL_V2=${IMAGE_URL%:*}:v2
echo ${IMAGE_URL_V2}

kubectl -n ${NS_NAME} set image deployment/webapp webapp=${IMAGE_URL_V2}
kubectl get canaries -A -w

kubectl describe canary webapp -n ${NS_NAME}

```




## refer 
- https://docs.flagger.app/
- https://aws.amazon.com/cn/blogs/containers/progressive-delivery-using-aws-app-mesh-and-flagger/




