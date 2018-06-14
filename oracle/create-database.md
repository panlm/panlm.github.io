
# add disks to ASM
using `asmca` to create additional asm diskgroup.
* create DATA using 10x 100GB vmdk
* create ARCH using 2x 100GB vmdk
* create REDO using 3x 10GB vmdk
set AU (Allocated Unit) = 1 MB for each diskgroup

# create database
```
dbca
```
![pic21](/oracle/pic21.png)
![pic22](/oracle/pic22.png)
![pic23](/oracle/pic23.png)
![pic24](/oracle/pic24.png)
![pic25](/oracle/pic25.png)
![pic26](/oracle/pic26.png)
![pic27](/oracle/pic27.png)
password: oracle
![pic28](/oracle/pic28.png)
![pic29](/oracle/pic29.png)
![pic30](/oracle/pic30.png)
password: oracle
![pic31](/oracle/pic31.png)
![pic32](/oracle/pic32.png)
![pic33](/oracle/pic33.png)
if you set percentage to larger number, and get some error. please remount your /shm filesystem
1. edit /etc/fstab to add “defaults,size=81920m “ to shm
2. "mount -o remount" to enable this tmpfs settingts.
![pic34](/oracle/pic34.png)
![pic35](/oracle/pic35.png)
ask customer to confirm language settings (character set)
![pic36](/oracle/pic36.png)
![pic37](/oracle/pic37.png)
![pic38](/oracle/pic38.png)
![pic39](/oracle/pic39.png)
![pic40](/oracle/pic40.png)
