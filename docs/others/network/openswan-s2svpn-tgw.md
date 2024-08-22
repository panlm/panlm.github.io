---
title: openswan-s2svpn-tgw-lab
description: connect to global site-2-site vpn service
created: 2023-01-19 22:00:04.389
last_modified: 2024-08-19
tags:
  - openswan
  - aws/network/tgw
  - aws/network/vpn
---

# openswan-s2svpn-tgw

![[attachments/openswan-s2svpn-tgw/IMG-openswan-s2svpn-tgw.png]]

## aws commercial region
- create customer gateway with your public ip address in your china region
- create tgw
- create attachment for your existed vpc
- create s2svpn connection
    - choose tgw
    - choose customer gw
    - choose static routing
    - keep default for others 
- download vpn configuration
    - vendor: generic
    - platform: generic
    - ikev1
- you need understand how to setup route tables

LEFT IP is public ip of your openswan
RIGHT IP is vpn public ip in your vpn configuration
SECRET in your vpn configuration

## china region
- spin up instance to install openswan (refer: [[../../../../notes/openswan]])
- 中国区域对于 vpn 端口有限制，建议使用global 区域模拟
- openswan 参考配置
    - `/etc/ipsec.d/aws.conf`
```
#
conn Tunnel1
    authby=secret
    auto=start
    type=tunnel
    ikelifetime=8h
    keylife=1h
    phase2alg=aes128-sha1;modp1024
    ike=aes128-sha1;modp1024
    keyingtries=%forever
    keyexchange=ike
    left=%defaultroute
    leftid=<local public ip address>
    leftsubnet=172.31.0.0/16
    right=<vpn public ip address>
    rightsubnet=10.200.0.0/16
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart_by_peer
```
    - `/etc/ipsec.d/aws.secrets`
```
<local public ip address>  <vpn public ip address> : PSK "sharedkey"
```

- check status 
```sh
systemctl enable ipsec
systemctl restart ipsec
ipsec status
```
- need iptables for masq (refer [[../../CLI/linux/linux-cmd#MASQUERADE-|iptables-MASQUERADE]])

## refer
- https://ly.lv/129
- https://kloudvm.medium.com/aws-site-to-site-vpn-using-openswan-ipsec-step-by-step-tutorial-c525a97487a3
- https://aws.amazon.com/blogs/networking-and-content-delivery/centralize-access-using-vpc-interface-endpoints/

![[attachments/openswan-s2svpn-tgw/IMG-openswan-s2svpn-tgw-1.png|800]]


