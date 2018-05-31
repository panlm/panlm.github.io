

# Create Kubernetes
## clone kubernetes blueprint from market place to your project (1pic)
![img1](https://github.com/panlm/panlm.github.io/blob/master/img/1.png)

* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


## edit credentials
![img2](img/img2.png)

edit default user, add private key to CENTOS.


## vm configurations
![img3](img/img3.png)
![img4](img/img4.png)
![img5](img/img5.png)

## edit task - configure minion
![img6](img/img6.png)


## other configure
![img7](img/img7.png)


## launch and have a cup of coffee :)
![img8](img/img8.png)




# Kubernetes Operation
![img9](img/img9.png)

