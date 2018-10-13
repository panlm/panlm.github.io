# Create Kubernetes Environment
* clone k8s 2.0 blueprint to your project
* update credentials
* update variable public key 
* update vm image (master & minion)
* update vm nic (master & minion)
* download some file to local and comment curl line in 'package install' task (master & minion)
* add environemnt to docker service (master & minion)
```bash
sudo sed -i '/ExecStart=/c\\ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock' /usr/lib/systemd/system/docker.service
cp /usr/lib/systemd/system/docker.service /tmp
sudo sed -i '/\[Service\]/c\\[Service]\nEnvironment=\"HTTP_PROXY=http://10.132.71.38:1080/\"' /usr/lib/systemd/system/docker.service
```
![kube-1.10.5-1](/kubernetes/kube-1.10.5-1.png){:height="85%" width="85%"}

* add more waiting time (line 22)
![kube-1.10.5-2](/kubernetes/kube-1.10.5-2.png){:height="85%" width="85%"}

* update HELM script, add using http proxy when helm init
```bash
printf -v no_proxy '%s,' 10.132.{250..251}.{1..255}
export no_proxy=${no_proxy}localhost
echo $no_proxy
http_proxy=http://10.132.71.38:1080/ no_proxy=${no_proxy} helm init --service-account helm
```
![kube-1.10.5-3](/kubernetes/kube-1.10.5-3.png){:height="85%" width="85%"}

* login to controller0 to execute ```kubectl```




