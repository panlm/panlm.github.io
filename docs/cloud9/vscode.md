---
title: vscode
description: 
created: 2024-08-19 09:36:24.009
last_modified: 2024-08-19
tags:
  - draft
---

# vscode

## install on ubuntu
- https://code.visualstudio.com/docs/setup/linux
```sh
wget -O '/tmp/linux-deb-x64.deb'  'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
sudo apt install /tmp/linux-deb-x64.deb -f

```

### systemctl
```sh
sudo tee /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=Start code server

[Service]
ExecStart=/usr/bin/code serve-web --port 8080 --host 127.0.0.1 --without-connection-token
#ExecStart=/usr/bin/code serve-web --port 8080 --host 0.0.0.0 --connection-token token-string 
Restart=always
Type=simple
User=ubuntu

[Install]
WantedBy = multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now code-server
sudo systemctl restart code-server

```

### access web ui with token
```
http://public-ip-address:8080/?tkn=token-string
```

### add basic auth
- refer: [[git/git-mkdocs/others/network/caddy#basic-http-auth-|basic auth]]


## extension
### continue
integrate with brconnector ([link](https://docs.continue.dev/reference/Model%20Providers/openai))

