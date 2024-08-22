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
wget -O 'linux-deb-x64.deb'  'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
sudo apt install ./linux-deb-x64.deb -f

```

### systemctl
```sh
sudo tee /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=Start code server

[Service]
ExecStart=/usr/bin/code serve-web --port 8080 --host 127.0.0.1 --without-connection-token
Restart=always
Type=simple
User=ec2-user

[Install]
WantedBy = multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now code-server
sudo systemctl start code-server



```


