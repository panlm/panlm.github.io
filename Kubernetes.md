

# Create Kubernetes
## clone kubernetes blueprint from market place to your project (1pic)
![img1](https://panlm.github.io/img/1.png)

* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


## edit credentials
![img2](https://panlm.github.io/img/2.png)

edit default user, add private key to CENTOS.


## vm configurations
![img3](https://panlm.github.io/img/3.png)
![img4](https://panlm.github.io/img/4.png)
![img5](https://panlm.github.io/img/5.png)

## edit task - configure minion
![img6](https://panlm.github.io/img/6.png)


## other configure
![img7](https://panlm.github.io/img/7.png)


## launch and have a cup of coffee :)
![img8](https://panlm.github.io/img/8.png)




# Kubernetes Operation
![img9](https://panlm.github.io/img/9.png)

