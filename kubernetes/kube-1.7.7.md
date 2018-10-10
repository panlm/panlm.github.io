# Create Kubernetes Environment
## clone kubernetes blueprint from market place to your project
![kube-1.7.7-1](/kubernetes/kube-1.7.7-1.png){:height="75%" width="75%"}

* CLUSTER_SUBNET -- pod network in k8s
* SERVICE_SUBNET -- service network in k8s
* KUBE_CLUSTER_DNS -- no idea
* PRISM_CLUSTER_IP / PRISM_DATA_SERVICE_IP -- nutanix cluster info
* PRISM_USERNAME / PRISM_PASSWORD -- credentials for nutanix prism
* CONTAINER_NAME -- where your VMs will located
* INSTANCE_PUBLIC_KEY -- public key for user who will login VM to execute all tasks


## edit credentials
![kube-1.7.7-2](/kubernetes/kube-1.7.7-2.png){:height="75%" width="75%"}

edit default user, add private key to CENTOS.

## vm configurations
![kube-1.7.7-3](/kubernetes/kube-1.7.7-3.png){:height="75%" width="75%"}
![kube-1.7.7-4](/kubernetes/kube-1.7.7-4.png){:height="75%" width="75%"}
![kube-1.7.7-5](/kubernetes/kube-1.7.7-5.png){:height="75%" width="75%"}

## edit task - configure minion
![kube-1.7.7-6](/kubernetes/kube-1.7.7-6.png){:height="75%" width="75%"}
* add environment to docker system script, to ensure download images through proxy
```Environment=\"HTTP_PROXY=http://10.132.71.38:1080/\"```

## other configure
![kube-1.7.7-7](/kubernetes/kube-1.7.7-7.png){:height="75%" width="75%"}

## launch and have a cup of coffee :)
![kube-1.7.7-8](/kubernetes/kube-1.7.7-8.png){:height="75%" width="75%"}

