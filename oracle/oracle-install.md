

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

# Single Node Oracle
## installing Grid
```
```

## installing oracle
```
```

# Errors
## got error if you did not install `compat-libcap1`
if you miss `compat-libcap1`, you will get this error:
![err1](/oracle/err1.png)

run following and re-run root.sh
```
/u01/app/11.2.0/grid/crs/install/roothas.pl -deconfig -force -verbose
```






