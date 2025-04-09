---
title: Configure MCP Server in Cline for SearxNG
description: 在 Cline 中配置 SearxNG MCP Server 实现搜索功能
created: 2025-04-08 21:21:49.447
last_modified: 2025-04-08
tags:
  - llm
status: myblog
---

# SearxNG MCP Server for Cline

## Build your own SearxNG

- Install docker & docker-compose on your linux
- Clone https://github.com/searxng/searxng-docker
- Edit .env
```
SEARXNG_HOSTNAME=www.hostname.domainname
LETSENCRYPT_EMAIL=mailbox@example.com
```
- Edit [searxng/settings.yml](https://github.com/searxng/searxng-docker/blob/master/searxng/settings.yml) 
```
# see https://docs.searxng.org/admin/settings/settings.html#settings-use-default-settings
use_default_settings: true
server:
  # base_url is defined in the SEARXNG_BASE_URL environment variable, see .env and docker-compose.yml
  secret_key: "xxxx"  # change this!
  limiter: false  # can be disabled for a private instance
  image_proxy: true
ui:
  static_use_hash: true
redis:
  url: redis://redis:6379/0
search:
  # remove format to deny access, use lower case.
  # formats: [html, csv, json, rss]
  formats:
    - html
    - json # <-- MCP need this format
```
- First time to start containers, need change docker-compose.yaml
```
searxng:
  ...
  # cap_drop:
  #   - ALL
  ...
```
- Start docker for searxng, caddy, redis, etc.
```
docker-compose up -d
```
- Add A record in route53 to point the public ip of EC2
    - Open 80, 443 port for this EC2
- Access your www.hostname.domainname

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline.png]]


## MCP for searxng
- you need node 20/22 on you laptop ([[../CLI/linux/nodejs-cmd|nodejs-cmd]])
- clone https://github.com/ihor-sokoliuk/mcp-searxng
- build it
```sh
npm run build
ls ./dist/index.js

```
- MCP settings in Cline
```json
{
  "mcpServers": {
    "searxng": {
      "timeout": 60,
      "command": "node",
      "args": [
        "/full/path/to/dist/index.js"
      ],
      "env": {
        "SEARXNG_URL": "https://www.hostname.domainname"
      },
      "transportType": "stdio"
    }
  }
}
```


## refer
https://docs.searxng.org/admin/installation-searxng.html#configuration

### what is mcp

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-6.png]]

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-5.png]]

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-1.png]]

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-4.png]]

### compare to traditional

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-2.png]]

### workflow

![[attachments/searxng-mcp-server-for-cline/IMG-searxng-mcp-server-for-cline-3.png]]

### another sample
```json
{
  "mcpServers": {
    "searxng": {
      "timeout": 60,
      "command": "uvx",
      "args": [
        "mcp-searxng"
      ],
      "env": {
        "SEARXNG_URL": "https://www.hostname.domainname"
      },
      "transportType": "stdio"
    }
  }
}
```


