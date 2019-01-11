# Kubernetes Operation
## some basic kubectl commands:
```
# kubectl get no
# kubectl get svc
# kubectl describe no
# kubectl describe po
# kubectl describe svc
# kubectl create -f nginx-service.xml
```
![kube-oper-1](/kubernetes/kube-oper-1.png){:height="75%" width="75%"}


## kubernetes dashboard
### access 1

* on master node, running kubectl to handle authentication with apiserver:<br/>
```kubectl proxy --address 0.0.0.0 --accept-hosts '.*'```
* open URL from browser:<br/>
```http://<master-ip>:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/```

### access 2

* check /etc/kubernetes/addons/dashboard.yml file to find nodeport of it's service
* access any work node with that port to open dashboard UI


## simplest POD

```yml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
  annotations:
spec:
  containers:
  - name: myapp-container
    image: busybox
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
```


## simplest POD with persistent storage

```yml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod-with-stg
  labels:
    app: myapp
  annotations:
spec:
  containers:
  - name: myapp-nginx
    image: nginx
    ports:
      - name: web
        containerPort: 80
    volumeMounts:
      - name: abs
        mountPath: "/usr/share/nginx/html"
  volumes:
  - name: abs
    persistentVolumeClaim:
      claimName: ntnx-pvc-demo
```

## PVC/PV/SC

```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ntnx-pvc-demo         # pvc name (for pod refer)
spec:
  storageClassName: silver    # your storage class name
  resources:
    requests:
      storage: 1Gi
  accessModes:
    - ReadWriteMany
```

## simplest deployment

```yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app3
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: app3
    spec:
      containers:
      - name: app3
        image: busybox
        command: ['sh', '-c', 'echo The app is running! && sleep 3600']
```


# Application Deployment
### [ ] Using kube-proxy

nginx-2.xml
```yml
apiVersion: v1
kind: ReplicationController
metadata:
  name: rc-nginx-2
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-2
    spec:
      containers:
      - name: nginx-2
        image: nginx
        ports:
        - containerPort: 80
```
> kubectl create -f nginx-2.xml

nginx-service-2.xml
```yml
kind: Service
apiVersion: v1
metadata:
  name: nginx-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: nginx-2
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
> kubectl create -f nginx-service-2.xml


```bash
kubectl proxy --port=8081 --address=0.0.0.0 --accept-hosts='.*'
```
and access: http://10.21.104.184:8081/api/v1/proxy/namespaces/default/services/nginx-service:80/


### [x] Using Nodeport

nginx-3.xml

```yml
apiVersion: v1
kind: ReplicationController
metadata:
  name: rc-nginx-3
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx-3
    spec:
      containers:
      - name: nginx-3
        image: nginx
        ports:
        - containerPort: 80
```
> kubectl create -f nginx-3.xml

nginx-service-3.xml

```yml
kind: Service
apiVersion: v1
metadata:
  name: nginx-service-nodeport
spec:
  type: NodePort
  selector:
    app: nginx-3
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
> kubectl create -f nginx-service-3.xml

```bash
kubectl get svc
```
and access: http://host-ip:port


### [ ] Using Load Balance

```yaml
```


### [x] Using Ingress
#### create app1, app2, backend, ingress controller, configmap, rbca, ingress rules, etc.

create app deployment & service

app-deployment.yaml

```yml
cat > app-deployment.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app1
        ports:
        - containerPort: 80
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app2
        ports:
        - containerPort: 80
EOF
```

app-service.yaml
```yaml
cat > app-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: appsvc1
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app1
---
apiVersion: v1
kind: Service
metadata:
  name: appsvc2
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
EOF
```

> ```kubectl create -f app-deployment.yaml -f app-service.yaml```

create nginx ingress controller, create dedicate namespace
> ```kubectl create namespace ingress```

create backend deployment & service

default-backend-deployment.yaml

```yaml
cat > default-backend-deployment.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-backend
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: default-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-backend
        image: gcr.io/google_containers/defaultbackend:1.0
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
EOF
```

default-backend-service.yaml

```yaml
cat > default-backend-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: default-backend
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: default-backend
EOF
```

> ```kubectl create -f default-backend-deployment.yaml -f default-backend-service.yaml -n=ingress```

create configmap

nginx-ingress-controller-config-map.yaml

```yaml
cat > nginx-ingress-controller-config-map.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-controller-conf
  labels:
    app: nginx-ingress-lb
data:
  enable-vts-status: 'true'
EOF
```

> ```kubectl create -f nginx-ingress-controller-config-map.yaml -n=ingress```

create controller deployment

nginx-ingress-controller-deployment.yaml

```yaml
cat > nginx-ingress-controller-deployment.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
spec:
  replicas: 1
  revisionHistoryLimit: 3
  template:
    metadata:
      labels:
        app: nginx-ingress-lb
    spec:
      terminationGracePeriodSeconds: 60
      serviceAccount: nginx
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.9.0
          imagePullPolicy: Always
          readinessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
          livenessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            timeoutSeconds: 5
          args:
            - /nginx-ingress-controller
            - --default-backend-service=\$(POD_NAMESPACE)/default-backend
            - --configmap=\$(POD_NAMESPACE)/nginx-ingress-controller-conf
            - --v=2
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - containerPort: 80
            - containerPort: 18080
EOF
```

create RBCA

nginx-ingress-controller-roles.yaml

```yaml
cat > nginx-ingress-controller-roles.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: nginx-role
rules:
- apiGroups:
  - ""
  - "extensions"
  resources:
  - configmaps
  - secrets
  - endpoints
  - ingresses
  - nodes
  - pods
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - list
  - watch
  - get
  - update
- apiGroups:
  - "extensions"
  resources:
  - ingresses
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
- apiGroups:
  - "extensions"
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: nginx-role
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-role
subjects:
- kind: ServiceAccount
  name: nginx
  namespace: ingress
EOF
```

> ```kubectl create -f nginx-ingress-controller-roles.yaml -n=ingress```
> ```kubectl create -f nginx-ingress-controller-deployment.yaml -n=ingress```

create ingress rules

nginx-ingress.yaml

```yaml
cat > nginx-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: test.akomljen.com    # you could leave empty here for *
    http:
      paths:
      - backend:
          serviceName: nginx-ingress
          servicePort: 18080
        path: /nginx_status
EOF
```

app-ingress.yaml

```yaml
cat > app-ingress.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: test.akomljen.com    # you could leave empty here for *
    http:
      paths:
      - backend:
          serviceName: appsvc1
          servicePort: 80
        path: /app1
      - backend:
          serviceName: appsvc2
          servicePort: 80
        path: /app2
EOF
```

> kubectl create -f nginx-ingress.yaml -n=ingress
> kubectl create -f app-ingress.yaml

expose nginx ingress controller

nginx-ingress-controller-service.yaml

```yaml
cat > nginx-ingress-controller-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: 30000
      name: http
    - port: 18080
      nodePort: 32000
      name: http-mgmt
  selector:
    app: nginx-ingress-lb
EOF
```
> ```kubectl create -f nginx-ingress-controller-service.yaml -n=ingress```

#### access app1, app2, nginx status, etc.

* http://test.domain.com:30000/app1
* http://test.domain.com:30000/app2
* http://test.domain.com:32000/nginx_status

before access it, you could mapping domain name to real ip address with /etc/hosts

reference [HERE](https://akomljen.com/kubernetes-nginx-ingress-controller/)

