---
title: AgentCore Identity 3LO on ECS (Cognito 版)
description: 用 Cognito 替代 Entra ID，把 AgentCore Identity 3-legged OAuth sample 部署到 ECS Fargate
created: 2026-07-08 16:00:00.000000
last_modified: 2026-07-08
tags:
- draft
- llm/agentcore
- aws/container/ecs
permalink: git-mkdocs/gen-ai/agentcore-identity-3lo-ecs-cognito
---

# AgentCore Identity 3LO on ECS（Cognito 替代 Entra ID）

> 基于 AWS blog [Secure AI agents with Amazon Bedrock AgentCore Identity on Amazon ECS](https://aws.amazon.com/blogs/machine-learning/secure-ai-agents-with-amazon-bedrock-agentcore-identity-on-amazon-ecs/) 的配套 sample 部署。
> 官方 sample：`awslabs/agentcore-samples` → `06-workshops/03-AgentCore-identity/07-Outbound_Auth_3LO_ECS_Fargate`
> 实测环境：账号 123456789012，us-west-2，2026-07-08 部署验证通过。
> 复现记录：2026-07-13 在全新 Workshop 账号（210987654321，`WSParticipantRole`）us-west-2 按本文从零重建，入站链路（DNS + ACM 证书 + `/docs` 302 跳 Cognito）验证通过，全栈 61/61 约 288s 建完。playbook 有效。

## 这个 sample 是什么

演示一个跑在 ECS Fargate 上的 AI agent，用 AgentCore Identity 做两件事：

- **Inbound（入站认证）**：ALB 用 OIDC 认证用户（原 sample 用 Microsoft Entra ID，**本文用 Amazon Cognito User Pool 替代**）
- **Outbound（出站授权）**：agent 用 3-legged OAuth（Authorization Code Grant）代用户去访问 GitHub，token 存在 AgentCore Identity 的 Token Vault

架构：ALB(OIDC 认证) → ECS Fargate 两个服务（Agentic Workload + Session Binding Service）→ Bedrock（Strands Agents + Claude）→ AgentCore Identity 管 GitHub OAuth token。S3 存 session，KMS 加密，WAF 挂 ALB，全程 arm64。

## 本次实测的关键资源清单

| 资源 | 值 |
|---|---|
| 账号 / region | 123456789012 / us-west-2 |
| 应用访问地址 | `https://agent-3lo.id.aws.panlm.click`（入口 `/docs`） |
| Route53 hosted zone | `id.aws.panlm.click` → `<your-hosted-zone-id>`（本账号新建，NS 委派自 panlm 账号的 `aws.panlm.click`） |
| ACM 证书 | `agent-3lo.id.aws.panlm.click`（DNS 验证，us-west-2） |
| Cognito User Pool | `us-west-2_EXAMPLE01` |
| Cognito domain | `agent3lo-example-98844`（→ `agent3lo-example-98844.auth.us-west-2.amazoncognito.com`） |
| Cognito App Client | `<your-app-client-id>`（带 secret） |
| Secrets Manager（Cognito 凭证） | `agent-oauth/credentials` |
| AgentCore Identity GitHub provider | `agent3lo_github_provider`（token-vault/default） |
| GitHub OAuth App client_id | `Ov23liBP9GlstuoP2OG1` |
| CDK bootstrap qualifier | `sample3lo` |

## 前置依赖（硬性）

1. **域名 + Route53 hosted zone**：ALB 走 HTTPS 需要 ACM 证书，必须有可控域名。本次做法见下方"域名准备"。
2. **Bedrock Claude 模型**：us-west-2 已开通（用 `us.anthropic.claude-haiku-4-5`）。
3. **OIDC IdP**：本文用 Cognito User Pool 替代 Entra ID。
4. **GitHub OAuth App**：outbound 授权目标，需自己在 GitHub 建。
5. 工具链：AWS CLI v2.27+、CDK v2、uv、Python 3.12+、Docker、Node。

## 部署步骤

### 1. 域名准备（跨账号 NS 委派）

本账号（123456789012）建子域 hosted zone，再回 panlm 账号的父域加 NS 记录委派：

```bash
# 在本账号建 hosted zone
aws route53 create-hosted-zone --name id.aws.panlm.click \
  --caller-reference "id-aws-panlm-click-$(date +%s)"
# 记下返回的 4 条 NS 记录

# 在 panlm 账号(profile panlm)的 aws.panlm.click zone 加 NS 委派
# UPSERT 一条 Name=id.aws.panlm.click Type=NS，值为上面 4 条 NS
aws route53 change-resource-record-sets --hosted-zone-id <aws.panlm.click的zoneid> \
  --change-batch file://ns_record.json
# 验证：dig NS id.aws.panlm.click @8.8.8.8
```

### 2. GitHub OAuth App + AgentCore Identity provider

**顺序很重要**——AgentCore Identity 会为每个 credential provider 生成**专属 callback URL**，必须先建 provider 才知道这个 URL，再回填 GitHub。

1. GitHub → Settings → Developer settings → OAuth Apps → New OAuth App
   - Homepage URL：`https://agent-3lo.id.aws.panlm.click`（占位即可）
   - Authorization callback URL：**先填占位**（GitHub 强制必填，注册后可改）
   - 拿到 `client_id`，生成 `client_secret`（只显示一次）

2. 用 client_id/secret 建 AgentCore Identity provider（**返回专属 callback URL**）：
```bash
aws bedrock-agentcore-control create-oauth2-credential-provider \
  --name agent3lo_github_provider \
  --credential-provider-vendor GithubOauth2 \
  --oauth2-provider-config-input '{"githubOauth2ProviderConfig":{"clientId":"<CLIENT_ID>","clientSecret":"<CLIENT_SECRET>"}}' \
  --region us-west-2
# 返回里的 callbackUrl 形如:
# https://bedrock-agentcore.us-west-2.amazonaws.com/identities/oauth2/callback/<uuid>
```

3. 回 GitHub OAuth App 设置页，把 Authorization callback URL **改成上面返回的专属 URL**，保存。

### 3. Cognito User Pool（替代 Entra ID 做 inbound OIDC）

```bash
# User Pool（邮箱登录）
aws cognito-idp create-user-pool --pool-name agent-3lo-pool \
  --auto-verified-attributes email --username-attributes email --region us-west-2
# → us-west-2_EXAMPLE01

# Hosted UI domain（前缀全局唯一）
aws cognito-idp create-user-pool-domain --domain agent3lo-example-98844 \
  --user-pool-id us-west-2_EXAMPLE01

# App Client（带 secret，authorization code flow，callback 指向 app 域名）
aws cognito-idp create-user-pool-client --user-pool-id us-west-2_EXAMPLE01 \
  --client-name agent-3lo-client --generate-secret \
  --allowed-o-auth-flows code \
  --allowed-o-auth-scopes openid email profile \
  --callback-urls "https://agent-3lo.id.aws.panlm.click/oauth2/idpresponse" \
  --supported-identity-providers COGNITO \
  --allowed-o-auth-flows-user-pool-client \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --region us-west-2
# → client_id / client_secret

# 存 Secrets Manager（sample 从这里读 IdP 凭证）
aws secretsmanager create-secret --name "agent-oauth/credentials" \
  --secret-string '{"client_id":"<CLIENT_ID>","client_secret":"<CLIENT_SECRET>"}' \
  --region us-west-2
```

Cognito 的 OIDC 端点从 issuer 的 well-known 拿（**不在 hosted UI domain 下，在 issuer 下**）：
```
https://cognito-idp.us-west-2.amazonaws.com/us-west-2_EXAMPLE01/.well-known/openid-configuration
```
- issuer / userinfo：`cognito-idp...`（authorization/token/userinfo 走 hosted UI domain）

### 4. clone sample + 改配置

```bash
git clone --depth 1 https://github.com/awslabs/agentcore-samples.git
cd agentcore-samples/06-workshops/03-AgentCore-identity/07-Outbound_Auth_3LO_ECS_Fargate
```

改 `config.py`（这些字段是 `CdkConfig` 的默认值，不从 .env 读，**必须改代码**）：

- `aws_region`：`eu-west-1` → `us-west-2`
- `identity_aws_region`：`eu-central-1` → `us-west-2`
- `inference_profile_id`：`eu.anthropic...` → `us.anthropic.claude-haiku-4-5-20251001-v1:0`
- `github_provider_name`：默认值（sample 里是 `github-oauth-client-i5yd5` 之类占位）→ `agent3lo_github_provider`（对上第 2 步建的 provider）

写 `.env`（DNS + OIDC 从这里读）：
```
OIDC_ISSUER=https://cognito-idp.us-west-2.amazonaws.com/us-west-2_EXAMPLE01
OIDC_AUTHORIZATION_ENDPOINT=https://agent3lo-example-98844.auth.us-west-2.amazoncognito.com/oauth2/authorize
OIDC_TOKEN_ENDPOINT=https://agent3lo-example-98844.auth.us-west-2.amazoncognito.com/oauth2/token
OIDC_USER_INFO_ENDPOINT=https://agent3lo-example-98844.auth.us-west-2.amazoncognito.com/oauth2/userInfo
OIDC_SECRET_NAME=agent-oauth/credentials
OIDC_SCOPE=openid email profile
DNS_DOMAIN_NAME=id.aws.panlm.click
DNS_HOSTED_ZONE_ID=<your-hosted-zone-id>
```

> ⚠️ **`DNS_DOMAIN_NAME` 填基础 hosted zone 域名（`id.aws.panlm.click`），不要带 `agent-3lo` 前缀！**
> CDK 代码（`cdk/constructs/agent.py`）里 `app_domain = f"agent-3lo.{domain_name}"`，会自己加前缀。
> 若填成 `agent-3lo.id.aws.panlm.click`，会变成 `agent-3lo.agent-3lo.id...`（双层），且跟 ACM 证书不匹配。**踩过这个坑。**

### 5. 部署

```bash
uv sync --all-groups
./deploy_sample.sh
```

脚本流程：检查工具 → 导出 requirements → cdk bootstrap（qualifier `sample3lo`）→ synth + checkov 扫描 → cdk deploy --all。

部署完 Outputs 给出 `AgentAppUrl = https://agent-3lo.id.aws.panlm.click`。

## 重大踩坑：本地 Colima 推 ECR 堵死 → 改用 AWS 内网 EC2 build

**现象**：本地 Colima（QEMU）build 镜像正常，但 `docker push` 到 ECR 卡在 layer `Waiting` 永不完成；配了 proxy 后 `docker login` 私有 ECR 又间歇 `EOF`（首尔 proxy 节点对 ECR TLS 长连接偶发断流，3 次 login 约 1 次失败，CDK 单次失败即退出）。ECR repo 里 0 image，push blob 基本传不动。

**根因**：Colima QEMU slirp 用户态网络对 ECR blob 上行吞吐极低；走 proxy 绕首尔对 AWS endpoint 又不稳。两条路都堵。

**解法（可靠）**：起一台 **us-west-2 的临时 arm64 EC2**（`c7g.xlarge`，AL2023 arm64），在 AWS 内网 build+push+deploy——所有层秒 `Pushed`，主栈几分钟建完。全程用 SSM Run Command 驱动，不需要 SSH/浏览器。

要点：
- 复用现成带 **AdministratorAccess + AmazonSSMManagedInstanceCore** 的 instance profile（本次用 `vscode-server-VSCodeInstanceProfile-*`），免建新 role
- EC2 用 instance profile 自带凭证，且在 us-west-2 内网，push ECR 走内网
- AMI 取最新 AL2023 arm64（可复现）：`aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64 --query Parameter.Value`
- 装 `docker git nodejs npm` + `npm i -g aws-cdk` + uv，clone 同一 sample、同样改 config.py/.env，跑 `deploy_sample.sh`
- ECS task 定义与 Dockerfile 都是 ARM64，EC2 选 arm64 机型架构一致
- 全程用 **SSM Run Command** 驱动（不开 SSH/入站端口）；config.py/.env 用 base64 经 SSM 注入；`deploy_sample.sh` 交互提示在 SSM 里会卡，用 `yes | ./deploy_sample.sh` 非交互跑

> 备选方案（未用）：Docker Desktop（vpnkit 网络比 Colima QEMU 稳）；us-west-2 CloudShell（内网，但要浏览器操作）。

## 验证（从 AWS 内网测，避开本地 proxy 干扰）

```bash
# 证书
echo | openssl s_client -connect agent-3lo.id.aws.panlm.click:443 \
  -servername agent-3lo.id.aws.panlm.click 2>/dev/null | openssl x509 -noout -subject
# → CN=agent-3lo.id.aws.panlm.click

# app 入口 /docs 应 302 跳 Cognito
curl -sI https://agent-3lo.id.aws.panlm.click/docs | grep -iE "HTTP/|location"
# → HTTP/2 302
# → location: https://agent3lo-example-98844.auth.us-west-2.amazoncognito.com/oauth2/authorize?client_id=<your-app-client-id>&redirect_uri=https%3A%2F%2Fagent-3lo.id.aws.panlm.click%2Foauth2%2Fidpresponse&...
```

根路径 `/` 返回 404 是正常的——app 只暴露 `/docs`（OpenAPI UI，充当 demo 界面）和 `/invocations`。

## 端到端测试（2026-07-09 实测）

### 1. 建 Cognito 测试用户

ALB OIDC 登录用。用 `--message-action SUPPRESS` 跳过邀请邮件（占位邮箱收不到也无所谓），再设永久密码免首次改密：

```bash
POOL=us-west-2_EXAMPLE01
USER="testuser@example.com"
PASS="${TEST_PASSWORD:?先 export TEST_PASSWORD=... 再跑}"

aws cognito-idp admin-create-user --user-pool-id $POOL \
  --username "$USER" \
  --user-attributes Name=email,Value="$USER" Name=email_verified,Value=true \
  --message-action SUPPRESS --region us-west-2

aws cognito-idp admin-set-user-password --user-pool-id $POOL \
  --username "$USER" --password "$PASS" --permanent --region us-west-2

# 确认 UserStatus=CONFIRMED
aws cognito-idp admin-get-user --user-pool-id $POOL --username "$USER" \
  --query '[Username,UserStatus]' --output text
```

> 占位邮箱 `testuser@example.com` 即可，Cognito 不校验真实性（`email_verified=true` 手动置）。测试完删。

### 2. 浏览器登录（inbound OIDC）

1. 打开 `https://agent-3lo.id.aws.panlm.click/docs`
2. 自动 302 跳 Cognito Hosted UI 登录页 → 输入上面用户名密码
3. 登录成功回到 `/docs`，看到 FastAPI OpenAPI UI（标题 `Agent Runtime - sample`，含 `GET /ping`、`POST /invocations` 两个端点）
   - 到这一步说明 **ALB → Cognito OIDC 入站认证链路打通**

### 3. 调 agent（触发 outbound 3LO）

在 `/docs` 页面：

1. 展开 **POST `/invocations`** → 点 **Try it out**
2. Request body 填：
   ```json
   {
     "sessionId": "test-session-1",
     "message": "list my github repositories"
   }
   ```
3. 点 **Execute**
4. agent 调 GitHub 工具时，因为该用户还没授权过 GitHub（3LO 首次），响应里会返回一个 **GitHub 授权 URL**
5. 打开该授权 URL → GitHub 登录并同意授权 → 回调到 Session Binding Service（`/oauth2/session-binding`）完成 token 绑定
6. 再次 Execute 同样请求 → agent 已能拿到该用户的 GitHub token，正常返回 repo 列表

> 这就是 3LO（3-Legged OAuth）的核心：用户**亲自授权**后，agent 才拿到代表该用户的 token，token 按用户隔离存在 AgentCore Identity Token Vault，后续请求自动复用。

## 清理

```bash
# 在部署目录
uv run cdk destroy --all
# 手动删残留：S3 桶内容 (sessions-123456789012-sample)、CloudWatch 日志组、Secrets Manager secret
# 额外资源：临时 build EC2、Cognito User Pool、ACM 证书、AgentCore Identity provider、Route53 zone + NS 委派记录
```
