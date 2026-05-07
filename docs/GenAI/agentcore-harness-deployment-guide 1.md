---
title: agentcore-harness-deployment-guide 1
type: note
permalink: main/agentcore-harness-deployment-guide-1
---

# 将 Claude Code Skill 部署到 AWS AgentCore Managed Harness Agent

## 方案概述

本方案将原本在 Claude Code / Cursor 中通过 Skill 执行的 AWS 最佳实践评估能力，打包部署到 **Amazon Bedrock AgentCore Managed Harness Agent** 上，实现云端托管、无需本地环境、按需调用的 AI Agent 服务。

### 核心思路

```
评估 Skill 文件 (SKILL.md + references/)     AWS Knowledge MCP Server
        ↓ 烘焙进容器                              ↓ remote_mcp 直连
Ubuntu arm64 容器镜像                      https://knowledge-mcp.global.api.aws
  (AWS CLI + kubectl + 6 Skills)                   ↓
        ↓ 推送 ECR                          Harness Tool 配置
        ↓                                         ↓
AgentCore Managed Harness ←─── skills[] + tools[remote_mcp] + CWL Observability
        ↓
invoke_harness API → Agent 加载 Skill + 调用 MCP 搜文档 + shell 跑命令 → 报告
```

---

## 1. 架构对比

| 维度 | Claude Code 本地 | AgentCore Managed Harness |
|------|-----------------|---------------------------|
| 运行环境 | 本地终端 | AWS 托管 microVM (隔离沙箱) |
| 模型调用 | Claude API | Amazon Bedrock (多模型可选) |
| Skill 加载 | `.agents/skills/` 目录 | 容器内预装 + `skills` 参数指向路径 |
| 工具执行 | 本地 shell | microVM 内 shell (内置) |
| MCP 工具 | MCP Server 本地连接 | `remote_mcp` 原生直连 |
| 状态管理 | 无 | 有状态 Session (可持久化) |
| 扩展性 | 单用户 | API 调用，支持多用户并发 |

---

## 2. Skill 与工具清单

容器内预装 **6 个评估 Skill**，MCP 工具通过 `remote_mcp` 原生接入。

### 容器内评估 Skill

| Skill | 用途 |
|-------|------|
| `aws-best-practice-research` | AWS 服务最佳实践调研与评估 |
| `eks-workload-best-practice-assessment` | EKS 工作负载级别深度评估 |
| `aws-service-chaos-research` | 混沌工程调研 |
| `aws-fis-experiment-prepare` | AWS FIS 实验准备 |
| `aws-fis-experiment-execute` | AWS FIS 实验执行 |
| `app-service-log-analysis` | 应用/服务日志分析 |

### Remote MCP 工具 (通过 Harness `tools` 配置直连)

```json
{
  "type": "remote_mcp",
  "name": "aws-knowledge-mcp",
  "config": {
    "remoteMcp": {
      "url": "https://knowledge-mcp.global.api.aws"
    }
  }
}
```

> **限制**: `remote_mcp` 仅支持 URL + 可选 headers，**不支持 SigV4 签名**。要调用需要 SigV4 的 AgentCore Runtime MCP Server，必须通过 AgentCore Gateway 包装（见下方 Gateway 工具）。

Harness 自动发现并注入以下 MCP 工具供 Agent 使用：

| MCP Tool | 用途 |
|----------|------|
| `aws___search_documentation` | 搜索 AWS 文档（按主题分类） |
| `aws___read_documentation` | 读取特定 AWS 文档页面内容 |
| `aws___recommend` | 获取相关文档推荐 |
| `aws___get_regional_availability` | 查询服务/API 的区域可用性 |
| `aws___list_regions` | 列出所有 AWS 区域 |
| `aws___retrieve_agent_sop` | 获取标准操作流程 (SOP) |

### AgentCore Gateway 工具 (通过 Gateway 调用 SigV4 MCP Server)

当目标 MCP Server 部署在 AgentCore Runtime 上（需 SigV4 认证）时，Harness 无法直接用 `remote_mcp` 连接。解决方案：

1. 创建 AgentCore Gateway，inbound auth 设为 `AWS_IAM`
2. 添加 MCP server target，outbound auth 设为 `GATEWAY_IAM_ROLE` + `service=bedrock-agentcore`
3. Harness 使用 `agentcore_gateway` 工具类型挂载

```json
{
  "type": "agentcore_gateway",
  "name": "billing-gateway",
  "config": {
    "agentCoreGateway": {
      "gatewayArn": "arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/my-gateway-id"
    }
  }
}
```

**IAM 权限要求**：
- **Gateway role**: 需要 `bedrock-agentcore:InvokeAgentRuntime` 权限（调目标 MCP runtime）
- **Harness role**: 需要 `bedrock-agentcore:InvokeGateway` 权限（调 Gateway 本身）

Gateway 工具名自动加前缀 `<target-name>___`，如 `billing-mcp-target___cost-explorer`。

---

## 3. 容器镜像构建

### 3.1 目录结构

```
harness-container/
├── Dockerfile
└── skills/
    ├── aws-best-practice-research/
    │   ├── SKILL.md
    │   ├── references/
    │   │   ├── assessment-workflow.md
    │   │   ├── output-template.md
    │   │   └── search-queries.md
    │   ├── README.md
    │   └── README_CN.md
    ├── eks-workload-best-practice-assessment/
    │   ├── SKILL.md
    │   ├── references/
    │   └── ...
    ├── aws-service-chaos-research/
    ├── aws-fis-experiment-prepare/
    ├── aws-fis-experiment-execute/
    └── app-service-log-analysis/
```

### 3.2 Dockerfile

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:${PATH}"

# Core tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip jq git python3 python3-pip ca-certificates groff less \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2 (arm64)
RUN curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip \
    && cd /tmp && unzip -qo awscliv2.zip && ./aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# kubectl
RUN curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# eksctl
RUN curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_arm64.tar.gz" \
    | tar xz -C /usr/local/bin

# Assessment skills baked in (MCP tools via remote_mcp, no wrapper skills needed)
COPY skills/ /opt/.agents/skills/

# Verification
RUN aws --version && kubectl version --client=true 2>/dev/null && echo "Build OK"
```

> **关键约束**: AgentCore 要求容器必须是 **`linux/arm64`** 架构。

### 3.3 构建和推送

```bash
# 准备 skill 文件
mkdir -p harness-container/skills

# 复制评估类 skill (从 GitHub 仓库)
git clone --depth 1 https://github.com/<YOUR_ORG>/skills.git /tmp/skills-repo
for d in /tmp/skills-repo/*/; do
  [ -f "$d/SKILL.md" ] && cp -r "$d" harness-container/skills/
done

# 构建 arm64 镜像
docker build --platform linux/arm64 -t harness-skills-agent:latest harness-container/

# 创建 ECR 仓库
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
aws ecr create-repository --repository-name harness-skills-agent --region $REGION

# 推送到 ECR
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/harness-skills-agent:latest"
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
docker tag harness-skills-agent:latest $ECR_URI
docker push $ECR_URI

# 备选：使用 crane 推送 (绕过 Docker daemon 网络问题)
# docker save harness-skills-agent:latest -o /tmp/image.tar
# crane auth login "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com" \
#   -u AWS -p $(aws ecr get-login-password --region $REGION)
# crane push /tmp/image.tar $ECR_URI
```

---

## 4. IAM 配置

### 4.1 创建 Execution Role

```bash
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "bedrock-agentcore.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name AgentCoreHarnessExecutionRole \
  --assume-role-policy-document file://trust-policy.json
```

### 4.2 附加权限策略

```bash
# ECR 拉取镜像
aws iam attach-role-policy --role-name AgentCoreHarnessExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# CloudWatch Logs (Observability)
aws iam attach-role-policy --role-name AgentCoreHarnessExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

# X-Ray (分布式追踪)
aws iam attach-role-policy --role-name AgentCoreHarnessExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess

# 自定义: Bedrock 模型调用 + 目标服务只读权限
cat > harness-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockModelInvocation",
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
      "Resource": "*"
    },
    {
      "Sid": "AWSReadAccess",
      "Effect": "Allow",
      "Action": [
        "eks:Describe*", "eks:List*",
        "ec2:Describe*",
        "autoscaling:Describe*",
        "iam:GetRole", "iam:GetPolicy", "iam:ListAttachedRolePolicies",
        "elasticloadbalancing:Describe*",
        "logs:DescribeLogGroups", "logs:GetLogEvents",
        "cloudwatch:GetMetricData", "cloudwatch:DescribeAlarms",
        "sts:GetCallerIdentity", "tag:GetResources"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy --role-name AgentCoreHarnessExecutionRole \
  --policy-name HarnessExecutionPolicy \
  --policy-document file://harness-policy.json
```

---

## 5. 创建 Harness Agent

### 5.1 使用 boto3 创建

```python
import boto3

client = boto3.client('bedrock-agentcore-control', region_name='us-east-1')

ACCOUNT_ID = "<YOUR_ACCOUNT_ID>"
ROLE_ARN = f"arn:aws:iam::{ACCOUNT_ID}:role/AgentCoreHarnessExecutionRole"
CONTAINER_URI = f"{ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/harness-skills-agent:latest"

SKILL_PATHS = [
    "/opt/.agents/skills/aws-best-practice-research",
    "/opt/.agents/skills/eks-workload-best-practice-assessment",
    "/opt/.agents/skills/aws-service-chaos-research",
    "/opt/.agents/skills/aws-fis-experiment-prepare",
    "/opt/.agents/skills/aws-fis-experiment-execute",
    "/opt/.agents/skills/app-service-log-analysis",
]

resp = client.create_harness(
    harnessName="skills_agent",
    executionRoleArn=ROLE_ARN,

    environmentArtifact={
        "containerConfiguration": {"containerUri": CONTAINER_URI}
    },

    model={
        "bedrockModelConfig": {
            "modelId": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
            "maxTokens": 16384,
        }
    },

    systemPrompt=[{
        "text": """You are an expert AWS Solutions Architect with access to
multiple assessment skills and AWS documentation tools.

## Assessment Skills (pre-installed at /opt/.agents/skills/)
- aws-best-practice-research: AWS service best practice assessment
- eks-workload-best-practice-assessment: EKS workload deep assessment
- aws-service-chaos-research: Chaos engineering research
- aws-fis-experiment-prepare / execute: FIS experiment lifecycle
- app-service-log-analysis: Application/service log analysis

## AWS Documentation Tools (via MCP)
You have aws-knowledge-mcp-server tools: search_documentation,
read_documentation, recommend, get_regional_availability, list_regions,
retrieve_agent_sop.

When asked to perform an assessment:
1. Load the appropriate SKILL.md and follow its workflow
2. Use MCP tools to search/read AWS documentation for best practices
3. Use shell to run AWS CLI, kubectl commands for live checks
4. Produce a comprehensive report

All CLI tools (aws, kubectl, eksctl, jq, git) are pre-installed.
Always use --region flag. Output in Chinese unless specified otherwise."""
    }],

    # remote_mcp 原生直连 AWS Knowledge MCP Server
    tools=[{
        "type": "remote_mcp",
        "name": "aws-knowledge-mcp",
        "config": {
            "remoteMcp": {
                "url": "https://knowledge-mcp.global.api.aws"
            }
        }
    }],

    skills=[{"path": p} for p in SKILL_PATHS],

    environment={
        "agentCoreRuntimeEnvironment": {
            "lifecycleConfiguration": {
                "idleRuntimeSessionTimeout": 1800,
                "maxLifetime": 7200,
            },
            "networkConfiguration": {"networkMode": "PUBLIC"}
        }
    },

    maxIterations=50,
    timeoutSeconds=3600,

    tags={
        "project": "best-practice-assessment",
        "owner": "<YOUR_ALIAS>",
    },
)
```

### 5.2 Observability (CloudWatch 日志)

Harness **自动**生成 traces、logs、metrics 到 CloudWatch，无需额外配置：

- **Traces**: 每次 invoke 自动记录模型调用、工具执行、shell 命令的时序和 payload
- **Logs**: 流式输出到 CloudWatch Logs
- **Metrics**: session 数量、延迟、token 用量、错误率 (OpenTelemetry 格式)

**前提条件**:
1. Execution Role 需要 `CloudWatchLogsFullAccess` + `AWSXRayDaemonWriteAccess` 权限
2. 账户需要一次性[启用 CloudWatch Transaction Search](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Enable-Lambda-TransactionSearch.html)

**查看日志**:
```bash
# AgentCore CLI
agentcore logs --harness skills_agent
agentcore traces list --harness skills_agent

# CloudWatch Console → AgentCore Observability Dashboard
```

### 5.3 模型选择注意事项

| 错误场景 | 原因 | 正确做法 |
|---------|------|---------|
| `The provided model identifier is invalid` | 直接使用 foundation model ID | 改用 **inference profile ID** |
| `Invocation with on-demand throughput isn't supported` | 使用了 foundation model ID | 改用 `us.xxx` 或 `global.xxx` 前缀的 profile |
| `marked by provider as Legacy` | 模型已过期 | 选择 ACTIVE 状态的模型 |

```bash
# 查看可用的 inference profiles
aws bedrock list-inference-profiles --region us-east-1 \
  --query "inferenceProfileSummaries[?contains(inferenceProfileId,'sonnet') && status=='ACTIVE'].{id:inferenceProfileId,name:inferenceProfileName}" \
  --output table
```

---

## 6. 调用 Agent

### 6.1 直接调用 (Python)

```python
import boto3, uuid
from botocore.config import Config

config = Config(read_timeout=900)  # 评估耗时长，需要大超时
client = boto3.client('bedrock-agentcore', region_name='us-east-1', config=config)

HARNESS_ARN = "arn:aws:bedrock-agentcore:us-east-1:<ACCOUNT_ID>:harness/<HARNESS_ID>"
SESSION_ID = str(uuid.uuid4()) + "-assessment"

resp = client.invoke_harness(
    harnessArn=HARNESS_ARN,
    runtimeSessionId=SESSION_ID,
    skills=[{"path": "/opt/.agents/skills/aws-best-practice-research"}],
    messages=[{
        "role": "user",
        "content": [{"text": "请对 us-west-2 的 my-cluster EKS 集群执行最佳实践评估"}]
    }],
)

for event in resp["stream"]:
    if "contentBlockDelta" in event:
        delta = event["contentBlockDelta"].get("delta", {})
        if "text" in delta:
            print(delta["text"], end="", flush=True)
```

### 6.2 读取 Agent 生成的文件

```python
resp = client.invoke_agent_runtime_command(
    agentRuntimeArn=HARNESS_ARN,
    runtimeSessionId=SESSION_ID,
    body={"command": "cat /tmp/eks-report.md"},
)
for event in resp["stream"]:
    chunk = event.get("chunk", {})
    if "contentDelta" in chunk:
        if "stdout" in chunk["contentDelta"]:
            print(chunk["contentDelta"]["stdout"], end="")
```

### 6.3 多轮对话 (同一 Session)

```python
# 第一轮: 评估
client.invoke_harness(
    harnessArn=HARNESS_ARN,
    runtimeSessionId=SESSION_ID,  # 保持同一 session
    messages=[{"role": "user", "content": [{"text": "评估 my-cluster"}]}],
)

# 第二轮: 追问 (agent 保留了上下文)
client.invoke_harness(
    harnessArn=HARNESS_ARN,
    runtimeSessionId=SESSION_ID,  # 同一 session
    messages=[{"role": "user", "content": [{"text": "帮我生成修复脚本"}]}],
)
```

---

## 7. 踩坑记录

### 7.1 区域支持

AgentCore Managed Harness 目前在 Preview 阶段，仅支持：

- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)
- `eu-central-1` (Frankfurt)
- `ap-southeast-2` (Sydney)

**东京 (ap-northeast-1) 不支持 Harness**，但 Agent 可以跨区域操作 AWS 资源 (通过 `--region` 参数)。

### 7.2 Base 环境极简

AgentCore 默认 base 环境是 Amazon Linux 2023 minimal：
- 没有 `aws` CLI
- 没有 `pip` / `python3-pip`
- 没有 `curl` (只有 `curl-minimal`，且有包冲突)
- 没有 `find`, `which`, `unzip`

**解决方案**: 构建自定义容器镜像，预装所有依赖。

### 7.3 ECR 权限

Harness Execution Role **必须**有 ECR 拉取权限才能使用自定义容器：

```bash
aws iam attach-role-policy --role-name AgentCoreHarnessExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

遗漏这一步会导致: `ECR access denied ... ecr:GetAuthorizationToken`

### 7.4 流式读取超时

Agent 执行评估时，中间有长时间的工具调用 (shell 命令)，客户端流可能超时。

```python
from botocore.config import Config
config = Config(read_timeout=900)  # 15 分钟
client = boto3.client('bedrock-agentcore', config=config)
```

### 7.5 容器 ENTRYPOINT

AgentCore 会**覆盖**容器的 `ENTRYPOINT` 和 `CMD`。不要依赖容器启动命令，把所有初始化放到 Dockerfile 的 `RUN` 阶段，或通过 `InvokeAgentRuntimeCommand` 在 session 启动后执行。

### 7.6 remote_mcp 不支持 SigV4

Harness 的 `remote_mcp` 工具类型只接受 URL + 可选 headers，**不支持 SigV4 签名**。这意味着：
- 公开 MCP Server（如 `https://knowledge-mcp.global.api.aws`）可以直连
- 部署在 AgentCore Runtime 上的 MCP Server（如 billing MCP）必须通过 **AgentCore Gateway** 包装后使用 `agentcore_gateway` 工具类型接入

**架构对比**：

| 目标 MCP Server | 认证方式 | Harness 工具类型 |
|---|---|---|
| 公开 HTTP(S) | 无 / API Key | `remote_mcp` (URL + headers) |
| AgentCore Runtime MCP | SigV4 | `agentcore_gateway` (需创建 Gateway + MCP target) |
| 需要 OAuth 的 MCP | OAuth 2.0 | `agentcore_gateway` (Gateway + OAuth credential provider) |

### 7.7 不依赖 shell 的纯 MCP 工具 Harness

如果 Harness 只通过 MCP 工具（不用 shell 跑 aws cli / kubectl），容器镜像可以极度精简：

```dockerfile
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
```

**实际案例**：billing_query_agent 用最小 ubuntu arm64 镜像 (~30MB)，所有费用查询通过 Gateway → billing MCP 工具完成，不需要 AWS CLI。

---

## 8. Skill 加载方式对比

| 方式 | 适用场景 | 优缺点 |
|------|---------|--------|
| **容器镜像预装** (本方案) | 生产环境 | 秒级启动，版本可控；更新需重新构建镜像 |
| **Session 启动时从 S3 拉取** | 开发测试 | 灵活，无需重建镜像；每次 session 有额外延迟 |
| **`npx` 安装公共 Skill** | 使用社区 Skill | 方便；仅限已发布的公共 Skill |

```python
# 容器镜像方式 (推荐) — 创建 harness 时注册 skill 路径
skills=[{"path": "/opt/.agents/skills/aws-best-practice-research"}]
```

```bash
# S3 拉取方式 — Session 启动后通过 exec 命令拉取
agentcore invoke --exec --harness my-agent --session-id "$SID" \
  "aws s3 cp s3://my-bucket/skills/ .agents/skills/ --recursive"
```

```bash
# npx 方式 — 安装社区 Skill
agentcore invoke --exec --harness my-agent --session-id "$SID" \
  "npx @anthropic-ai/agent-skills add xlsx github"
```

---

## 9. 后续改进方向

1. **CI/CD 自动化** — 用 GitHub Actions 自动构建镜像、推送 ECR、更新 Harness ([参考](https://aws.amazon.com/blogs/machine-learning/deploy-ai-agents-on-amazon-bedrock-agentcore-using-github-actions/))
2. **多 Harness 拆分** — 按职能创建专用 Harness (安全评估、成本优化、混沌工程)
3. **Memory 持久化** — 启用 AgentCore Memory，跨 session 记住评估历史
4. **自定义 JWT 认证** — 为 Harness 配置 inbound auth，对外暴露安全 API
5. **AgentCore Gateway** — ✅ 已实现：将 billing MCP Server 注册到 Gateway，Harness 通过 `agentcore_gateway` 工具调用（见 7.6 节）
6. **更多 MCP Server** — 挂载更多 remote MCP (如 GitHub MCP, Jira MCP) 扩展 Agent 能力
7. **Inline Functions** — 添加 human-in-the-loop 审批工具，关键操作前需人工确认

---

## 参考链接

- [AgentCore Harness 文档](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/harness.html)
- [Environment and Skills](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/harness-environment.html)
- [Connect to Tools](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/harness-tools.html)
- [Observability](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability.html)
- [create_harness API](https://docs.aws.amazon.com/boto3/latest/reference/services/bedrock-agentcore-control/client/create_harness.html)
- [Strands Agents Skills](https://strandsagents.com/docs/user-guide/concepts/plugins/skills/)