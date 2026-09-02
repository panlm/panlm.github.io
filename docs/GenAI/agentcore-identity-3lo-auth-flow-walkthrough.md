---
title: AgentCore Identity 3LO 授权全过程（日志还原）
description: 从 ECS + CloudTrail 真实日志还原 AgentCore Identity 3-legged OAuth（Authorization Code Grant）出站授权时序，并与 AWS 官方 blog / 文档对齐
created: 2026-07-13
last_modified: 2026-07-13
tags:
- llm/agentcore
- aws/identity
- oauth
permalink: git-mkdocs/gen-ai/agentcore-identity-3lo-auth-flow-walkthrough
---

# AgentCore Identity 3LO 授权全过程（真实日志还原）

> 配套部署见 [AgentCore Identity 3LO on ECS（Cognito 替代 Entra ID）](agentcore-identity-3lo-ecs-cognito.md)。
> 本文用一次**真实成功授权**的日志（2026-07-13，账号 123456789012，us-west-2），把 3-legged OAuth（Authorization Code Grant）出站授权的每一步还原出来，并逐条对齐 AWS 官方描述。
> 参考：
> - Blog：[Secure AI agents with Amazon Bedrock AgentCore Identity on Amazon ECS](https://aws.amazon.com/blogs/machine-learning/secure-ai-agents-with-amazon-bedrock-agentcore-identity-on-amazon-ecs/) → 章节 *Amazon Bedrock AgentCore Identity: Authorization Code Grant*
> - 官方文档：[OAuth 2.0 authorization URL session binding](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/oauth2-authorization-url-session-binding.html)

## 参与角色

| 角色 | 职责 |
|---|---|
| **User（浏览器）** | 通过 ALB→Cognito 完成 inbound 登录；点授权 URL 给 GitHub 授权 |
| **Agent（ECS 服务）** | 跑 Strands agent，调 `list_github_repos` 工具时向 AgentCore Identity 取 token |
| **Session Binding Service（ECS 服务）** | 独立 HTTPS 端点 `/oauth2/session-binding`，接 AgentCore 回调，验证"发起授权的人 == 当前登录的人"，再让 AgentCore 存 token |
| **AgentCore Identity** | 生成授权 URL、管 Workload Identity、抓并存 token 到 **Token Vault**（按用户隔离） |
| **GitHub** | OAuth 授权服务器 + 资源服务器（`api.github.com`） |

## 关键前提：token 存在 Token Vault，按用户隔离

agent 每次调工具前先向 AgentCore Identity 取 token：
- **Vault 里该用户有有效 token** → 直接返回 → 跳过授权（agent 直接干活）
- **Vault 里没有** → 触发 3LO → 返回授权 URL，走完整授权

> 这解释了为什么 demo「从头演示」要**换一个 inbound 用户**（新用户在 vault 里没 token）。详见配套文档的 Demo reset 一节。

## 完整时序（真实日志还原）

本次用一个**全新 Cognito 用户** `demo02@example.com` 登录，它从未授权过 GitHub，所以走了完整 3LO。

日志源三路：
- **ECS Agent** log group：`AgentOAuthStack-...AgentLogGroup...`
- **ECS SessionBinding** log group：`AgentOAuthStack-...SessionBindingLogGroup...`
- **CloudTrail**（AgentCore Identity 数据面无独立 log group，走 CloudTrail）

时间戳：CloudTrail 显示为 UTC+8（北京时间），ECS 日志为 UTC。下表已统一标注 UTC。

### 阶段 0：Inbound 登录（ALB → Cognito）

```
CloudTrail 12:10:34 UTC  Token_POST  cognito-idp.amazonaws.com
```
用户在 Cognito Hosted UI 登录，ALB 完成 OIDC 认证，浏览器带着会话进入 `/docs`。

### 阶段 1：Execute #1 — agent 取 token 发现 vault 空，生成授权 URL

```
Agent      12:10:57 UTC  POST /invocations HTTP/1.1 200 OK
CloudTrail 12:10:57 UTC  GetWorkloadAccessTokenForUserId  bedrock-agentcore
CloudTrail 12:10:59 UTC  GetResourceOauth2Token           bedrock-agentcore
Agent      12:10:59 UTC  Getting OAuth2 token...
Agent      12:10:59 UTC  ERROR - Error in requires_access_token decorator
Agent      12:10:59 UTC  AuthorizationRequiredError: Please authorize GitHub access:
           https://bedrock-agentcore.us-west-2.amazonaws.com/identities/oauth2/authorize?request_uri=urn:ietf:params:oauth:request_uri:NDU0ZjJj...
Agent      12:11:08 UTC  Tool #1: list_github_repos
           → "It looks like you need to authorize GitHub access first. Please click the link ..."
```

**发生了什么**：
1. agent 收到 `/invocations`，调 `list_github_repos` 工具
2. 工具的 `@requires_access_token` 装饰器先用 **`GetWorkloadAccessTokenForUserId`** 拿到代表该用户的 workload access token
3. 再调 **`GetResourceOauth2Token`** 向 vault 要 GitHub token → vault 空
4. AgentCore 于是返回一个**授权 URL**（含 `request_uri=...NDU0ZjJj...`，这是本次授权会话的 session URI）
5. agent 把授权 URL 作为响应返回给用户

> 对应官方步骤 **1. Invoke agent（GetResourceOauth2Token）** + **2. Generate authorization URL**。

### 阶段 2：用户授权 → 回调 Session Binding Service

用户点开授权 URL → 跳 GitHub → 登录并 **Authorize**。GitHub 授权后，AgentCore Identity 把浏览器重定向到应用注册的 HTTPS 回调端点：

```
SessionBinding 12:11:36 UTC  GET /oauth2/session-binding?session_id=urn:ietf:params:oauth:request_uri:NDU0ZjJj... HTTP/1.1 200 OK
```

**发生了什么**：
1. 回调带回 `session_id`，**其值正是阶段 1 授权 URL 里的 `request_uri`（`NDU0ZjJj...`）** —— 两者一致是关键
2. Session Binding Service 校验：发起授权请求的用户 == 当前浏览器登录的用户（防止授权 URL 被转发给别人盗权）
3. 校验通过 → 调 **`CompleteResourceTokenAuth`** → AgentCore Identity 去 GitHub 换取 access token，**存入 Token Vault**（按该用户隔离）

> 对应官方步骤 **3. Authorize and obtain access token**。`request_uri == session_id` 就是官方强调的 session binding 防串号机制的实证。

### 阶段 3：Execute #2 — agent 复用 vault token，成功拿 repo

```
Agent      12:12:24 UTC  POST /invocations HTTP/1.1 200 OK
Agent      12:12:27 UTC  Getting OAuth2 token...
CloudTrail 12:12:27 UTC  GetResourceOauth2Token  bedrock-agentcore
Agent      12:12:28 UTC  HTTP Request: GET https://api.github.com/user/repos?per_page=10&sort=updated "HTTP/1.1 200 OK"
Agent      12:12:38 UTC  Tool #1: list_github_repos
Agent      12:12:38 UTC  Here are your GitHub repositories:
           1. litellm  2. panlm.github.io  3. devops-agent-ui  ...  10. aws-bestpractice-research-skill
```

**发生了什么**：
1. 用户回 `/docs` 再次 Execute 同一请求
2. agent 再调 `GetResourceOauth2Token` → 这次 vault **有 token** → 返回 GitHub access token
3. 工具带 token 调 `GET api.github.com/user/repos` → **200 OK**
4. agent 把 repo 列表返回给用户

> 对应官方步骤 **4. Re-invoke agent to obtain access token**。

## 与官方 4 步的逐条对齐

| 官方文档步骤 | 本次日志证据（UTC） |
|---|---|
| 1. Invoke agent → `GetResourceOauth2Token` 取授权 URL | 12:10:57 `GetWorkloadAccessTokenForUserId` + 12:10:59 `GetResourceOauth2Token`（vault 空） |
| 2. Generate authorization URL + session URI | agent 抛出 `.../authorize?request_uri=...NDU0ZjJj...` |
| 3. 用户授权 → 重定向应用端点 → `CompleteResourceTokenAuth` 存 token | 12:11:36 SessionBinding `/oauth2/session-binding?session_id=...NDU0ZjJj...` 200 |
| 4. Re-invoke → 取到 access token | 12:12:27 `GetResourceOauth2Token`（第 2 次）+ `api.github.com/user/repos 200` → repo 列表 |

结论：**ECS + CloudTrail 日志与官方 blog/文档的 Authorization Code Grant 时序完全吻合**，`request_uri`↔`session_id` 一致印证了 session binding 的用户校验环节。

## 涉及的 AgentCore Identity API（数据面，走 CloudTrail 可见）

| API | 何时调 | 作用 |
|---|---|---|
| `GetWorkloadAccessTokenForUserId` | 每次取 token 前 | 换取代表某 inbound 用户的 workload access token |
| `GetResourceOauth2Token` | agent 取 GitHub token 时 | 查 vault；无则返回授权 URL，有则返回 access token |
| `CompleteResourceTokenAuth` | Session Binding 校验通过后 | 令 AgentCore 去 GitHub 换 token 并存入 vault |

## 失败排查速查（本次踩过的坑）

| 现象 | 根因 | 处理 |
|---|---|---|
| Swagger 报 `Error: response status is 200` | 响应是流式，Swagger 无法渲染，非真失败 | 看 ECS 日志或浏览器 DevTools Network 的原始响应 |
| 每次都要求重新授权、vault 一直空 | 授权回调没走完（GitHub callback URL 与 provider 的 callbackUrl 不一致，redirect_uri mismatch） | GitHub OAuth App 的 callback 必须**精确等于** provider 的 `callbackUrl` |
| `401 Unauthorized` 调 `api.github.com` | 用户在 GitHub 侧 Revoke 了授权，但 vault 里旧 token 未清 | vault 无删单 token 的 API；换用户，或删+重建 provider |
| `ConverseStream AccessDeniedException`（marketplace subscribe） | 新账号 Bedrock 模型访问未开通 | admin 跑 `create-foundation-model-agreement`；建后等 3–5 分钟传播 |
