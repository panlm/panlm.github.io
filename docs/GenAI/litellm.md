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
