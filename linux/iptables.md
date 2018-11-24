

# NAT

```bash
iptables -t nat -A POSTROUTING -s 10.21.104.128/25 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.21.104.0/25 -o eth1 -j MASQUERADE
```
