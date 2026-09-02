---
title: AIClient-2-API 部署指南
description: AIClient-2-API 部署指南
created: 2026-03-28 20:42:44.649000
last_modified: 2026-08-27
type: note
status: myblog
permalink: git-mkdocs/gen-ai/aiclient-2-api
---

# AIClient-2-API 部署指南（Kiro OAuth）

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

脚本 `/home/ubuntu/kiro-oauth-get-cred.py` 从 Kiro CLI 的本地 SQLite 数据库中读取 `refreshToken`、`clientId`、`clientSecret`，输出凭据文件。

**Kiro CLI 数据库路径**：

| 操作系统   | 路径                                              |
| ------- | ----------------------------------------------- |
| Linux   | `~/.local/share/kiro-cli/data.sqlite3`          |
| macOS   | `~/Library/Application Support/kiro-cli/data.sqlite3` |

凭据存在 `auth_kv` 表里，两个 key：

| key                                  | 提供字段                                          |
| ------------------------------------ | --------------------------------------------- |
| `kirocli:odic:token`                 | `access_token` / `refresh_token` / `expires_at` |
| `kirocli:odic:device-registration`   | `client_id` / `client_secret`                  |

> **不要从 `~/.aws/sso/cache/` 取凭据**。那里的 `kiro-auth-token.json` / `kiro-auth-token-cli.json` 是**陈旧快照**，即使 `kiro-cli whoami` 显示已登录，这些文件里的 `expiresAt` 也可能早已过期（实测差了 6 天）。sqlite 的 `auth_kv` 才是活数据。
>
> macOS 上 Keychain 里确实有同名条目（`kirocli:odic:token`、`kirocli:odic:device-registration`），但读它会弹系统授权框，直读 sqlite 更省事。

```python
import sqlite3, json, os

# Linux
# db = os.path.expanduser("~/.local/share/kiro-cli/data.sqlite3")
# macOS
# db = os.path.expanduser("~/Library/Application Support/kiro-cli/data.sqlite3")

# 自动检测平台
import platform
if platform.system() == "Darwin":
    db = os.path.expanduser("~/Library/Application Support/kiro-cli/data.sqlite3")
else:
    db = os.path.expanduser("~/.local/share/kiro-cli/data.sqlite3")
conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)  # 只读打开，避免锁住 kiro-cli 正在用的库
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
os.chmod(out, 0o600)  # 内含明文 refreshToken/clientSecret

print(f"Done: {out}")
```

> 输出文件含明文 `refreshToken` + `clientSecret`，导入完成后建议 `shred -u ~/kiro_credentials.json` 删掉。

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
    "REQUIRED_API_KEY": "<your-api-key>",
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
curl -s http://localhost:3000/claude-kiro-oauth/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-api-key>" \
  -d '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "你好"}],
    "max_tokens": 50,
    "stream": false
  }'
```

## API 端点

由于使用 Kiro OAuth 作为 provider，URL 路径需要带 `claude-kiro-oauth` 前缀进行显式路由：

| 协议        | 地址                                                            |     |
| --------- | ------------------------------------------------------------- | --- |
| OpenAI 兼容 | `http://localhost:3000/claude-kiro-oauth/v1/chat/completions` |     |
| Claude 兼容 | `http://localhost:3000/claude-kiro-oauth/v1/messages`         |     |
| Web 管理界面  | `http://localhost:3000/`（密码：`<your-password>`）                |     |

> **说明**：如果 `config.json` 中 `MODEL_PROVIDER` 已设为 `claude-kiro-oauth`，不带前缀的 `/v1/chat/completions` 也会默认走 Kiro OAuth。带前缀是显式路由，适合多 provider 共存场景。

## Proxy 配置

如果服务器无法直接访问 AWS OIDC 端点或其他外部服务，可以配置代理。

在 `configs/config.json` 中添加以下字段：

```json
{
    "PROXY_URL": "http://127.0.0.1:7890",
    "PROXY_ENABLED_PROVIDERS": ["claude-kiro-oauth"]
}
```

**支持的代理类型**：

| 类型     | 格式示例                      |
| ------ | ------------------------- |
| HTTP   | `http://127.0.0.1:7890`   |
| HTTPS  | `https://127.0.0.1:7890`  |
| SOCKS5 | `socks5://127.0.0.1:1080` |

**配置方式**：

1. **配置文件**（推荐）：直接修改 `configs/config.json`，添加 `PROXY_URL` 和 `PROXY_ENABLED_PROVIDERS`
2. **Web UI**：在管理界面的「配置」页面 → "Proxy Settings" 区域填写代理地址，勾选需要走代理的 provider

> **注意**：`PROXY_ENABLED_PROVIDERS` 是一个数组，可以指定多个 provider 使用代理，例如 `["claude-kiro-oauth", "gemini-cli-oauth"]`。

## 可用模型

模型列表随镜像版本变化，别写死在配置里，实时查：

```bash
curl -s https://<your-domain>/v1/models -H "x-api-key: <your-api-key>" \
  | python3 -c 'import sys,json;print("\n".join(m["id"] for m in json.load(sys.stdin)["data"]))'
```

3.3.8 上实测 15 个：

```
claude-haiku-4-5        claude-haiku-4-5-20251001
claude-opus-4-5         claude-opus-4-5-20251101
claude-opus-4-6         claude-opus-4-7         claude-opus-4-8
claude-opus-5
claude-sonnet-4-5       claude-sonnet-4-5-20250929
claude-sonnet-4-6       claude-sonnet-5
gpt-5.6-luna            gpt-5.6-sol             gpt-5.6-terra
```

> **模型 ID 一律用连字符**（`claude-opus-4-8`），网关内部会转成上游要的点号形式（`claude-opus-4.8`）。直接传点号形式会 400。
>
> 老版本（如 2.16.3）的 `FULL_MODEL_MAPPING` 里没有新模型条目，靠 `customModels` 注入 ID **绕不过去** —— 真正生效的是 `FULL_MODEL_MAPPING ∩ KIRO_MODELS`，缺条目就会把 ID 原样发上游导致 400。要新模型只能升镜像。

## 首次运行 Claude CLI 跳过登录

如果是第一次运行 Claude CLI，可以在 `~/.claude.json` 中添加以下配置，跳过登录流程：

```json
{
  "hasCompletedOnboarding": true
}
```

## Token 刷新机制

AIClient-2-API 内部自动处理 token 刷新（`CRON_REFRESH_TOKEN: true`）。它使用凭据文件中的 `refreshToken` + `clientId` + `clientSecret` 向 `oidc.us-east-1.amazonaws.com/token` 请求新的 `accessToken`，在当前 token 过期前自动完成续期。`accessToken` 寿命 1 小时，`CRON_NEAR_MINUTES: 1` 表示距过期 30 分钟内就开始尝试刷新。

> **但 `refreshToken` 本身也有寿命。** 它一旦失效，自动续期就永久失败，日志开始每 60 秒刷一次 `Token refresh failed: Request failed with status code 400`，且**不会自愈**。这时唯一的解法是重新从 Kiro CLI 同步一份新凭据（见下方「手动同步」）。排查见「[故障排查](#故障排查)」。

### 手动触发内部刷新

如果需要立即刷新 token，可以执行容器内的刷新脚本：

```bash
sudo docker exec aiclient2api node src/scripts/kiro-idc-token-refresh.js configs/kiro-auth-token.json
```

该脚本读取 `configs/kiro-auth-token.json` 中的 `refreshToken` + `clientId` + `clientSecret`，向 AWS OIDC 端点请求新的 `accessToken`（有效期 1 小时），并将结果保存到容器内。

### 手动同步 Kiro CLI 凭据

如果重新登录了 Kiro CLI，或 `refreshToken` 已失效，需要重新提取凭据并同步。**推荐走 API 导入**（见「[添加更多 Kiro OAuth 账号](#添加更多-kiro-oauth-账号)」），它会自动落到 `configs/kiro/<timestamp>_kiro-auth-token/` 并关联到 provider pool，**无需重启**。

覆盖式同步（仅适用于单节点、且 pool 里引用的就是 `configs/kiro-auth-token.json` 的场景）：

```bash
python3 /home/ubuntu/kiro-oauth-get-cred.py
cp /home/ubuntu/kiro_credentials.json /home/ubuntu/AIClient-2-API/docker/configs/kiro-auth-token.json
sudo docker compose restart
```

> **先确认 pool 引用的到底是哪个文件**，否则覆盖了也不生效：
>
> ```bash
> grep -o 'configs/kiro[^"]*' /home/ubuntu/AIClient-2-API/docker/configs/provider_pools.json | sort -u
> ```
>
> 多节点场景下 pool 引用的是 `configs/kiro/<timestamp>_kiro-auth-token/*.json`，此时 `configs/kiro-auth-token.json` 只是个不被引用的孤儿文件，覆盖它没有任何效果。

### 热加载配置（替代重启）

改完 `config.json` 或 `provider_pools.json` 后，不必 `docker compose restart`：

```bash
TOKEN=$(curl -s -X POST https://<your-domain>/api/login \
  -H "Content-Type: application/json" \
  -d '{"password":"<your-password>"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

curl -s -X POST https://<your-domain>/api/reload-config \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{}'
```

返回 `{"success":true,"message":"Configuration files reloaded successfully",...}` 即生效。

## 添加更多 Kiro OAuth 账号

如果需要添加额外的 Kiro 账号（多账号负载均衡），可以通过 API 导入。支持本地和远程两种方式。

### 1. 提取新账号凭据

在已登录新 Kiro 账号的机器上执行：

```bash
python3 /home/ubuntu/kiro-oauth-get-cred.py
```

> **macOS 用户**：脚本已支持自动检测平台，直接运行即可。凭据会输出到 `~/kiro_credentials.json`。

### 2a. 本地导入（在服务器上操作）

由于 Kiro CLI 使用 builder-id 认证方式，需要用 `/api/kiro/import-aws-credentials` 接口（传完整凭据对象），而不是 `/api/kiro/batch-import-tokens`（仅支持 social auth）。

先登录管理后台获取 token：

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"password":"<your-password>"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
```

导入凭据：

```bash
CREDS=$(cat /home/ubuntu/kiro_credentials.json)
curl -s -X POST http://localhost:3000/api/kiro/import-aws-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"credentials\": [$CREDS]}"
```

### 2b. 远程导入（从本地机器通过 HTTPS 导入）

适用于 Kiro CLI 安装在本地开发机（如 macOS），而 AIClient-2-API 部署在远程服务器的场景。

先在本地提取凭据：

```bash
python3 kiro-oauth-get-cred.py
```

登录远程管理后台获取 token：

```bash
TOKEN=$(curl -s -X POST https://<your-domain>/api/login \
  -H "Content-Type: application/json" \
  -d '{"password":"<your-password>"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
```

远程导入凭据：

```bash
CREDS=$(cat ~/kiro_credentials.json)
curl -s -X POST https://<your-domain>/api/kiro/import-aws-credentials \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"credentials\": [$CREDS]}"
```

### 导入结果

成功后会返回类似：

```
event: complete
data: {"success":true,"total":1,"successCount":1,"failedCount":0,...}
```

新账号会自动保存到 `configs/kiro/` 目录并关联到 provider pool，无需重启服务。

## 故障排查

### 先分清两层：进程活 ≠ 能推理

`/health` 返回 `{"status":"healthy"}` **只证明 Node 进程活着，不代表能推理**。容器 `healthy`、`restarts=0`、HTTP 200、证书有效 —— 这些全绿的同时推理可能 100% 失败。

判断「能不能真的用」看 provider pool 的 `isHealthy`：

```bash
python3 -c "
import json
d=json.load(open('/home/ubuntu/AIClient-2-API/docker/configs/provider_pools.json'))
for prov,lst in d.items():
    print(prov+':')
    for e in lst:
        print('  uuid=',str(e.get('uuid'))[:8],'healthy=',e.get('isHealthy'),
              'disabled=',e.get('isDisabled'),'err=',e.get('errorCount'),
              'creds=',e.get('KIRO_OAUTH_CREDS_FILE_PATH') or e.get('KIRO_OAUTH_CREDS_DIR_PATH'))
"
```

再加一条端到端探活（最可靠）：

```bash
curl -s -X POST https://<your-domain>/v1/messages \
  -H "x-api-key: <your-api-key>" -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":16,"messages":[{"role":"user","content":"只回复：OK"}]}'
```

### 症状 1：客户端报 404 Not Found，提示"检查模型名"

```json
{"error":{"message":"Not Found","code":404,"suggestions":[
  "Check your request format and parameters",
  "Verify the model name is a valid Claude model",
  "Ensure the message format follows Anthropic API specifications"]}}
```

**这三条 suggestions 是死文案**（出自 `src/utils/common.js`），跟模型名毫无关系，别顺着它查。

真实原因看服务端日志：

```
POST http://<your-domain>/messages
[Config] Ignoring invalid MODEL_PROVIDER in path segment: messages
[Server] Request failed (404): Not Found
```

请求路径少了 `/v1`。网关只注册 `/v1/messages`、`/v1/models`、`/v1/responses`，`/messages` 被当成 provider 名去解析，解析失败就 404。

修法取决于客户端怎么拼路径：

| 客户端 | base URL 填法 |
| --- | --- |
| 原生 Anthropic SDK、Claude Code（自己拼 `/v1/messages`） | `https://<your-domain>` |
| Vercel AI SDK、opencode 等（baseURL 默认自带 `/v1`，只拼 `/messages`） | `https://<your-domain>/v1` |

判断方法：抓服务端日志看实际打进来的 path 是 `/messages` 还是 `/v1/messages`。

### 症状 2：日志每 60 秒刷一次 `status code 400`

```
[Kiro] Expiry date is near, refreshing token...
[Kiro Auth] Successfully loaded OAuth credentials from ./configs/kiro/xxx_kiro-auth-token/xxx_kiro-auth-token.json
[Kiro Auth] Token refresh failed: Request failed with status code 400
[Token Refresh Error] Failed to refresh token for claude-kiro-oauth<uuid>: ...
```

`refreshToken` 已失效，自动续期永久失败，**不会自愈**（实测累计刷了 5736 次）。

确认凭据过期时间：

```bash
python3 -c "
import json,glob,datetime
now=datetime.datetime.now(datetime.timezone.utc)
for f in sorted(glob.glob('/home/ubuntu/AIClient-2-API/docker/configs/kiro/*/*.json'))+\
         sorted(glob.glob('/home/ubuntu/AIClient-2-API/docker/configs/kiro-auth-token.json')):
    d=json.load(open(f)); e=d.get('expiresAt','?')
    try:
        t=datetime.datetime.fromisoformat(str(e).replace('Z','+00:00'))
        st='EXPIRED' if t<now else 'VALID'
    except Exception: st='?'
    print(f'{st:8} {e}  {f}')
"
```

修：从 Kiro CLI 重新提取凭据并用 `/api/kiro/import-aws-credentials` 导入（见上方）。

> **`isHealthy=false` 的节点仍会被刷新 cron 轮到**，光把它标成不健康并不会停止 400 噪音 —— 必须置 `isDisabled: true` 或直接把节点从 pool 里删掉，再 `reload-config`。

### 症状 3：`curl: (35) tlsv1 alert internal error`

不是 TLS 版本/cipher 不匹配，而是**服务端根本没有证书**。直接看：

```bash
sudo ls /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
```

目录为空说明 Caddy 一直没签发成功，常见原因是 ACME challenge 被安全组挡了 —— 详见「[Caddy 反向代理](#配置-caddy-https-反向代理)」里的 DNS-01 说明。

### 清理死凭证

过期凭据留着只会产生 400 噪音，且可能被 pool 误选。**先备份再删**：

```bash
cd /home/ubuntu/AIClient-2-API/docker
DEAD="configs/kiro/<ts1>_kiro-auth-token configs/kiro/<ts2>_kiro-auth-token"

# 1. 备份（连 provider_pools.json 一起打包，方便整体回滚）
sudo tar czf /home/ubuntu/kiro-dead-creds-backup-$(date +%Y%m%d).tar.gz $DEAD configs/provider_pools.json
sudo chmod 600 /home/ubuntu/kiro-dead-creds-backup-*.tar.gz

# 2. 从 pool 移除对应节点（按 uuid 前缀匹配）
sudo cp configs/provider_pools.json configs/provider_pools.json.bak
sudo python3 -c "
import json
p='configs/provider_pools.json'; d=json.load(open(p))
DEAD_UUIDS=('<uuid-prefix-1>','<uuid-prefix-2>')
for prov in list(d):
    before=len(d[prov])
    d[prov]=[e for e in d[prov] if not str(e.get('uuid','')).startswith(DEAD_UUIDS)]
    print(f'{prov}: {before} -> {len(d[prov])}')
json.dump(d,open(p,'w'),indent=2)
"

# 3. 删文件
sudo rm -rf $DEAD

# 4. 热加载（见上方 reload-config），然后确认噪音归零
sudo docker logs --since 75s aiclient2api 2>&1 | grep -icE "refresh failed|Token Refresh Error"
```

最后一条命令输出 `0` 才算干净。

> 删之前务必确认哪些文件**没被引用**：`grep -o 'configs/kiro[^"]*' configs/provider_pools.json | sort -u`。不在这个列表里、且 `config.json` 也没有 `KIRO_OAUTH_CREDS_*` 指向它的，就是孤儿文件，可以安全删除。

## 用 device code 重新授权（备选方案）

如果没有可用的 Kiro CLI 可提取凭据，可以让网关自己跑一遍 AWS SSO OIDC device code 流程。

```bash
TOKEN=$(curl -s -X POST https://<your-domain>/api/login \
  -H "Content-Type: application/json" \
  -d '{"password":"<your-password>"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

curl -s -X POST https://<your-domain>/api/providers/claude-kiro-oauth/generate-auth-url \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"method":"builder-id","saveToConfigs":true}'
```

返回的 `authUrl`（即 `verificationUriComplete`，已内嵌 user code）在浏览器打开并批准，服务端后台轮询拿到 token 后自动落盘 + 关联到 pool。

**三个坑**：

1. **必须传 `saveToConfigs: true`**。否则凭据会落到 `~/.kiro/oauth_creds.json`，不进 `configs/kiro/`，也不会关联到 provider pool。
2. **授权窗口硬编码 5 分钟**。轮询参数是字面量 `interval=5, expiresIn=300`，**没有使用 AWS 返回的 `expiresIn`/`interval`** —— 超时就得整个流程重来。发起前先把浏览器准备好。
3. 每次调用会先 `stopKiroPollingTask()` 掉所有进行中的 kiro 轮询任务，**不能并发跑两个授权流程**。

> 授权页在 AWS 域名下（`view.awsapps.com`），不受网关所在安全组的入站规则限制 —— 所以即使你的 IP 不在 443 白名单里、打不开管理界面，这个流程依然可用（前提是能用 API 拿到 token）。

### IdC（企业版 Identity Center）不被支持

`authMethod` 只能是 `builder-id` 或 `social`。走 IdC 登录的 Kiro 账号，CodeWhisperer 请求需要携带 `profileArn`，而网关只在 `authMethod === 'social'` 分支才会注入 `profileArn`（`claude-kiro.js`），`builder-id` 分支不发 —— 所以 IdC 的 profile 绑定信息会丢失。

不过 **Kiro CLI 即使用 IdC 登录，它注册的 OIDC device client 也带 `clientId`/`clientSecret`，按 `builder-id` 导入即可正常工作** —— 这就是第三步脚本里把 `authMethod` 写死成 `builder-id` 的原因。

## 配置 Caddy HTTPS 反向代理

通过 Caddy 在 443 端口提供 HTTPS，反代到 AIClient-2-API 的 3000 端口。80 端口保留给 Nginx（code-server）。

### 前置条件

- 安装 Caddy：参考 https://caddyserver.com/docs/install
- 域名 A 记录指向本机公网 IP（**注意**：非 EIP 的公网 IP 在实例 stop/start 后会变，需手动更新 A 记录）
- 安全组放行 443 端口入站 —— 若这里按 IP 白名单收紧，**必须改用 DNS-01**，见下方说明

### Caddyfile 配置（`/etc/caddy/Caddyfile`）

```
{
	http_port 444
}

<your-domain> {
	reverse_proxy localhost:3000
}
```

`http_port 444` 避免与 Nginx 80 端口冲突，Caddy 通过 TLS-ALPN-01 在 443 端口自动申请和续期 Let's Encrypt 证书。

### ⚠️ 如果安全组按 IP 白名单收紧了 443，必须改用 DNS-01

上面的配置有个隐藏前提：**443 对公网开放**。一旦把安全组 443 收成只允许特定源 IP，两种 HTTP 类 challenge 会同时失效：

- `http-01` 需要公网 80 —— 但 `http_port 444` 已经让 Caddy 不听 80
- `tls-alpn-01` 需要公网 443 —— Let's Encrypt 的校验机不在白名单里

结果是证书永远签不下来，且 Caddy 以 6 小时退避重试，**不会自愈**（实测日志 `tls.obtain ... attempt 49, elapsed 584297s, retrying_in 21600`，静默失效了两个月）。

改用 DNS-01（443/80 都不需要对公网开放，以 Route53 为例）：

```bash
# apt 装的 caddy 不含 route53 模块，需要重新下带模块的二进制
curl -fsSL -o /tmp/caddy-r53 \
  "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com/caddy-dns/route53"
sudo install -m0755 /tmp/caddy-r53 /usr/local/bin/caddy
sudo apt-mark hold caddy   # 防止 apt 升级把无模块的二进制换回来
```

用 drop-in 覆盖 systemd 的 `ExecStart`/`ExecReload` 指向 `/usr/local/bin/caddy`（`/etc/systemd/system/caddy.service.d/override.conf`），Caddyfile 里加：

```
<your-domain> {
	reverse_proxy localhost:3000
	tls {
		dns route53 {
			max_retries 10
			hosted_zone_id <your-zone-id>
		}
		resolvers 1.1.1.1
	}
}
```

EC2 instance role 需要该 hosted zone 的 `route53:ChangeResourceRecordSets` / `ListHostedZones` / `GetChange` 权限。

验证必须核对**实际在跑的二进制**，否则可能还是旧的：

```bash
sudo readlink -f /proc/$(systemctl show -p MainPID --value caddy)/exe   # 应为 /usr/local/bin/caddy
sudo /usr/local/bin/caddy list-modules | grep route53                   # 应有输出
```

> Let's Encrypt 的 failed-validation 限流是每账号每 hostname 每小时 5 次，签发失败不要循环重试。

### 启动

```bash
sudo systemctl restart caddy
```

### 验证

```bash
curl -s -o /dev/null -w "HTTP %{http_code}" https://<your-domain>/
# 返回 HTTP 200 即成功
```

## another solution

https://github.com/jwadow/kiro-gateway





