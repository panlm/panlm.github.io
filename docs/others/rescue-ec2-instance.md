---
title: Rescue EC2 Instance
description: 恢复 EC2 实例步骤
created: 2023-01-20 10:54:51.597
last_modified: 2023-12-24
tags:
  - aws/compute/ec2
---
# Rescue EC2 Instance

- https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-boot-issues/

![[../git-attachment/rescue-ec2-instance-png-1.png]]

![[../git-attachment/rescue-ec2-instance-png-2.png]]

## ssh to rescue

```sh
sudo su -

lsblk
rescuedev=/dev/xvdf1

rescuemnt=/mnt
mkdir -p $rescuemnt
mount $rescuedev $rescuemnt
for i in proc sys dev run; do mount --bind /$i $rescuemnt/$i ; done
chroot $rescuemnt
```

- refer: [[../CLI/linux/linux-cmd#xfs-mount-]]

## umount

```sh
exit

umount $rescuemnt/{proc,sys,dev,run,}

```


![[../git-attachment/rescue-ec2-instance-png-3.png]]


## refer

automation runbook
- https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-ec2rescue.html

