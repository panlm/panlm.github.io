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
 
* setup IP address manually
  * address
  * gateway
  * dns

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

# crowbar initial
* crowbar settings
<br/>default network settings
![net1](/openstack/net1.png)
<br/>network mode
![net2](/openstack/net2.png)
<br/>repos
![net3](/openstack/net3.png)
<br/>my environment
![net4](/openstack/net4.png)
<br/>network detail - admin
![net5](/openstack/net5.png)
<br/>network detail - bmc
![net6](/openstack/net6.png)
<br/>network detail - bmc_vlan
![net7](/openstack/net7.png)
<br/>network detail - nova_floating
![net8](/openstack/net8.png)
<br/>network detail - public
![net9](/openstack/net9.png)
<br/>network detail - storage
![net10](/openstack/net10.png)
> chapter 7.5.5 in deploy guide pdf

* common error
![error1](/openstack/error1.png)
![error2](/openstack/error2.png)

* init crowbar
```sh
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
  ![open6](/openstack/open6.png)

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

