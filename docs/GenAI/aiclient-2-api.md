---
title: AIClient-2-API 部署指南
description: AIClient-2-API 部署指南
created: 2026-03-28 20:42:44.649
last_modified: 2026-04-04
type: note
status: myblog
---

# AIClient-2-API 部署指南（Kiro OAuth）

- https://github.com/justlovemaki/AIClient-2-API

## 前置条件

- Ubuntu Linux（已在 22.04 上测试）
- Kiro CLI 已安装并登录（`~/.local/share/kiro-cli/data.sqlite3` 必须存在）

## 第一步：安装 Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

## 第二步：克隆仓库

```bash
cd /home/ubuntu
git clone https://github.com/justlovemaki/AIClient-2-API.git
```

## 第三步：提取 Kiro 凭据

脚本 `/home/ubuntu/kiro-oauth-get-cred.py` 从 Kiro CLI 的本地 SQLite 数据库中读取 `refreshToken`、`clientId`、`clientSecret`，输出凭据文件：

```python
import sqlite3, json, os

db = os.path.expanduser("~/.local/share/kiro-cli/data.sqlite3")
conn = sqlite3.connect(db)
cursor = conn.cursor()

cursor.execute("SELECT value FROM auth_kv WHERE key='kirocli:odic:token'")
token = json.loads(cursor.fetchone()[0])

cursor.execute("SELECT value FROM auth_kv WHERE key='kirocli:odic:device-registration'")
reg = json.loads(cursor.fetchone()[0])

conn.close()

creds = {
    "accessToken": token["access_token"],
    "refreshToken": token["refresh_token"],
    "expiresAt": token["expires_at"],
    "authMethod": "builder-id",
    "idcRegion": token.get("region", "us-east-1"),
    "clientId": reg["client_id"],
    "clientSecret": reg["client_secret"]
}

out = os.path.expanduser("~/kiro_credentials.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(creds, f, indent=2)

print(f"Done: {out}")
```

执行：

```bash
python3 /home/ubuntu/kiro-oauth-get-cred.py
```

**重要**：`authMethod` 必须设为 `builder-id`，不能用 `social`。原因是 Kiro CLI 数据库中没有 `profileArn` 字段，而 `social` 模式请求 API 时需要携带 `profileArn`，为空会导致 400 错误。Kiro CLI 注册了 OIDC 设备客户端（带 `clientId`/`clientSecret`），可以走 `builder-id`（IDC）认证流程正常工作。

## 第四步：创建配置文件

```bash
cd /home/ubuntu/AIClient-2-API/docker
mkdir -p configs
```

复制凭据：

```bash
cp /home/ubuntu/kiro_credentials.json configs/kiro-auth-token.json
```

创建 `configs/config.json`：

```json
{
    "REQUIRED_API_KEY": "123456",
    "SERVER_PORT": 3000,
    "HOST": "0.0.0.0",
    "MODEL_PROVIDER": "claude-kiro-oauth",
    "PROVIDER_POOLS_FILE_PATH": "configs/provider_pools.json",
    "REQUEST_MAX_RETRIES": 3,
    "REQUEST_BASE_DELAY": 1000,
    "CRON_NEAR_MINUTES": 1,
    "CRON_REFRESH_TOKEN": true,
    "MAX_ERROR_COUNT": 3,
    "LOG_ENABLED": true,
    "LOG_OUTPUT_MODE": "all",
    "LOG_LEVEL": "info",
    "LOG_DIR": "logs",
    "LOG_MAX_FILE_SIZE": 10485760,
    "LOG_MAX_FILES": 10,
    "TLS_SIDECAR_ENABLED": false
}
```

创建 `configs/provider_pools.json`：

```json
{
  "claude-kiro-oauth": [
    {
      "customName": "Kiro OAuth 节点1",
      "KIRO_OAUTH_CREDS_FILE_PATH": "configs/kiro-auth-token.json",
      "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "checkModelName": "claude-haiku-4-5",
      "checkHealth": false,
      "isHealthy": true,
      "isDisabled": false,
      "lastUsed": null,
      "usageCount": 0,
      "errorCount": 0,
      "lastErrorTime": null
    }
  ]
}
```

## 第五步：启动服务

```bash
cd /home/ubuntu/AIClient-2-API/docker
sudo docker compose up -d
```

## 第六步：验证

测试 API 调用：

```bash
curl -s http://localhost:3000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 123456" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "你好"}],
    "max_tokens": 50,
    "stream": false
  }'
```

## API 端点

| 协议 | 地址 |
|------|------|
| OpenAI 兼容 | `http://localhost:3000/v1/chat/completions` |
| Claude 兼容 | `http://localhost:3000/v1/messages` |
| Web 管理界面 | `http://localhost:3000/`（密码：`admin123`） |

## 可用模型

`claude-opus-4-6`、`claude-sonnet-4-6`、`claude-opus-4-5`、`claude-sonnet-4-5`、`claude-haiku-4-5`

## Token 刷新机制

AIClient-2-API 内部自动处理 token 刷新（`CRON_REFRESH_TOKEN: true`）。它使用凭据文件中的 `refreshToken` + `clientId` + `clientSecret` 向 `oidc.us-east-1.amazonaws.com/token` 请求新的 `accessToken`，在当前 token 过期前自动完成续期。

### 手动触发内部刷新

如果需要立即刷新 token，可以执行容器内的刷新脚本：

```bash
sudo docker exec aiclient2api node src/scripts/kiro-idc-token-refresh.js configs/kiro-auth-token.json
```

该脚本读取 `configs/kiro-auth-token.json` 中的 `refreshToken` + `clientId` + `clientSecret`，向 AWS OIDC 端点请求新的 `accessToken`（有效期 1 小时），并将结果保存到容器内。

### 手动同步 Kiro CLI 凭据

如果重新登录了 Kiro CLI，需要重新提取凭据并同步：

```bash
python3 /home/ubuntu/kiro-oauth-get-cred.py
cp /home/ubuntu/kiro_credentials.json /home/ubuntu/AIClient-2-API/docker/configs/kiro-auth-token.json
sudo docker compose restart
```


