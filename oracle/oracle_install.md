


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
5. NIC coalescing
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

7.  hosts and resolv.conf
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

8. yum setting
copy install cd to special directory (/pub/cdrom)
```
[cdrom]
name=cdrom
baseurl=file:///pub/cdrom
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

9. install packages
```
yum -y install gcc gcc-c++
yum -y install compat-gcc-34-3.4.6 compat-libstdc++-33-3.2.3 libaio libaio-devel
yum -y install elfutils-libelf-devel compat-libcap1
```

10. sysctl.conf
add following lines to /etc/sysctl.conf to reduce swapping
```
vm.overcommit_memory = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.swappiness = 0
net.ipv4.conf.eth1.rp_filter = 2
```

huge page settings ([LINK HERE](http://blog.csdn.net/tianlesoftware/article/details/8536435))
```
vm.nr_hugepages = 3500   # 2MB each page (30000)
```

some settings for your reference
```
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
fs.file-max = 6815744
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
```

