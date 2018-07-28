
**Thanks  _CunLei.Zhang@nutanix.com_  for reviewing this doc!**

---

# VM config in vsphere
## Add more disks to VM
add disks under different iscsi controller, <br/>
for example 3 data file disks in iscsi1; 3 redo disks in iscsi2; 3 archive log disks in iscsi3; put quotum disk in iscsi0

![os1](/oracle/os1.png)

# VM OS config
## basic
* (mandatory) install centos 6.8, select `base` in installation
* (mandatory) disable selinux & iptables
* (optional) disable nic discovery rules
```
cd /etc/udev/rules.d
rm -f 70-persistent-net.rules
ln -sf /dev/null 70-persistent-net.rules
```

* (mandatory) install vmware-tool
* (optional) NIC coalescing
```
```

* (mandatory for rac) assign ip address
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

* (mandatory for rac) hosts and resolv.conf
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

## install packages
* (mandatory) yum setting
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

* (mandatory) install packages
```bash
yum -y install gcc gcc-c++
yum -y install compat-gcc-34-3.4.6 compat-libstdc++-33-3.2.3 libaio libaio-devel
yum -y install elfutils-libelf-devel compat-libcap1
```

## kernel settinghs
* (mandatory) add following lines to /etc/sysctl.conf to reduce swapping
```conf
vm.overcommit_memory = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.swappiness = 0
net.ipv4.conf.eth1.rp_filter = 2
```

* (optional) huge page settings ([LINK HERE](http://blog.csdn.net/tianlesoftware/article/details/8536435))
```conf
vm.nr_hugepages = 3500   # 2MB each page (30000)
```
reboot and check `/proc/meminfo |grep HugePages`
  > !!! don't let hugepage to exhaust all memory
  > #don’t use hugeapge, it maybe eat up your memory, and swap in/out storm.
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

* (mandatory) /etc/security/limit.conf
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

## boot file
* (mandatory) add lines to /etc/rc.local: 
```sh
#please disable these line, because of the incompatible between UEK and vmxnet3
#/sbin/ethtool -G eth0 rx 4096 tx 4096
#/sbin/ethtool -G eth1 rx 4096 tx 4096

#if you have more disks, please add them as following
#for disk in sda sdb sdc sdd sde sdf; do
lsscsi | grep NUTANIX | awk '{print $NF}' | awk -F"/" '{print $NF}' | grep -v "-" | while read disk ; do
    echo 1024 > /sys/block/${disk}/queue/max_sectors_kb
    echo ${disk} " max_sectors_kb set to 1024"
    echo noop > /sys/block/${disk}/queue/scheduler
    echo ${disk} " scheduler set to noop"
done
```
* (mandatory and verifying needed) or using `/etc/udev/rules.d/71-block-max-sectors.rules`
```
ACTION=="add|change", SUBSYSTEM=="block", RUN+="/bin/sh -c '/bin/echo 1024 > /sys%p/queue/max_sectors_kb'"
```
or
```
ACTION=="add", SUBSYSTEMS=="scsi", ATTRS{vendor}=="NUTANIX ", ATTRS{model}=="VDISK", RUN+="/bin/sh -c 'echo 1024 >/sys$DEVPATH/queue/max_sectors_kb'"
```

## user settings
* (mandatory) oracle users
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

* (mandatory) setting password for grid & oracle
```sh
passwd grid
passwd oracle
```

* (mandatory) profile for grid
```sh
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=/u01/app/11.2.0/grid; export ORACLE_HOME
ORACLE_SID=+ASM1; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
```

* (mandatory) profile for oracle
```sh
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
ORACLE_SID=unitepos1  ; export ORACLE_SID
PATH=$ORACLE_HOME/bin:$PATH; export PATH
```

## prepare raw disk
* (mandatory) Add following to VM’s vmx file, and remove vm from inventory and add it back again.
```conf
disk.EnableUUID = "TRUE"
```

* (optional) add following to scsi_id.config
```sh
echo "options=-g" >> /etc/scsi_id.config
```

  > Oracle Linux 5 
```sh
scsi_id -g -s /block/sd?
```
  > Oracle Linux 6/7, CentOS 6/7
```sh
scsi_id -g -u -d /dev/sd?
```

* (mandatory) add ASM disks to OS, get disk name, such as sdb, sdc, sdd, etc
```sh
for i in b c d ; do
    /sbin/scsi_id -g -u -d /dev/sd$i
done
36000c295d0f74f996c7da9f53628b241
36000c298f8ce5da326f6752e20d1b452
36000c29a2f64c4089fe3964592096a33
```
  > sample rules file: /etc/udev/rules.d/99-oracle-asmdevices.rules
```conf
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c295d0f74f996c7da9f53628b241", NAME="asm-disk1", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c298f8ce5da326f6752e20d1b452", NAME="asm-disk2", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29a2f64c4089fe3964592096a33", NAME="asm-disk3", OWNER="grid", GROUP="asmadmin", MODE="0660"
```
    > If you have lots of disks, maybe you should change `?` to `*`
```conf
KERNEL=="sd*1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="36000c29fd0e9d9a6f4e161bd82450aec", NAME="asm-scsi1-0", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

* (mandatory) reboot or run as followings
```sh
/sbin/udevadm test /block/sdb/sdb1 
/sbin/udevadm control --reload-rules 
/sbin/start_udev
ls -al /dev/asm*
```

* refer to: 
  * https://oracle-base.com/articles/linux/udev-scsi-rules-configuration-in-oracle-linux
  * https://www.centos.org/docs/5/html/5.2/Virtualization/sect-Virtualization-Virtualized_block_devices-Configuring_persistent_storage_in_a_Red_Hat_Enterprise_Linux_5_environment.html


## (optional) multipath
```
```
* reference
  * http://www.zhongweicheng.com/?p=1612
  * http://www.zhongweicheng.com/?p=1608
  * https://willsnotes.wordpress.com/2010/10/13/linux-rhel-5-configuring-multipathing-with-dm-multipath/


## (mandatory for rac) multi writer
* enable multi write
```
```

* disable shadow-clone in nutanix cluster
```
```









---

*Author: Leiming.Pan@nutanix.com*<br/>
*Last update: 22 Jun, 2018*

