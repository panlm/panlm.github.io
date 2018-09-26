

# Create Kubernetes Environment
## clone kubernetes blueprint from market place to your project
![kubernetes1](/kubernetes/1.png){:height="75%" width="75%"}

* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


## edit credentials
![kubernetes2](/kubernetes/2.png){:height="75%" width="75%"}

edit default user, add private key to CENTOS.

## vm configurations
![kubernetes3](/kubernetes/3.png){:height="75%" width="75%"}
![kubernetes4](/kubernetes/4.png){:height="75%" width="75%"}
![kubernetes5](/kubernetes/5.png){:height="75%" width="75%"}

## edit task - configure minion
![kubernetes6](/kubernetes/6.png){:height="75%" width="75%"}

## other configure
![kubernetes7](/kubernetes/7.png){:height="75%" width="75%"}

## launch and have a cup of coffee :)
![kubernetes8](/kubernetes/8.png){:height="75%" width="75%"}

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

## Application Deployment
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
```yaml
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
```
* app-service.yaml
```yaml
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
```

> kubectl create -f app-deployment.yaml -f app-service.yaml

* create nginx ingress controller, create dedicate namespace
> kubectl create namespace ingress

* create backend deployment & service
* default-backend-deployment.yaml
```yaml
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
```

* default-backend-service.yaml
```yaml
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
```

> kubectl create -f default-backend-deployment.yaml -f default-backend-service.yaml -n=ingress

* create configmap
* nginx-ingress-controller-config-map.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-controller-conf
  labels:
    app: nginx-ingress-lb
data:
  enable-vts-status: 'true'
```

> kubectl create -f nginx-ingress-controller-config-map.yaml -n=ingress

* create controller deployment
* nginx-ingress-controller-deployment.yaml
```yaml
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
```

* create RBCA
* nginx-ingress-controller-roles.yaml
```yaml
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
```

> kubectl create -f nginx-ingress-controller-roles.yaml -n=ingress
> kubectl create -f nginx-ingress-controller-deployment.yaml -n=ingress

* create ingress rules
* nginx-ingress.yaml
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: test.domain.com    # you could leave empty here for *
    http:
      paths:
      - backend:
          serviceName: nginx-ingress
          servicePort: 18080
        path: /nginx_status
```

* app-ingress.yaml
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: test.domain.com    # you could leave empty here for *
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
```

> kubectl create -f nginx-ingress.yaml -n=ingress
> kubectl create -f app-ingress.yaml

* expose nginx ingress controller
* nginx-ingress-controller-service.yaml
```yaml
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
```

> kubectl create -f nginx-ingress-controller-service.yaml -n=ingress

#### access app1, app2, nginx status, etc.
* http://test.domain.com:30000/app1
* http://test.domain.com:30000/app2
* http://test.domain.com:32000/nginx_status

before access it, you could mapping domain name to real ip address with /etc/hosts

reference [HERE](https://akomljen.com/kubernetes-nginx-ingress-controller/)


# Reference
* http://murat1985.github.io/kubernetes/cni/consul/2016/05/26/cni-consul.html
* https://blog.laputa.io/kubernetes-flannel-networking-6a1cb1f8ec7c
* https://blog.csdn.net/xingwangc2014/article/details/51204224
* http://dockone.io/article/618


## 理解kubernetes网络
- [POD Network](https://medium.com/google-cloud/understanding-kubernetes-networking-pods-7117dd28727)
- [Service Network](https://medium.com/google-cloud/understanding-kubernetes-networking-services-f0cb48e4cc82)
- [NodePort, LB, Ingress](https://medium.com/google-cloud/understanding-kubernetes-networking-ingress-1bc341c84078)
  - https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers
  - https://kubernetes.github.io/ingress-nginx/deploy/
  - https://www.weave.works/blog/kubernetes-beginners-guide/
  - https://kubernetes.io/docs/concepts/cluster-administration/networking/
  - [nutanix acs 2.0](https://docs.google.com/document/d/14Zy5NGDzpntkej1BliQB7jb5q7E3IuVnr3vk9LHyEGw/edit)
  - [introduce nsx and kubernetes](http://www.routetocloud.com/2017/10/introduction-to-nsx-and-kubernetes/)
  - [Kubernetes NodePort vs LoadBalancer vs Ingress? When should I use what?](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0) :+1:
  - network testing
    - [ ] proxy + cluster ip
    - [x] nodeport
    - [ ] load balance
    - [x] ingress




## Others
- [difference between replicator controller, replicator factor, deployment in k8s](https://www.mirantis.com/blog/kubernetes-replication-controller-replica-set-and-deployments-understanding-replication-options/)


- https://hackernoon.com/setting-up-nginx-ingress-on-kubernetes-2b733d8d2f45
- https://medium.com/@cashisclay/kubernetes-ingress-82aa960f658e
- https://akomljen.com/kubernetes-nginx-ingress-controller/
- 