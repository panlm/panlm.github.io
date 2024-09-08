---
title: python-cmd
created: 2022-12-05 10:37:03.829
last_modified: 2024-02-06
tags:
  - python
---

# python-cmd

## python38 on amazon linux 
### yum
```sh
sudo yum install -y amazon-linux-extras
amazon-linux-extras | grep -i python
sudo amazon-linux-extras enable python3.8
sudo yum install -y python3.8 python38-devel

```

### compile
[Install Python 3.8 on CentOS 7 / CentOS 8 | ComputingForGeeks](https://computingforgeeks.com/how-to-install-python-3-on-centos/)

```sh
./configure --enable-optimizations --with-ensurepip=install
make altinstall
```

## venv
```sh
python3 -m venv venv
source ./venv/bin/activate
pip install --upgrade pip

```

## http.server

!!! danger "unencrypted traffic"

```sh
python -m http.server -d output/html 80
python3 -m http.server 80 &
```

## refer
- [[python-sample-phase-json]]
- [[python-sample-to-create-upload]]
- 


