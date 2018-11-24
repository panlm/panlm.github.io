# 相关内容
* [cloud-init](cloud-init)
* [some packages](necessary-pkg-centos)
* [iptables](iptables)
* [mapping-internal-external](mapping-internal-external)



# 加密原理

```
          +------------+                           +------------+
          | Server CA  |                           | Client CA  |
          +-+----------+                           +-+----------+
            ^                                        ^
            |                                        |
            | Can I trust server.pem?                | Can I trust client.pem?
            |                                        |
            |                        tcp port :6443  |
        +---+-----------+   client.pem           +---+-----------+
        |               | +--------------------> |               |
        |    kubectl    |                        |   API Server  |
        |               | <--------------------+ |               |
        +---------------+      server-cert.pem   +---------------+
```

公钥加密数据

私钥解密数据

