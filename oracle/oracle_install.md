


# 虚拟机配置
## VM config in vsphere


## VM OS config
### basic
* install centos 6.8, select `base` in installation
* disable selinux & iptables
* disable nic discovery rules
```
cd /etc/udev/rules.d
rm -f 70-persistent-net.rules
ln -sf /dev/null 70-persistent-net.rules
```

* install vmware-tool
* NIC coalescing
```
```

* assign ip address
> eth0
```conf
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
> eth1 (for RAC internal connection)
```conf
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

* hosts and resolv.conf
> /etc/hosts
```
172.32.230.83 rac1 
172.32.230.84 rac2 
172.32.230.85 rac1-vip 
172.32.230.86 rac2-vip
192.168.99.1 rac1-priv
192.168.99.2 rac2-priv
```
> /etc/resolv.conf
```
search
nameserver 10.6.11.120
```
> add scan ip to DNS server, such as:
```
rac-scan   172.32.230.87/88/89
```

### install packages
* yum setting
  * copy install cd to special directory (/pub/cdrom)
  * create yum file in /etc/yum.repos.d/
```conf
[cdrom]
name=cdrom
baseurl=file:///pub/cdrom
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

* install packages
```bash
yum -y install gcc gcc-c++
yum -y install compat-gcc-34-3.4.6 compat-libstdc++-33-3.2.3 libaio libaio-devel
yum -y install elfutils-libelf-devel compat-libcap1
```

### kernel settinghs
* add following lines to /etc/sysctl.conf to reduce swapping
```conf
vm.overcommit_memory = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.swappiness = 0
net.ipv4.conf.eth1.rp_filter = 2
```

* huge page settings ([LINK HERE](http://blog.csdn.net/tianlesoftware/article/details/8536435))
```conf
vm.nr_hugepages = 3500   # 2MB each page (30000)
```
> reboot and check /proc/meminfo |grep HugePages
!!! don't let hugepage to exhaust all memory
#don’t use hugeapge, it maybe eat up your memory, and swap in/out storm.
> some settings for your reference
```conf
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

* /etc/security/limit.conf
change default value:
```conf
oracle   soft   memlock    50000000
oracle   hard   memlock    50000000
```
to:
```conf
oracle   soft   memlock    15000000
oracle   hard   memlock    15000000
```
> some settings for your reference
```conf
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
```

### boot file
* add lines to /etc/rc.local: 
```sh
#please disable these line, because of the incompatible between UEK and vmxnet3
#/sbin/ethtool -G eth0 rx 4096 tx 4096
#/sbin/ethtool -G eth1 rx 4096 tx 4096
for disk in sda sdb sdc sdd sde sdf; do
    echo 1024 > /sys/block/$disk/queue/max_sectors_kb
    echo $disk " max_sectors_kb set to 1024"
done
```

### user settings
* oracle users
```sh
groupadd dba
groupadd oinstall
groupadd asmdba
groupadd asmadmin
groupadd asmoper
useradd -g oinstall -G dba,asmdba oracle
useradd -g oinstall -G asmdba,asmadmin,asmoper,dba grid
mkdir -p /u01/app/grid
mkdir -p /u01/app/11.2.0/grid
mkdir -p /u01/app/oracle
chown -R grid:oinstall /u01
chown -R oracle:oinstall /u01/app/oracle
```

* setting password for grid & oracle
```sh
passwd grid
passwd oracle
```

* profile for grid
```bash
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=/u01/app/11.2.0/grid; export ORACLE_HOME
ORACLE_SID=+ASM1; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
```

* profile for oracle
```bash
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
ORACLE_SID=unitepos1  ; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
```

### prepare raw disk
* Add following to VM’s vmx file
```
disk.EnableUUID = "TRUE"
```

* add following to scsi_id.config
```
echo "options=-g" >> /etc/scsi_id.config
```

> Oracle Linux 5 
```
# scsi_id -g -s /block/sd?
```
> Oracle Linux 6/7, CentOS 6/7
```
# scsi_id -g -u -d /dev/sd?
```

* add ASM disks to OS, get disk name, such as sdb, sdc, sdd, etc
```sh
for i in b c d ; do
    /sbin/scsi_id -g -u -d /dev/sd$i
done
36000c295d0f74f996c7da9f53628b241
36000c298f8ce5da326f6752e20d1b452
36000c29a2f64c4089fe3964592096a33
```
> sample rules file
```
/etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c295d0f74f996c7da9f53628b241", NAME="asm-disk1", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c298f8ce5da326f6752e20d1b452", NAME="asm-disk2", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29a2f64c4089fe3964592096a33", NAME="asm-disk3", OWNER="grid", GROUP="asmadmin", MODE="0660"
```
> If you have lots of disks, maybe you should change ? to *
```
KERNEL=="sd*1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29fd0e9d9a6f4e161bd82450aec", NAME="asm-scsi1-0", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

* reboot or run as followings
```
/sbin/udevadm test /block/sdb/sdb1 
/sbin/udevadm control --reload-rules 
/sbin/start_udev
ls -al /dev/asm*
```

* refer to: 
https://oracle-base.com/articles/linux/udev-scsi-rules-configuration-in-oracle-linux
https://www.centos.org/docs/5/html/5.2/Virtualization/sect-Virtualization-Virtualized_block_devices-Configuring_persistent_storage_in_a_Red_Hat_Enterprise_Linux_5_environment.html


### multipath
```
```
* reference
http://www.zhongweicheng.com/?p=1612
http://www.zhongweicheng.com/?p=1608
https://willsnotes.wordpress.com/2010/10/13/linux-rhel-5-configuring-multipathing-with-dm-multipath/


### multi writer
```
```


# Database Installation
## installing Grid
![pic2](/oracle/pic2.png)

![pic3](/oracle/pic3.png)

choose typical installation

![pic4](/oracle/pic4.png)

click setup and test

![pic5](/oracle/pic5.png)
password is oracle, select asmadmin (same with the groupname you defined in 99-oracle-rawdevices.rules)

![pic6](/oracle/pic6.png)
Create a "CRS" asm diskgroup when install, using quorum disk.

![pic7](/oracle/pic7.png)

![pic8](/oracle/pic8.png)





## installing oracle











