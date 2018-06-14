


```
#remove vmnic0 from vswitch0
esxcfg-vswitch -U vmnic0 vSwitch0
#create vswitch1 and make vmnic0 as uplink
esxcfg-vswitch -a vSwitch1
esxcfg-vswitch -L vmnic0 vSwitch1

#add port group & vmkernel to vSwitch1
esxcfg-vswitch --add-pg='145.145' vSwitch1

esxcfg-vswitch -p '145.145' -v 3 vSwitch1
esxcfg-vswitch -A 'management' vSwitch1
esxcfg-vswitch -p management -v 3 vSwitch1
esxcfg-vmknic -a -i DHCP -p management
esxcfg-vmknic -e management
esxcli network ip interface ipv4 set --interface-name=vmk2 --ipv4=145.145.101.201 --netmask=255.255.0.0 --type=static
esxcli network ip interface tag add -i vmk2 -t Management
esxcfg-route 145.145.0.11
```



