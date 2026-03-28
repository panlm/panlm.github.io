---
title: DevLake-Local-Setup-with-Colima
description: null
type: note
tags:
- devlake
- colima
- docker
- kiro
- grafana
permalink: git-mkdocs/gen-ai/dev-lake-local-setup-with-colima
---

# DevLake Local Setup with Colima

## Overview

Apache DevLake 本地容器环境，使用 Colima 替代 Docker Desktop，用于展示 Kiro IDE 使用指标数据。

## Architecture
- **Colima** - 轻量级 macOS 容器运行时，替代 Docker Desktop
  - 虚拟化框架: macOS Virtualization.Framework (vz)
  - 架构: aarch64 (Apple Silicon)
  - 挂载类型: virtiofs
  - 多架构支持: linux/arm64, linux/amd64, linux/386
- **DevLake v1.0.3-beta10** - 数据平台（最新版本，2026-03-12 发布）
- **MySQL 8** - 数据存储（数据库: lake）
- **Grafana** - 仪表板可视化
- **q_dev 插件** - 从 S3 采集 Kiro/Q Developer CSV 指标数据

### 容器列表

| 容器名 | 镜像 | 端口映射 | 用途 |
|--------|------|----------|------|
| devlake-devlake-1 | apache/devlake:v1.0.3-beta10 | 8080→8080 | API 后端 |
| devlake-config-ui-1 | apache/devlake-config-ui:v1.0.3-beta10 | 4000→4000 | 配置界面 |
| devlake-grafana-1 | apache/devlake-dashboard:v1.0.3-beta10 | 3002→3000 | Grafana 仪表盘 |
| devlake-mysql-1 | mysql:8 | 3306→3306 | 数据库 |

### 访问地址

- Config UI: http://localhost:4000
- Grafana: http://localhost:3002 (admin/admin)
- API: http://localhost:8080
- MySQL: localhost:3306 (merico/merico, db: lake)


## Installation

### 下载 docker-compose.yml 和 env 文件

从 GitHub Release 页面下载对应版本的配置文件：

```bash
mkdir -p /private/tmp/devlake && cd /private/tmp/devlake

# 下载 docker-compose.yml 和 env.example
curl -sLO https://github.com/apache/incubator-devlake/releases/download/v1.0.3-beta10/docker-compose.yml
curl -sLO https://github.com/apache/incubator-devlake/releases/download/v1.0.3-beta10/env.example

# 创建 .env 并生成加密密钥
cp env.example .env
echo "" >> .env
ENCRYPTION_KEY=$(openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1)
echo "ENCRYPTION_SECRET=\"${ENCRYPTION_KEY}\"" >> .env

# 设置 FORCE_MIGRATION=true（升级时需要）
sed -i '' 's/FORCE_MIGRATION=false/FORCE_MIGRATION=true/' .env

# 替换镜像源为 scarf（Docker Hub 不稳定时用 scarf 前缀）
sed -i '' 's|apache/devlake|devlake.docker.scarf.sh/apache/devlake|g' docker-compose.yml
```

Release 下载页：https://github.com/apache/incubator-devlake/releases

### 安装 Colima（macOS）

```bash
brew install colima docker docker-compose

# 配置 docker-compose 插件路径，在 ~/.docker/config.json 中添加：
# "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
# 同时移除 "credsStore": "desktop" 和 "currentContext": "desktop-linux"
```

- Docker Compose: `/private/tmp/devlake/docker-compose.yml`
- Environment: `/private/tmp/devlake/.env`
- Docker Config: `~/.docker/config.json`

## Quick Start / Stop

### 启动

```bash
# 1. 启动 Colima（4GB 内存，2 CPU，20GB 磁盘）
colima start --cpu 2 --memory 4 --disk 20

# 2. 启动 DevLake
cd /private/tmp/devlake && docker compose up -d

# 3. 等待约 30 秒，然后访问
# Config UI: http://localhost:4000
# Grafana:   http://localhost:3002 (admin/admin)
# API:       http://localhost:8080
# MySQL:     localhost:3306 (merico/merico, db: lake)
```

### 停止

```bash
# 1. 停止 DevLake 容器
cd /private/tmp/devlake && docker compose down

# 2. 停止 Colima（释放 4GB 内存）
colima stop
```

### 完全清理（会丢失所有数据）

```bash
cd /private/tmp/devlake && docker compose down -v
colima stop
```

## q_dev Connection Configuration

通过 API 创建 S3 连接：

```bash
curl -X POST http://localhost:8080/plugins/q_dev/connections \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "kiro-metrics-iamuser",
    "accessKeyId": "<YOUR_ACCESS_KEY>",
    "secretAccessKey": "<YOUR_SECRET_KEY>",
    "region": "us-east-1",
    "bucket": "kiro-prompt-logging-xxxxx",
    "rateLimitPerHour": 10000
  }'
```

当前连接配置：
- Connection ID: 1
- Name: kiro-metrics-iamuser
    - S3 Bucket: `kiro-prompt-logging-xxxxx`
- S3 Prefix: `prefix`
- Region: us-east-1
- IAM User: `kiro-metrics-iamuser`（需要 s3:ListBucket + s3:GetObject 权限）

## 触发数据采集 Pipeline

```bash
curl -X POST http://localhost:8080/pipelines \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "q_dev collect",
    "plan": [[{
      "plugin": "q_dev",
      "options": {
        "connectionId": 1,
        "prefix": "prefix"
      }
    }]]
  }'
```

查看 pipeline 状态：

```bash
curl -s http://localhost:8080/pipelines/<PIPELINE_ID> | python3 -m json.tool
```

## MySQL 直连查询

```bash
# 通过 docker exec
docker exec -it devlake-mysql-1 mysql -u merico -pmerico lake

# 查看 Kiro 指标数据
SELECT user_id, date, chat_ai_code_lines, chat_messages_sent FROM _tool_q_dev_user_data ORDER BY date;
```

## Key Tables

| 表名 | 用途 |
|------|------|
| `_tool_q_dev_connections` | S3 连接配置 |
| `_tool_q_dev_s3_file_meta` | 已处理的 S3 CSV 文件 |
| `_tool_q_dev_user_data` | 按用户+日期的每日明细（46 字段） |
| `_tool_q_dev_user_report` | 新格式用户报告（credits/messages） |

## Docker Images（使用 Scarf 镜像源）

```
devlake.docker.scarf.sh/apache/devlake:v1.0.3-beta10
devlake.docker.scarf.sh/apache/devlake-config-ui:v1.0.3-beta10
devlake.docker.scarf.sh/apache/devlake-dashboard:v1.0.3-beta10
mysql:8
```


## Troubleshooting

### Config UI 容器未启动 (Exit Code 137)

Colima 重启后，config-ui 容器可能因之前关机或内存不足而处于 Exited 状态，其他容器会自动恢复但 config-ui 需要手动启动：

```bash
# 检查容器状态
docker ps -a --filter "name=config"

# 手动启动
docker start devlake-config-ui-1

# 验证是否可访问
curl -s -o /dev/null -w "%{http_code}" http://localhost:4000
# 应返回 200
```

## Important Notes

- `.env` 中 `FORCE_MIGRATION=true` 用于升级时自动迁移数据库 schema
- Docker Hub 镜像拉取不稳定时，使用 `devlake.docker.scarf.sh` 镜像源
- `~/.docker/config.json` 需要移除 `credsStore: desktop` 和 `currentContext: desktop-linux`，改为 Colima 配置
- q_dev 插件重复执行 pipeline 会追加数据（非 upsert），查询时注意去重

## Version History

- v1.0.2-beta9: 缺少 Chat_AICodeLines 等字段
- v1.0.3-beta10: 新增全部 46 个 CSV 字段支持，包括 Chat、CodeFix、Dev、DocGeneration、TestGeneration、Transformation

