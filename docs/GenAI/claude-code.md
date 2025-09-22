---
title: Claude Code
description:
created: 2025-09-08 14:20:22.908
last_modified: 2025-09-08
tags:
  - draft
  - llm
---

# claude-code

```mermaid
flowchart LR
    A[Claude Code] --> B[LiteLLM]
    B --> C[OpenAI Compatible API]
    C --> D[大型语言模型]

```

## use litellm directly

https://docs.anthropic.com/en/docs/claude-code/llm-gateway

```
export ANTHROPIC_BASE_URL=https://litellm.xxx
export ANTHROPIC_AUTH_TOKEN=sk-xxx
export ANTHROPIC_MODEL="us.anthropic.claude-3-7-sonnet-20250219-v1:0"

claude

```

refer: [[litellm]]

## use claude-code-router

https://github.com/musistudio/claude-code-router/tree/main

only support openrouter, not support litellm




