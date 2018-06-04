

## Create Kubernetes Environment
### clone kubernetes blueprint from market place to your project
![kubernetes1](/kubernetes/1.png){:height="50%" width="50%"}

* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


### edit credentials
![kubernetes2](/kubernetes/2.png){:height="50%" width="50%"}

edit default user, add private key to CENTOS.


### vm configurations
![kubernetes3](/kubernetes/3.png){:height="50%" width="50%"}
![kubernetes4](/kubernetes/4.png){:height="50%" width="50%"}
![kubernetes5](/kubernetes/5.png){:height="50%" width="50%"}

### edit task - configure minion
![kubernetes6](/kubernetes/6.png){:height="50%" width="50%"}


### other configure
![kubernetes7](/kubernetes/7.png){:height="50%" width="50%"}


### launch and have a cup of coffee :)
![kubernetes8](/kubernetes/8.png){:height="50%" width="50%"}




## Kubernetes Operation
![kubernetes9](/kubernetes/9.png){:height="50%" width="50%"}

```kubectl get no```
```kubectl get svc```
```kubectl describe no```
```kubectl describe po```
```kubectl describe svc```



## deply container
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


## deply service
```yml
kind: Service
apiVersion: v1
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx-2
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

## access applications


## Reference
* http://murat1985.github.io/kubernetes/cni/consul/2016/05/26/cni-consul.html
* https://blog.laputa.io/kubernetes-flannel-networking-6a1cb1f8ec7c
* https://blog.csdn.net/xingwangc2014/article/details/51204224
* http://dockone.io/article/618

### 理解kubernetes网络
- [POD Network](https://medium.com/google-cloud/understanding-kubernetes-networking-pods-7117dd28727)
- [Service Network](https://medium.com/google-cloud/understanding-kubernetes-networking-services-f0cb48e4cc82)
- [NodePort, LB, Ingress](https://medium.com/google-cloud/understanding-kubernetes-networking-ingress-1bc341c84078)




