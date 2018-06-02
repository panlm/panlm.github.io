

```conf
#cloud-config
disable_root: False
ssh_enabled: True
ssh_pwauth: True
runcmd:
- systemctl restart sshd
- usermod -s /bin/bash root
- passwd -u root
- echo 'nutanix/4u' |passwd --stdin root
- chmod 555 /
- augtool --autosave "set /files/etc/ssh/sshd_config/PermitRootLogin yes"
- augtool --autosave "set /files/etc/ssh/sshd_config/PasswordAuthentication yes"
users:
  - name: centos
    ssh-authorized-keys:
      - @@{INSTANCE_PUBLIC_KEY}@@
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```

```conf
# following line is identical
# ssh_pwauth: True
# runcmd:
# - augtool --autosave "set /files/etc/ssh/sshd_config/PasswordAuthentication yes"
```

# reference
- augeas
    https://blog.whe.me/post/cloud-init-configurations.html
    http://frederic-wou.net/augeas-instaalion-on-centos-7-1/




