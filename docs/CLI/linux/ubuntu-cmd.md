---
title: ubuntu
description: 
created: 2023-01-23 13:08:13.012
last_modified: 2024-02-09
tags:
  - ubuntu
---

## install missing kernel module
```
sudo apt install linux-modules-extra-`uname -r`
```

## dpkg
```sh
dpkg -l |grep pkg_name
```

### search file belongs to
```sh
dpkg -S /bin/ls
```

### get all files the package installed 
```sh
dpkg-query -L <package_name>
```

### get all files in deb package  
```sh
dpkg-deb -c <package_name.deb>
```


## apt-file -- find pkg provide files
```sh
sudo apt-get install apt-file
sudo apt-file update
apt-file search  a.h
```

## fixed specific version
```sh
sudo apt install terraform=1.5.7-1
sudo apt-mark hold terraform
```


## install develop packages
```sh
sudo apt-get install build-essential
```
类似 `yum -y groupinstall "Development Tools"`

## install docker
https://docs.docker.com/engine/install/ubuntu/
```
```

