---
title: github-page-howto
description: github-page-howto
created: 2023-01-02 13:55:05.242
last_modified: 2024-02-16
icon: material/emoticon-happy-outline
status: happy
tags:
  - github
---

# how to put workshop on github 

## obsidian tips
- [[obsidian|obsidian]]

## Material for mkdocs 
https://github.com/squidfunk/mkdocs-material

### review local
```sh
mkdocs serve
```

### status in front matter
- get icons: https://pictogrammers.com/library/mdi/
- copy paste to extra.css

- emoji and icons, search from here
    - https://squidfunk.github.io/mkdocs-material/reference/icons-emojis/#using-emojis

### plugins for mkdocs
- https://github.com/mkdocs/catalog
- For full documentation visit [mkdocs.org](https://www.mkdocs.org)

### enable discussion 
- start from this page ([link](https://squidfunk.github.io/mkdocs-material/setup/adding-a-comment-system/))
- generate config file ([link](https://giscus.app/))
- add `comment: true` to all pages ([link](https://squidfunk.github.io/mkdocs-material/plugins/meta/))

## awesome pages plugin
- https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin

## highlight block
### in material for mkdocs
- https://squidfunk.github.io/mkdocs-material/reference/admonitions/
```
!!! warning "This is a github note"
??? note "right-click & open-in-new-tab: "
```
- sample

!!! warning "This is a github note"

### ~~in hosted on github~~

> [!WARNING] 
> This is a github note

> [!IMPORTANT]  
> Crucial information necessary for users to succeed.

> [!NOTE]  
> Critical content demanding immediate user attention due to potential risks.

> [!example] 

```ad-summary
summary
```

## remove custom domain
- remove `static/CNAME` file
    - this file include line: `aws-labs.panlm.xyz`
- remove custom domain from github `Pages` page
- rename repo name to `git-ghpages`
- change in `config.toml`
    - `baseURL` --> `https://panlm.github.io/git-ghpages/`


## ~~hosted on github page~~
- https://gohugo.io/hosting-and-deployment/hosting-on-github/

![github-page-howto-1.png](../git-attachment/github-page-howto-1.png)

## ~~build local~~ 
- https://aws-samples.github.io/aws-modernization-workshop-sample/20_build/1_setup/

```sh
git submodule init
git submodule update
```

## other :material-ab-testing: :smile:
