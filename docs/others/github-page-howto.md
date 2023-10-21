---
title: "github-page-howto"
description: "github-page-howto"
chapter: true
weight: 99999999
created: 2023-01-02 13:55:05.242
last_modified: 2023-01-02 13:55:05.242
tags: 
- github 
---

# how to put workshop on github 

- [build local](#build-local)
- [hosted on github page](#hosted-on-github-page)


## build local
- https://aws-samples.github.io/aws-modernization-workshop-sample/20_build/1_setup/

```sh
git submodule init
git submodule update
```


## hosted on github page
- https://gohugo.io/hosting-and-deployment/hosting-on-github/

![github-page-howto-1.png](github-page-howto-1.png)


## remove custom domain

- remove `static/CNAME` file
    - this file include line: `aws-labs.panlm.xyz`
- remove custom domain from github `Pages` page
- rename repo name to `git-ghpages`
- change in `config.toml`
    - `baseURL` --> `https://panlm.github.io/git-ghpages/`

