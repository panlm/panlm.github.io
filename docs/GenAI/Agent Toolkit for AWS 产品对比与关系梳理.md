---
title: Agent Toolkit for AWS 产品对比与关系梳理
type: note
tags:
- agent-toolkit
- mcp
- aws
- aws-cn
- devops-agent
- comparison
permalink: git-mkdocs/gen-ai/agent-toolkit-for-aws-产品对比与关系梳理
---

# Agent Toolkit for AWS 产品对比与关系梳理

> **验证日期**: 2026-05-07
> **验证方式**: 通过 mcp-proxy-for-aws 实际调用 AWS MCP Server 测试

## 产品全景

AWS 围绕 MCP（Model Context Protocol）有三个层次的产品/项目：

### 1. Agent Toolkit for AWS（正式产品，GA 2026-05-06）

- **组织**: `github.com/aws/agent-toolkit-for-aws`
- **定位**: 官方统一品牌，包含 MCP Server + Skills + Plugins
- **核心组件**:
  - **AWS MCP Server** — 托管远程服务端，endpoint: `https://aws-mcp.us-east-1.api.aws/mcp`
  - **Agent Skills** — 经过评估验证的策展式知识包
  - **Agent Plugins** — Claude Code / Codex / Cursor 一键安装
- **认证**: 知识类工具（文档/Skills/区域）无需认证可匿名访问；API 执行类工具需 IAM SigV4（通过 mcp-proxy-for-aws 桥接）
- **企业特性**: IAM condition key `aws:CalledViaAWSMCP`、CloudWatch 指标、CloudTrail 审计

### 2. MCP Proxy for AWS（配套客户端组件，仅 API 执行类工具需要）

- **组织**: `github.com/aws/mcp-proxy-for-aws`
- **定位**: 本地运行的开源代理，解决认证协议不匹配
- **作用**: MCP 协议只支持 OAuth 2.1，AWS 用 IAM SigV4 → proxy 在本地做转换
- **两种用法**:
  1. 作为 proxy — 桥接 MCP 客户端和 AWS MCP Server
  2. 作为 library — 编程式接入 LangChain/LlamaIndex/Strands Agents

### 3. awslabs/mcp（社区前身，继续维护）

- **组织**: `github.com/awslabs/mcp`（9000+ stars）
- **定位**: 早期开源 MCP servers 集合，针对具体 AWS 服务的本地 MCP server
- **包含**: aws-documentation-mcp-server、CDK、CloudFormation、ECS、Lambda、Bedrock、DynamoDB 等
- **特点**: 每个 server 独立运行在本地（stdio transport）
- **状态**: 继续工作并接受贡献，最有用的项目逐步迁移到 Agent Toolkit

## 关系图谱

```
awslabs/mcp (社区前身，本地运行，多个独立 server)
    │
    │  经验沉淀、最佳实践提炼
    ▼
Agent Toolkit for AWS (正式产品，统一品牌)
    ├── AWS MCP Server (托管远程服务端，AWS 云端运行)
    │     └── 工具: call_aws, run_script, search_documentation,
    │           read_documentation, retrieve_skill, suggest_aws_commands,
    │           get_regional_availability, list_regions, recommend,
    │           get_presigned_url, get_tasks
    ├── Agent Skills (经过验证的知识包)
    └── Agent Plugins (一键安装)
         │
         │  本地需要通过
         ▼
MCP Proxy for AWS (本地代理，IAM SigV4 ↔ MCP stdio)
```

## 工具集对比

### aws-knowledge-mcp-server vs Agent Toolkit AWS MCP Server

| 工具 | knowledge-mcp (旧) | Agent Toolkit (新) | 说明 |
|------|:---:|:---:|------|
| search_documentation | ✅ | ✅ | AWS 文档搜索 |
| read_documentation | ✅ | ✅ | 读取文档页面 |
| recommend | ✅ | ✅ | 文档推荐 |
| retrieve_skill | ✅ | ✅ | 加载 Agent Skill |
| get_regional_availability | ✅ | ✅ | 区域可用性检查 |
| list_regions | ✅ | ✅ | 列出所有区域 |
| call_aws | ❌ | ✅ | 执行 AWS CLI 命令 |
| run_script | ❌ | ✅ | 沙盒 Python 执行 |
| suggest_aws_commands | ❌ | ✅ | 自然语言→CLI 建议 |
| get_presigned_url | ❌ | ✅ | S3 预签名 URL |
| get_tasks | ❌ | ✅ | 轮询长任务状态 |

**结论**: Agent Toolkit 是 knowledge-mcp 的超集，可以直接替换。

### awslabs/aws-api-mcp-server vs Agent Toolkit call_aws

| 维度 | awslabs/aws-api-mcp-server | Agent Toolkit call_aws |
|------|--------------------------|----------------------|
| 运行位置 | 本地或自托管 EC2 | AWS 云端托管 |
| 参数格式 | `service_name` + `api_name` + `parameters` | `cli_command`（CLI 字符串） |
| 中国分区支持 | ✅ (通过 boto3 profile) | ❌ 明确拒绝 cn-* |
| GovCloud 支持 | ✅ | 未验证（可能也不支持） |
| 审计能力 | 无（需自建日志） | CloudTrail + CloudWatch |
| 沙盒脚本 | ❌ | ✅ run_script |
| 只读控制 | 环境变量 READ_OPERATIONS_ONLY | IAM 策略 + condition key |

## 中国分区（aws-cn）支持情况

### 实测结果（2026-05-07 验证）

| 测试 | 结果 |
|------|------|
| Global profile → Agent Toolkit → us-east-1 | ✅ 成功 |
| Global profile → Agent Toolkit → cn-north-1 | ❌ `Calls to region cn-north-1 not available at this time` |
| Global profile → Agent Toolkit → cn-northwest-1 | ❌ `Calls to region cn-northwest-1 not available at this time` |
| CN profile → Agent Toolkit (SigV4 签名) | ❌ `401 Unauthorized`（跨分区签名无效） |

### Agent Toolkit 无中国支持的原因

1. **MCP Server 仅部署在 us-east-1 和 eu-central-1**，无中国区 endpoint
2. **服务端有 region 白名单**，硬拦截 cn-* region 的 API 调用
3. **无任何环境变量或配置**支持切换 partition
4. **aws-cn 凭证无法用于 Global endpoint 的 SigV4 签名**

### 中国区场景解决方案

| 场景 | 推荐方案 |
|------|---------|
| DevOps Agent 运维 aws-cn | 自建 EC2 + awslabs/aws-api-mcp-server（当前架构不变） |
| Coding Agent 开发 Global 资源 | Agent Toolkit for AWS |
| Coding Agent 操作 aws-cn | 本地 stdio 模式跑 awslabs/aws-api-mcp-server |
| 中国区 AWS 文档 | awslabs/aws-documentation-mcp-server + `AWS_DOCUMENTATION_PARTITION=aws-cn` |

## Skills 使用方法

Skills 是 Agent Toolkit 提供的策展式知识包，使用流程：

### 流程: 搜索 → 发现 → 加载 → 执行

```
Step 1: search_documentation(search_phrase="...", topics=["agent_skills"])
        → 返回匹配的 skill 列表（含 skill_name）

Step 2: retrieve_skill(skill_name="aws-serverless")
        → 返回 SKILL.md（工作流、最佳实践、引用文件列表）

Step 3: retrieve_skill(skill_name="...", file="references/xxx.md")
        → 返回引用的参考文件（详细步骤、决策框架等）
```

### 已知可用 Skills（部分）

| skill_name | 领域 |
|-----------|------|
| aws-serverless | Lambda/API GW/Step Functions 全流程 |
| aws-cdk | CDK 部署、调试、重构 |
| aws-cloudformation | CFN 模板编写和排错 |
| debugging-lambda-timeouts | Lambda 超时排查 |
| connecting-lambda-to-api-gateway | Lambda + API GW 集成 |
| creating-api-gateway-stage | API GW Stage 创建 |
| enabling-lambda-vpc-internet-access | VPC Lambda 联网 |
| troubleshooting-application-failures | 应用故障日志分析 |
| aws-amplify | Amplify Gen2 全栈开发 |
| aws-cleanrooms | Clean Rooms 排错 |

## 认证要求（实测验证 2026-05-07）

### 重要发现：Agent Toolkit 支持匿名直接访问

Agent Toolkit 的 AWS MCP Server (`https://aws-mcp.us-east-1.api.aws/mcp`) **可以直接通过 `fastmcp run` 匿名访问**，无需 mcp-proxy-for-aws，无需任何 AWS 凭证。与 `knowledge-mcp.global.api.aws` 使用方式完全一致。

Blog 原文确认: "Documentation retrieval no longer requires authentication."

### 工具认证分级

| 工具 | 匿名可用 | 需 IAM 认证 | 说明 |
|------|:---:|:---:|------|
| `search_documentation` | ✅ | | 文档搜索 |
| `read_documentation` | ✅ | | 读取文档 |
| `retrieve_skill` | ✅ | | 加载 Skill |
| `recommend` | ✅ | | 文档推荐 |
| `list_regions` | ✅ | | 区域列表 |
| `get_regional_availability` | ✅ | | 可用性检查 |
| `call_aws` | | ❌ | 需 mcp-proxy-for-aws + IAM |
| `run_script` | | ❌ | 需 mcp-proxy-for-aws + IAM |
| `suggest_aws_commands` | | ❌ | 需 mcp-proxy-for-aws + IAM |
| `get_presigned_url` | | ❌ | 需 mcp-proxy-for-aws + IAM |
| `get_tasks` | | ❌ | 需 mcp-proxy-for-aws + IAM |

### 何时需要 mcp-proxy-for-aws？

- **不需要**: 仅使用文档、Skills、区域查询等知识类工具 → 直接 `fastmcp run` 匿名访问
- **需要**: 要执行 `call_aws`、`run_script` 等 API 操作 → 必须通过 proxy 做 IAM SigV4 签名

## 配置示例

### 方案 A：匿名访问（仅知识类工具，推荐替换 knowledge-mcp）

旧配置:
```json
"aws-knowledge-mcp-server": {
  "type": "local",
  "command": ["uvx", "fastmcp", "run", "https://knowledge-mcp.global.api.aws"],
  "enabled": true
}
```

新配置（Agent Toolkit 匿名直连，无需认证，工具从 6 个升级到 11 个）:
```json
"aws-knowledge-mcp-server": {
  "type": "local",
  "command": ["uvx", "fastmcp", "run", "https://aws-mcp.us-east-1.api.aws/mcp"],
  "enabled": true
}
```

> 注：匿名模式下 call_aws/run_script 等会报错 "Failed to serve request"，但不影响知识类工具正常使用。

### 方案 B：认证访问（全部 11 个工具可用）

```json
"aws-mcp": {
  "type": "local",
  "command": ["uvx", "mcp-proxy-for-aws@latest", "https://aws-mcp.us-east-1.api.aws/mcp", "--region", "us-east-1", "--profile", "panlm"],
  "enabled": true
}
```

### 方案 C：两者并存 — 匿名 Agent Toolkit + 中国区 API

```json
{
  "aws-knowledge-mcp-server": {
    "type": "local",
    "command": ["uvx", "fastmcp", "run", "https://aws-mcp.us-east-1.api.aws/mcp"],
    "enabled": true
  },
  "aws-cn-api": {
    "type": "local",
    "command": ["uvx", "awslabs.aws-api-mcp-server@latest"],
    "env": {
      "AWS_API_MCP_PROFILE_NAME": "panlmcn",
      "READ_OPERATIONS_ONLY": "true"
    },
    "enabled": true
  }
}
```

### Claude Code 安装

```bash
# Plugin 方式（含认证，全功能）
/plugin marketplace add aws/agent-toolkit-for-aws
/plugin install aws-core@agent-toolkit-for-aws

# 或直接 MCP 配置（带认证）
claude mcp add-json aws-mcp --scope user \
  '{"command":"uvx","args":["mcp-proxy-for-aws@latest","https://aws-mcp.us-east-1.api.aws/mcp","--region","us-east-1"]}'

# 匿名模式（仅知识类工具）
claude mcp add-json aws-mcp --scope user \
  '{"command":"uvx","args":["fastmcp","run","https://aws-mcp.us-east-1.api.aws/mcp"]}'
```

## DevOps Agent 中国区桥接架构（不变）

Agent Toolkit 无法替代此架构，因为 DevOps Agent 需要 Streamable HTTP transport + 公网 endpoint，且需要访问 aws-cn。

```
DevOps Agent (Global, us-east-1)
    │ X-API-Key header
    ▼
ALB (mcp-cn.aws.panlm.click)
    ▼
EC2: awslabs/aws-api-mcp-server (AUTH_TYPE=no-auth)
    │ boto3 profile → IAM Roles Anywhere
    ▼
aws-cn (cn-north-1 / cn-northwest-1)
```

详见: [[AWS DevOps Agent 接入中国区方案]]

## 参考链接

- [AWS Blog: The AWS MCP Server is now generally available](https://aws.amazon.com/blogs/aws/the-aws-mcp-server-is-now-generally-available/)
- [Agent Toolkit for AWS 产品页](https://aws.amazon.com/products/developer-tools/agent-toolkit-for-aws/)
- [Agent Toolkit GitHub](https://github.com/aws/agent-toolkit-for-aws)
- [MCP Proxy for AWS GitHub](https://github.com/aws/mcp-proxy-for-aws)
- [awslabs/mcp GitHub](https://github.com/awslabs/mcp)
- [AWS MCP Server User Guide](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/mcp-server.html)