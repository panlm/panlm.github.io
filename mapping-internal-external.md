








# script to keep mapping

```bash
#!/bin/bash
host1=10.21.104.51
host2=10.21.104.56
host3=10.21.104.57
host4=10.21.104.58
host5=10.21.104.59
host6=10.21.104.60

for i in 1 2 3 4 5 6 ; do
    str="host$i"
    ps -ef |grep -v grep |grep -w 339$i
    if [ $? -eq 1 ]; then
        ssh -i /root/id_rsa -TfnN -R 0.0.0.0:339$i:${!str}:3389 ubuntu@13.124.175.242
    fi
done
```

