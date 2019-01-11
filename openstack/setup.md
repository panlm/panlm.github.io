# network
public 10.132.68.x
admin 172.16.1.1
admin dhcp 172.16.10.10-200

1. new vm
2. copy repo to vm
3. create repo
4. zypper update
5. 


# OS configuration

* disable firewall

```bash
systemctl stop SuSEfirewall2
systemctl stop SuSEfirewall2_init
systemctl disable SuSEfirewall2
systemctl disable SuSEfirewall2_init
```

* cp media to local

```bash
mount SLE-12-SP2-Server-DVD-x86_64-GM-DVD1.iso /mnt
rsync -avP /mnt/ /srv/tftpboot/suse-12.2/x86_64/install/
umount /mnt
mount SUSE-OPENSTACK-CLOUD-7-x86_64-GM-DVD1.iso /mnt
rsync -avP /mnt/ /srv/tftpboot/suse-12.2/x86_64/repos/Cloud/
umount /mnt
```

* snapshot your vm before network configuration, due to some settings could not be changed after initiated. 

* assign 2 nic to this vm and ensure ```eth0``` is ```0x03``` and ```eth1``` is ```0x04```, otherwize you need to remove nic from vm and attach them again
![local-nic1](/openstack/local-nic1.png)

* setup network, using ```yast lan```
  * address: eth0 --> 172.16.1.10, eth1 --> 10.132.249.10
  * gateway: 10.132.128.4
  * dns: 10.132.70.1
  * add full qualify hostname to ```/etc/hosts```
  ![local-nic2](/openstack/local-nic2.png)

* update packages
  * copy all update packages to ```/srv/tftpboot/suse-12.2/x86_64/repos/```
  * add repos
    ```
    cd /srv/tftpboot/suse-12.2/x86_64/repos/
    zypper addrepo -n suse-12.2-pool -p 98 $PWD/SLES12-SP2-Pool SLES12-SP2-Pool
    zypper addrepo -n suse-12.2-updates -p 98 $PWD/SLES12-SP2-Updates SLES12-SP2-Updates
    zypper addrepo -n cloud7-pool -p 98 $PWD/SUSE-OpenStack-Cloud-7-Pool SUSE-OpenStack-Cloud-7-Pool
    zypper addrepo -n cloud7-updates -p 98 $PWD/SUSE-OpenStack-Cloud-7-Updates SUSE-OpenStack-Cloud-7-Updates
    ```
  * update system
    ```
    zypper update
    reboot
    ```
  * remove repos
    ```
    zypper removerepo suse-12.2-pool
    zypper removerepo suse-12.2-updates
    zypper removerepo cloud7-pool
    zypper removerepo cloud7-updates
    ```

# crowbar initial
* crowbar settings
<br/>default network settings
![crowbar-net-default](/openstack/crowbar-net-default.png)
<br/>network mode
![crowbar-net-mode](/openstack/crowbar-net-mode.png)
<br/>repos
![crowbar-net-repos](/openstack/crowbar-net-repos.png)
<br/>network - admin
![crowbar-net-admin](/openstack/crowbar-net-admin.png)
<br/>network detail - admin
![crowbar-net-admin-detail](/openstack/crowbar-net-admin-detail.png)
<br/>network - bmc
![crowbar-net-bmc](/openstack/crowbar-net-bmc.png)
<br/>network detail - bmc
![crowbar-net-bmc-detail](/openstack/crowbar-net-bmc-detail.png)
<br/>network - bmc_vlan
![crowbar-net-bmc_vlan](/openstack/crowbar-net-bmc_vlan.png)
<br/>network detail - bmc_vlan
![crowbar-net-bmc_vlan-detail](/openstack/crowbar-net-bmc_vlan-detail.png)
<br/>network - nova_fixed
![crowbar-net-nova_fixed](/openstack/crowbar-net-nova_fixed.png)
<br/>network detail - nova_fixed
![crowbar-net-nova_fixed-detail](/openstack/crowbar-net-nova_fixed-detail.png)
<br/>network - nova_floating
![crowbar-net-nova_floating](/openstack/crowbar-net-nova_floating.png)
<br/>network detail - nova_floating
![crowbar-net-nova_floating-detail](/openstack/crowbar-net-nova_floating-detail.png)
<br/>network - os_sdn
![crowbar-net-os_sdn](/openstack/crowbar-net-os_sdn.png)
<br/>network detail - os_sdn
![crowbar-net-os_sdn-detail](/openstack/crowbar-net-os_sdn-detail.png)
<br/>network - public
![crowbar-net-public](/openstack/crowbar-net-public.png)
<br/>network detail - public
![crowbar-net-public-detail](/openstack/crowbar-net-public-detail.png)
<br/>network - storage
![crowbar-net-storage](/openstack/crowbar-net-storage.png)
<br/>network detail - storage
![crowbar-net-storage-detail](/openstack/crowbar-net-storage-detail.png)
> chapter 7.5.5 in deploy guide pdf

* init crowbar
<br/>enable internet access (maybe)
```sh
systemctl start postgresql
systemctl start crowbar-init
crowbarctl database -U crowbar -P crowbar create
```
<br/>check log from `/var/log/crowbar/crowbar_init.log`

* Install Admin Node from Web UI
![inst1](/openstack/inst1.png)
<br/>Start installation, and check log from `/var/log/crowbar/install.log`
![inst2](/openstack/inst2.png)
<br/>default username and password is `crowbar` and `crowbar`
![inst3](/openstack/inst3.png)
![inst4](/openstack/inst4.png)

* if you reboot the admin node, double check service as following

```
systemctl start postgresql
systemctl start crowbar
```

# Prepare to setup openstack
## Admin node
* enable all available repos
![repo](/openstack/repo.png)

* prepare for STONITH
  * for physical machine, set "Enable BMC" to True
  ![ipmi1](/openstack/ipmi1.png)
  ![ipmi2](/openstack/ipmi2.png)
  ![ipmi3](/openstack/ipmi3.png)
  * for virtual machine, set "Enable BMC" to False and setup SBD as following
    * create shared block device for quorum
    * install sbd on each vm which will be added to pacemaker cluster
    ```
    zypper install sbd
    ```
    * initiate the block device
    ```
    sbd -d /dev/sdb create
    ```

## 3-party nfs node
* set NFS Server separatly
  * disable firewall
  * enable ```nfsserver```
  ```
  systemctl start nfsserver
  systemctl enable nfsserver
  ```
  * create directory ```mkdir /sharepostgres /sharerabbitmq```
  * config ```/etc/exports```
  ```
  /sharepostgres 10.132.128.0/255.255.128.0(rw,async,no_root_squash,no_subtree_check)
  /sharerabbitmq 10.132.128.0/255.255.128.0(rw,async,no_root_squash,no_subtree_check)
  ```

## New PXE node
* PXE Openstack Nodes

## Existed SLES node
* Convert Existed SUSE Linux to Openstack Node
  * update SLES12-SP2-Pool repo (ignore this step if you clone vm from admin node)
  ```
  scp -rp SLES12-SP2-Pool root@10.132.251.172:/srv/tftpboot/suse-12.2/x86_64/repos/
  ```
  * delete some repos if you clond vm from admin node (repos with pri=98 is added manually.)
  ![repos](/openstack/repos.png)
  * run script
  ```
  wget http://10.132.249.10:8091/suse-12.2/x86_64/crowbar_register
  chmod a+x crowbar_register
  ./crowbar_register
  ```

# Setup Openstack
* enable openstack components - Pacemaker
  * for physical machine
  <br/>set STONITH to IPMI
  ![pacemaker1](/openstack/pacemaker1.png)
  ![pacemaker2](/openstack/pacemaker2.png)
  ![pacemaker3](/openstack/pacemaker3.png)
  ![pacemaker4](/openstack/pacemaker4.png)
  * for virtual machine
  <br/>set STONITH to SBD, using 'generic' watchdog
  ![sbd1](/openstack/sbd1.png)
  <br/>set stable disk path
  ![sbd2](/openstack/sbd2.png)
  ![sbd3](/openstack/sbd3.png)
  ![sbd4](/openstack/sbd4.png)

* enable openstack components - Database
  * using nfs server we created before to put database. Don't using nfs on admin node, due to the config file will be replaced by chef. 
  * enable database using pgsql
  ![db1](/openstack/db1.png)
  ![db2](/openstack/db2.png)
  <br/>you could create database on [x] cluster or [x] single node

* enable openstack components - RabbitMQ
  * using nfs server we created before.
  <br/>you could create RabbitMQ on cluster only
  ![rabbitmq1](/openstack/rabbitmq1.png)
  ![rabbitmq2](/openstack/rabbitmq2.png)

* enable openstack components - Keystone
![open7](/openstack/open7.png)
![open8](/openstack/open8.png)
<br/>you could create it on cluster only

* enable openstack components - Glance
![open9](/openstack/open9.png)
![open10](/openstack/open10.png)
![open11](/openstack/open11.png)
![open12](/openstack/open12.png)
<br/>you could create it on [ ] cluster or [x] single node

