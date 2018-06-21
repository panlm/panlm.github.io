



* disable firewall
```bash
systemctl stop SuSEfirewall2
systemctl stop SuSEfirewall2_init
systemctl disable SuSEfirewall2
systemctl disable SuSEfirewall2_init
```

* cp media to local
```
mount SLE-12-SP2-Server-DVD-x86_64-GM-DVD1.iso /mnt
rsync -avP /mnt/ /srv/tftpboot/suse-12.2/x86_64/install/
umount /mnt

mount SUSE-OPENSTACK-CLOUD-7-x86_64-GM-DVD1.iso /mnt
rsync -avP /mnt/ /srv/tftpboot/suse-12.2/x86_64/repos/Cloud/
umount /mnt
```








