

```
#cloud-config
users:
  - name: centos
    ssh-authorized-keys:
      - @@{INSTANCE_PUBLIC_KEY}@@
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```


