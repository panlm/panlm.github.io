

# Create Kubernetes
## clone kubernetes blueprint from market place to your project (1pic)
![kubernetes1](/kubernetes/1.png){:height="50%" width="50%"}


* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


## edit credentials
![kubernetes2](https://panlm.github.io/kubernetes/2.png)

edit default user, add private key to CENTOS.


## vm configurations
![kubernetes3](https://panlm.github.io/kubernetes/3.png)
![kubernetes4](https://panlm.github.io/kubernetes/4.png)
![kubernetes5](https://panlm.github.io/kubernetes/5.png)

## edit task - configure minion
![kubernetes6](https://panlm.github.io/kubernetes/6.png)


## other configure
![kubernetes7](https://panlm.github.io/kubernetes/7.png)


## launch and have a cup of coffee :)
![kubernetes8](https://panlm.github.io/kubernetes/8.png)




# Kubernetes Operation
![kubernetes9](https://panlm.github.io/kubernetes/9.png)

