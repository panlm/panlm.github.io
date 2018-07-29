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

# crowbar initial
* crowbar settings
![pic1](/openstack/1.png)

![pic2](/openstack/2.png)

![pic3](/openstack/3.png)

![pic4](/openstack/4.png)

![pic5](/openstack/5.png)

![pic6](/openstack/6.png)

> chapter 7.5.5 in deploy guide pdf

* common error
![error1](/openstack/error1.png)
![error2](/openstack/error2.png)

* init crowbar
```sh
systemctl start crowbar-init
crowbarctl database -U crowbar -P crowbar create
```
check log from `/var/log/crowbar/crowbar_init.log`

* Install Admin Node from Web UI
![inst1](/openstack/inst1.png)

```
systemctl start postgresql
systemctl start crowbar
```

![inst2](/openstack/inst2.png)

check log from `/var/log/crowbar/install.log`

![inst3](/openstack/inst3.png)

default username and password is `crowbar` and `crowbar`

![inst4](/openstack/inst4.png)

# Prepare to setup openstack
* add all package to repo on crowbar admin node

* set ipmi
![ipmi](/openstack/ipmi.png)

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

* PXE Openstack Nodes

* Convert Existed SUSE Linux to Openstack Node
  * update SLES12-SP2-Pool repo
  ```
  scp -rp SLES12-SP2-Pool root@10.132.251.172:/srv/tftpboot/suse-12.2/x86_64/repos/
  ```
  * run script
  ```
  wget http://10.132.249.10:8091/suse-12.2/x86_64/crowbar_register
  chmod a+x crowbar_register
  ./crowbar_register
  ```
  * enable all available repos
  ![repo](/openstack/repo.png)
  * enable openstack components - Pacemaker
  ![open1](/openstack/open1.png)
  ![open2](/openstack/open2.png)
  ![open3](/openstack/open3.png)
  * enable openstack components - Database
    * using nfs we created before to put database. Don't using nfs on admin node, due to the config file will be replaced by chef. 
    * enable database using pgsql
    ![open4](/openstack/open4.png)
    ![open5](/openstack/open5.png)
    > you could create it on [x] cluster or [x] single node
  * enable openstack components - RabbitMQ
    * using nfs we created before. 
    * enable RabbitMQ on cluster only
    ![open6](/openstack/open6.png)
  * enable openstack components - Keystone
  ![open7](/openstack/open7.png)
  ![open8](/openstack/open8.png)
  > you could create it on cluster only
  * enable openstack components - Glance
  ![open9](/openstack/open9.png)
  ![open10](/openstack/open10.png)
  ![open11](/openstack/open11.png)
  ![open12](/openstack/open12.png)
  > you could create it on [ ] cluster or [x] single node

 










