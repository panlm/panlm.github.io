---
title: opencode
description: opencode
created: 2026-01-08 09:02:24.499
last_modified: 2026-01-08
tags: 
  - draft
---

# opencode

## install

- https://opencode.ai/
- oh-my-openagent
    - https://github.com/code-yeongyu/oh-my-opencode/blob/dev/README.zh-cn.md

## bashrc

```
export LITELLM_PROXY_URL=https://litellm.xxx/v1
export LITELLM_PROXY_API_KEY=sk-xxx
export OPENCODE_MODEL=opus-4-6
export CONTEXT7_API_KEY=ctx7sk-xxx
```

## opencode.json

```
{
  "$schema": "https://opencode.ai/config.json",
  "model": "litellm/{env:OPENCODE_MODEL}",
  "provider": {
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LiteLLM Proxy",
      "options": {
        "baseURL": "{env:LITELLM_PROXY_URL}",
        "apiKey": "{env:LITELLM_PROXY_API_KEY}"
      },
      "models": {
        "{env:OPENCODE_MODEL}": {
          "name": "Claude Opus 4.6 (via LiteLLM)"
        }
      }
    }
  },
  "mcp": {
    "aws-knowledge-mcp-server": {
      "type": "local",
      "command": ["uvx", "fastmcp", "run", "https://knowledge-mcp.global.api.aws"],
      "enabled": true
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "${env:CONTEXT7_API_KEY}"
      },
      "enabled": true
    }
  }
}
```




