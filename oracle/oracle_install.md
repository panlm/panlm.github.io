


# 虚拟机配置
## VM config in vsphere

## VM OS config
1. install centos 6.8, select `base` in installation
2. disable selinux & iptables
3. disable nic discovery rules
```
cd /etc/udev/rules.d
rm -f 70-persistent-net.rules
ln -sf /dev/null 70-persistent-net.rules
```
4. install vmware-tool
2. NIC coalescing
```
```
6. assign ip address
eth0
```
###eth0
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
IPADDR=172.32.230.83
NETMASK=255.255.255.0
GATEWAY=172.32.230.193
IPV6INIT=no
USERCTL=no
```

eth1 (for RAC internal connection)
```
DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
IPADDR=192.168.99.1
NETMASK=255.255.255.0
IPV6INIT=no
USERCTL=no
```

1.  hosts and resolv.conf
/etc/hosts
```
172.32.230.83 rac1 
172.32.230.84 rac2 
172.32.230.85 rac1-vip 
172.32.230.86 rac2-vip
192.168.99.1 rac1-priv
192.168.99.2 rac2-priv
```

/etc/resolv.conf
```
search
nameserver 10.6.11.120
```

add scan ip to DNS server, such as:
```
rac-scan   172.32.230.87/88/89
```

1. yum setting
```
[cdrom]
name=cdrom
baseurl=file:///pub/RHEL/Server/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

