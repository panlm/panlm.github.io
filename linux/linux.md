# certification

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

