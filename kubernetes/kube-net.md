# Summary
## Flannel
- [POD Network](https://medium.com/google-cloud/understanding-kubernetes-networking-pods-7117dd28727)
<br/>![kube-net-1](/kubernetes/kube-net-1.png){:height="65%" width="65%"}

- [Service Network](https://medium.com/google-cloud/understanding-kubernetes-networking-services-f0cb48e4cc82)
<br/>![kube-net-2](/kubernetes/kube-net-2.png){:height="65%" width="65%"}
<br/>![kube-net-3](/kubernetes/kube-net-3.png){:height="65%" width="65%"}
<br/>![kube-net-4](/kubernetes/kube-net-4.png){:height="65%" width="65%"}

 Here’s the netfilter is a rules-based packet processing engine. It runs in kernel space and gets a look at every packet at various points in its life cycle. It matches packets against rules and when it finds a rule that matches it takes the specified action. Among the many actions it can take is redirecting the packet to another destination. That’s right, netfilter is a kernel space proxy. The following illustrates the role netfilter plays when kube-proxy is running as a user space proxy.

<br/>![kube-net-5](/kubernetes/kube-net-5.png){:height="65%" width="65%"}

 In this mode kube-proxy opens a port (10400 in the example above) on the local host interface to listen for requests to the test-service, inserts netfilter rules to reroute packets destined for the service IP to its own port, and forwards those requests to a pod on port 8080. That is how a request to 10.3.241.152:80 magically becomes a request to 10.0.2.2:8080. Given the capabilities of netfilter all that’s required to make this all work for any service is for kube-proxy to open a port and insert the correct netfilter rules for that service, which it does in response to notifications from the master api server of changes in the cluster.

 There’s one more little twist to the tale. I mentioned above that user space proxying is expensive due to marshaling packets. In kubernetes 1.2 kube-proxy gained the ability to run in iptables mode. In this mode kube-proxy mostly ceases to be a proxy for inter-cluster connections, and instead delegates to netfilter the work of detecting packets bound for service IPs and redirecting them to pods, all of which happens in kernel space. In this mode kube-proxy’s job is more or less limited to keeping netfilter rules in sync.

<br/>![kube-net-6](/kubernetes/kube-net-6.png){:height="65%" width="65%"}

- [NodePort, LB, Ingress](https://medium.com/google-cloud/understanding-kubernetes-networking-ingress-1bc341c84078)


## Calico




# 理解kubernetes网络

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



