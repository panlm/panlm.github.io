

# create vswitch on 1Gb interface
```
#remove vmnic0 from vswitch0
esxcfg-vswitch -U vmnic0 vSwitch0

#create vswitch1 and make vmnic0 as uplink
esxcfg-vswitch -a vSwitch1
esxcfg-vswitch -L vmnic0 vSwitch1

#add port group to vSwitch1 and assign vlan id
esxcfg-vswitch --add-pg='145.145' vSwitch1
esxcfg-vswitch -p '145.145' -v 3 vSwitch1

# add vmkernel to vSwitch1
esxcfg-vswitch -A 'management' vSwitch1
esxcfg-vswitch -p management -v 3 vSwitch1
esxcfg-vmknic -a -i DHCP -p management
esxcfg-vmknic -e management
esxcli network ip interface ipv4 set --interface-name=vmk2 --ipv4=145.145.101.201 --netmask=255.255.0.0 --type=static

# allow management flow on this vmkernel
esxcli network ip interface tag add -i vmk2 -t Management

# set defaut gateway
esxcfg-route 145.145.0.11
```

# shutdown cvm for adding nic and poweron
```
vim-cmd vmsvc/power.shutdown 1
```

> refer
```
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/power.getstate <id>
vim-cmd vmsvc/power.shutdown <id>
vim-cmd vmsvc/devices.createnic 1 9 number vmxnet3 '145.145'
vim-cmd vmsvc/get.networks 1
```

# set ipmi
```
/ipmitool lan set 1 ipsrc static
/ipmitool lan set 1 ipaddr 145.145.101.210
/ipmitool lan set 1 netmask 255.255.0.0
/ipmitool lan set 1 defgw ipaddr 145.145.0.11
/ipmitool lan set 1 vlan id 3
```

