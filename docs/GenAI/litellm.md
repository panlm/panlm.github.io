---
title: litellm
description: vs Openrouter
created: 2025-09-07 21:34:39.492
last_modified: 2025-09-07
tags:
  - draft
  - llm
---

# litellm

openrouter vs litellm 
- saas vs self-managed

## roocode with litellm

[doc link](https://docs.roocode.com/providers/litellm?utm_source=extension&utm_medium=ide&utm_campaign=provider_docs)

（首选）在 litellm 中添加 AWS AKSK 后，通过 Bedrock 添加的模型 `us.anthropic.claude-3-7-sonnet-20250219-v1:0`，在 roocode 中如何使用它

![[attachments/litellm/IMG-20251010-1249787.png|300]]

（存在多次调用）在 litellm 中添加 openai compatible API 后，例如 litellm 中调用 brconnector 中的 `cr-claude-3-5-sonnet-v2`，在 roocode 中如何使用它

![[attachments/litellm/IMG-20251010-1245407.png|300]]

（不稳定）如果下面配置无法生效，或者显示刷新模型失败，考虑直接访问远程4000端口，或先禁用代理再启用

![[attachments/litellm/IMG-20251010-1309170.png|300]]

## Setup 

https://github.com/BerriAI/litellm?tab=readme-ov-file#proxy-key-management-docs

- need docker ([[git/git-mkdocs/CLI/linux/docker-cmd#install-]])
- run 
```sh
# Get the code
git clone https://github.com/BerriAI/litellm

# Go to folder
cd litellm

# Add the master key - you can change this after setup
echo 'LITELLM_MASTER_KEY="sk-1234"' > .env

# Add the litellm salt key - you cannot change this after adding a model
# It is used to encrypt / decrypt your LLM API Key credentials
echo 'LITELLM_SALT_KEY="sk-1234"' >> .env

source .env

# Start
docker compose up -d

```

### get more latest stable version

- https://github.com/BerriAI/litellm/pkgs/container/litellm

## Add OpenAI Compatibile API

- add models in BRConnector 
    - add `openai` prefix
    - use https://openai-url/v1
![[attachments/litellm/IMG-20250921-1431090.png|800]]

## litellm cli

不能用来调用 code review，因为它没有 agent 能力，不会自动访问文件或目录
https://docs.litellm.ai/docs/proxy/management_cli

```bash
export LITELLM_PROXY_API_KEY=sk-xxx
export LITELLM_PROXY_URL=https://litellm.xxx


litellm-proxy models list
litellm-proxy chat completions 'us.anthropic.claude-3-5-sonnet-20241022-v2:0' \
  -m "user: hi who are u "

```

## todo

- integration with sagemaker










