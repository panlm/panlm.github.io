**Thanks  _CunLei.Zhang@nutanix.com_  for reviewing this doc!**

---

# Two Nodes Oracle RAC
## installing Grid
![pic2](/oracle/pic2.png)

![pic3](/oracle/pic3.png)

choose typical installation

![pic4](/oracle/pic4.png)

click setup and test

![pic5](/oracle/pic5.png)
password is oracle, select asmadmin (same with the groupname you defined in 99-oracle-rawdevices.rules)

![pic6](/oracle/pic6.png)
Create a "CRS" asm diskgroup when install, using quorum disk.

![pic7](/oracle/pic7.png)

![pic8](/oracle/pic8.png)

## installing oracle
![pic11](/oracle/pic11.png)
![pic12](/oracle/pic12.png)
![pic13](/oracle/pic13.png)
![pic14](/oracle/pic14.png)
![pic15](/oracle/pic15.png)
![pic16](/oracle/pic16.png)
![pic17](/oracle/pic17.png)
![pic18](/oracle/pic18.png)

# Single Node Oracle (From CunLei, Thanks)
## installing Grid
![s01.png](/oracle/cunlei/s01.png)
![s02.png](/oracle/cunlei/s02.png)
![s03.png](/oracle/cunlei/s03.png)
![s04.png](/oracle/cunlei/s04.png)
![s05.png](/oracle/cunlei/s05.png)
![s06.png](/oracle/cunlei/s06.png)
![s07.png](/oracle/cunlei/s07.png)
![s08.png](/oracle/cunlei/s08.png)
![s09.png](/oracle/cunlei/s09.png)
![s10.png](/oracle/cunlei/s10.png)
![s11.png](/oracle/cunlei/s11.png)
![s12.png](/oracle/cunlei/s12.png)
![s13.png](/oracle/cunlei/s13.png)

## create asm
using `asmca` to create additional asm diskgroup.
* create DATA using 10x 100GB vmdk
* create ARCH using 2x 100GB vmdk
* create REDO using 3x 10GB vmdk
set AU (Allocated Unit) = 1 MB for each diskgroup

![t01.png](/oracle/cunlei/t01.png)

![t02.png](/oracle/cunlei/t02.png)
选择External方式，针对所有非仲裁的数据DiskGroup。仲裁DiskGroup建议使用High。

![t03.png](/oracle/cunlei/t03.png)

## installing oracle
![u01.png](/oracle/cunlei/u01.png)
![u02.png](/oracle/cunlei/u02.png)
![u03.png](/oracle/cunlei/u03.png)
![u04.png](/oracle/cunlei/u04.png)
![u05.png](/oracle/cunlei/u05.png)
![u06.png](/oracle/cunlei/u06.png)
![u07.png](/oracle/cunlei/u07.png)
![u08.png](/oracle/cunlei/u08.png)
![u09.png](/oracle/cunlei/u09.png)
![u10.png](/oracle/cunlei/u10.png)
![u11.png](/oracle/cunlei/u11.png)
![u12.png](/oracle/cunlei/u12.png)
![u13.png](/oracle/cunlei/u13.png)

# Errors
## got error if you did not install `compat-libcap1`
if you miss `compat-libcap1`, you will get this error:
![err1](/oracle/err1.png)

run following and re-run root.sh
```
/u01/app/11.2.0/grid/crs/install/roothas.pl -deconfig -force -verbose
```










---

*Author: Leiming.Pan@nutanix.com*<br/>
*Last update: 22 Jun, 2018*

