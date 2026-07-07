---
title: Quick Desktop Session 解析
type: guide
permalink: main/quick-desktop-session-作为审计日志方案
tags:
  - quick-desktop
  - audit
  - security
  - session-trace
  - compliance
share_link: https://notes-share.aws.panlm.click/aeixxv95
share_updated: 2026-06-18T14:51:33+08:00
---

# Quick Desktop Session 解析

> 目标：解析 Amazon Quick Desktop（AI 办公 agent）本地落盘的 session 数据，把 agent 的操作过程读取、还原成可读 trace。
> 结论先行：**数据真实存在且粒度极细（等同/细于 Claude Code 的 session trace），但它是「应用私有遥测」而非「合规级审计日志」**——可读、可还原，但不防篡改、可被用户一键清除、schema 无官方契约。要做正式合规留痕，必须在此基础上加「只读外导 + 端点侧监控」。

## 1. 数据在哪里

### 1.1 顶层目录
- macOS: `~/.quickwork/`
- Windows: `%USERPROFILE%\.quickwork\`
- 本机实测总大小约 1.5G。

### 1.2 关键：按 profile 分库（官方文档未提）
实际架构经历过迁移（根目录有 `.legacy_migrated`、`*.legacy.bak`）。**当前活跃数据不在根目录，而在 profile 子目录下**：

```
~/.quickwork/
├── profiles.json                      # 列出所有 profile，last_active 指向当前
├── sessions/sessions.db               # ← legacy 旧库（本机停在 2026-04-30）
└── profiles/
    └── federate-prod/                  # ← 当前登录 profile (user@example.com)
        ├── sessions/
        │   ├── sessions.db             # ← 真正在用的会话库
        │   ├── sessions.db-wal
        │   ├── sessions.db-shm
        │   └── <session-id>/           # 每个会话一个 workspace 沙箱目录
        ├── agents.json                 # 敏感：agent 配置
        ├── mcp_config.json             # 敏感：MCP 连接
        ├── device_configuration_id     # 敏感
        └── ...
```

**定位当前库的正确方法**：读 `profiles.json` 的 `last_active` 字段 → 拼出 `profiles/<last_active>/sessions/sessions.db`。不要硬编码路径。

### 1.3 每个会话的 workspace 沙箱
路径：`profiles/<profile>/sessions/<session-id>/workspace/`

| 子目录 | 内容 |
|--------|------|
| `artifacts/` | agent 产出的文件（生成的文档、图片等） |
| `attached_files/` | 用户上传的附件 |
| `tmp/` | 中间文件（如翻译任务的 JSON 字典） |
| `tools/` | 各 MCP 工具的本地缓存 |

> 注意：手动会话用 UUID 命名（如 `80e64aca-...`）；定时后台任务用语义名（如 `scheduled-marvin-user--52041a18`、`scheduled-feed-agent--xxx`、`scheduled-kg-cloud-sync--xxx`）。两类**共用同一个 sessions.db**，只是 `session_type` 不同（`main` vs `task`）。本机有 5781 个 `scheduled-*` 目录，后台 agent 跑得很频繁。

## 2. 如何获取

会话数据存在每个 profile 下的 SQLite 库 `profiles/<profile>/sessions/sessions.db`，配套有 `-wal` / `-shm`。用任意 SQLite 客户端只读打开即可，无需特殊权限（文件归当前用户所有）。

### 2.1 定位当前库
```bash
# 读 profiles.json 的 last_active，拼出当前库路径
PROFILE=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.quickwork/profiles.json')))['last_active'])")
DB="$HOME/.quickwork/profiles/$PROFILE/sessions/sessions.db"
```

### 2.2 看库里有哪些表
```bash
sqlite3 "$DB" ".tables"      # 表清单
sqlite3 "$DB" ".schema"      # 完整建表语句（字段含义自解释）
```
重点是两张表：`sessions`（会话元数据）和 `session_events`（逐事件 trace，append-only，`data` 列是每个事件的完整 JSON 载荷）。其余为 FTS5 全文索引、向量嵌入等辅助表。

### 2.3 列出会话、按字符串检索
```bash
# 按真实事件数排出"干了事"的会话
sqlite3 "$DB" "SELECT session_id,count(*) n,datetime(max(timestamp),'unixepoch','localtime') last \
  FROM session_events GROUP BY session_id ORDER BY n DESC LIMIT 10;"

# 全文检索某关键字命中哪个会话（搜事件载荷）
sqlite3 "$DB" "SELECT DISTINCT session_id FROM session_events WHERE data LIKE '%关键字%';"
```

### 2.4 还原某个会话的完整时间线
推荐用 Python 只读直连（`session_events.data` 内含多行 JSON，经 shell 管道会错位）。读出 `type` / `timestamp` / `data` 按 `rowid` 排序，再用事件载荷里的 `tool_use_id` 把「工具开始 → 参数 → 返回」三类事件配成一次完整调用即可渲染成可读 trace。事件类型与字段名直接看 `data` 的 JSON key，无需预先知道 schema。

## 3. 这套数据能审计到什么粒度

实测可完整还原（等同 Claude Code session trace）：
- ✅ 用户每条原始指令（含中文）
- ✅ 助手的思考过程（`full_content`）
- ✅ 每次工具调用：工具名 + 完整参数 + 完整返回
- ✅ 每步 token 消耗与模型
- ✅ 错误与 agent 的自我纠正（如用错 list ID 后的反思）
- ✅ 人工审批记录（谁、何时、批了哪个工具调用、批准范围）
- ✅ 写入长期记忆的内容
- ✅ 子任务（spawn/translator 等）的目标与结果
- ✅ 产物文件（workspace/artifacts）

`metrics/metrics-YYYY-MM-DD.jsonl`（按天分文件，AWS EMF 格式，含 `_aws`）补充遥测级数据：
- `ToolName`+`ToolCallCount`+`Integration`（每次工具调用）
- `Model`+`InputTokens`+`OutputTokens`+`CostUSD`+`RequestLatency`（每次模型请求与花费）
- `AgentId`+`ProactiveAgentRun`+`DispatchMode`（后台 agent 自主运行）
- `Phase`+`PhaseLatency`、`session_id`+`thread_id`（可关联回 sessions.db）

## 4. 用作审计留痕的三个局限

1. **可被用户一键清除**：Settings → Customization → Danger zone → Clear all data，不可逆，审计链随时断。
2. **无防篡改**：sessions.db / metrics jsonl 都是当前用户可读写的普通文件（`rw-r--r--`），用户自己能改/删。不满足 append-only / WORM / 防篡改要求。
3. **非官方契约**：schema 是逆向所得，AWS 未公开保证其稳定性（已见多次 legacy 迁移）。不能作为正式合规依据。

附加风险：trace 内含**高敏感数据**（真实邮件 ID、邮箱、客户名、SFDC Account ID、日历、文件路径等）。外导/存储本身需做访问控制与脱敏。

## 5. 安全只读访问要点（给后续脚本）
- 一律用 `sqlite3.connect("file:<path>?mode=ro", uri=True)`，不写库（避免破坏 WAL）。
- 跨所有 profile 搜索：`glob ~/.quickwork/profiles/*/sessions/sessions.db` + 根目录 legacy 库。
- 字符串检索命中会话：`SELECT session_id,type,timestamp FROM session_events WHERE data LIKE '%...%'`。
- 多行 JSON 会破坏 shell 管道分隔，**用 Python 直连 SQLite**，别用 `sqlite3 -separator` 经 shell。
- 敏感字段（邮件 ID、token、account id）按需脱敏后再输出/留存。

## 相关
- 探查时间：2026-06-18，本机 user@hostname（Claude Code）
- 当前活跃 profile：`federate-prod`（user@example.com）
