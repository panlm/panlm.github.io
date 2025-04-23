---
title: MCP Server on EC2
description: 将 MCP Server 移动到远端，减少本地资源占用
created: 2025-04-21 10:45:11.160
last_modified: 2025-04-21
tags:
  - draft
  - llm/mcp
status: myblog
---

# MCP Server on EC2

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
uv python install 3.10
```

we will use [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) to move mcp server to ec2 and let client access mcp server through SSE

```mermaid
graph LR
    A["LLM Client<br>Cline in VSCode"] <-->|SSE| B1
    A <-->|SSE| B2

    subgraph EC2["EC2 Instance"]
        B1["mcp-proxy"]
        C1["Local MCP Server"]
        B1 <-->|stdio| C1
        B2["mcp-proxy"]
        C2["Local MCP Server"]
        B2 <-->|stdio| C2

    end

    style A fill:#ffe6f9,stroke:#333,color:black,stroke-width:2px
    style B1 fill:#e6e6ff,stroke:#333,color:black,stroke-width:2px
    style C1 fill:#e6ffe6,stroke:#333,color:black,stroke-width:2px
    style B2 fill:#e6e6ff,stroke:#333,color:black,stroke-width:2px
    style C2 fill:#e6ffe6,stroke:#333,color:black,stroke-width:2px
    style EC2 fill:#f0f0f0,stroke:#333,stroke-width:2px

```

- start mcp-proxy 
```sh
nohup mcp-proxy --sse-host=0.0.0.0 --sse-port=8808 uvx mcp-server-fetch 2>&1 1>/tmp/mcp-proxy-8808.log &
nohup mcp-proxy --sse-host=0.0.0.0 --sse-port=8809 --env FASTMCP_LOG_LEVEL ERROR uvx awslabs.aws-documentation-mcp-server@latest 2>&1 1>/tmp/mcp-proxy-8809.log &
nohup mcp-proxy --sse-host=0.0.0.0 --sse-port=8810 --env SEARXNG_URL https://searx.xxx -- docker run -i --rm -e SEARXNG_URL mcp-searxng:latest 2>&1 1>/tmp/mcp-proxy-8810.log &

```

## Use SSE to MCP Server in VSCode Cline

- mcp-server json sample
```json
    "mcp-server-fetch-remote": {
      "autoApprove": [
        "fetch"
      ],
      "disabled": false,
      "timeout": 60,
      "url": "http://xxx:8808/sse",
      "transportType": "sse"
    },
    "awslabs.aws-documentation-mcp-server-remote": {
      "autoApprove": [],
      "disabled": false,
      "timeout": 60,
      "url": "http://xxx:8809/sse",
      "transportType": "sse"
    },
    "searxng-remote": {
      "autoApprove": [
        "searxng_web_search",
        "web_url_read"        
      ],
      "disabled": false,
      "timeout": 60,
      "url": "http://xxx:8810/sse",
      "transportType": "sse"
    },

```

## Use SSE to MCP Server in Dify

- install MCP tools Via SSE plugin in Dify marketplace
![[attachments/build-mcp-server-on-ec2/IMG-build-mcp-server-on-ec2.png|500]]

- Set up authorization
```json
{
  "fetch": {
    "url": "http://xxx:8808/sse",
    "headers": {},
    "timeout": 60,
    "sse_read_timeout": 300
  },
  "aws-docs": {
    "url": "http://xxx:8809/sse",
    "headers": {},
    "timeout": 60,
    "sse_read_timeout": 300
  },
  "searxng": {
    "url": "http://xxx:8810/sse",
    "headers": {},
    "timeout": 60,
    "sse_read_timeout": 300
  }
}
```

- create a new agent in Dify Studio
![[attachments/build-mcp-server-on-ec2/IMG-build-mcp-server-on-ec2-1.png]]





