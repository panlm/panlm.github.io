

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
![kubernetes2](/kubernetes/2.png){:height="50%" width="50%"}

edit default user, add private key to CENTOS.


## vm configurations
![kubernetes3](/kubernetes/3.png){:height="50%" width="50%"}
![kubernetes4](/kubernetes/4.png){:height="50%" width="50%"}
![kubernetes5](/kubernetes/5.png){:height="50%" width="50%"}

## edit task - configure minion
![kubernetes6](/kubernetes/6.png){:height="50%" width="50%"}


## other configure
![kubernetes7](/kubernetes/7.png){:height="50%" width="50%"}


## launch and have a cup of coffee :)
![kubernetes8](/kubernetes/8.png){:height="50%" width="50%"}




# Kubernetes Operation
![kubernetes9](/kubernetes/9.png){:height="50%" width="50%"}

