---
title: github-page-howto
description: github-page-howto
created: 2023-01-02 13:55:05.242
last_modified: 2023-11-03 15:49:55.785
tags:
  - github
---

> [!WARNING] This is a github note

# how to put workshop on github 

## build local

- https://aws-samples.github.io/aws-modernization-workshop-sample/20_build/1_setup/

```sh
git submodule init
git submodule update
```


## hosted on github page

- https://gohugo.io/hosting-and-deployment/hosting-on-github/

![github-page-howto-1.png](../git-attachment/github-page-howto-1.png)


## remove custom domain

- remove `static/CNAME` file
    - this file include line: `aws-labs.panlm.xyz`
- remove custom domain from github `Pages` page
- rename repo name to `git-ghpages`
- change in `config.toml`
    - `baseURL` --> `https://panlm.github.io/git-ghpages/`

## awesome pages plugin

- https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin


## highlight block
### in github

> [!WARNING] 
> This is a github note

> [!IMPORTANT]  
> Crucial information necessary for users to succeed.

> [!NOTE]  
> Critical content demanding immediate user attention due to potential risks.

### in material mkdocs

- https://squidfunk.github.io/mkdocs-material/reference/admonitions/
```
!!! warning "This is a github note"
```

## plugins for mkdocs

- https://github.com/mkdocs/catalog
- For full documentation visit [mkdocs.org](https://www.mkdocs.org)



