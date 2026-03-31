---
title: 从-Kiro-CLI-提取凭据文件
description: 从-Kiro-CLI-提取凭据文件
created: 2026-03-28 20:42:44.649
last_modified: 2026-03-28
tags: 
  - draft
permalink: 从-Kiro-CLI-提取凭据文件
---

# 从 Kiro CLI 提取凭据文件

## 前提

- 已通过 `kiro-cli` 登录成功。
- on ubuntu linux
- clone https://github.com/justlovemaki/AIClient-2-API

## 提取命令

### mac

- on mac: check ~/.aws/sso/cache

### ubuntu

```bash
python3 << 'EOF'
import sqlite3, json, os

db = os.path.expanduser("~/.local/share/kiro-cli/data.sqlite3")
conn = sqlite3.connect(db)
cursor = conn.cursor()

# 获取 token
cursor.execute("SELECT value FROM auth_kv WHERE key='kirocli:odic:token'")
token = json.loads(cursor.fetchone()[0])

# 获取 clientId/clientSecret
cursor.execute("SELECT value FROM auth_kv WHERE key='kirocli:odic:device-registration'")
reg = json.loads(cursor.fetchone()[0])

conn.close()

creds = {
    "accessToken": token["access_token"],
    "refreshToken": token["refresh_token"],
    "profileArn": "",
    "expiresAt": token["expires_at"],
    "authMethod": "social",
    "provider": "Google",
    "region": token.get("region", "us-east-1"),
    "clientId": reg["client_id"],
    "clientSecret": reg["client_secret"]
}

out = os.path.expanduser("~/kiro_credentials.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(creds, f, indent=2)

print(f"Done: {out}")
EOF
```

## 原理

Kiro CLI 登录后将 token 存储在 SQLite 数据库中：

- 数据库路径：`~/.local/share/kiro-cli/data.sqlite3`
- 表：`auth_kv`
- 关键记录：
  - `kirocli:odic:token` → access_token、refresh_token、expires_at、region
  - `kirocli:odic:device-registration` → client_id、client_secret

脚本将这些字段转换为 AIClient-2-API 所需的格式并写入 JSON 文件。

## 启动服务

```bash
cd ~/AIClient-2-API
node src/core/master.js  --host 127.0.0.1 --port 3000 --model-provider claude-kiro-oauth --kiro-oauth-creds-file ~/kiro_credentials.json
```

## for opencode

```
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "claude-proxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Claude Proxy",
      "options": {
        "baseURL": "http://localhost:3000/claude-kiro-oauth/v1",
        "apiKey": "xxxxxx"
      },
      "models": {
        "claude-opus-4-6": {
          "name": "Claude Opus 4.6"
        }
      }
    }
  },
  "model": "claude-proxy/claude-opus-4-6"
}
```


