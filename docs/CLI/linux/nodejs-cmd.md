---
title: nodejs-cmd
description: 
created: 2024-03-04 08:53:55.117
last_modified: 2024-03-04
tags:
  - nodejs
---

# nodejs-cmd

## install
https://github.com/nvm-sh/nvm/releases 
```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

source ~/.bashrc
nvm install 20
# nvm use 20
node -v
npm -v
```
- 16 works on amazon linux 2 (has glibc 2.26)
- 18/20 does not work on AL2 (no glibc 2.27/2.28)
- 20 works on ubuntu 22

### on al2023
https://linux.how2shout.com/how-to-install-nodejs-20-x-on-amazon-linux-2023/
```sh
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
dnf update
dnf install -y nodejs20
```

### on ubuntu
https://joshtronic.com/2023/04/23/how-to-install-nodejs-20-on-ubuntu-2004-lts/

## H1
https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-typescript.html
```sh
npm -g install typescript
```

To update your project's NPM dependencies to the latest permitted version according to the rules you specified in `package.json`:
```sh
npm update
```

```sh
# Install the latest version of everything that matches the ranges in 'package.json'
npm install

# Install the same exact dependency versions as recorded in 'package-lock.json'
npm ci
```








