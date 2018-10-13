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

![kube-net-7](/kubernetes/kube-net-7.png){:height="65%" width="65%"}

![kube-net-8](/kubernetes/kube-net-8.png){:height="65%" width="65%"}

![kube-net-9](/kubernetes/kube-net-9.png){:height="65%" width="65%"}

![kube-net-10](/kubernetes/kube-net-10.png){:height="65%" width="65%"}

## Calico

  In the Calico approach, IP packets to or from a workload are routed and firewalled by the Linux routing table and iptables infrastructure on the workload’s host. For a workload that is sending packets, Calico ensures that the host is always returned as the next hop MAC address regardless of whatever routing the workload itself might configure. For packets addressed to a workload, the last IP hop is that from the destination workload’s host to the workload itself.

![kube-net-11](/kubernetes/kube-net-11.png){:height="65%" width="65%"}
 
  Suppose that IPv4 addresses for the workloads are allocated from a datacenter-private subnet of 10.65/16, and that the hosts have IP addresses from 172.18.203/24. If you look at the routing table on a host you will see something like this:

```
ubuntu@calico-ci02:~$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.18.203.1    0.0.0.0         UG    0      0        0 eth0
10.65.0.0       0.0.0.0         255.255.0.0     U     0      0        0 ns-db03ab89-b4
10.65.0.21      172.18.203.126  255.255.255.255 UGH   0      0        0 eth0
10.65.0.22      172.18.203.129  255.255.255.255 UGH   0      0        0 eth0
10.65.0.23      172.18.203.129  255.255.255.255 UGH   0      0        0 eth0
10.65.0.24      0.0.0.0         255.255.255.255 UH    0      0        0 tapa429fb36-04
172.18.203.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

  There is one workload on this host with IP address 10.65.0.24, and accessible from the host via a TAP (or veth, etc.) interface named tapa429fb36-04. Hence there is a direct route for 10.65.0.24, through tapa429fb36-04. Other workloads, with the .21, .22 and .23 addresses, are hosted on two other hosts (172.18.203.126 and .129), so the routes for those workload addresses are via those hosts.

  The direct routes are set up by a Calico agent named Felix when it is asked to provision connectivity for a particular workload. A BGP client (such as BIRD) then notices those and distributes them – perhaps via a route reflector – to BGP clients running on other hosts, and hence the indirect routes appear also.



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



