---
title: pluto
description: Kubernetes 升级小工具
created: 2023-05-18 09:40:00.214
last_modified: 2024-01-13
tags:
  - kubernetes
---

# pluto-cmd

## scan
- scan folder
```sh
pluto detect-files -d .
```
- scan helm
```sh
pluto detect-helm -o wide
```


## install
### asdf
- https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies
```sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bash_profile
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bash_profile
source ~/.bash_profile
```

### pluto
- https://pluto.docs.fairwinds.com/installation/#asdf
```sh
asdf plugin-add pluto
lastest_version=$(asdf list-all pluto |tail -n 1)
asdf install pluto ${lastest_version}
asdf local pluto ${lastest_version}
pluto version
```






