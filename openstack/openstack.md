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

* setup IP address manually
    * address
    * gateway
    * dns

* crowbar settings
![pic1](/openstack/1.png)

![pic2](/openstack/2.png)

> chapter 7.5.5 in deploy guide pdf

* init crowbar
```sh
systemctl start crowbar-init
crowbarctl database -U crowbar -P crowbar create
```
check log from `/var/log/crowbar/crowbar_init.log`

* Web UI






